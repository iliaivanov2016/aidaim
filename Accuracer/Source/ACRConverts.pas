unit ACRConverts;

interface

{$I ACRVer.inc}

uses SysUtils,
     DB,
{$IFDEF MSWINDOWS}
     Controls,
     Windows,
{$ENDIF}
{$IFDEF LINUX}
     Libc,
{$ENDIF}
     ACRTypes,
     ACRStrUtils,
     ACRDecUtil,
     ACRDecFmt,
     ACRDecCRC,
{$IFDEF D12H}
     ACR_d12h,
{$ENDIF}
{$IFNDEF D6H}
     ACRD4Routines,
{$ENDIF}   
{$IFDEF DEBUG_LOG}
     ACRDebug,
{$ENDIF}
     ACRExcept,
     ACRConst,
     ACRMemory  // last
     ;

const
  WildCardMultipleChar = '%';
  WildCardSingleChar = '_';

type

{$IFDEF LINUX}
  // Delphi7 Controls.pas
  TDate = type TDateTime;
  TTime = type TDateTime;
{$ENDIF}

  TSQLFieldType = packed record
    SqlName:            AnsiString;
    AdvancedFieldType:  TACRAdvancedFieldType;
    BaseFieldType:      TACRBaseFieldType;
    FieldType:          TFieldType;
  end;

  TACRFieldTypeDesc = packed record
    Name:               AnsiString;
    AdvancedFieldType:  TACRAdvancedFieldType;
  end;

// 0 - unknown
var ACRFieldTypeNamesCRC: array[1..35] of Cardinal;
var SQLFieldTypeNamesCRC: array[1..59] of Cardinal;

const ACRFieldTypes: array[1..35] of TACRFieldTypeDesc = (
(Name: 'Char'; AdvancedFieldType:     aftChar),
(Name: 'Varchar'; AdvancedFieldType:     aftString),

(Name: 'WideChar'; AdvancedFieldType:     aftWideChar),
(Name: 'WideVarchar'; AdvancedFieldType:     aftWideString),

(Name: 'ShortInt'; AdvancedFieldType:     aftShortint),
(Name: 'SmallInt'; AdvancedFieldType:     aftSmallint),
(Name: 'Integer'; AdvancedFieldType:     aftInteger),
(Name: 'LargeInt'; AdvancedFieldType:     aftLargeint),
(Name: 'Byte'; AdvancedFieldType:     aftByte),
(Name: 'Word'; AdvancedFieldType:     aftWord),
(Name: 'Cardinal'; AdvancedFieldType:     aftCardinal),

(Name: 'AutoInc'; AdvancedFieldType:     aftAutoInc),
(Name: 'AutoIncShortInt'; AdvancedFieldType:     aftAutoIncShortint),
(Name: 'AutoIncSmallInt'; AdvancedFieldType:     aftAutoIncSmallint),
(Name: 'AutoIncInteger'; AdvancedFieldType:     aftAutoIncInteger),
(Name: 'AutoIncLargeInt'; AdvancedFieldType:     aftAutoIncLargeint),
(Name: 'AutoIncByte'; AdvancedFieldType:     aftAutoIncByte),
(Name: 'AutoIncWord'; AdvancedFieldType:     aftAutoIncWord),
(Name: 'AutoIncCardinal'; AdvancedFieldType:     aftAutoIncCardinal),

(Name: 'Single'; AdvancedFieldType:     aftSingle),
(Name: 'Double'; AdvancedFieldType:     aftDouble),
(Name: 'Extended'; AdvancedFieldType:     aftExtended),

(Name: 'Boolean'; AdvancedFieldType:     aftBoolean),

(Name: 'Currency'; AdvancedFieldType:     aftCurrency),

(Name: 'Date'; AdvancedFieldType:     aftDate),
(Name: 'Time'; AdvancedFieldType:     aftTime),
(Name: 'DateTime'; AdvancedFieldType:     aftDateTime),
(Name: 'TimeStamp'; AdvancedFieldType:     aftTimeStamp),

(Name: 'Memo'; AdvancedFieldType:     aftMemo),
(Name: 'WideMemo'; AdvancedFieldType:     aftWideMemo),
(Name: 'FormattedMemo'; AdvancedFieldType:     aftFormattedMemo),
(Name: 'BLOB'; AdvancedFieldType:     aftBlob),
(Name: 'Graphic'; AdvancedFieldType:     aftGraphic),

(Name: 'Bytes'; AdvancedFieldType:     aftBytes),
(Name: 'VarBytes'; AdvancedFieldType:     aftVarBytes)
);

const
  SQLFieldTypes: array[1..59] of TSQLFieldType = (

    (SqlName: 'CHAR';           AdvancedFieldType: aftChar;           BaseFieldType: bftChar;         FieldType: ftFixedChar),
    (SqlName: 'FIXEDCHAR';      AdvancedFieldType: aftChar;           BaseFieldType: bftChar;         FieldType: ftFixedChar),
    (SqlName: 'STRING';         AdvancedFieldType: aftString;         BaseFieldType: bftVarchar;      FieldType: ftString),
    (SqlName: 'VARCHAR';        AdvancedFieldType: aftString;         BaseFieldType: bftVarchar;      FieldType: ftString),
    (SqlName: 'VARCHAR2';       AdvancedFieldType: aftString;         BaseFieldType: bftVarchar;      FieldType: ftString),
    (SqlName: 'WIDECHAR';       AdvancedFieldType: aftWideChar;       BaseFieldType: bftWideChar;     FieldType: ftWideString),
{$IFDEF D10H}
    (SqlName: 'FIXEDWIDECHAR';  AdvancedFieldType: aftWideChar;       BaseFieldType: bftWideChar;     FieldType: ftFixedWideChar),
{$ELSE}
    (SqlName: 'FIXEDWIDECHAR';  AdvancedFieldType: aftWideChar;       BaseFieldType: bftWideChar;     FieldType: ftWideString),
{$ENDIF}
    (SqlName: 'WIDESTRING';     AdvancedFieldType: aftWideString;     BaseFieldType: bftWideVarchar;  FieldType: ftWideString),
    (SqlName: 'WIDEVARCHAR';    AdvancedFieldType: aftWideString;     BaseFieldType: bftWideVarchar;  FieldType: ftWideString),

    (SqlName: 'SIGNEDINT16';    AdvancedFieldType: aftSmallint;       BaseFieldType: bftSignedInt16;  FieldType: ftSmallint),
    (SqlName: 'SMALLINT';       AdvancedFieldType: aftSmallint;       BaseFieldType: bftSignedInt16;  FieldType: ftSmallint),
    (SqlName: 'INTEGER';        AdvancedFieldType: aftInteger;        BaseFieldType: bftSignedInt32;  FieldType: ftInteger),
    (SqlName: 'SIGNEDINT32';    AdvancedFieldType: aftInteger;        BaseFieldType: bftSignedInt32;  FieldType: ftInteger),
    (SqlName: 'SIGNEDINT64';    AdvancedFieldType: aftLargeint;       BaseFieldType: bftSignedInt64;  FieldType: ftLargeint),
    (SqlName: 'LARGEINT';       AdvancedFieldType: aftLargeint;       BaseFieldType: bftSignedInt64;  FieldType: ftLargeint),
    (SqlName: 'INT64';          AdvancedFieldType: aftLargeint;       BaseFieldType: bftSignedInt64;  FieldType: ftLargeint),
    (SqlName: 'UNSIGNEDINT16';  AdvancedFieldType: aftWord;           BaseFieldType: bftUnsignedInt16;FieldType: ftWord),
    (SqlName: 'WORD';           AdvancedFieldType: aftWord;           BaseFieldType: bftUnsignedInt16;FieldType: ftWord),
{$IFDEF D12H}
    (SqlName: 'SIGNEDINT8';     AdvancedFieldType: aftShortint;       BaseFieldType: bftSignedInt8;   FieldType: ftShortint),
    (SqlName: 'SHORTINT';       AdvancedFieldType: aftShortint;       BaseFieldType: bftSignedInt8;   FieldType: ftShortint),
    (SqlName: 'UNSIGNEDINT8';   AdvancedFieldType: aftByte;           BaseFieldType: bftUnsignedInt8; FieldType: ftByte),
    (SqlName: 'BYTE';           AdvancedFieldType: aftByte;           BaseFieldType: bftUnsignedInt8; FieldType: ftByte),
    (SqlName: 'UNSIGNEDINT32';  AdvancedFieldType: aftCardinal;       BaseFieldType: bftUnsignedInt32;FieldType: ftLongWord),
    (SqlName: 'CARDINAL';       AdvancedFieldType: aftCardinal;       BaseFieldType: bftUnsignedInt32;FieldType: ftLongWord),
{$ELSE}
    (SqlName: 'SIGNEDINT8';     AdvancedFieldType: aftShortint;       BaseFieldType: bftSignedInt8;   FieldType: ftInteger),
    (SqlName: 'SHORTINT';       AdvancedFieldType: aftShortint;       BaseFieldType: bftSignedInt8;   FieldType: ftInteger),
    (SqlName: 'UNSIGNEDINT8';   AdvancedFieldType: aftByte;           BaseFieldType: bftUnsignedInt8; FieldType: ftWord),
    (SqlName: 'BYTE';           AdvancedFieldType: aftByte;           BaseFieldType: bftUnsignedInt8; FieldType: ftWord),
    (SqlName: 'UNSIGNEDINT32';  AdvancedFieldType: aftCardinal;       BaseFieldType: bftUnsignedInt32;FieldType: ftLargeint),
    (SqlName: 'CARDINAL';       AdvancedFieldType: aftCardinal;       BaseFieldType: bftUnsignedInt32;FieldType: ftLargeint),
{$ENDIF}

    (SqlName: 'AUTOINC';        AdvancedFieldType: aftAutoInc;        BaseFieldType: bftSignedInt32;  FieldType: ftAutoInc),
    (SqlName: 'AUTOINCSHORTINT';AdvancedFieldType: aftAutoIncShortint;BaseFieldType: bftSignedInt8;   FieldType: ftAutoInc),
    (SqlName: 'AUTOINCSMALLINT';AdvancedFieldType: aftAutoIncSmallint;BaseFieldType: bftSignedInt16;  FieldType: ftAutoInc),
    (SqlName: 'AUTOINCINTEGER'; AdvancedFieldType: aftAutoIncInteger; BaseFieldType: bftSignedInt32;  FieldType: ftAutoInc),
    (SqlName: 'AUTOINCLARGEINT';AdvancedFieldType: aftAutoIncLargeint;BaseFieldType: bftSignedInt64;  FieldType: ftLargeInt),
    (SqlName: 'AUTOINCBYTE';    AdvancedFieldType: aftAutoIncByte;    BaseFieldType: bftUnsignedInt8; FieldType: ftAutoInc),
    (SqlName: 'AUTOINCWORD';    AdvancedFieldType: aftAutoIncWord;    BaseFieldType: bftUnsignedInt16;FieldType: ftAutoInc),
    (SqlName: 'AUTOINCCARDINAL';AdvancedFieldType: aftAutoIncCardinal;BaseFieldType: bftUnsignedInt32;FieldType: ftAutoInc),

    (SqlName: 'FLOAT';          AdvancedFieldType: aftDouble;         BaseFieldType: bftDouble;       FieldType: ftFloat),
    (SqlName: 'SINGLE';         AdvancedFieldType: aftSingle;         BaseFieldType: bftSingle;       FieldType: ftFloat),
    (SqlName: 'DOUBLE';         AdvancedFieldType: aftDouble;         BaseFieldType: bftDouble;       FieldType: ftFloat),
    (SqlName: 'EXTENDED';       AdvancedFieldType: aftExtended;       BaseFieldType: bftExtended;     FieldType: ftFloat),

    (SqlName: 'LOGICAL';        AdvancedFieldType: aftBoolean;        BaseFieldType: bftLogical;      FieldType: ftBoolean),
    (SqlName: 'BOOLEAN';        AdvancedFieldType: aftBoolean;        BaseFieldType: bftLogical;      FieldType: ftBoolean),
    (SqlName: 'BOOL';           AdvancedFieldType: aftBoolean;        BaseFieldType: bftLogical;      FieldType: ftBoolean),
    (SqlName: 'BIT';            AdvancedFieldType: aftBoolean;        BaseFieldType: bftLogical;      FieldType: ftBoolean),

    (SqlName: 'CURRENCY';        AdvancedFieldType: aftCurrency;      BaseFieldType: bftCurrency;     FieldType: ftCurrency),
    (SqlName: 'MONEY';          AdvancedFieldType: aftCurrency;      BaseFieldType: bftCurrency;     FieldType: ftCurrency),

    (SqlName: 'DATE';            AdvancedFieldType: aftDate;          BaseFieldType: bftDate;         FieldType: ftDate),
    (SqlName: 'TIME';            AdvancedFieldType: aftTime;          BaseFieldType: bftTime;         FieldType: ftTime),
    (SqlName: 'DATETIME';        AdvancedFieldType: aftDateTime;      BaseFieldType: bftDateTime;     FieldType: ftDateTime),
{$IFDEF D6H}
    (SqlName: 'TIMESTAMP';       AdvancedFieldType: aftTimeStamp;     BaseFieldType: bftDateTime;     FieldType: ftTimeStamp),
{$ELSE}
    (SqlName: 'TIMESTAMP';       AdvancedFieldType: aftTimeStamp;     BaseFieldType: bftDateTime;     FieldType: ftUnknown),
{$ENDIF}

    (SqlName: 'BLOB';            AdvancedFieldType: aftBlob;          BaseFieldType: bftBlob;         FieldType: ftBlob),
    (SqlName: 'BLOB';            AdvancedFieldType: aftBlob;          BaseFieldType: bftBlob;         FieldType: ftParadoxOle),
    (SqlName: 'BLOB';            AdvancedFieldType: aftBlob;          BaseFieldType: bftBlob;         FieldType: ftTypedBinary),
    (SqlName: 'BLOB';            AdvancedFieldType: aftBlob;          BaseFieldType: bftBlob;         FieldType: ftDBaseOle),
    (SqlName: 'GRAPHIC';         AdvancedFieldType: aftGraphic;       BaseFieldType: bftBlob;         FieldType: ftGraphic),
    (SqlName: 'MEMO';            AdvancedFieldType: aftMemo;          BaseFieldType: bftClob;         FieldType: ftMemo),
    (SqlName: 'CLOB';            AdvancedFieldType: aftMemo;          BaseFieldType: bftClob;         FieldType: ftMemo),
    (SqlName: 'FORMATTEDMEMO';   AdvancedFieldType: aftFormattedMemo; BaseFieldType: bftClob;         FieldType: ftFmtMemo),
{$IFDEF D10H}
    (SqlName: 'WIDEMEMO';        AdvancedFieldType: aftWideMemo;      BaseFieldType: bftWideClob;     FieldType: ftWideMemo),
    (SqlName: 'WIDECLOB';        AdvancedFieldType: aftWideMemo;      BaseFieldType: bftWideClob;     FieldType: ftWideMemo),
{$ELSE}
    (SqlName: 'WIDEMEMO';        AdvancedFieldType: aftWideMemo;      BaseFieldType: bftWideClob;     FieldType: ftMemo),
    (SqlName: 'WIDECLOB';        AdvancedFieldType: aftWideMemo;      BaseFieldType: bftWideClob;     FieldType: ftMemo),
{$ENDIF}

    (SqlName: 'GUID';            AdvancedFieldType: aftChar;          BaseFieldType: bftChar;         FieldType: ftGuid),
    (SqlName: 'BYTES';           AdvancedFieldType: aftBytes;         BaseFieldType: bftBytes;        FieldType: ftBytes),
    (SqlName: 'VARBYTES';        AdvancedFieldType: aftVarBytes;      BaseFieldType: bftVarBytes;     FieldType: ftVarBytes)
  );

  // Convert AdvancedFieldType to BasicFieldType
  function AdvancedFieldTypeToBaseFieldType(AdvancedFieldType: TACRAdvancedFieldType): TACRBaseFieldType;
  // Convert BaseFieldType to AdvancedFieldType
  function BaseFieldTypeToAdvancedFieldType(BaseFieldType: TACRBaseFieldType): TACRAdvancedFieldType;

  // Converts TFieldType to TACRAdvancedFieldType
  function FieldTypeToACRAdvFieldType(FieldType: TFieldType): TACRAdvancedFieldType;
  // Converts TACRAdvancedFieldType to TFieldType
  function ACRAdvFieldTypeToFieldType(AdvancedFieldType: TACRAdvancedFieldType): TFieldType;

  // AdvancedFieldType for print
  function AftToStr(AdvancedFieldType: TACRAdvancedFieldType): AnsiString;
  // BaseFieldType for print
  function BftToStr(BaseFieldType: TACRBaseFieldType): AnsiString;

  // ACR field type name to AdvancedFieldType
  function ACRStrToAft(ACRTypeName: AnsiString): TACRAdvancedFieldType;
  // ACR field type name to BaseFieldType
  function ACRStrToBft(ACRTypeName: AnsiString): TACRBaseFieldType;
  // SQL field type name to AdvancedFieldType
  function SQLStrToAft(SQLTypeName: AnsiString): TACRAdvancedFieldType;
  // SQL field type name to BaseFieldType
  function SQLStrToBft(SQLTypeName: AnsiString): TACRBaseFieldType;


  // Convert ACRDate to Date
  function ACRDateToDate(ACRDate: TACRDate): TDate; overload;
  // Convert Date to ACRDate
  function DateToACRDate(Date: TDate): TACRDate; overload;

  // Convert ACRTime to Time
  function ACRTimeToTime(ACRTime: TACRTime): TTime; overload;
  // Convert Time to ACRTime
  function TimeToACRTime(Time: TTime): TACRTime; overload;

  // Convert ACRDateTime to DateTime
  function ACRDateTimeToDateTime(ACRDateTime: TACRDateTime): TDateTime; overload;
  // Convert DateTime to ACRDateTime
  function DateTimeToACRDateTime(DateTime: TDateTime): TACRDateTime; overload;

  // return true if field type is a BLOB field type
  function IsBLOBFieldType(FieldType: TACRBaseFieldType): Boolean; overload;
  function IsBLOBFieldType(FieldType: TACRAdvancedFieldType): Boolean; overload;

  // return true if field type is a varchar field type
  function IsVarcharFieldType(FieldType: TACRBaseFieldType): Boolean; overload;
  function IsVarcharFieldType(FieldType: TACRAdvancedFieldType): Boolean; overload;

  // return true if field type is a AnsiString field type, but not wide AnsiString
  function IsStringFieldType(FieldType: TACRBaseFieldType): Boolean; overload;
  function IsStringFieldType(FieldType: TACRAdvancedFieldType): Boolean; overload;

  // return true if field type is a wide AnsiString field type
  function IsWideStringFieldType(FieldType: TACRBaseFieldType): Boolean; overload;
  function IsWideStringFieldType(FieldType: TACRAdvancedFieldType): Boolean; overload;

  // return true if field type is bytes field type
  function IsBytesFieldType(FieldType: TACRBaseFieldType): Boolean; overload;
  function IsBytesFieldType(FieldType: TACRAdvancedFieldType): Boolean; overload;

  // return true if field type is Autoinc field type
  function IsAutoincFieldType(FieldType: TACRAdvancedFieldType): Boolean; overload;

  // return true if DataType is numeric
  function IsNumericFieldType(FieldType: TACRBaseFieldType): Boolean;

  // return true if DataType is integer
  function IsIntegerFieldType(FieldType: TACRBaseFieldType): Boolean;

  // return true if DataType is TateTime, Time, Date, TimeStamp
  function IsDateTimeFieldType(FieldType: TACRBaseFieldType): Boolean;

  // Result = Can cast this type
  function IsConvertableFieldType(FieldType: TACRAdvancedFieldType): boolean;

  // Like '%_' compare for AnsiString
  function IsStrMatchPattern(StrPtr: PAnsiChar; PatternPtr: PAnsiChar; bIgnoreCase:boolean): Boolean;
  // Like '%_' compare for WideString
  function IsWideStrMatchPattern(StrPtr: PWideChar; PatternPtr: PWideChar; bIgnoreCase:boolean): Boolean;

  function GetStrLength(Buffer: PAnsiChar; FieldType: TACRAdvancedFieldType): Integer;

  function GetReservedWord(Word: TReservedWord): WideString;

  // return HEX AnsiString converted from the source buffer
  function ACRBinaryToHEX(Data: PAnsiChar; Size: Integer): WideString;
  // return MIME64 AnsiString converted from the source buffer
  function ACRBinaryToMIME64(Data: PAnsiChar; Size: Integer): WideString;
  // allocate buffer and return binary data converted from HEX
  function ACRHEXToBinary(const HEXValue: WideString): PAnsiChar;
  // allocate buffer and return binary data converted from MIME64
  function ACRMIME64ToBinary(const MIME64Value: WideString): PAnsiChar;
{$IFDEF DEBUG_LOG}
  function LockTypeToStr(LockType: TACRLockType): AnsiString;
  function GetRecordModeToStr(GetRecordMode: TACRGetRecordMode): AnsiString;
  function GetRecordResultToStr(GetRecordResult: TACRGetRecordResult): AnsiString;
{$ENDIF}

implementation

//------------------------------------------------------------------------------
// Convert AdvancedFieldType to BasicFieldType
//------------------------------------------------------------------------------
function AdvancedFieldTypeToBaseFieldType(AdvancedFieldType: TACRAdvancedFieldType): TACRBaseFieldType;
var i: Integer;
begin
  Result := bftUnknown;
  for i:=Low(SQLFieldTypes) to High(SQLFieldTypes) do
    if SQLFieldTypes[i].AdvancedFieldType = AdvancedFieldType then
      begin
        Result := SQLFieldTypes[i].BaseFieldType;
        break;
      end;
end;//AdvancedFieldTypeToBasicFieldType


//------------------------------------------------------------------------------
// Convert BaseFieldType to AdvancedFieldType
//------------------------------------------------------------------------------
function BaseFieldTypeToAdvancedFieldType(BaseFieldType: TACRBaseFieldType): TACRAdvancedFieldType;
var i: Integer;
begin
  Result := aftUnknown;
  for i:=Low(SQLFieldTypes) to High(SQLFieldTypes) do
    if SQLFieldTypes[i].BaseFieldType = BaseFieldType then
      begin
        Result := SQLFieldTypes[i].AdvancedFieldType;
        break;
      end;
end;//BaseFieldTypeToAdvancedFieldType


//------------------------------------------------------------------------------
// Converts TFieldType to TACRAdvancedFieldType
//------------------------------------------------------------------------------
function FieldTypeToACRAdvFieldType(FieldType: TFieldType): TACRAdvancedFieldType;
var i: Integer;
begin
  Result := aftUnknown;
  for i:=Low(SQLFieldTypes) to High(SQLFieldTypes) do
    if SQLFieldTypes[i].FieldType = FieldType then
      begin
        Result := SQLFieldTypes[i].AdvancedFieldType;
        break;
      end;
  if (Result = aftUnknown) then
    raise EACRException.Create(30289, ErrorGUnknownDataType,
                               [IntToStr(Integer(FieldType))]); 
end;//FieldTypeToACRAdvFieldType


//------------------------------------------------------------------------------
// Converts TACRAdvancedFieldType to TFieldType
//------------------------------------------------------------------------------
function ACRAdvFieldTypeToFieldType(AdvancedFieldType: TACRAdvancedFieldType): TFieldType;
var i: Integer;
begin
  Result := ftUnknown;
  for i:=Low(SQLFieldTypes) to High(SQLFieldTypes) do
    if SQLFieldTypes[i].AdvancedFieldType = AdvancedFieldType then
      begin
        Result := SQLFieldTypes[i].FieldType;
        break;
      end;
end;//ACRAdvFieldTypeToFieldType


//------------------------------------------------------------------------------
// AdvancedFieldType for print
//------------------------------------------------------------------------------
function AftToStr(AdvancedFieldType: TACRAdvancedFieldType): AnsiString;
var i: Integer;
begin
  Result := 'Unknown';
  for i:=Low(SQLFieldTypes) to High(SQLFieldTypes) do
    if SQLFieldTypes[i].AdvancedFieldType = AdvancedFieldType then
      begin
        Result := SQLFieldTypes[i].SqlName;
        break;
      end;
end;//AftToStr


//------------------------------------------------------------------------------
// BaseFieldType for print
//------------------------------------------------------------------------------
function BftToStr(BaseFieldType: TACRBaseFieldType): AnsiString;
var i: Integer;
begin
  Result := 'Unknown';
  for i:=Low(SQLFieldTypes) to High(SQLFieldTypes) do
    if SQLFieldTypes[i].BaseFieldType = BaseFieldType then
      begin
        Result := SQLFieldTypes[i].SqlName;
        break;
      end;
end;//BftToStr


//------------------------------------------------------------------------------
// ACR field type name to AdvancedFieldType
//------------------------------------------------------------------------------
function ACRStrToAft(ACRTypeName: AnsiString): TACRAdvancedFieldType;
var i:    Integer;
    crc:  Cardinal;
begin
  Result := aftUnknown;
  crc := GetTableNameCRCAnsi(ACRTypeName,True);
  for i := 1 to High(ACRFieldTypeNamesCRC) do
   if (ACRFieldTypeNamesCRC[i] = crc) then
    begin
     Result := ACRFieldTypes[i].AdvancedFieldType;
     break;
    end;
end; // ACRStrToAft


//------------------------------------------------------------------------------
// ACR field type name to BaseFieldType
//------------------------------------------------------------------------------
function ACRStrToBft(ACRTypeName: AnsiString): TACRBaseFieldType;
var i:    Integer;
    crc:  Cardinal;
begin
  Result := bftUnknown;
  crc := GetTableNameCRCAnsi(ACRTypeName,True);
  for i := 1 to High(ACRFieldTypeNamesCRC) do
   if (ACRFieldTypeNamesCRC[i] = crc) then
    begin
     Result := AdvancedFieldTypeToBaseFieldType(ACRFieldTypes[i].AdvancedFieldType);
     break;
    end;
end; // ACRStrToBft


//------------------------------------------------------------------------------
// SQL field type name to AdvancedFieldType
//------------------------------------------------------------------------------
function SQLStrToAft(SQLTypeName: AnsiString): TACRAdvancedFieldType;
var i:    Integer;
    crc:  Cardinal;
begin
  Result := aftUnknown;
  crc := GetTableNameCRCAnsi(SQLTypeName,True);
  for i := 1 to High(SQLFieldTypeNamesCRC) do
   if (SQLFieldTypeNamesCRC[i] = crc) then
    begin
     Result := SQLFieldTypes[i].AdvancedFieldType;
     break;
    end;
end; // SQLStrToAft


//------------------------------------------------------------------------------
// SQL field type name to BaseFieldType
//------------------------------------------------------------------------------
function SQLStrToBft(SQLTypeName: AnsiString): TACRBaseFieldType;
var i:    Integer;
    crc:  Cardinal;
begin
  Result := bftUnknown;
  crc := GetTableNameCRCAnsi(SQLTypeName,True);
  for i := 1 to High(SQLFieldTypeNamesCRC) do
   if (SQLFieldTypeNamesCRC[i] = crc) then
    begin
     Result := SQLFieldTypes[i].BaseFieldType;
     break;
    end;
end; // SQLStrToBft


//------------------------------------------------------------------------------
// Convert ACRDate to Date
//------------------------------------------------------------------------------
function ACRDateToDate(ACRDate: TACRDate): TDate;
begin
  if (ACRDate = DATE_IS_NULL) then
   Result := 0
  else
   Result := ACRDate - DateDelta;
end;//ACRDateToDate


//------------------------------------------------------------------------------
// Convert Date to ACRDate
//------------------------------------------------------------------------------
function DateToACRDate(Date: TDate): TACRDate;
begin
  Result := Trunc(Date) + DateDelta;
end;//DateToACRDate


//------------------------------------------------------------------------------
// Convert ACRTime to Time
//------------------------------------------------------------------------------
function ACRTimeToTime(ACRTime: TACRTime): TTime;
begin
  if (ACRTime = TIME_IS_NULL) then
   Result := 0
  else
   Result := Frac(ACRTime / (24*60*60*1000));
end;//ACRTimeToTime


//------------------------------------------------------------------------------
// Convert Time to ACRTime
//------------------------------------------------------------------------------
function TimeToACRTime(Time: TTime): TACRTime;
begin
  //Result := Trunc(Frac(Time) * (24*60*60*1000));
  Result := Round(Frac(Time) * (24*60*60*1000));
end;//TimeToACRTime


//------------------------------------------------------------------------------
// Convert ACRDateTime to DateTime
//------------------------------------------------------------------------------
function ACRDateTimeToDateTime(ACRDateTime: TACRDateTime): TDateTime;
begin
  if (ACRDateTime.Time = TIME_IS_NULL) then
   Result := ACRDateToDate(ACRDateTime.Date)
  else
   Result := ACRDateToDate(ACRDateTime.Date) + ACRTimeToTime(ACRDateTime.Time);
end;//ACRDateTimeToDateTime


//------------------------------------------------------------------------------
// Convert DateTime to ACRDateTime
//------------------------------------------------------------------------------
function DateTimeToACRDateTime(DateTime: TDateTime): TACRDateTime;
begin
  Result.Date := DateToACRDate(DateTime);
  Result.Time := TimeToACRTime(DateTime);
end;//ACRDateTimeToDateTime


//------------------------------------------------------------------------------
// return true if field type is a BLOB field type
//------------------------------------------------------------------------------
function IsBLOBFieldType(FieldType: TACRBaseFieldType): Boolean;
begin
  Result := FieldType in [bftBLOB, bftClob, bftWideClob];
end; // IsBLOBFieldType


//------------------------------------------------------------------------------
// return true if field type is a BLOB field type
//------------------------------------------------------------------------------
function IsBLOBFieldType(FieldType: TACRAdvancedFieldType): Boolean;
begin
  Result := FieldType in [aftBLOB, aftGraphic, aftMemo, aftFormattedMemo, aftWideMemo];
end; // IsBLOBFieldType


//------------------------------------------------------------------------------
// return true if field type is a varchar field type
//------------------------------------------------------------------------------
function IsVarcharFieldType(FieldType: TACRBaseFieldType): Boolean;
begin
  Result := FieldType in [bftWideVarchar, bftVarchar];
end; // IsVarcharFieldType


//------------------------------------------------------------------------------
// return true if field type is a varchar field type
//------------------------------------------------------------------------------
function IsVarcharFieldType(FieldType: TACRAdvancedFieldType): Boolean;
begin
  Result := FieldType in [aftWideString, aftString];
end; // IsVarcharFieldType


//------------------------------------------------------------------------------
// return true if field type is a AnsiString field type, but not wide AnsiString
//------------------------------------------------------------------------------
function IsStringFieldType(FieldType: TACRBaseFieldType): Boolean;
begin
  Result := FieldType in [bftChar, bftWideChar, bftVarchar, bftWideVarchar , bftClob, bftWideClob];
end; // IsStringFieldType


//------------------------------------------------------------------------------
// return true if field type is a AnsiString field type, but not wide AnsiString
//------------------------------------------------------------------------------
function IsStringFieldType(FieldType: TACRAdvancedFieldType): Boolean;
begin
  Result := FieldType in [aftChar, aftString, aftWideChar, aftWideString ]; // , aftMemo, aftFormattedMemo, aftWideMemo
end; // IsStringFieldType


//------------------------------------------------------------------------------
// return true if field type is a wide AnsiString field type
//------------------------------------------------------------------------------
function IsWideStringFieldType(FieldType: TACRBaseFieldType): Boolean;
begin
  Result := FieldType in [bftWideChar, bftWideVarchar, bftWideClob];
end; // IsStringFieldType


//------------------------------------------------------------------------------
// return true if field type is a wide AnsiString field type
//------------------------------------------------------------------------------
function IsWideStringFieldType(FieldType: TACRAdvancedFieldType): Boolean;
begin
  Result := FieldType in [aftWideChar, aftWideString, aftWideMemo];
end; // IsWideStringFieldType


//------------------------------------------------------------------------------
// return true if field type is a Bytes field type, but not wide Bytes
//------------------------------------------------------------------------------
function IsBytesFieldType(FieldType: TACRBaseFieldType): Boolean;
begin
  Result := FieldType in [bftBytes, bftVarBytes];
end; // IsBytesFieldType


//------------------------------------------------------------------------------
// return true if field type is a Bytes field type, but not wide Bytes
//------------------------------------------------------------------------------
function IsBytesFieldType(FieldType: TACRAdvancedFieldType): Boolean;
begin
  Result := FieldType in [aftBytes, aftVarBytes];
end; // IsBytesFieldType


//------------------------------------------------------------------------------
// return true if field type is a Autoinc field type, but not wide Autoinc
//------------------------------------------------------------------------------
function IsAutoincFieldType(FieldType: TACRAdvancedFieldType): Boolean;
begin
  Result := FieldType in [aftAutoInc,
                          aftAutoIncShortint,
                          aftAutoIncSmallint,
                          aftAutoIncInteger,
                          aftAutoIncLargeint,
                          aftAutoIncByte,
                          aftAutoIncWord,
                          aftAutoIncCardinal];
end; // IsAutoincFieldType


//------------------------------------------------------------------------------
// return true if DataType is numeric
//------------------------------------------------------------------------------
function IsNumericFieldType(FieldType: TACRBaseFieldType): Boolean;
begin
  Result := FieldType in [bftSignedInt8, bftSignedInt16, bftSignedInt32, bftSignedInt64,
                          bftUnsignedInt8, bftUnsignedInt16, bftUnsignedInt32,
                          bftSingle, bftDouble, bftExtended, bftCurrency];
end;//IsNumericDataType


//------------------------------------------------------------------------------
// return true if DataType is numeric
//------------------------------------------------------------------------------
function IsIntegerFieldType(FieldType: TACRBaseFieldType): Boolean;
begin
  Result := FieldType in [
                          bftSignedInt8, bftSignedInt16, bftSignedInt32,
                          bftSignedInt64,
                          bftUnsignedInt8, bftUnsignedInt16, bftUnsignedInt32
                         ];
end;//IsIntegerDataType


//------------------------------------------------------------------------------
// return true if DataType is TateTime, Time, Date, TimeStamp
//------------------------------------------------------------------------------
function IsDateTimeFieldType(FieldType: TACRBaseFieldType): Boolean;
begin
  Result := FieldType in [bftDate, bftTime, bftDateTime];
end;//IsDateTimeFieldType

//------------------------------------------------------------------------------
// Result = Can cast this type
//------------------------------------------------------------------------------
function IsConvertableFieldType(FieldType: TACRAdvancedFieldType): boolean;
begin
  Result := FieldType in [aftChar, aftString, aftWideChar, aftWideString,
                          aftShortint, aftSmallint, aftInteger,
                          aftAutoInc, aftAutoIncShortint,
                          aftAutoIncSmallint, aftAutoIncInteger,
                          aftAutoIncLargeint, aftAutoIncByte,
                          aftAutoIncWord, aftAutoIncCardinal,
                          aftLargeint, aftByte, aftWord, aftCardinal,
                          aftSingle, aftDouble, aftExtended,
                          aftBoolean,
                          aftCurrency,
                          aftDate, aftTime, aftDateTime, aftTimeStamp];
end; // IsConvertableFieldType


//------------------------------------------------------------------------------
// IsStrMatchPattern
//------------------------------------------------------------------------------
function IsStrMatchPattern(StrPtr: PAnsiChar; PatternPtr: PAnsiChar; bIgnoreCase:boolean): Boolean;
var i : integer;
    bEQ: Boolean;
    tmp1, tmp2: array [0..1] of AnsiChar;
begin
  if (bIgnoreCase) then
   begin
    tmp1[1]:=#0;
    tmp2[1]:=#0;
   end;
  repeat
      if (StrComp(PatternPtr,WildCardMultipleChar)=0) then
       begin
         Result:=True;
         exit;
       end
      else if (StrPtr^=#0) and (PatternPtr^ <> #0) then
       begin
         Result:=False;
         exit;
       end
      else if (StrPtr^=#0) then
       begin
         Result:=True;
         exit;
       end
      else
         begin
           case PatternPtr^ of
            WildCardMultipleChar:
               begin
                for i:=0 to Length(StrPtr)-1 do
                 begin
                  if IsStrMatchPattern(StrPtr+i,PatternPtr+1,bIgnoreCase) then
                   begin
                    Result := True;
                    exit;
                   end;
                 end;
                Result := False;
                exit;
               end;
            WildCardSingleChar:
               begin
                inc(StrPtr);
                inc(PatternPtr);
               end;
            else
               begin
// changed in v.4.80 to avoid bugs in Asian Windows
                if (bIgnoreCase) then
                 begin
                  tmp1[0] := StrPtr^;
                  tmp2[0] := PatternPtr^;
{$IFDEF MSWINDOWS}
                   //bEQ := (Q_AnsiCompTextL(tmp1, tmp2, 1) = 0)
                   bEQ := (CompareStringA(LOCALE_USER_DEFAULT,
                           NORM_IGNORECASE + SORT_STRINGSORT,
  //                         SORT_STRINGSORT,
                           tmp1, 1, tmp2, 1) - 2) = 0
{$ENDIF}
{$IFDEF LINUX}
                   bEQ := (strncmp(tmp1, tmp2, 1)) = 0
{$ENDIF}
                 end // bIgnoreCase
                else
                 begin
{$IFDEF MSWINDOWS}
                 //bEQ := (Q_AnsiCompStrL(tmp1, tmp2, 1) = 0);
// changed in v.4.80 to avoid bugs in Asian Windows
                   bEQ := (StrPtr^ = PatternPtr^);
{
                   bEQ := (CompareStringA(LOCALE_USER_DEFAULT,
  //                         NORM_IGNORECASE + SORT_STRINGSORT,
                           SORT_STRINGSORT,
                           tmp1, 1, tmp2, 1) - 2) = 0;
}
{$ENDIF}
{$IFDEF LINUX}
                   bEQ := (StrPtr^ = PatternPtr^);
// changed in v.4.80 to avoid bugs in Asian Windows
//                   bEQ := (strncmp(tmp1, tmp2, 1)) = 0;
{$ENDIF}
                 end; // not bIgnoreCase
                if (bEQ) then
                 begin
                  inc(StrPtr);
                  inc(PatternPtr);
                 end
                else
                 begin
                  Result:=False;
                  exit;
                 end;
               end;
           end; // case
         end; // non-simple cases
  until false;
end;// IsStrMatchPattern


//------------------------------------------------------------------------------
// Like '%_' compare for WideString
//------------------------------------------------------------------------------
function IsWideStrMatchPattern(StrPtr: PWideChar; PatternPtr: PWideChar; bIgnoreCase:boolean): Boolean;
var i,len:            Integer;
    bOk:              Boolean;
{$IFDEF MSWINDOWS}
    tmp1, tmp2:       array [0..1] of WideChar;
{$ENDIF}
{$IFDEF LINUX}
    UCS4_S1, UCS4_S2: UCS4String;
{$ENDIF}
begin
{$IFDEF MSWINDOWS}
  if (bIgnoreCase) then
   begin
    tmp1[1]:=#$0000;
    tmp2[1]:=#$0000;
   end;
{$ENDIF}
  repeat
{$IFDEF MSWINDOWS}
      if (CompareStringW(LOCALE_USER_DEFAULT,
                        NORM_IGNORECASE + SORT_STRINGSORT,
                        PatternPtr,
                        Length(PatternPtr),
                        WideChar(WildCardMultipleChar),
                        1)-2 = 0) then
{$ENDIF}
{$IFDEF LINUX}
      UCS4_S1 := WideStringToUCS4AnsiString(PatternPtr);
      UCS4_S2 := WideStringToUCS4AnsiString(WildCardMultipleChar);
  // glibc 2.1.2 / 2.1.3 implementations of wcscoll() and wcsxfrm()
  // have severe capacity limits.  Comparing two 100k strings may
  // exhaust the stack and kill the process.
  // Fixed in glibc 2.1.91 and later.
      SetLastError(0);
      if (wcscoll(PUCS4Chars(UCS4_S1), PUCS4Chars(UCS4_S2)) = 0) then
{$ENDIF}
       begin
         Result:=True;
         exit;
       end
      else if (StrPtr^=#0) and (PatternPtr^ <> #0) then
       begin
         Result:=False;
         exit;
       end
      else if (StrPtr^=#0) then
       begin
         Result:=True;
         exit;
       end
      else
         begin
           // changed in v.4.80
           case AnsiChar(PatternPtr^) of
            WildCardMultipleChar:
               begin
                len := GetStrLength(PAnsiChar(StrPtr),aftWideChar) div 2;
                for i:=0 to len-1 do
                 begin
                  if IsWideStrMatchPattern(StrPtr+i,PatternPtr+1,bIgnoreCase) then
                   begin
                    Result := True;
                    exit;
                   end;
                 end;
                Result := False;
                exit;
               end;
            WildCardSingleChar:
               begin
                inc(StrPtr);
                inc(PatternPtr);
               end;
            else
               begin
                bOk := false;
                if bIgnoreCase then
                 begin
{$IFDEF MSWINDOWS}
                  tmp1[0] := StrPtr^;
                  tmp2[0] := PatternPtr^;
                  if (Windows.CompareStringW(LOCALE_USER_DEFAULT,
                        NORM_IGNORECASE + SORT_STRINGSORT,
                        tmp1, 1, tmp2,1)-2 = 0) then
{$ENDIF}
{$IFDEF LINUX} // case not ignored
                  UCS4_S1 := WideStringToUCS4AnsiString(PatternPtr);
                  UCS4_S2 := WideStringToUCS4AnsiString(StrPtr);
                  if (wcscoll(PUCS4Chars(UCS4_S1), PUCS4Chars(UCS4_S2))
                         = 0) then
{$ENDIF}
                   bOk := true;
                 end
                else
                 begin
{$IFDEF MSWINDOWS}
// changed in v.4.80 to avoid bugs in Asian Windows
                  if (PatternPtr^ = StrPtr^) then
{
                  if (Windows.CompareStringW(LOCALE_USER_DEFAULT,
                        SORT_STRINGSORT,
                        PatternPtr, 1, StrPtr,1)-2 = 0) then
}
{$ENDIF}
{$IFDEF LINUX}
// changed in v.4.80 to avoid bugs in Asian Windows
{
                  UCS4_S1 := WideStringToUCS4AnsiString(PatternPtr);
                  UCS4_S2 := WideStringToUCS4AnsiString(StrPtr);
                  if (wcscoll(PUCS4Chars(UCS4_S1), PUCS4Chars(UCS4_S2))
                         = 0) then
}
                  if (PatternPtr^ = StrPtr^) then
{$ENDIF}
                   bOk := true;
                 end;

                if (bOk) then
                 begin
                  inc(StrPtr);
                  inc(PatternPtr);
                 end
                else
                 begin
                  Result:=False;
                  exit;
                 end;
               end;
           end; // case
         end; // non-simple cases
  until false;
end;// IsWideStrMatchPattern


//------------------------------------------------------------------------------
// return String (both Ansi and Wide) value length in bytes without #0 terminator
//------------------------------------------------------------------------------
function GetStrLength(Buffer: PAnsiChar; FieldType: TACRAdvancedFieldType): Integer;
var i: Integer;
begin
 if (IsWideStringFieldType(FieldType)) then
  begin
    //Result := Length(WideCharTOString(PWideChar(Buffer))) * 2
    i := 0;
    Result := 0;
    while (Buffer <> nil) do
     begin
      if (PAnsiChar(Buffer+i)^ = #0) then
        if (PAnsiChar(Buffer+i+1)^ = #0) then
         begin
          Result := i;
          break;
         end;
      Inc(i);
      Inc(i);
     end;
  end
 else
  Result := {$IFDEF D12H}aaStrLen({$ELSE}StrLen({$ENDIF}Buffer);
end; // GetStrLength


//------------------------------------------------------------------------------
// return reserved word text
//------------------------------------------------------------------------------
function GetReservedWord(Word: TReservedWord): WideString;
begin
  Result := ACRSQLReservedWords[Integer(Word)];
end; // GetReservedWord


//------------------------------------------------------------------------------
// return HEX AnsiString converted from the source buffer
//------------------------------------------------------------------------------
function ACRBinaryToHEX(Data: PAnsiChar; Size: Integer): WideString;
var fm: TFormat_HEX;
begin
 fm := TFormat_HEX.Create;
 try
   Result := fm.Encode(Data^,Size);
 finally
   fm.Free;
 end;
end; // ACRBinaryToHEX


//------------------------------------------------------------------------------
// return MIME64 AnsiString converted from the source buffer
//------------------------------------------------------------------------------
function ACRBinaryToMIME64(Data: PAnsiChar; Size: Integer): WideString;
var fm: TFormat_MIME64;
begin
 fm := TFormat_MIME64.Create;
 try
   Result := fm.Encode(Data^,Size);
 finally
   fm.Free;
 end;
end; // ACRBinaryToMIME64


//------------------------------------------------------------------------------
// allocate buffer and return binary data converted from HEX
//------------------------------------------------------------------------------
{$IFDEF D12H}
function ACRHEXToBinary(const HEXValue: WideString): PAnsiChar;
var s: WideString;
    l: Integer;
var fm: TFormat_HEX;
begin
 fm := TFormat_HEX.Create;
 try
   s := fm.Decode(HEXValue);
   l := Length(s);
   if (l <= 0) then
     Result := nil
   else
     begin
       Result := MemoryManager.GetMem(l*2);
       Move(PAnsiChar(@s[1])^,Result^,l*2);
     end;
 finally
   fm.Free;
 end;
end; // ACRHEXToBinary
{$ELSE}
function ACRHEXToBinary(const HEXValue: WideString): PAnsiChar;
var s: AnsiString;
    l: Integer;
var fm: TFormat_HEX;
begin
 fm := TFormat_HEX.Create;
 try
   s := fm.Decode(HEXValue);
   l := Length(s);
   if (l <= 0) then
     Result := nil
   else
     begin
       Result := MemoryManager.GetMem(l);
       Move(PAnsiChar(@s[1])^,Result^,l);
     end;
 finally
   fm.Free;
 end;
end; // ACRHEXToBinary
{$ENDIF}


//------------------------------------------------------------------------------
// allocate buffer and return binary data converted from MIME64
//------------------------------------------------------------------------------
{$IFDEF D12H}
function ACRMIME64ToBinary(const MIME64Value: WideString): PAnsiChar;
var s: WideString;
    l: Integer;
var fm: TFormat_MIME64;
begin
 fm := TFormat_MIME64.Create;
 try
   s := fm.Decode(MIME64Value);
   l := Length(s);
   if (l <= 0) then
     Result := nil
   else
     begin
       Result := MemoryManager.GetMem(l*2);
       Move(PAnsiChar(@s[1])^,Result^,l*2);
     end;
 finally
   fm.Free;
 end;
end; // ACRMIME64ToBinary
{$ELSE}
function ACRMIME64ToBinary(const MIME64Value: WideString): PAnsiChar;
var s: AnsiString;
    l: Integer;
var fm: TFormat_MIME64;
begin
 fm := TFormat_MIME64.Create;
 try
   s := fm.Decode(MIME64Value);
   l := Length(s);
   if (l <= 0) then
     Result := nil
   else
     begin
       Result := MemoryManager.GetMem(l);
       Move(PAnsiChar(@s[1])^,Result^,l);
     end;
 finally
   fm.Free;
 end;
end; // ACRMIME64ToBinary
{$ENDIF}




{$IFDEF DEBUG_LOG}
function LockTypeToStr(LockType: TACRLockType): AnsiString;
begin
 Result := 'Unknown lock type';
 case LockType of
  ltX: Result := 'X';
  ltIS: Result := 'IS';
  ltS: Result := 'S';
  ltIRW: Result := 'IRW';
  ltRW: Result := 'RW';
  ltU: Result := 'U';
 end;
end;


function GetRecordModeToStr(GetRecordMode: TACRGetRecordMode): AnsiString;
begin
 Result := 'Unknown get record mode';
 case GetRecordMode of
  grmCurrent: Result := 'Current';
  grmNext: Result := 'Next';
  grmPrior: Result := 'Prior';
 end;
end; // GetRecordModeToStr


function GetRecordResultToStr(GetRecordResult: TACRGetRecordResult): AnsiString;
begin
 Result := 'Unknown get record result';
 case GetRecordResult of
  grrOK: Result := 'OK';
  grrBOF: Result := 'BOF';
  grrEOF: Result := 'EOF';
  grrError: Result := 'Error';
 end;
end; // GetRecordResultToStr
{$ENDIF}


procedure ACRFillTypeNamesCRC;
var i:    Integer;
    crc:  Cardinal;
begin
  for i := 1 to High(ACRFieldTypeNamesCRC) do
   begin
    crc := GetTableNameCRCAnsi(ACRFieldTypes[i].Name,True);
    ACRFieldTypeNamesCRC[i] := crc;
   end;
  for i := 1 to High(SQLFieldTypeNamesCRC) do
   begin
    crc := GetTableNameCRCAnsi(SQLFieldTypes[i].SqlName,True);
    SQLFieldTypeNamesCRC[i] := crc;
   end;
end; // ACRFillTypeNamesCRC


initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ACRConverts> starting initialization...');
{$ENDIF}
  ACRMemoryIncUseCount;
  ACRFillTypeNamesCRC;
{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ACRConverts> initialized');
{$ENDIF}

finalization

  ACRMemoryDecUseCount;


end.
