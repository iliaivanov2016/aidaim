unit ACRVariant;

{$I ACRVer.inc}

interface

uses SysUtils, Classes,

{$IFDEF MSWINDOWS}
     Controls,
     Windows,
{$ENDIF}
{$IFDEF LINUX}
     Libc,
     Types,
{$ENDIF}

     Math,

// Accuracer units

{$IFNDEF D6H}
     ACRD4Routines,
{$ENDIF}
{$IFDEF DEBUG_LOG}
     ACRDebug,
{$ENDIF}

{$IFDEF D12H}
     ACR_d12h,
{$ENDIF}

     ACRCompression,
     ACRTypes,
     ACRTypesRoutines,
     ACRConst,
     ACRConverts,
     ACRDecUtil,
     ACRDecCRC,
     ACRDecFMT,

     ACRExcept;

type
{$IFDEF LINUX}
  // Windows.pas
  LCID = DWORD;
const
  LOCALE_USER_DEFAULT =  $400;
  SORT_STRINGSORT     = $1000;
  NORM_IGNORECASE     =     1;
  // Delphi7 Controls.pas
type
  TDate = type TDateTime;
  TTime = type TDateTime;
{$ENDIF}


 // BLOB since v.4.40 are stored in the following format:
 //ANSI         | DATA | 0
 //FDataSize = Lenth(DATA)
 //Unicode      | DATA | 00
 //FDataSize = Lenth(DATA)
 TACRVariant = class(TObject)
  public
   FDataType:     TACRBaseFieldType;    // type of data
   FIsNull:       ByteBool;             // Abstract Boolean Flag
   FDataSize:     Integer;              // size of data value
   FPData:        PAnsiChar;                // Binary data representation
   FIsDataLinked: ByteBool;             // freemem required?
   // added in v.5.10
   FMaxStrLen:    Integer;              // maximum string length in characters - for stored functions
   FIsBLOB:       Boolean;
  public
   // set Buffer to FPData without any other actions
   procedure InternalSetBuffer(Buffer: PAnsiChar; BufferSize: Integer);
   procedure LoadFromStream(Stream: TStream); virtual;
   procedure SaveToStream(Stream: TStream); virtual;
   // Constructor
   constructor Create(DataType: TACRBaseFieldType = bftUnknown);
   // Destructor
   destructor Destroy; override;
   // SetNull
   procedure SetNull(DataType: TACRBaseFieldType = bftUnknown);
   // Free Buffer
   procedure Clear(DataType: TACRBaseFieldType = bftUnknown);
   // Set data size
   procedure SetDataSize(NewSize: Integer);
   // Assign data from source (or make link to Source.Data)
   procedure Assign(
                      Source:       TACRVariant;
                      CopyDataFlag: Boolean = True;
                      AssignName:      Boolean = True
                    ); virtual;
   // Set Data (or make link to Data)
   procedure SetData(
                     Buffer:            Pointer;
                     Size:              Integer;
                     DataType:          TACRBaseFieldType;
                     CopyDataFlag:      Boolean = True;
                     NotLinkedBuffer:   Boolean = False
                     );
   // Copy Data to Address
   function CopyDataToAddress(Buffer: Pointer; MaxSize: Integer = -1): boolean;
   // Cast to new data type
   procedure Cast(NewDataType: TACRBaseFieldType);
   // return true if DataType is numeric
   function IsNumericDataType: Boolean;
   // return true if DataType is integer
   function IsIntegerDataType: Boolean;
   // return true if DataType is AnsiString
   function IsStringDataType: Boolean;
   // return true if DataType is WideString
   function IsWideStringDataType: Boolean;
   // return true if DataType is Time, Date, DateTime
   function IsDateTimeDataType: Boolean;

   // return Length of AnsiString or -1 (if not IsStringType)
   function StrLen: Integer;

   // data := -data ( if not number then raise)
   procedure InvertValue;
   // data := data + value
   procedure Add(Value: TACRVariant);
   // data := data - value
   procedure Sub(Value: TACRVariant);
   // data := data * value
   procedure Mul(Value: TACRVariant);
   // data := data / value
   procedure Division(Value: TACRVariant);

    // ABS operation
    procedure AbsData;
    // CEILING operation
    procedure CeilingData;
    // FLOOR operation
    procedure FloorData;
    // MOD operation
    procedure ModData(Value: TACRVariant);
    // POWER operation
    procedure PowerData(Value: TACRVariant);
    // RAND operation
    procedure RandomData(Value: TACRVariant = nil);
    // ROUND operation
    procedure RoundData(Value: TACRVariant = nil);
    // SIGN operation
    procedure SignData;
    // TRUNCATE operation
    procedure TruncateData(Value: TACRVariant = nil);

    // AND operation
    procedure AndData(Value: TACRVariant);
    // OR operation
    procedure OrData(Value: TACRVariant);
    // NOT operation
    procedure NotData;
    // SHL operation
    procedure ShlData(Value: TACRVariant);
    // SHR operation
    procedure ShrData(Value: TACRVariant);
    // XOR operation
    procedure XorData(Value: TACRVariant);
    // HEX operation
    procedure HexData(Format: TACRHexStringFormat = ahexfDefault);
    // DATEADD
    procedure DateAdd(DatePart: TACRDatePart; Number: Integer);
    // DATEDIFF
    procedure DateDiff(DatePart: TACRDatePart; StartDate,EndDate: TACRVariant);
    // EXP function
    procedure ExpData;
    // LOG / LN function
    procedure LogData(Base: TACRVariant = nil);
    // LOG10 function
    procedure Log10Data;
    // COS function
    procedure CosData;
    // SIN function
    procedure SinData;
    // ACOS function
    procedure AcosData;
    // ASIN function
    procedure AsinData;
    // ATAN function
    procedure AtanData;
    // ATAN2 function
    procedure Atan2Data(YCoord: TACRVariant);
    // COT function
    procedure CotData;
    // TAN function
    procedure TanData;
    // SQR function
    procedure SqrData;
    // SQRT function
    procedure SqrtData;
    // DEGREES function
    procedure DegreesData;
    // RADIANS function
    procedure RadiansData;
    // PI function
    procedure PiData;

    function CompareMemoAndAnsiString(
                              ReverseResult:      Boolean;
                              Str:                TACRVariant;
                              TrueFalseNullLogic: Boolean = True;
                              CaseInsensitive:    Boolean = True;
                              PartialKey:         Boolean = False
                                ): TACRCompareResult;
    // Compare with another Variants
    function Compare(
                    Value:              TACRVariant;
                    TrueFalseNullLogic: Boolean = True;
                    CaseInsensitive:    Boolean = True;
                    PartialKey:         Boolean = False
                   ): TACRCompareResult;

   // return 32-bit usigned integer hash value for the value stored in FPData or
   // ACR_NULL_HASH for null value
   function GetBinaryHash: TACRRecordHashValue;
   // convert unicode string to ANSI if it has no Unicode symbols
   procedure ConvertWideStringToAnsiStringIfNotUnicode;
  private
   // Set Data Type
   procedure SetDataType(DataType: TACRBaseFieldType);
   // return advanced data type
   function GetAdvDataType: TACRAdvancedFieldType;
   // CastResultToType
   procedure CastResultToType(NewDataType: TACRBaseFieldType; out Result);
   // Cast value to empty FPData
   procedure CastAndSetData(const Value; ValueType: TACRBaseFieldType);
   // raise EACRException if FPData = nil
   procedure CheckDataForNull;

  private
   // return (FPData = nil)
   function GetIsNull: Boolean;

   // Set typed Data to Variant
   procedure SetDataValue(const value; ValueType: TACRBaseFieldType);
   // Set typed Data from Variant
   procedure GetDataValue(out Value; ValueType: TACRBaseFieldType);

   // Set Data for Signed Int8 (Shortint)
   procedure SetDataAsSignedInt8(Value: Shortint);
   // Get Data for Signed Int8 (Shortint)
   function  GetDataAsSignedInt8: Shortint;

   // Set Data for Signed Int16 (Smallint)
   procedure SetDataAsSignedInt16(Value: Smallint);
   // Get Data for Signed Int16 (Smallint)
   function GetDataAsSignedInt16: Smallint;

   // Set Data for Signed Int32 (Integer)
   procedure SetDataAsSignedInt32(Value: Integer);
   // Get Data for Signed Int32 (Integer)
   function GetDataAsSignedInt32: Integer;

   // Set Data for Signed Int64 (Int64)
   procedure SetDataAsSignedInt64(Value: Int64);
   // Get Data for Signed Int64 (Int64)
   function  GetDataAsSignedInt64: Int64;

   // Set Data for Unsigned Int8 (Byte)
   procedure SetDataAsUnsignedInt8(Value: Byte);
   // Get Data for Unsigned Int8 (Byte)
   function  GetDataAsUnsignedInt8: Byte;

   // Set Data for Unsigned Int16 (Word)
   procedure SetDataAsUnsignedInt16(Value: Word);
   // Get Data for Unsigned Int16 (Word)
   function  GetDataAsUnsignedInt16: Word;

   // Set Data for Unsigned Int32 (Cardinal)
   procedure SetDataAsUnsignedInt32(Value: Cardinal);
   // Get Data for Unsigned Int32 (Cardinal)
   function  GetDataAsUnsignedInt32: Cardinal;


   // Set Data for Char, Varchar (String)
   procedure SetDataAsString(Value: AnsiString);
   // Get Data as AnsiString
   function  GetDataAsString: AnsiString;

   // Set Data for WideChar, WideVarchar (WideString)
   procedure SetDataAsWideString(Value: WideString);
   // Get Data as WideString
   function  GetDataAsWideString: WideString;


   // Set Data for Single
   procedure SetDataAsSingle(Value: Single);
   // Get Data for Single
   function  GetDataAsSingle: Single;

   // Set Data for Double
   procedure SetDataAsDouble(Value: Double);
   // Get Data for Double
   function  GetDataAsDouble: Double;

   // Set Data for Extended
   procedure SetDataAsExtended(Value: Extended);
   // Get Data for Extended
   function  GetDataAsExtended: Extended;


   // Set Data for AcrDate
   procedure SetDataAsACRDate(Value: TACRDate);
   // Get Data for AcrDate
   function  GetDataAsACRDate: TACRDate;
   // Set Data for TDate
   procedure SetDataAsTDate(Value: TDate);
   // Get Data for TDate
   function  GetDataAsTDate: TDate;


   // Set Data for AcrTime
   procedure SetDataAsACRTime(Value: TACRTime);
   // Get Data for AcrTime
   function  GetDataAsACRTime: TACRTime;
   // Set Data for TTime
   procedure SetDataAsTTime(Value: TTime);
   // Get Data for TTime
   function  GetDataAsTTime: TTime;

   // Set Data for AcrDateTime
   procedure SetDataAsACRDateTime(Value: TACRDateTime);
   // Get Data for AcrDateTime
   function  GetDataAsACRDateTime: TACRDateTime;
   // Set Data for TDateTime
   procedure SetDataAsTDateTime(Value: TDateTime);
   // Get Data for TDateTime
   function  GetDataAsTDateTime: TDateTime;

   // Set Data for Boolean
   procedure SetDataAsBoolean(Value: TACRLogical);
   // Get Data for Boolean
   function  GetDataAsBoolean: TACRLogical;


   // Set Data for Currency
   procedure SetDataAsCurrency(Value: TACRCurrency);
   // Get Data for Currency
   function  GetDataAsCurrency: TACRCurrency;

   // Set Data from Borland Variant type
   procedure SetDataAsVariant(Value: Variant);
   // Get Data to Borland Variant type
   function GetDataAsVariant: Variant;

  public
   property DataType: TACRBaseFieldType read FDataType write SetDataType;
   property AdvDataType: TACRAdvancedFieldType read GetAdvDataType;
   property DataSize: Integer read FDataSize;
   property IsNull: Boolean read GetIsNull;
   property PData: PAnsiChar read FPData;
   property IsDataLinked: ByteBool read FIsDataLinked;
   property IsBlob: Boolean read FIsBlob;
  public
   property AsShortint: Shortint      read GetDataAsSignedInt8    write SetDataAsSignedInt8;
   property AsSmallint: Smallint      read GetDataAsSignedInt16   write SetDataAsSignedInt16;
   property AsInteger: Integer        read GetDataAsSignedInt32   write SetDataAsSignedInt32;
   property AsInt64: Int64            read GetDataAsSignedInt64   write SetDataAsSignedInt64;
   property AsByte: Byte              read GetDataAsUnsignedInt8  write SetDataAsUnsignedInt8;
   property AsWord: Word              read GetDataAsUnsignedInt16 write SetDataAsUnsignedInt16;
   property AsCardinal: Cardinal      read GetDataAsUnsignedInt32 write SetDataAsUnsignedInt32;
   property AsLongWord: Cardinal      read GetDataAsUnsignedInt32 write SetDataAsUnsignedInt32;

   property AsSingle: Single          read GetDataAsSingle        write SetDataAsSingle;
   property AsDouble: Double          read GetDataAsDouble        write SetDataAsDouble;
   property AsExtended: Extended      read GetDataAsExtended      write SetDataAsExtended;

   property AsString: AnsiString      read GetDataAsString        write SetDataAsString;
   property AsWideString: WideString  read GetDataAsWideString    write SetDataAsWideString;

   property AsACRDate: TACRDate       read GetDataAsACRDate       write SetDataAsACRDate;
   property AsACRTime: TACRTime       read GetDataAsACRTime       write SetDataAsACRTime;
   property AsACRDateTime: TACRDateTime read GetDataAsACRDateTime write SetDataAsACRDateTime;
   property AsTDate: TDate            read GetDataAsTDate         write SetDataAsTDate;
   property AsTTime: TTime            read GetDataAsTTime         write SetDataAsTTime;
   property AsTDateTime: TDateTime    read GetDataAsTDateTime     write SetDataAsTDateTime;

   property AsBoolean: TACRLogical    read GetDataAsBoolean       write SetDataAsBoolean;
   property AsLogical: TACRLogical    read GetDataAsBoolean       write SetDataAsBoolean;
   property AsCurrency: TACRCurrency  read GetDataAsCurrency      write SetDataAsCurrency;

   property AsVariant: Variant        read GetDataAsVariant       write SetDataAsVariant;
   // added in v.5.10
   { TODO -oLeo : add it to assignements AsString, etc. }
   // maximum string length in characters - for stored functions
   property MaxStrLen: Integer read FMaxStrLen write FMaxStrLen;
 end;


////////////////////////////////////////////////////////////////////////////////
//
// TACRSQLParam
//
////////////////////////////////////////////////////////////////////////////////

  TACRSQLParam = class (TACRVariant)
   private
    FName:     WideString;
    FNameCRC:  Cardinal;
   protected
    procedure SetName(NewName: WideString);
   public
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
    procedure Assign(
                      Source:       TACRVariant;
                      CopyDataFlag: Boolean = True;
                      AssignName:      Boolean = True
                    ); override;
    destructor Destroy; override;
   public
    property Name: WideString read FName write SetName;
    property NameCRC: Cardinal read FNameCRC;
  end;


////////////////////////////////////////////////////////////////////////////////
//
// TACRSQLParams
//
////////////////////////////////////////////////////////////////////////////////

  TACRSQLParams = class (TObject)
   private
    FParamList: TACRList;
   private
    function GetCount: Integer;
    function GetValue(Index: Integer): TACRSQLParam;
    procedure SetValue(Index: Integer; Value: TACRSQLParam);
    procedure SetAsVariant(Value: Variant);
    function GetAsVariant: Variant;
   public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function AddCreated: TACRSQLParam;
    procedure Assign(Source: TACRSQLParams);
    function GetParamByName(Name: WideString): TACRSQLParam;
    function GetParamIndexByName(Name: WideString): Integer;
    procedure LoadFromStream(Stream: TACRStream);
    procedure SaveToStream(Stream: TACRStream);
    // return hash value of all parameters
    function GetHashValue: TACRRecordHashValue;
    // return -1 if not found or index of the parameter stored in FParamList
    function FindByNameCRC(NameCRC: Cardinal): Integer;
   public
    property Count: Integer read GetCount;
    property Items[Index: Integer]: TACRSQLParam read GetValue write SetValue; default;
    property AsVariant: Variant read GetAsVariant write SetAsVariant;
  end;//TACRSQLParams


// Return Common DataType for 2 types, or ftUnknown
function GetCommonDataType(a,b: TACRBaseFieldType): TACRBaseFieldType; overload;
// Return Common DataType for 2 types, or ftUnknown
function GetCommonDataType(a,b: TACRAdvancedFieldType): TACRAdvancedFieldType; overload;

// Allocate new buffer and convert data to it
function CastToNewBuffer(
                          const Buffer;
                          const DataType: TACRBaseFieldType;
                          const NewDataType: TACRBaseFieldType
                        ): PAnsiChar; overload;


// Allocate new buffer and convert data to it
function CastToNewBuffer(
                          const Buffer;
                          const DataType: TACRBaseFieldType;
                          const NewDataType: TACRBaseFieldType;
                          out NewDataSize: Integer
                        ): PAnsiChar; overload;

// return ture if Cast is not needed for CompareValueBuffers
function ACRIsCastNotNeeded(BaseFieldType1,BaseFieldType2: TACRBaseFieldType):Boolean;

implementation

uses
{$IFDEF D6H}
     Variants, DateUtils,
{$ENDIF}
     ACRMain,
     ACRMemory  // last
     ;



//------------------------------------------------------------------------------
// set Buffer to FPData without any other actions
//------------------------------------------------------------------------------
procedure TACRVariant.InternalSetBuffer(Buffer: PAnsiChar; BufferSize: Integer);
begin
 if (Buffer <> nil) and (BufferSize > 0) then
  begin
    FPData := Buffer;
    FDataSize := BufferSize;
    FIsNull := False;
  end
 else
  Clear(FDataType); 
end; // InternalSetBuffer


//------------------------------------------------------------------------------
// load from stream
//------------------------------------------------------------------------------
procedure TACRVariant.LoadFromStream(Stream: TStream);
begin
  Clear;
  LoadDataFromStream(FDataType,Sizeof(FDataType),Stream,10183);
  // fixed in v.5.90
  FIsBLOB := IsBLOBFieldType(FDataType);
  LoadDataFromStream(FIsNull,Sizeof(FIsNull),Stream,10184);
  if (not FIsNull) then
   begin
    LoadDataFromStream(FDataSize,Sizeof(FDataSize),Stream,10185);
    if (FDataSize <= 0) then
     begin
      FPData := nil;
      FIsNull := True;
      FDataSize := 0;
     end
    else
     begin
      FPData := MemoryManager.GetMem(FDataSize);
      LoadDataFromStream(FPData^,FDataSize,Stream,10186);
     end;
   end;
end; // LoadFromStream


//------------------------------------------------------------------------------
// save to stream
//------------------------------------------------------------------------------
procedure TACRVariant.SaveToStream(Stream: TStream);
begin
  SaveDataToStream(FDataType,Sizeof(FDataType),Stream,10179);
  SaveDataToStream(FIsNull,Sizeof(FIsNull),Stream,10180);
  if (not FIsNull) then
   begin
    SaveDataToStream(FDataSize,Sizeof(FDataSize),Stream,10181);
    SaveDataToStream(FPData^,FDataSize,Stream,10182);
   end;
end; // SaveToStream


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRVariant.Create(DataType: TACRBaseFieldType);
begin
  FPData := nil;
  FDataType := DataType;
  FDataSize := 0;
  FIsDataLinked := false;
  FIsNull := True;
  // added in v.5.10
  FMaxStrLen := 0; // not used - for stored functions
  FIsBLOB := IsBLOBFieldType(FDataType);
end;//Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRVariant.Destroy;
begin
  Clear;
end;//Destroy


//------------------------------------------------------------------------------
// SetNull
//------------------------------------------------------------------------------
procedure TACRVariant.SetNull(DataType: TACRBaseFieldType);
begin
  FIsNull := True;
end;//SetNull


//------------------------------------------------------------------------------
// Free Buffer
//------------------------------------------------------------------------------
procedure TACRVariant.Clear(DataType: TACRBaseFieldType);
var sz: Integer;
begin
  if ((FPData <> nil) and (not FIsDataLinked)) then
   begin
    if (ACR_ENCRYPTED_DB_USED) then
     begin
      if (FIsBlob) then
       sz := MemoryManager.GetMemoryBufferSize(FPData)
      else
       sz := FDataSize;
      FillChar(FPData^,sz,$00);
     end;
    MemoryManager.FreeAndNilMem(FPData);
   end;
  FPData := nil;
  FDataType := DataType;
  FIsBLOB := IsBLOBFieldType(FDataType);
  FDataSize := 0;
  FIsDataLinked := false;
  FIsNull := True;
end;//Clear


//------------------------------------------------------------------------------
// Set data size
//------------------------------------------------------------------------------
procedure TACRVariant.SetDataSize(NewSize: Integer);
begin
  if (NewSize = 0) then
   SetNull
  else
   begin
    FDataSize := NewSize;
    if (FPData = nil) then
     FPData := MemoryManager.GetMem(FDataSize)
    else
     MemoryManager.ReallocMem(FPData,FDataSize,False);
    FIsNull := False; 
   end;
end; // SetDataSize


//------------------------------------------------------------------------------
// Set Data Type
//------------------------------------------------------------------------------
procedure TACRVariant.SetDataType(DataType: TACRBaseFieldType);
begin
  if not IsNull then
    try
      Cast(DataType);
    except
      Clear(DataType);
    end
  else
   if (FPData <> nil) then
    Clear(DataType)
   else
    FDataType := DataType;
  FIsBLOB := IsBLOBFieldType(FDataType);
end;//SetDataType


//------------------------------------------------------------------------------
// return advanced data type
//------------------------------------------------------------------------------
function TACRVariant.GetAdvDataType: TACRAdvancedFieldType;
begin
  Result := BaseFieldTypeToAdvancedFieldType(FDataType);
end; // TACRAdvancedFieldType


//------------------------------------------------------------------------------
// CastResultToType
//------------------------------------------------------------------------------
procedure TACRVariant.CastResultToType(NewDataType: TACRBaseFieldType; out Result);
var
  p:        Pointer;
  TmpSize:  Integer;
begin
  p := CastToNewBuffer(FPData, FDataType, NewDataType, TmpSize);
  case NewDataType of
    bftChar,
    bftVarChar:
      begin
        SetLength(AnsiString(Result), TmpSize-1);
        Move(PAnsiChar(p)^, PAnsiChar(Result)^, TmpSize);
      end;
    bftWideChar, bftWideVarChar:
      begin
        SetLength(WideString(Result), (TmpSize) div 2 - 1);
        Move(PWideChar(p)^, PWideChar(Result)^, TmpSize);
      end;
    else
      Move(p^, Result, TmpSize);
  end;
  MemoryManager.FreeAndNilMem(p);
end;//CastResultToType


//------------------------------------------------------------------------------
// Cast value to empty FPData
//------------------------------------------------------------------------------
procedure TACRVariant.CastAndSetData(const Value; ValueType: TACRBaseFieldType);
var p: Pointer;
begin
  if ((FPData <> nil) and (not FIsDataLinked)) then
    MemoryManager.FreeAndNilMem(FPData);
  if (ValueType in [bftChar, bftVarChar, bftWideChar, bftWideVarchar]) then
    p := Pointer(Value)
  else
    p := @Value;
  FPData := CastToNewBuffer(p, ValueType, FDataType, FDataSize);
end;//CastAndSetData


//------------------------------------------------------------------------------
// raise EACRException if FPData = nil
//------------------------------------------------------------------------------
procedure TACRVariant.CheckDataForNull;
begin
 if IsNull then
   raise EACRException.Create(30016, ErrorGValueIsNull);
end;//CheckDataForNull


//------------------------------------------------------------------------------
// Assign data from source (or make link to Source.Data)
//------------------------------------------------------------------------------
procedure TACRVariant.Assign(
                      Source:       TACRVariant;
                      CopyDataFlag: Boolean;
                      AssignName:      Boolean
                            );
const Zero: Word = $0000;
var w,BufSize: Integer;
    bStr:      Boolean;
begin
  Clear;
  if (Source = nil) then
   raise EACRException.Create(12442,ErrorLNilPointer);
  FDataType := Source.FDataType;
  FIsBLOB := Source.FIsBLOB;
  FDataSize := Source.FDataSize;
  FIsDataLinked := not CopyDataFlag;
  FIsNull := Source.FIsNull;
  bStr := IsStringFieldType(FDataType);
  // added in v.5.10, updated in v.5.85
  if (FMaxStrLen = 0) then
   FMaxStrLen := Source.MaxStrLen;
  if ((FMaxStrLen > 0) and (FDataSize > 0) and (bStr)) then
  begin
   if (IsWideStringDataType) then
    w := 2
   else
    w := 1;
   FDataSize := Min(FDataSize,(FMaxStrLen+1) * w);
   FPData := MemoryManager.GetMem(FDataSize);
   Move(Source.FPData^, FPData^, FDataSize-w);
   Move(Zero,PByte(FPData+FDataSize-w)^,w);
   FIsDataLinked := False;
  end
  else
  begin
    if (not Source.IsNull) then
      if (CopyDataFlag) then
        begin
  // modified in 4.50 as in v.4.40 memo fields are loaded with additional #0#0
  // at the end if the buffer for correct comparison
         if (Source.FIsBlob) then
          begin
            BufSize := MemoryManager.GetMemoryBufferSize(Source.FPData);
            FPData := MemoryManager.GetMem(BufSize);
            Move(Source.FPData^, FPData^, BufSize);
          end
         else
          begin
            FPData := MemoryManager.GetMem(FDataSize);
            Move(Source.FPData^, FPData^, FDataSize);
          end;
        end
      else
        FPData := Source.FPData;
  end;
end;//Assign


//------------------------------------------------------------------------------
// Set Data (or make link to Data)
//------------------------------------------------------------------------------
procedure TACRVariant.SetData(
                     Buffer:            Pointer;
                     Size:              Integer;
                     DataType:          TACRBaseFieldType;
                     CopyDataFlag:      Boolean;
                     NotLinkedBuffer:   Boolean // if true - IsDataLinked must be False
                     );
begin
  if (CopyDataFlag) then
    begin
      if ((FPData <> nil) and
          (not FIsDataLinked) and
          (Size = FDataSize)) then
      // Using Old Buffer (FPData)
      else
        begin
          Clear;
          FPData := MemoryManager.GetMem(Size)
{
          if (DataType = bftClob) then
            FDataSize := Size+1
          else
          if (DataType = bftWideClob) then
            FDataSize := Size+2
          else
            FDataSize := Size;
          if (FDataSize = Size) then
           FPData := MemoryManager.GetMem(FDataSize)
          else
           FPData := MemoryManager.AllocMem(FDataSize);
}
        end
    end
  else
    begin
      Clear;
      FPData := Buffer;
    end;
  FDataSize := Size;
  if (FDataType <> DataType) then
  begin
   FDataType := DataType;
   FIsBLOB := IsBLOBFieldType(FDataType);
  end;
  FIsNull := False;
  if (NotLinkedBuffer) then
    FIsDataLinked := False
  else
    FIsDataLinked := (not CopyDataFlag);
  if (CopyDataFlag) then
   begin
//   if (FDataSize = Size) then
     Move(Buffer^, FPData^, FDataSize);
{
   else
     begin
       Move(Buffer^, FPData^, Size);
       FDataSize := Size;
     end;
}
   end;
end;//SetData


//------------------------------------------------------------------------------
// Copy Data to Address
//------------------------------------------------------------------------------
function TACRVariant.CopyDataToAddress(Buffer: Pointer; MaxSize: Integer): boolean;
var
  L: Integer;
begin
  if (IsNull) then
    begin
      Result := False;
    end
  else
    begin
      L := DataSize;
      // modified in 4.90
      if (MaxSize <> -1) then
       if (L > MaxSize) then
        L := MaxSize;
{
      if (MaxSize <> -1) then
       if (L > MaxSize) then
        raise EACRException.Create(20056, ErrorABufferSizeExceeded);
}
      Move(FPData^, Buffer^, L);
      Result := True;
    end;
end;//CopyDataToAddress




//------------------------------------------------------------------------------
// return (FPData = nil)
//------------------------------------------------------------------------------
function TACRVariant.GetIsNull: Boolean;
begin
  Result := FIsNull or (FPData = nil);
end;//GetIsNull


//------------------------------------------------------------------------------
// Set typed Data to Variant
//------------------------------------------------------------------------------
procedure TACRVariant.SetDataValue(const value; ValueType: TACRBaseFieldType);
var bNull: Boolean;
begin
  bNull := (FPData = nil);
  if ( (FDataType = ValueType) and
       (not bNull) and
       (not IsStringDataType) and
       (not FIsDataLinked) ) then
   begin
    Move(Value, FPData^, FDataSize)
   end
  else
  if (FIsBlob) then
   begin
    // 4.60
    if (not bNull) then
      Clear(ValueType)
    else
     FDataType := ValueType;
    AllocMemAndSetData(ValueType, Value, FPData, FDataSize);
   end
  else
   begin
    if (IsWideStringFieldType(ValueType)) then
     begin
       if (Length(WideString(value)) <= 0) then
        begin
         // empty string
         Clear(ValueType);
         Exit;
        end;
     end
    else
    if (IsStringFieldType(ValueType)) then
     begin
       if (Length(AnsiString(value)) <= 0) then
        begin
         // empty string
         Clear(ValueType);
         Exit;
        end;
     end;
    if (not bNull) then
      Clear(FDataType);
    if FDataType = bftUnknown then
      FDataType := ValueType;
    if (FDataType = ValueType) then
      AllocMemAndSetData(FDataType, Value, FPData, FDataSize)
    else
      CastAndSetData(Value, ValueType);
    FIsBLOB := IsBLOBFieldType(FDataType);
   end;
  if (FPData = nil) then
   FIsNull := True
  else
   FIsNull := False;
  FIsDataLinked := False;
end;//SetDataValue


//------------------------------------------------------------------------------
// Set typed Data from Variant
//------------------------------------------------------------------------------
procedure TACRVariant.GetDataValue(out Value; ValueType: TACRBaseFieldType);
var Len:    Integer;
    w:      Word;
    Offset: Integer;
begin
  CheckDataForNull;
  if (FDataType = ValueType) or
     (
      IsStringFieldType(FDataType) and IsStringFieldType(ValueType) and
      (IsWideStringFieldType(FDataType) = IsWideStringFieldType(ValueType))
     )
     then
   begin
     case ValueType of
      bftChar,
      bftVarchar,
      bftClob,
      bftBlob:
        begin
          if (FIsBlob) then
           begin
            SetLength(AnsiString(Value), FDataSize);
            Move(PAnsiChar(FPData)^, PAnsiChar(Value)^, FDataSize);
           end
          else
           begin
            SetLength(AnsiString(Value), FDataSize-1);
            Move(PAnsiChar(FPData)^, PAnsiChar(Value)^, FDataSize-1);
            Len := {$IFDEF D12H}aaStrLen({$ELSE}SysUtils.StrLen({$ENDIF}PAnsiChar(AnsiString(Value)));
            if (Len < (FDataSize - 1)) then
             SetLength(AnsiString(Value), Len);
           end;
        end;
      bftWideChar,
      bftWideClob,
      bftWideVarchar:
        begin
          if (FIsBlob) then
           begin
            SetLength(WideString(Value), FDataSize div 2);
            // fixed in 4.95
            if (FDataSize >= 2) then
             Move(PWideChar(FPData)^, PWideChar(Value)^, FDataSize);
{
            SetLength(WideString(Value), FDataSize+2);
            Move(PWideChar(FPData)^, PWideChar(Value)^, FDataSize);
            w := 0;
            Move(w,PAnsiChar(PAnsiChar(Value) + FDataSize)^,SizeOf(w));
}
           end
          else
           begin
            Offset := GetStrLength(FPData,aftWideString);
            if (Offset >= FDataSize) then
             Offset := FDataSize;
            SetLength(WideString(Value), Offset div 2);
            // fixed in 4.95
            if (Offset >= 2) then
             begin
              Move(PWideChar(FPData)^, PWideChar(Value)^, Offset);
             end;
//            w := 0;
//            Move(w,PAnsiChar(PAnsiChar(Value) + Offset)^,SizeOf(w));
           end;
        end;
      else
        CopyDataToAddress(@Value);
     end;
   end
  else
    CastResultToType(ValueType, Value);
end;//GetDataValue


//------------------------------------------------------------------------------
// Set Data for Int8 (Shortint)
//------------------------------------------------------------------------------
procedure TACRVariant.SetDataAsSignedInt8(Value: Shortint);
begin
  SetDataValue(Value, bftSignedInt8);
end;//SetDataAsSignedInt8


//------------------------------------------------------------------------------
// Get Data for Int8 (Shortint)
//------------------------------------------------------------------------------
function TACRVariant.GetDataAsSignedInt8: Shortint;
begin
  GetDataValue(Result, bftSignedInt8);
end;//GetDataAsSignedInt8



//------------------------------------------------------------------------------
// Set Data for Signed Int16 (Smallint)
//------------------------------------------------------------------------------
procedure TACRVariant.SetDataAsSignedInt16(Value: Smallint);
begin
  SetDataValue(Value, bftSignedInt16);
end;//SetDataAsSignedInt16


//------------------------------------------------------------------------------
// Get Data for Signed Int16 (Smallint)
//------------------------------------------------------------------------------
function TACRVariant.GetDataAsSignedInt16: Smallint;
begin
  GetDataValue(Result, bftSignedInt16);
end;



//------------------------------------------------------------------------------
// Set Data for Signed Int32 (Integer)
//------------------------------------------------------------------------------
procedure TACRVariant.SetDataAsSignedInt32(Value: Integer);
begin
  SetDataValue(Value, bftSignedInt32);
end;//SetDataAsSignedInt32


//------------------------------------------------------------------------------
// Get Data for Signed Int32 (Integer)
//------------------------------------------------------------------------------
function TACRVariant.GetDataAsSignedInt32: Integer;
begin
  GetDataValue(Result, bftSignedInt32);
end;//GetDataAsSignedInt32



//------------------------------------------------------------------------------
// Set Data for Signed Int64 (Int64)
//------------------------------------------------------------------------------
procedure TACRVariant.SetDataAsSignedInt64(Value: Int64);
begin
  SetDataValue(Value, bftSignedInt64);
end;//SetDataAsSignedInt64


//------------------------------------------------------------------------------
// Get Data for Signed Int64 (Int64)
//------------------------------------------------------------------------------
function TACRVariant.GetDataAsSignedInt64: Int64;
begin
  GetDataValue(Result, bftSignedInt64);
end;//GetDataAsSignedInt64


//------------------------------------------------------------------------------
// Set Data for Unsigned Int8 (Byte)
//------------------------------------------------------------------------------
procedure TACRVariant.SetDataAsUnsignedInt8(Value: Byte);
begin
  SetDataValue(Value, bftUnsignedInt8);
end;//SetDataAsUnsignedInt8


//------------------------------------------------------------------------------
// Get Data for Unsigned Int8 (Byte)
//------------------------------------------------------------------------------
function TACRVariant.GetDataAsUnsignedInt8: Byte;
begin
  GetDataValue(Result, bftUnsignedInt8);
end;//GetDataAsUnsignedInt8


//------------------------------------------------------------------------------
// Set Data for Unsigned Int16 (Word)
//------------------------------------------------------------------------------
procedure TACRVariant.SetDataAsUnsignedInt16(Value: Word);
begin
  SetDataValue(Value, bftUnsignedInt16);
end;//SetDataAsUnsignedInt16


//------------------------------------------------------------------------------
// Get Data for Unsigned Int16 (Word)
//------------------------------------------------------------------------------
function TACRVariant.GetDataAsUnsignedInt16: Word;
begin
  GetDataValue(Result, bftUnsignedInt16);
end;//GetDataAsUnsignedInt16


//------------------------------------------------------------------------------
// Set Data for Unsigned Int32 (Cardinal)
//------------------------------------------------------------------------------
procedure TACRVariant.SetDataAsUnsignedInt32(Value: Cardinal);
begin
  SetDataValue(Value, bftUnsignedInt32);
end;//SetDataAsUnsignedInt32


//------------------------------------------------------------------------------
// Get Data for Unsigned Int32 (Cardinal)
//------------------------------------------------------------------------------
function TACRVariant.GetDataAsUnsignedInt32: Cardinal;
begin
  GetDataValue(Result, bftUnsignedInt32);
end;//GetDataAsUnsignedInt32


//------------------------------------------------------------------------------
// Set Data for Char, Varchar (String)
//------------------------------------------------------------------------------
procedure TACRVariant.SetDataAsString(Value: AnsiString);
begin
  SetDataValue(Value, bftVarchar);
end;//SetDataAsString


//------------------------------------------------------------------------------
// Get Data as AnsiString
//------------------------------------------------------------------------------
function TACRVariant.GetDataAsString: AnsiString;
begin
  // changed in v.4.60 to support empty strings
  if (FIsNull) then
   Result := ''
  else
   GetDataValue(Result, bftVarchar);
end;//GetDataAsString


//------------------------------------------------------------------------------
// Set Data for WideChar, WideVarchar (WideString)
//------------------------------------------------------------------------------
procedure TACRVariant.SetDataAsWideString(Value: WideString);
begin
  SetDataValue(Value, bftWideVarchar);
end;//SetDataAsWideString


//------------------------------------------------------------------------------
// Get Data as WideString
//------------------------------------------------------------------------------
function TACRVariant.GetDataAsWideString: WideString;
begin
  // changed in v.4.60 to support empty strings
  if (FIsNull) then
    Result := ''
  else
    GetDataValue(Result, bftWideVarchar);
end;//GetDataAsWideString


//------------------------------------------------------------------------------
// Set Data for Single
//------------------------------------------------------------------------------
procedure TACRVariant.SetDataAsSingle(Value: Single);
begin
  SetDataValue(Value, bftSingle);
end;//SetDataAsSingle


//------------------------------------------------------------------------------
// Get Data for Single
//------------------------------------------------------------------------------
function TACRVariant.GetDataAsSingle: Single;
begin
  GetDataValue(Result, bftSingle);
end;//GetDataAsSingle


//------------------------------------------------------------------------------
// Set Data for Double
//------------------------------------------------------------------------------
procedure TACRVariant.SetDataAsDouble(Value: Double);
begin
  SetDataValue(Value, bftDouble);
end;//SetDataAsDouble


//------------------------------------------------------------------------------
// Get Data for Double
//------------------------------------------------------------------------------
function TACRVariant.GetDataAsDouble: Double;
begin
  GetDataValue(Result, bftDouble);
end;//GetDataAsDouble


//------------------------------------------------------------------------------
// Set Data for Extended
//------------------------------------------------------------------------------
procedure TACRVariant.SetDataAsExtended(Value: Extended);
begin
  SetDataValue(Value, bftExtended);
end;//SetDataAsExtended


//------------------------------------------------------------------------------
// Get Data for Extended
//------------------------------------------------------------------------------
function TACRVariant.GetDataAsExtended: Extended;
begin
  GetDataValue(Result, bftExtended);
end;//GetDataAsExtended




//------------------------------------------------------------------------------
// Set Data for AcrDate
//------------------------------------------------------------------------------
procedure TACRVariant.SetDataAsACRDate(Value: TACRDate);
begin
  SetDataValue(Value, bftDate);
end;//SetDataAsACRDate


//------------------------------------------------------------------------------
// Get Data for AcrDate
//------------------------------------------------------------------------------
function TACRVariant.GetDataAsACRDate: TACRDate;
begin
  GetDataValue(Result, bftDate);
end;//GetDataAsACRDate


//------------------------------------------------------------------------------
// Set Data for TDate
//------------------------------------------------------------------------------
procedure TACRVariant.SetDataAsTDate(Value: TDate);
begin
  SetDataAsACRDate(DateToACRDate(Value));
end;//SetDataAsTDate


//------------------------------------------------------------------------------
// Get Data for TDate
//------------------------------------------------------------------------------
function TACRVariant.GetDataAsTDate: TDate;
begin
  Result := ACRDateToDate(GetDataAsACRDate);
end;//GetDataAsTDate


//------------------------------------------------------------------------------
// Set Data for AcrTime
//------------------------------------------------------------------------------
procedure TACRVariant.SetDataAsACRTime(Value: TACRTime);
begin
  SetDataValue(Value, bftTime);
end;//SetDataAsACRTime


//------------------------------------------------------------------------------
// Get Data for AcrTime
//------------------------------------------------------------------------------
function TACRVariant.GetDataAsACRTime: TACRTime;
begin
  GetDataValue(Result, bftTime);
end;//GetDataAsACRTime


//------------------------------------------------------------------------------
// Set Data for TTime
//------------------------------------------------------------------------------
procedure TACRVariant.SetDataAsTTime(Value: TTime);
begin
  SetDataAsACRTime(TimeToACRTime(Value));
end;//SetDataAsTTime


//------------------------------------------------------------------------------
// Get Data for AcrTime
//------------------------------------------------------------------------------
function TACRVariant.GetDataAsTTime: TTime;
begin
  Result := ACRTimeToTime(GetDataAsACRTime);
end;//GetDataAsTTime



//------------------------------------------------------------------------------
// Set Data for AcrDateTime
//------------------------------------------------------------------------------
procedure TACRVariant.SetDataAsACRDateTime(Value: TACRDateTime);
begin
  SetDataValue(Value, bftDateTime);
end;//SetDataAsACRDateTime


//------------------------------------------------------------------------------
// Get Data for AcrDateTime
//------------------------------------------------------------------------------
function TACRVariant.GetDataAsACRDateTime: TACRDateTime;
begin
  GetDataValue(Result, bftDateTime);
end;//GetDataAsACRDateTime


//------------------------------------------------------------------------------
// Set Data for TDateTime
//------------------------------------------------------------------------------
procedure TACRVariant.SetDataAsTDateTime(Value: TDateTime);
begin
  SetDataAsACRDateTime(DateTimeToACRDateTime(Value));
end;//SetDataAsTDateTime


//------------------------------------------------------------------------------
// Get Data for TDateTime
//------------------------------------------------------------------------------
function TACRVariant.GetDataAsTDateTime: TDateTime;
begin
  Result := ACRDateTimeToDateTime(GetDataAsACRDateTime);
end;//GetDataAsTDateTime



procedure TACRVariant.SetDataAsBoolean(Value: TACRLogical);
begin
  SetDataValue(Value, bftLogical);
end;


//------------------------------------------------------------------------------
// Get Data for Boolean
//------------------------------------------------------------------------------
function TACRVariant.GetDataAsBoolean: TACRLogical;
begin
  GetDataValue(Result, bftLogical);
end;//GetDataAsBoolean


//------------------------------------------------------------------------------
// Set Data for Currency
//------------------------------------------------------------------------------
procedure TACRVariant.SetDataAsCurrency(Value: TACRCurrency);
begin
  SetDataValue(Value, bftCurrency);
end;//SetDataAsCurrency


//------------------------------------------------------------------------------
// Get Data for Currency
//------------------------------------------------------------------------------
function TACRVariant.GetDataAsCurrency: TACRCurrency;
begin
  GetDataValue(Result, bftCurrency);
end;//GetDataAsCurrency


//------------------------------------------------------------------------------
// Set Data from Borland Variant type
//------------------------------------------------------------------------------
procedure TACRVariant.SetDataAsVariant(Value: Variant);
var i,c,l,d: Integer;
    buf: PAnsiChar;
begin
  case VarType(Value) of
    //varEmpty
    //varNull
    varSmallint:
      AsSmallint := Value;
    varInteger:
      AsInteger := Value;
    varSingle:
      AsSingle := Value;
    varDouble:
      AsDouble := Value;
    varCurrency:
      AsCurrency := Value;
    varDate:
      AsTDateTime := Value;
// fixed in 4.95 - for BDS 2009
    varOleStr{$IFDEF D12H},varUString{$ENDIF}:
      AsWideString := Value;
    //varDispatch
    //varError
    varBoolean: AsBoolean := Value;
    //varVariant
    //varUnknown
    varShortInt:
      AsShortInt := Value;
    varWord:
      AsWord := Value;
    varLongWord:
      AsCardinal := Value;
   {$IFDEF D6H}
    varInt64:
      AsInt64 := Value;
    {$ENDIF}
    varByte:
      AsByte := Value;
    //varStrArg = $0048
    //varString,
// fixed in 4.95 - for BDS 2009
//    varString .. varString + $1F:
    varString, $0048, varAny,$0110 .. $07FF:
      AsString := Value;
    varArray + varByte:
      begin
       d := VarArrayDimCount(Value);
       l := VarArrayLowBound(Value,d);
       c := VarArrayHighBound(Value,d) - l + 1;
       SetDataSize(c);
       FDataType := bftBytes;
       buf := VarArrayLock(Value);
       try
         Move(buf^,PData^,FDataSize);
       finally
         VarArrayUnlock(Value);
       end;
{
       for i := l to VarArrayHighBound(Value,d) do
        PByte(pData+i-l)^ := Byte(Value[i]);
}
      end;
    //varAny
    //varTypeMask
    //varArray
    //varByRef
    varNull:
      SetNull(FDataType);
    else
      raise EACRException.Create(30113, ErrorGUnsupportedVariantType, [IntToStr(VarType(Value))]);
  end;
end;//SetDataAsVariant


//------------------------------------------------------------------------------
// Get Data to Borland Variant type
//------------------------------------------------------------------------------
function TACRVariant.GetDataAsVariant: Variant;
var i: Integer;
    buf: PAnsiChar;
begin
  case FDataType of
    bftChar,
    bftVarchar:
      Result := AsString;
    bftWideChar,
    bftWideVarchar:
      Result := AsWideString;


    bftSignedInt8:
      Result := AsShortint;
    bftSignedInt16:
      Result := AsSmallint;
    bftSignedInt32:
      Result := AsInteger;
   {$IFDEF D6H}
    bftSignedInt64:
      Result := AsInt64;
    {$ENDIF}
    bftUnsignedInt8:
      Result := AsByte;
    bftUnsignedInt16:
      Result := AsWord;
    bftUnsignedInt32:
      Result := AsCardinal;

    bftSingle:
      Result := AsSingle;
    bftDouble:
      Result := AsDouble;
    bftExtended:
      Result := AsExtended;

    bftDate:
      Result := AsTDate;
    bftTime:
      Result := AsTTime;
    bftDateTime:
      Result := AsTDateTime;

    bftLogical:
      Result := AsLogical;

    bftCurrency:
      Result := AsCurrency;

    bftBlob:
      Result := AsString;

    bftBytes:
      begin
        if (IsNull) then
         VarClear(Result)
        else
         begin
          Result := VarArrayCreate([0,FDataSize-1],varByte);
          buf := VarArrayLock(Result);
          try
            Move(PData^,buf^,FDataSize);
          finally
            VarArrayUnlock(Result);
          end;
{
          for i := 0 to FDataSize-1 do
           Result[i] := PByte(PData+i)^;
}
         end;
      end;

    else
      // Check for null
      if (IsNull) then
        Result := Null
      else
      raise EACRException.Create(30114, ErrorGUnsupportedVariantType, [BftToStr(FDataType)]);
  end;
end;//GetDataAsVariant


//------------------------------------------------------------------------------
// Cast
//------------------------------------------------------------------------------
procedure TACRVariant.Cast(NewDataType: TACRBaseFieldType);
var p: Pointer;
    NewSize: Integer;
begin
  if (FDataType = NewDataType) then
    Exit;
  if (IsNull) then
    begin
      Clear(NewDataType);
    end
  else
    begin
      // Optimized in v.4.80
      if (
          (((FDataType = bftChar) or (FDataType = bftVarChar)) and
          ((NewDataType = bftChar) or (NewDataType = bftVarChar)))
          or
          (((FDataType = bftWideChar) or (FDataType = bftWideVarChar)) and
          ((NewDataType = bftWideChar) or (NewDataType = bftWideVarChar)))
         ) then
       begin
        // no need to convert data by CAST SQL operator
        // (memo is stored different from char/widechar)
        FDataType := NewDataType;
       end
      else
       begin
        p := CastToNewBuffer(FPData, FDataType, NewDataType, NewSize);
        Clear(NewDataType);
        FIsNull := False;
        FDataType := NewDataType;
        FIsBLOB := IsBLOBFieldType(FDataType);
        FPData := p;
        FDataSize := NewSize;
       end;
    end;
end;//Cast


//------------------------------------------------------------------------------
// return true if DataType is numeric
//------------------------------------------------------------------------------
function TACRVariant.IsNumericDataType: Boolean;
begin
  Result := IsNumericFieldType(FDataType);
end;//IsNumericDataType


//------------------------------------------------------------------------------
// return true if DataType is numeric
//------------------------------------------------------------------------------
function TACRVariant.IsIntegerDataType: Boolean;
begin
  Result := IsIntegerFieldType(FDataType);
end;//IsNumericDataType


//------------------------------------------------------------------------------
// return true if DataType is AnsiString
//------------------------------------------------------------------------------
function TACRVariant.IsStringDataType: Boolean;
begin
  Result := IsStringFieldType(FDataType);
end;//IsStringDataType


//------------------------------------------------------------------------------
// return true if DataType is WideString
//------------------------------------------------------------------------------
function TACRVariant.IsWideStringDataType: Boolean;
begin
  Result := IsWideStringFieldType(FDataType);
end;//IsStringDataType


//------------------------------------------------------------------------------
// return true if DataType is Time, Date, DateTime
//------------------------------------------------------------------------------
function TACRVariant.IsDateTimeDataType: Boolean;
begin
  Result := IsDateTimeFieldType(FDataType);
end;//IsDateTimeFieldType


//------------------------------------------------------------------------------
// return Length of AnsiString or -1 (if not IsStringType)
//------------------------------------------------------------------------------
function TACRVariant.StrLen: Integer;
begin
  if (FIsBLOB) then
   Result := FDataSize
  else
  if (IsStringDataType and (not IsNull)) then
  begin
    if (IsWideStringDataType) then
     Result := GetStrLength(FPData,BaseFieldTypeToAdvancedFieldType(FDataType)) shr 1
    else
     Result := GetStrLength(FPData,BaseFieldTypeToAdvancedFieldType(FDataType))
{
  if (IsStringDataType and (not IsNull)) then
    if (IsWideStringDataType) then
      Result := ((FDataSize) div 2) - 1
    else
      Result := FDataSize - 1
}
  end
  else
    Result := -1;
end; // StrLen


//------------------------------------------------------------------------------
// value := -value ( if not number then raise)
//------------------------------------------------------------------------------
procedure TACRVariant.InvertValue;
var adt: TACRDateTime;
begin
  if not IsNull then
    case FDataType of
      bftSignedInt8:      AsShortint := -AsShortint;
      bftSignedInt16:     AsSmallint := -AsSmallint;
      bftSignedInt32:     AsInteger := -AsInteger;
      bftSignedInt64:     AsInt64 := -AsInt64;

      bftUnsignedInt8:    AsShortint := -AsByte;
      bftUnsignedInt16:   AsSmallint := -AsWord;
      bftUnsignedInt32:   AsInteger := -AsCardinal;

      bftSingle:          AsSingle := -AsSingle;
      bftDouble:          AsDouble := -AsDouble;
      bftExtended:        AsExtended := -AsExtended;

      bftDate:            AsACRDate := -AsACRDate;
      bftTime:            AsACRTime := MILSECS_IN_DAY-AsACRTime;
      bftDateTime:
       begin
        adt := AsACRDateTime;
        adt.Date := -adt.Date;
        adt.Time := {MILSECS_IN_DAY }- adt.Time;
        AsACRDateTime := adt;
       end;
      bftLogical:         AsLogical := not AsLogical;
      bftCurrency:        AsCurrency := -AsCurrency;
      else
        raise EACRException.Create(30123, ErrorGCannotInvertValue, [BftToStr(FDataType)]);
    end;
end;//InvertValue


{$IFOPT Q+}
 {$DEFINE RESET_OVERFLOW}
 {$Q-}
{$ENDIF}
//------------------------------------------------------------------------------
// data := data + value
//------------------------------------------------------------------------------
procedure TACRVariant.Add(Value: TACRVariant);
var
  dt: TACRDateTime;
begin
// changed in v.4.60 to allow '' + 'str'
  if (IsStringDataType or Value.IsStringDataType) then
   begin
    if (IsWideStringDataType or Value.IsWideStringDataType) then
      AsWideString := AsWideString + Value.AsWideString
    else
      AsString := AsString + Value.AsString;
   end
  else
  if (Value.IsNull)  then
    SetNull(FDataType)
  else
    if not IsNull then
      begin
        Cast(GetCommonDataType(FDataType, Value.DataType));
{
        if ((IsNumericDataType) and (FIsNull or Value.IsNull)) then
         Clear
        else
}        
          case FDataType of
            bftChar,
            bftVarchar:         AsString := AsString + Value.AsString;
            bftWideChar,
            bftWideVarchar:     AsWideString := AsWideString + Value.AsWideString;

            bftSignedInt8:      AsShortint := AsShortint + Value.AsShortint;
            bftSignedInt16:     AsSmallint := AsSmallint + Value.AsSmallint;
            bftSignedInt32:     AsInteger := AsInteger + Value.AsInteger;
            bftSignedInt64:     AsInt64 := AsInt64 + Value.AsInt64;

            bftUnsignedInt8:    AsByte := AsByte + Value.AsByte;
            bftUnsignedInt16:   AsWord := AsWord + Value.AsWord;
            bftUnsignedInt32:   AsCardinal := AsCardinal + Value.AsCardinal;

            bftSingle:          AsSingle := AsSingle + Value.AsSingle;
            bftDouble:          AsDouble := AsDouble + Value.AsDouble;
            bftExtended:        AsExtended := AsExtended + Value.AsExtended;

            bftDate:            AsACRDate := AsACRDate + Value.AsACRDate;
            bftTime:            AsACRTime := AsACRTime + Value.AsACRTime;
            bftDateTime:        begin
                                  dt := AsACRDateTime;
                                  dt.Date := dt.Date + Value.AsACRDateTime.Date;
                                  dt.Time := dt.Time + Value.AsACRDateTime.Time;
                                  if (dt.Time >= MILSECS_IN_DAY) then
                                   begin
                                    dt.Date := dt.Date + dt.Time div MILSECS_IN_DAY;
                                    dt.Time := dt.Time mod MILSECS_IN_DAY;
                                   end;
                                  AsACRDateTime := dt;
                                end;

            bftLogical:         AsLogical := AsLogical or Value.AsLogical;
            bftCurrency:        AsCurrency := AsCurrency + Value.AsCurrency;
            else
              raise EACRException.Create(30124, ErrorGNotNumericDataType, ['+']);
        end;
      end
    else//If IsNull
      Assign(Value);

end;//Add


//------------------------------------------------------------------------------
// data := data - value
//------------------------------------------------------------------------------
procedure TACRVariant.Sub(Value: TACRVariant);
var
  dt: TACRDateTime;
begin
  if Value.IsNull then
    SetNull(FDataType)
  else
    if not IsNull then
      begin
        Cast(GetCommonDataType(FDataType, Value.DataType));
        case FDataType of
          bftSignedInt8:      AsShortint := AsShortint - Value.AsShortint;
          bftSignedInt16:     AsSmallint := AsSmallint - Value.AsSmallint;
          bftSignedInt32:     AsInteger := AsInteger - Value.AsInteger;
          bftSignedInt64:     AsInt64 := AsInt64 - Value.AsInt64;

          bftUnsignedInt8:    AsByte := AsByte - Value.AsByte;
          bftUnsignedInt16:   AsWord := AsWord - Value.AsWord;
          bftUnsignedInt32:   AsCardinal := AsCardinal - Value.AsCardinal;

          bftSingle:          AsSingle := AsSingle - Value.AsSingle;
          bftDouble:          AsDouble := AsDouble - Value.AsDouble;
          bftExtended:        AsExtended := AsExtended - Value.AsExtended;

          bftDate:            AsACRDate := AsACRDate - Value.AsACRDate;
          bftTime:            AsACRTime := AsACRTime - Value.AsACRTime;
          bftDateTime:        begin
                                dt := AsACRDateTime;
                                dt.Date := dt.Date - Value.AsACRDateTime.Date;
                                dt.Time := dt.Time - Value.AsACRDateTime.Time;
                                if (dt.Time >= MILSECS_IN_DAY) then
                                 begin
                                  dt.Date := dt.Date + dt.Time div MILSECS_IN_DAY;
                                  dt.Time := dt.Time mod MILSECS_IN_DAY;
                                 end;
                                AsACRDateTime := dt;
                              end;

          bftLogical:         AsLogical := AsLogical or Value.AsLogical;
          bftCurrency:        AsCurrency := AsCurrency - Value.AsCurrency;

          else
            raise EACRException.Create(30125, ErrorGNotNumericDataType, ['-']);
        end;
      end;
end;//Sub


//------------------------------------------------------------------------------
// data := data * value
//------------------------------------------------------------------------------
procedure TACRVariant.Mul(Value: TACRVariant);
var
  dt: TACRDateTime;
begin
  if Value.IsNull then
    SetNull(FDataType)
  else
    if not IsNull then
      begin
        Cast(GetCommonDataType(FDataType, Value.DataType));
        case FDataType of
          bftSignedInt8:      AsShortint := AsShortint * Value.AsShortint;
          bftSignedInt16:     AsSmallint := AsSmallint * Value.AsSmallint;
          bftSignedInt32:     AsInteger := AsInteger * Value.AsInteger;
          bftSignedInt64:     AsInt64 := AsInt64 * Value.AsInt64;

          bftUnsignedInt8:    AsByte := AsByte * Value.AsByte;
          bftUnsignedInt16:   AsWord := AsWord * Value.AsWord;
          bftUnsignedInt32:   AsCardinal := AsCardinal * Value.AsCardinal;

          bftSingle:          AsSingle := AsSingle * Value.AsSingle;
          bftDouble:          AsDouble := AsDouble * Value.AsDouble;
          bftExtended:        AsExtended := AsExtended * Value.AsExtended;

          bftDate:            AsACRDate := AsACRDate * Value.AsACRDate;
          bftTime:            AsACRTime := AsACRTime * Value.AsACRTime;
          bftDateTime:        begin
                                dt := AsACRDateTime;
                                dt.Date := dt.Date * Value.AsACRDateTime.Date;
                                dt.Time := dt.Time * Value.AsACRDateTime.Time;
                                if (dt.Time >= MILSECS_IN_DAY) then
                                 begin
                                  dt.Date := dt.Date + dt.Time div MILSECS_IN_DAY;
                                  dt.Time := dt.Time mod MILSECS_IN_DAY;
                                 end;
                                AsACRDateTime := dt;
                              end;

          bftLogical:         AsLogical := AsLogical or Value.AsLogical;
          bftCurrency:        AsCurrency := AsCurrency * Value.AsCurrency;
          else
            raise EACRException.Create(30126, ErrorGNotNumericDataType, ['*']);
        end;
      end;
end;//Mul


//------------------------------------------------------------------------------
// data := data / value
//------------------------------------------------------------------------------
procedure TACRVariant.Division(Value: TACRVariant);
var
  dt: TACRDateTime;
begin
  if Value.IsNull then
    SetNull(FDataType)
  else
    if not IsNull then
      begin
        try
          Cast(GetCommonDataType(FDataType, Value.DataType));
          case FDataType of
            bftSignedInt8:      AsShortint := AsShortint div Value.AsShortint;
            bftSignedInt16:     AsSmallint := AsSmallint div Value.AsSmallint;
            bftSignedInt32:     AsInteger := AsInteger div Value.AsInteger;
            bftSignedInt64:     AsInt64 := AsInt64 div Value.AsInt64;

            bftUnsignedInt8:    AsByte := AsByte div Value.AsByte;
            bftUnsignedInt16:   AsWord := AsWord div Value.AsWord;
            bftUnsignedInt32:   AsCardinal := AsCardinal div Value.AsCardinal;

            bftSingle:          AsSingle := AsSingle / Value.AsSingle;
            bftDouble:          AsDouble := AsDouble / Value.AsDouble;
            bftExtended:        AsExtended := AsExtended / Value.AsExtended;

            bftDate:            AsACRDate := AsACRDate div Value.AsACRDate;
            bftTime:            AsACRTime := AsACRTime div Value.AsACRTime;
            bftDateTime:        begin
                                  dt := AsACRDateTime;
                                  dt.Date := dt.Date div Value.AsACRDateTime.Date;
                                  dt.Time := dt.Time div Value.AsACRDateTime.Time;
                                  if (dt.Time >= MILSECS_IN_DAY) then
                                   begin
                                    dt.Date := dt.Date + dt.Time div MILSECS_IN_DAY;
                                    dt.Time := dt.Time mod MILSECS_IN_DAY;
                                   end;
                                  AsACRDateTime := dt;
                                end;

            bftLogical:         AsLogical := AsLogical or Value.AsLogical;
            bftCurrency:        AsCurrency := AsCurrency / Value.AsCurrency;
            else
              raise EACRException.Create(30127, ErrorGNotNumericDataType, ['/']);
          end;
        except
          on EACRException do raise;
          on e: Exception do
            raise EACRException.Create(30128, ErrorGDivisionError, [e.Message]);
      end;
    end;
end;//Division
 {$IFDEF RESET_OVERFLOW}
  {$Q+}
 {$ENDIF}

//------------------------------------------------------------------------------
// ABS operation
//------------------------------------------------------------------------------
procedure TACRVariant.AbsData;
begin
  if not IsNull then
    begin
      case FDataType of
        bftSignedInt8:      AsShortint := Abs(AsShortint);
        bftSignedInt16:     AsSmallint := Abs(AsSmallint);
        bftSignedInt32:     AsInteger := Abs(AsInteger);
        bftSignedInt64:     AsInt64 := Abs(AsInt64);

        bftUnsignedInt8,
        bftUnsignedInt16,
        bftUnsignedInt32:  ;

        bftSingle:          AsSingle := Abs(AsSingle);
        bftDouble:          AsDouble := Abs(AsDouble);
        bftExtended:        AsExtended := Abs(AsExtended);
        bftCurrency:        AsCurrency := Abs(AsCurrency);
        else
          raise EACRException.Create(11651, ErrorGNotNumericDataType, ['*']);
      end;
    end;
end; // AbsData


//------------------------------------------------------------------------------
// CEILING operation
//------------------------------------------------------------------------------
procedure TACRVariant.CeilingData;
var res: Integer;
begin
  if (not IsNull) and (IsNumericDataType) then
    begin
      case FDataType of
        bftSignedInt8,
        bftSignedInt16,
        bftSignedInt32,
        bftSignedInt64,
        bftUnsignedInt8,
        bftUnsignedInt16,
        bftUnsignedInt32:  Cast(bftSignedInt32);

        bftSingle:          res := Ceil(AsSingle);
        bftDouble:          res := Ceil(AsDouble);
        bftExtended:        res := Ceil(AsExtended);
        bftCurrency:        res := Ceil(AsCurrency);
        else
          raise EACRException.Create(11653, ErrorGNotNumericDataType, ['*']);
      end;
      if (not IsIntegerDataType) then
       begin
        Clear(bftSignedInt32);
        AsInteger := res;
       end;
    end
   else
    SetNull(bftSignedInt32);
end; // CeilingData


//------------------------------------------------------------------------------
// FLOOR operation
//------------------------------------------------------------------------------
procedure TACRVariant.FloorData;
var res: Integer;
begin
  if (not IsNull) and (IsNumericDataType) then
    begin
      case FDataType of
        bftSignedInt8,
        bftSignedInt16,
        bftSignedInt32,
        bftSignedInt64,
        bftUnsignedInt8,
        bftUnsignedInt16,
        bftUnsignedInt32:  Cast(bftSignedInt32);

        bftSingle:          res := Floor(AsSingle);
        bftDouble:          res := Floor(AsDouble);
        bftExtended:        res := Floor(AsExtended);
        bftCurrency:        res := Floor(AsCurrency);
        else
          raise EACRException.Create(11654, ErrorGNotNumericDataType, ['*']);
      end;
      if (not IsIntegerDataType) then
       begin
        Clear(bftSignedInt32);
        AsInteger := res;
       end;
    end
   else
    SetNull(bftSignedInt32);
end; // FloorDate


//------------------------------------------------------------------------------
// MOD operation
//------------------------------------------------------------------------------
procedure TACRVariant.ModData(Value: TACRVariant);
begin
 if (IsNull or (not IsNumericDataType) or (not Value.IsNumericDataType)) then
  SetNull(bftSignedInt64)
 else
  begin
   if (FDataType <> bftSignedInt64) then
    Cast(bftSignedInt64);
   if (Value.DataType <> bftSignedInt64) then
    Value.Cast(bftSignedInt64);
   AsInt64 := AsInt64 MOD Value.AsInt64;
  end;
end; // ModData


//------------------------------------------------------------------------------
// POWER operation
//------------------------------------------------------------------------------
procedure TACRVariant.PowerData(Value: TACRVariant);
begin
 if (IsNull or (not IsNumericDataType) or (not Value.IsNumericDataType)) then
  SetNull(bftSignedInt64)
 else
  begin
   if (IsIntegerDataType and Value.IsIntegerDataType) then
    begin
     if (FDataType <> bftSignedInt64) then
      Cast(bftSignedInt64);
     if (Value.DataType <> bftSignedInt64) then
      Value.Cast(bftSignedInt64);
     AsInt64 := Trunc(Power(AsInt64,Value.AsInt64));
    end
   else
    begin
     if (FDataType <> bftExtended) then
      Cast(bftExtended);
     if (Value.DataType <> bftExtended) then
      Value.Cast(bftExtended);
     AsExtended := Power(AsExtended,Value.AsExtended);
    end;
  end;
end; // PowerData


//------------------------------------------------------------------------------
// RAND operation
//------------------------------------------------------------------------------
procedure TACRVariant.RandomData(Value: TACRVariant);
var x: Integer;
begin
  if (IsNull or (Value = nil)) then
   begin
    Clear(bftExtended);
    AsExtended := Random;
   end
  else
   begin
    if (Value.DataType <> bftSignedInt32) then
     Value.Cast(bftSignedInt32);
    x := Random(Value.AsInteger);
    Clear(bftSignedInt32);
    AsInteger:=x;
   end;
end; // RandomData


//------------------------------------------------------------------------------
// ROUND operation
//------------------------------------------------------------------------------
procedure TACRVariant.RoundData(Value: TACRVariant);
var x,p:    Int64;
    e:      Extended;
    y,i:    Integer;
begin
  if (Value = nil) then
   begin
    if (IsNull) then
     Clear(bftSignedInt64)
    else
    begin
      if (FDataType <> bftExtended) then
       Cast(bftExtended);
      x := Round(AsExtended);
      Clear(bftSignedInt64);
      SetDataAsSignedInt64(x);
    end;
   end
  else
   begin
    if (IsNull) then
     Clear(bftVarchar)
    else
    begin
      if (FDataType <> bftExtended) then
       Cast(bftExtended);
      if (Value.DataType <> bftSignedInt64) then
       Cast(bftSignedInt64);
      p := Value.AsInt64;
      // fixed in v.5.60
      e := Self.AsExtended;
      if (Frac(e) > 0) then
      begin
        e := 0.5;
        y := 1;
        for i := 1 to p do
         begin
           e := e / 10;
           y := y * 10;
          end;
        e := e + AsExtended;
        e := Trunc(e * y) / y;
      end;
      Clear(bftVarchar);
      if (e = 0) and (Value = nil) then
        SetDataAsString('0')
      else
        SetDataAsString(Format('%.'+IntToStr(p)+'f',[e]));
    end;
   end;
end; // RoundData


//------------------------------------------------------------------------------
// SIGN operation
//------------------------------------------------------------------------------
procedure TACRVariant.SignData;
begin
  if not IsNull then
    begin
      case FDataType of
        bftSignedInt8:  if (AsShortint > 0) then
                         AsShortint := 1
                        else
                        if (AsShortint < 0) then
                         AsShortint := -1
                        else
                         AsShortint := 0;
        bftSignedInt16: if (AsSmallint > 0) then
                         AsSmallint := 1
                        else
                        if (AsSmallint < 0) then
                         AsSmallint := -1
                        else
                         AsSmallint := 0;
        bftSignedInt32: if (AsInteger > 0) then
                         AsInteger := 1
                        else
                        if (AsInteger < 0) then
                         AsInteger := -1
                        else
                         AsInteger := 0;
        bftSignedInt64: if (AsInt64 > 0) then
                         AsInt64 := 1
                        else
                        if (AsInt64 < 0) then
                         AsInt64 := -1
                        else
                         AsInt64 := 0;

        bftUnsignedInt8:  if (AsByte > 0) then
                            AsByte := 1
                          else
                            AsByte := 0;
        bftUnsignedInt16: if (AsWord > 0) then
                            AsWord := 1
                          else
                            AsWord := 0;
        bftUnsignedInt32: if (AsCardinal > 0) then
                            AsCardinal := 1
                          else
                            AsCardinal := 0;

        bftSingle:        if (AsSingle > 0) then
                            AsSingle := 1
                          else
                          if (AsSingle < 0) then
                            AsSingle := -1
                          else
                            AsSingle := 0;
        bftDouble:        if (AsDouble > 0) then
                            AsDouble := 1
                          else
                          if (AsDouble < 0) then
                            AsDouble := -1
                          else
                            AsDouble := 0;
        bftExtended:      if (AsExtended > 0) then
                            AsExtended := 1
                          else
                          if (AsExtended < 0) then
                            AsExtended := -1
                          else
                            AsExtended := 0;
        bftCurrency:      if (AsCurrency > 0) then
                            AsCurrency := 1
                          else
                          if (AsCurrency < 0) then
                            AsCurrency := -1
                          else
                            AsCurrency := 0;
        else
          raise EACRException.Create(11652, ErrorGNotNumericDataType, ['*']);
      end;
    end;
end; // SignData


//------------------------------------------------------------------------------
// TRUNCATE operation
//------------------------------------------------------------------------------
procedure TACRVariant.TruncateData(Value: TACRVariant);
var x,p:    Int64;
    e:      Extended;
    y,i:    Integer;
begin
  if (IsNull or (Value = nil)) then
   begin
    if (FDataType <> bftExtended) then
     Cast(bftExtended);
    x := Trunc(AsExtended);
    Clear(bftSignedInt64);
    SetDataAsSignedInt64(x);
   end
  else
   begin
    if (FDataType <> bftExtended) then
     Cast(bftExtended);
    if (Value.DataType <> bftSignedInt64) then
     Cast(bftSignedInt64);
    p := Value.AsInt64;
    // fixed in v.5.60
    e := Self.AsExtended;
    if (Frac(e) > 0) then
    begin
      y := 1;
      for i := 1 to p do
         y := y * 10;
      e := AsExtended;
      e := Trunc(e * y) / y;
    end;
    Clear(bftVarchar);
    if (e = 0) and (Value = nil) then
      SetDataAsString('0')
    else
      SetDataAsString(Format('%.'+IntToStr(p)+'f',[e]));
   end;
end; // TruncateData


//------------------------------------------------------------------------------
// AND operation
//------------------------------------------------------------------------------
procedure TACRVariant.AndData(Value: TACRVariant);
begin
 if (Value.IsNull) then
  Clear(FDataType)
 else
 if (not IsNull) then
  begin
   Cast(GetCommonDataType(FDataType, Value.DataType));
   case FDataType of
      bftSignedInt8:    AsShortInt := AsShortint AND Value.AsShortint;
      bftUnsignedInt8:  AsByte := AsByte AND Value.AsByte;
      bftSignedInt16:   AsSmallInt := AsSmallInt AND Value.AsSmallInt;
      bftUnsignedInt16: AsWord := AsWord AND Value.AsWord;
      bftSignedInt32:   AsInteger := AsInteger AND Value.AsInteger;
      bftUnsignedInt32: AsCardinal := AsCardinal AND Value.AsCardinal;
      bftSignedInt64:   AsInt64 := AsInt64 AND Value.AsInt64;
      bftLogical:       AsBoolean := AsBoolean AND Value.AsBoolean;
   else
     raise EACRException.Create(11645, ErrorGNotNumericDataType, ['*']);
   end;
  end;
end; // AndData


//------------------------------------------------------------------------------
// OR operation
//------------------------------------------------------------------------------
procedure TACRVariant.OrData(Value: TACRVariant);
begin
 if (Value.IsNull) then
  Clear(FDataType)
 else
 if (not IsNull) then
  begin
   Cast(GetCommonDataType(FDataType, Value.DataType));
   case FDataType of
      bftSignedInt8:    AsShortInt := AsShortint OR Value.AsShortint;
      bftUnsignedInt8:  AsByte := AsByte OR Value.AsByte;
      bftSignedInt16:   AsSmallInt := AsSmallInt OR Value.AsSmallInt;
      bftUnsignedInt16: AsWord := AsWord OR Value.AsWord;
      bftSignedInt32:   AsInteger := AsInteger OR Value.AsInteger;
      bftUnsignedInt32: AsCardinal := AsCardinal OR Value.AsCardinal;
      bftSignedInt64:   AsInt64 := AsInt64 OR Value.AsInt64;
      bftLogical:       AsBoolean := AsBoolean OR Value.AsBoolean;
   else
     raise EACRException.Create(11646, ErrorGNotNumericDataType, ['*']);
   end;
  end;
end; // OrData


//------------------------------------------------------------------------------
// NOT operation
//------------------------------------------------------------------------------
procedure TACRVariant.NotData;
begin
 if (not IsNull) then
  begin
   case FDataType of
      bftSignedInt8:    AsShortInt := NOT AsShortint;
      bftUnsignedInt8:  AsByte := NOT AsByte;
      bftSignedInt16:   AsSmallInt := NOT AsSmallInt ;
      bftUnsignedInt16: AsWord := NOT AsWord;
      bftSignedInt32:   AsInteger := NOT AsInteger;
      bftUnsignedInt32: AsCardinal := NOT AsCardinal;
      bftSignedInt64:   AsInt64 := NOT AsInt64;
      bftLogical:       AsBoolean := NOT AsBoolean;
   else
     raise EACRException.Create(11647, ErrorGNotNumericDataType, ['*']);
   end;
  end;
end; // NotData


//------------------------------------------------------------------------------
// SHL operation
//------------------------------------------------------------------------------
procedure TACRVariant.ShlData(Value: TACRVariant);
begin
 if (Value.IsNull) then
  Clear(FDataType)
 else
 if (not IsNull) then
  begin
   Cast(GetCommonDataType(FDataType, Value.DataType));
   case FDataType of
      bftSignedInt8:    AsShortInt := AsShortint SHL Value.AsShortint;
      bftUnsignedInt8:  AsByte := AsByte SHL Value.AsByte;
      bftSignedInt16:   AsSmallInt := AsSmallInt SHL Value.AsSmallInt;
      bftUnsignedInt16: AsWord := AsWord SHL Value.AsWord;
      bftSignedInt32:   AsInteger := AsInteger SHL Value.AsInteger;
      bftUnsignedInt32: AsCardinal := AsCardinal SHL Value.AsCardinal;
      bftSignedInt64:   AsInt64 := AsInt64 SHL Value.AsInt64;
   else
     raise EACRException.Create(11648, ErrorGNotNumericDataType, ['*']);
   end;
  end;
end; // ShlData


//------------------------------------------------------------------------------
// SHR operation
//------------------------------------------------------------------------------
procedure TACRVariant.ShrData(Value: TACRVariant);
begin
 if (Value.IsNull) then
  Clear(FDataType)
 else
 if (not IsNull) then
  begin
   Cast(GetCommonDataType(FDataType, Value.DataType));
   case FDataType of
      bftSignedInt8:    AsShortInt := AsShortint SHR Value.AsShortint;
      bftUnsignedInt8:  AsByte := AsByte SHR Value.AsByte;
      bftSignedInt16:   AsSmallInt := AsSmallInt SHR Value.AsSmallInt;
      bftUnsignedInt16: AsWord := AsWord SHR Value.AsWord;
      bftSignedInt32:   AsInteger := AsInteger SHR Value.AsInteger;
      bftUnsignedInt32: AsCardinal := AsCardinal SHR Value.AsCardinal;
      bftSignedInt64:   AsInt64 := AsInt64 SHR Value.AsInt64;
   else
     raise EACRException.Create(11649, ErrorGNotNumericDataType, ['*']);
   end;
  end;
end; // ShrData


//------------------------------------------------------------------------------
// XOR operation
//------------------------------------------------------------------------------
procedure TACRVariant.XorData(Value: TACRVariant);
begin
 if (Value.IsNull) then
  Clear(FDataType)
 else
 if (not IsNull) then
  begin
   Cast(GetCommonDataType(FDataType, Value.DataType));
   case FDataType of
      bftSignedInt8:    AsShortInt := AsShortint XOR Value.AsShortint;
      bftUnsignedInt8:  AsByte := AsByte XOR Value.AsByte;
      bftSignedInt16:   AsSmallInt := AsSmallInt XOR Value.AsSmallInt;
      bftUnsignedInt16: AsWord := AsWord XOR Value.AsWord;
      bftSignedInt32:   AsInteger := AsInteger XOR Value.AsInteger;
      bftUnsignedInt32: AsCardinal := AsCardinal XOR Value.AsCardinal;
      bftSignedInt64:   AsInt64 := AsInt64 XOR Value.AsInt64;
      bftLogical:       AsBoolean := AsBoolean XOR Value.AsBoolean;
   else
     raise EACRException.Create(11650, ErrorGNotNumericDataType, ['*']);
   end;
  end;
end; // XorData


//------------------------------------------------------------------------------
// HEX operation
//------------------------------------------------------------------------------
procedure TACRVariant.HexData(Format: TACRHexStringFormat);
var Res:     WideString;
    bString: Boolean;
    fm:      TFormat_HEX;
begin
  // if one of operands is null or not numeric
  if (FIsNull) then Exit;
  bString := IsStringDataType;
  if  ((not bString) and (not IsIntegerDataType))
      then
   begin
    Clear(bftChar);
    Exit;
   end;
   if (Format = ahexfDelphi) then
    Res := '$'
   else
   if (Format = ahexfCPP) then
    Res := '0x'
   else
    Res := '';
   if (bString) then
    begin
     fm := TFormat_HEX.Create;
     try
       Res := Res + fm.Encode(FPdata^,
                    GetStrLength(FPData,BaseFieldTypeToAdvancedFieldType(FDataType)));
     finally
       fm.Free;
     end;
    end
   else
   case FDataType of
      bftSignedInt8: Res := Res + IntToHex(AsShortint,2);
      bftUnsignedInt8: Res := Res + IntToHex(AsByte,2);
      bftSignedInt16: Res := Res + IntToHex(AsSmallint,4);
      bftUnsignedInt16: Res := Res + IntToHex(AsWord,4);
      bftSignedInt32: Res := Res + IntToHex(AsInteger,8);
      bftUnsignedInt32: Res := Res + IntToHex(AsCardinal,8);
      bftSignedInt64: Res := Res + IntToHex(AsInt64,16);
   end;
   if (Format = ahexfCPP) then
    Res := AnsiLowerCase(Res);
   Clear(bftWideChar);
   AsWideString := Res;
end; // HexData


//------------------------------------------------------------------------------
// DATEADD
//------------------------------------------------------------------------------
procedure TACRVariant.DateAdd(DatePart: TACRDatePart; Number: Integer);
var v:                      TDateTime;
    y,m,d,h,min,sec,msec,w: Word;
    x:                      Integer;
begin
  if (DatePart = dpUNDEFINED) then
   Exit;
  try
    if (not IsDateTimeDataType) then
      Cast(bftDateTime);
    v := GetDataAsTDateTime;
{ TODO : make uinternal ACREncodeDateTime, ACRDecodeDateTime to avoid bugs with TDateTime with too low value (1732 year for example) }    
    DecodeDateTime(v,y,m,d,h,min,sec,msec);
    case DatePart of
     dpYEAR:
     begin
      y := Word(Integer(y)+Number);
     end;
     dpQUARTER,dpMONTH:
     begin
      if (DatePart = dpQuarter) then
      begin
        if (Number >= 0) then
          x := Number*3
        else
          x := -Number*3;
      end
      else
      begin
        if (Number >= 0) then
          x := Number
        else
          x := -Number;
      end;
      while (x > 0) do
      begin
       if (Number >= 0) then
       begin
        if (m < 12) then
        begin
         Inc(m);
        end
        else
        begin
         m := 1;
         Inc(y);
        end // m = 12
       end
       else
       begin
        if (m > 1) then
        begin
         Dec(m);
        end
        else
        begin
         m := 12;
         Dec(y);
        end // m = 1
       end;
       Dec(x);
      end;
     end;
     dpDAY,dpWEEK:
     begin
      if (DatePart = dpWeek) then
      begin
       if (Number >= 0) then
         x := Number*7
       else
         x := -Number*7;
      end // week
      else
      begin
       if (Number >= 0) then
         x := Number
       else
         x := -Number;
      end; // day
      while (x > 0) do
      begin
       if (Number >= 0) then
       begin
         // next day
         w := ACRGetMaxDayOfMonth(m,y);
         if (d < w) then
         begin
           Inc(d);
         end
         else
         begin
          d := 1;
          if (m < 12) then
          begin
           // next month
           Inc(m);
          end // m < 12
          else
          begin
           // next year
           Inc(y);
           m := 1;
          end; // m = 12
         end; // d >= max day of month
       end // > 0
       else
       begin
         // prior day
         if (d > 1) then
         begin
          Dec(d);
         end
         else
         begin
          if (m > 1) then
          begin
           Dec(m);
           d := ACRGetMaxDayOfMonth(m,y);
          end // m > 1
          else
          begin
           m := 12;
           Dec(y);
           d := 31;
          end; //  m = 1
         end; //d = 1
       end; // < 0
       Dec(x);
      end; // x > 0
     end; // dpDAY, dpWEEK
     dpHOUR:
     begin
      if (Number >= 0) then
        x := Number
      else
        x := -Number;
      while (x > 0) do
      begin
       if (Number >= 0) then
       begin
        if (h < 23) then
        begin
         Inc(h);
        end // h < 24
        else
        begin
         h := 0;
         // next day
         w := ACRGetMaxDayOfMonth(m,y);
         if (d < w) then
         begin
           Inc(d);
         end
         else
         begin
          d := 1;
          if (m < 12) then
          begin
           // next month
           Inc(m);
          end // m < 12
          else
          begin
           // next year
           Inc(y);
           m := 1;
          end; // m = 12
         end; // d >= max day of month
        end; // h = 24
       end // Number > 0
       else
       begin
        if (h > 0) then
        begin
         Dec(h);
        end // h > 0
        else
        begin
         h := 23;
         // prior day
         if (d > 1) then
         begin
          Dec(d);
         end
         else
         begin
          if (m > 1) then
          begin
           Dec(m);
           d := ACRGetMaxDayOfMonth(m,y);
          end // m > 1
          else
          begin
           m := 12;
           Dec(y);
           d := 31;
          end; //  m = 1
         end; //d = 1
        end; // h = 0
       end; // Number < 0
       Dec(x);
      end; // x > 0
     end; // dpHOUR
     dpMINUTE:
     begin
      if (Number >= 0) then
        x := Number
      else
        x := -Number;
      while (x > 0) do
      begin
       if (Number >= 0) then
       begin
        // next minute
        if (min < 59) then
        begin
          Inc(min);
        end
        else
        begin
          min := 0;
          if (h < 23) then
          begin
           Inc(h);
          end // h < 24
          else
          begin
           h := 0;
           // next day
           w := ACRGetMaxDayOfMonth(m,y);
           if (d < w) then
           begin
             Inc(d);
           end
           else
           begin
            d := 1;
            if (m < 12) then
            begin
             // next month
             Inc(m);
            end // m < 12
            else
            begin
             // next year
             Inc(y);
             m := 1;
            end; // m = 12
           end; // d >= max day of month
          end; // h = 24
        end; // min = 59
       end // Number >= 0
       else
       begin
        // prior minute
        if (min > 0) then
        begin
          Dec(min);
        end
        else
        begin
          min := 59;
          if (h > 0) then
          begin
           Dec(h);
          end // h > 0
          else
          begin
           h := 23;
           // prior day
           if (d > 1) then
           begin
            Dec(d);
           end
           else
           begin
            if (m > 1) then
            begin
             Dec(m);
             d := ACRGetMaxDayOfMonth(m,y);
            end // m > 1
            else
            begin
             m := 12;
             Dec(y);
             d := 31;
            end; //  m = 1
           end; //d = 1
          end; // h = 0
        end; //  min = 0
       end; // Number < 0
       Dec(x);
      end; // x > 0
     end; // dpMINUTE
     dpSECOND:
     begin
      if (Number >= 0) then
        x := Number
      else
        x := -Number;
      while (x > 0) do
      begin
       if (Number >= 0) then
       begin
        // next second
        if (sec < 59) then
        begin
          Inc(sec);
        end
        else
        begin
          sec := 0;
          // next minute
          if (min < 59) then
          begin
            Inc(min);
          end
          else
          begin
            min := 0;
            if (h < 23) then
            begin
             Inc(h);
            end // h < 24
            else
            begin
             h := 0;
             // next day
             w := ACRGetMaxDayOfMonth(m,y);
             if (d < w) then
             begin
               Inc(d);
             end
             else
             begin
              d := 1;
              if (m < 12) then
              begin
               // next month
               Inc(m);
              end // m < 12
              else
              begin
               // next year
               Inc(y);
               m := 1;
              end; // m = 12
             end; // d >= max day of month
            end; // h = 24
          end; // min = 59
        end; // next second
       end // Number >= 0
       else
       begin
        // prior second
        if (sec > 0) then
        begin
          Dec(sec);
        end
        else
        begin
          sec := 59;
          // prior minute
          if (min > 0) then
          begin
            Dec(min);
          end
          else
          begin
            min := 59;
            if (h > 0) then
            begin
             Dec(h);
            end // h > 0
            else
            begin
             h := 23;
             // prior day
             if (d > 1) then
             begin
              Dec(d);
             end
             else
             begin
              if (m > 1) then
              begin
               Dec(m);
               d := ACRGetMaxDayOfMonth(m,y);
              end // m > 1
              else
              begin
               m := 12;
               Dec(y);
               d := 31;
              end; //  m = 1
             end; //d = 1
            end; // h = 0
          end; //  min = 0
        end; // sec = 0
       end; // Number < 0
       Dec(x);
      end; // x > 0
     end; // dpSECOND
     dpMILLISECOND:
     begin
      if (Number >= 0) then
        x := Number
      else
        x := -Number;
      while (x > 0) do
      begin
       if (Number >= 0) then
       begin
        // next millisecond
        if (msec < 999) then
        begin
          Inc(msec);
        end
        else
        begin
          msec := 0;
          // next second
          if (sec < 59) then
          begin
            Inc(sec);
          end
          else
          begin
            sec := 0;
            // next minute
            if (min < 59) then
            begin
              Inc(min);
            end
            else
            begin
              min := 0;
              if (h < 23) then
              begin
               Inc(h);
              end // h < 24
              else
              begin
               h := 0;
               // next day
               w := ACRGetMaxDayOfMonth(m,y);
               if (d < w) then
               begin
                 Inc(d);
               end
               else
               begin
                d := 1;
                if (m < 12) then
                begin
                 // next month
                 Inc(m);
                end // m < 12
                else
                begin
                 // next year
                 Inc(y);
                 m := 1;
                end; // m = 12
               end; // d >= max day of month
              end; // h = 24
            end; // min = 59
          end; // next second
        end; // next millisecond
       end // Number >= 0
       else
       begin
        // next millisecond
        if (msec > 0) then
        begin
          Dec(msec);
        end
        else
        begin
          msec := 999;
          // prior second
          if (sec > 0) then
          begin
            Dec(sec);
          end
          else
          begin
            sec := 59;
            // prior minute
            if (min > 0) then
            begin
              Dec(min);
            end
            else
            begin
              min := 59;
              if (h > 0) then
              begin
               Dec(h);
              end // h > 0
              else
              begin
               h := 23;
               // prior day
               if (d > 1) then
               begin
                Dec(d);
               end
               else
               begin
                if (m > 1) then
                begin
                 Dec(m);
                 d := ACRGetMaxDayOfMonth(m,y);
                end // m > 1
                else
                begin
                 m := 12;
                 Dec(y);
                 d := 31;
                end; //  m = 1
               end; //d = 1
              end; // h = 0
            end; //  min = 0
          end; // sec = 0
        end; // prior milliscond
       end; // Number < 0
       Dec(x);
      end; // x > 0
     end; // dpMILLISECOND
    end; // CASE
    // fix day for ferburary
    if (DatePart in [dpQUARTER,dpMONTH,dpYEAR]) and (d >= 29) then
    begin
      w := ACRGetMaxDayOfMonth(m,y);
      if (d > w) then
       d := w;
    end;
    v := EncodeDateTime(y,m,d,h,min,sec,msec);
    SetDataAsTDateTime(v);
  except
    Clear;
  end;
end; // DateAdd


//------------------------------------------------------------------------------
// DATEDIFF
//------------------------------------------------------------------------------
procedure TACRVariant.DateDiff(DatePart: TACRDatePart; StartDate,EndDate: TACRVariant);
var v:                                TDateTime;
    q,q1,dw,
    sy,sm,sd,sh,smin,ssec,smsec,
    ey,em,ed,eh,emin,esec,emsec:      Word;
    x:                                Integer;
    bMinus:                           Boolean;
begin
  if (DatePart = dpUNDEFINED) then
   Exit;
  try
    if (not StartDate.IsDateTimeDataType) then
     StartDate.Cast(bftDateTime);
    if (not EndDate.IsDateTimeDataType) then
     EndDate.Cast(bftDateTime);
    bMinus := (StartDate.Compare(EndDate,False,False,False) = cmprGreater);
    if (bMinus) then
    begin
      v := StartDate.AsTDateTime;
      DecodeDateTime(v,ey,em,ed,eh,emin,esec,emsec);
      v := EndDate.AsTDateTime;
      DecodeDateTime(v,sy,sm,sd,sh,smin,ssec,smsec);
      if (DatePart = dpWEEK) then
        dw := DayOfWeek(v);
    end
    else
    begin
      v := StartDate.AsTDateTime;
      DecodeDateTime(v,sy,sm,sd,sh,smin,ssec,smsec);
      if (DatePart = dpWEEK) then
        dw := DayOfWeek(v);
      v := EndDate.AsTDateTime;
      DecodeDateTime(v,ey,em,ed,eh,emin,esec,emsec);
    end;
    x := 0;
    case DatePart of
     dpYEAR:
     begin
      while (sy <> ey) do
      begin
       Inc(sy);
       Inc(x);
      end; // while dates not equal
     end; // dpYEAR
     dpQUARTER:
     begin
      while (sy <> ey) or (sm <> em) do
      begin
       q := (sm - 1) div 3;
       if (sm < 12) then
       begin
        Inc(sm);
       end
       else
       begin
        sm := 1;
        Inc(sy);
       end;
       q1 := (sm - 1) div 3;
       if (q <> q1) then
         Inc(x);
      end; // while dates not equal
     end; // dpQUARTER
     dpMONTH:
     begin
      while (sy <> ey) or (sm <> em) do
      begin
       if (sm < 12) then
       begin
        Inc(sm);
       end
       else
       begin
        sm := 1;
        Inc(sy);
       end;
       Inc(x);
      end; // while dates not equal
     end; // dpMONTH
     dpWEEK:
     begin
      while (sy <> ey) or (sm <> em) or (sd <> ed) do
      begin
       if (sd < 28) then
        Inc(sd)
       else
       if (sd < ACRGetMaxDayOfMonth(sm,sy)) then
        Inc(sd)
       else
       begin
         sd := 1;
         // next month
         if (sm < 12) then
         begin
          Inc(sm);
         end
         else
         begin
          sm := 1;
          Inc(sy);
         end;
       end;
       Inc(dw);
       if (dw = 8) then
       begin
        dw := 1;
        Inc(x);
       end;
      end; // while dates not equal
     end; // dpWEEK
     dpDAY:
     begin
      while (sy <> ey) or (sm <> em) or (sd <> ed) do
      begin
       if (sd < 28) then
        Inc(sd)
       else
       if (sd < ACRGetMaxDayOfMonth(sm,sy)) then
        Inc(sd)
       else
       begin
         sd := 1;
         // next month
         if (sm < 12) then
         begin
          Inc(sm);
         end
         else
         begin
          sm := 1;
          Inc(sy);
         end;
       end;
       Inc(x);
      end; // while dates not equal
     end; // dpDAY
     dpHOUR:
     begin
      while (sy <> ey) or (sm <> em) or (sd <> ed) or (sh <> eh) do
      begin
       if (sh < 23) then
         Inc(sh)
       else
       begin
         sh := 0;
         // next day
         if (sd < 28) then
          Inc(sd)
         else
         if (sd < ACRGetMaxDayOfMonth(sm,sy)) then
          Inc(sd)
         else
         begin
           sd := 1;
           // next month
           if (sm < 12) then
           begin
            Inc(sm);
           end // next month
           else
           begin
            sm := 1;
            Inc(sy);
           end; // next year
         end; // day of month
       end;
       Inc(x);
      end; // while dates not equal
     end; // dpHOUR
     dpMINUTE:
     begin
      while (sy <> ey) or (sm <> em) or (sd <> ed) or (sh <> eh) or (smin <> emin) do
      begin
       if (smin < 59) then
        Inc(smin)
       else
       begin
         smin := 0;
         // next hour
         if (sh < 23) then
           Inc(sh)
         else
         begin
           sh := 0;
           // next day
           if (sd < 28) then
            Inc(sd)
           else
           if (sd < ACRGetMaxDayOfMonth(sm,sy)) then
            Inc(sd)
           else
           begin
             sd := 1;
             // next month
             if (sm < 12) then
             begin
              Inc(sm);
             end // next month
             else
             begin
              sm := 1;
              Inc(sy);
             end; // next year
           end; // next day
         end; // next hour
       end; // next minute of hour
       Inc(x);
      end; // while dates not equal
     end; // dpMINUTE
     dpSECOND:
     begin
      while (sy <> ey) or (sm <> em) or (sd <> ed) or (sh <> eh) or
            (smin <> emin) or (ssec <> esec) do
      begin
       if (ssec < 59) then
        Inc(ssec)
       else
       begin
         ssec := 0;
         // next minute
         if (smin < 59) then
          Inc(smin)
         else
         begin
           smin := 0;
           // next hour
           if (sh < 23) then
             Inc(sh)
           else
           begin
             sh := 0;
             // next day
             if (sd < 28) then
              Inc(sd)
             else
             if (sd < ACRGetMaxDayOfMonth(sm,sy)) then
              Inc(sd)
             else
             begin
               sd := 1;
               // next month
               if (sm < 12) then
               begin
                Inc(sm);
               end // next month
               else
               begin
                sm := 1;
                Inc(sy);
               end; // next year
             end; // next day
           end; // next hour
         end; // next minute 
       end; // next second of minute
       Inc(x);
      end; // while dates not equal
     end; // dpSECOND
     dpMILLISECOND:
     begin
      while (sy <> ey) or (sm <> em) or (sd <> ed) or (sh <> eh) or
            (smin <> emin) or (ssec <> esec) or (smsec <> emsec) do
      begin
       if (smsec < 999) then
         Inc(smsec)
       else
       begin
         smsec := 0;
         // next second
         if (ssec < 59) then
          Inc(ssec)
         else
         begin
           ssec := 0;
           // next minute
           if (smin < 59) then
            Inc(smin)
           else
           begin
             smin := 0;
             // next hour
             if (sh < 23) then
               Inc(sh)
             else
             begin
               sh := 0;
               // next day
               if (sd < 28) then
                Inc(sd)
               else
               if (sd < ACRGetMaxDayOfMonth(sm,sy)) then
                Inc(sd)
               else
               begin
                 sd := 1;
                 // next month
                 if (sm < 12) then
                 begin
                  Inc(sm);
                 end // next month
                 else
                 begin
                  sm := 1;
                  Inc(sy);
                 end; // next year
               end; // next day
             end; // next hour
           end; // next minute
         end; // next second
       end; // next millisecond of second
       Inc(x);
      end; // while dates not equal
     end; // dpMILLISECOND
    end;
    Clear(bftSignedInt32);
    if (bMinus) then
     x := -x;
    SetDataAsSignedInt32(x);
  except
    Clear;
  end;
end; // DateDiff


//------------------------------------------------------------------------------
// EXP function
//------------------------------------------------------------------------------
procedure TACRVariant.ExpData;
var e: extended;
begin
  if not IsNull then
    begin
      e := GetDataAsExtended;
      e := Exp(e);
      case FDataType of
        bftSignedInt8:      AsShortint := Round(e);
        bftSignedInt16:     AsSmallint := Round(e);
        bftSignedInt32:     AsInteger := Round(e);
        bftSignedInt64:     AsInt64 := Round(e);

        bftUnsignedInt8:    AsByte := Round(e);
        bftUnsignedInt16:   AsWord := Round(e);
        bftUnsignedInt32:   AsCardinal := Round(e);

        bftSingle:          AsSingle := e;
        bftDouble:          AsDouble := e;
        bftExtended:        AsExtended := e;
        bftCurrency:        AsCurrency := e;
        else
          raise EACRException.Create(12488, ErrorGNotNumericDataType, ['EXP']);
      end;
    end;
end; // ExpData


//------------------------------------------------------------------------------
// LOG / LN function
//------------------------------------------------------------------------------
procedure TACRVariant.LogData(Base: TACRVariant);
var b,e: extended;
begin
  if not IsNull then
    begin
      e := GetDataAsExtended;
      b := Exp(1);
      if (Base <> nil) then
       if (not Base.IsNull) then
        b := Base.AsExtended;
      e := LogN(b,e);
      case FDataType of
        bftSignedInt8:      AsShortint := Round(e);
        bftSignedInt16:     AsSmallint := Round(e);
        bftSignedInt32:     AsInteger := Round(e);
        bftSignedInt64:     AsInt64 := Round(e);

        bftUnsignedInt8:    AsByte := Round(e);
        bftUnsignedInt16:   AsWord := Round(e);
        bftUnsignedInt32:   AsCardinal := Round(e);

        bftSingle:          AsSingle := e;
        bftDouble:          AsDouble := e;
        bftExtended:        AsExtended := e;
        bftCurrency:        AsCurrency := e;
        else
          raise EACRException.Create(12489, ErrorGNotNumericDataType, ['LOG']);
      end;
    end;
end; // LogData


//------------------------------------------------------------------------------
// LOG10 function
//------------------------------------------------------------------------------
procedure TACRVariant.Log10Data;
var e: extended;
begin
  if not IsNull then
    begin
      e := GetDataAsExtended;
      e := Log10(e);
      case FDataType of
        bftSignedInt8:      AsShortint := Round(e);
        bftSignedInt16:     AsSmallint := Round(e);
        bftSignedInt32:     AsInteger := Round(e);
        bftSignedInt64:     AsInt64 := Round(e);

        bftUnsignedInt8:    AsByte := Round(e);
        bftUnsignedInt16:   AsWord := Round(e);
        bftUnsignedInt32:   AsCardinal := Round(e);

        bftSingle:          AsSingle := e;
        bftDouble:          AsDouble := e;
        bftExtended:        AsExtended := e;
        bftCurrency:        AsCurrency := e;
        else
          raise EACRException.Create(12490, ErrorGNotNumericDataType, ['LOG10']);
      end;
    end;
end; // Log10Data


//------------------------------------------------------------------------------
// COS function
//------------------------------------------------------------------------------
procedure TACRVariant.CosData;
var e: extended;
begin
  if not IsNull then
    begin
      e := GetDataAsExtended;
      e := Cos(e);
      case FDataType of
        bftSignedInt8:      AsShortint := Round(e);
        bftSignedInt16:     AsSmallint := Round(e);
        bftSignedInt32:     AsInteger := Round(e);
        bftSignedInt64:     AsInt64 := Round(e);

        bftUnsignedInt8:    AsByte := Round(e);
        bftUnsignedInt16:   AsWord := Round(e);
        bftUnsignedInt32:   AsCardinal := Round(e);

        bftSingle:          AsSingle := e;
        bftDouble:          AsDouble := e;
        bftExtended:        AsExtended := e;
        bftCurrency:        AsCurrency := e;
        else
          raise EACRException.Create(12491, ErrorGNotNumericDataType, ['COS']);
      end;
    end;
end; // COS


//------------------------------------------------------------------------------
// SIN function
//------------------------------------------------------------------------------
procedure TACRVariant.SinData;
var e: extended;
begin
  if not IsNull then
    begin
      e := GetDataAsExtended;
      e := Sin(e);
      case FDataType of
        bftSignedInt8:      AsShortint := Round(e);
        bftSignedInt16:     AsSmallint := Round(e);
        bftSignedInt32:     AsInteger := Round(e);
        bftSignedInt64:     AsInt64 := Round(e);

        bftUnsignedInt8:    AsByte := Round(e);
        bftUnsignedInt16:   AsWord := Round(e);
        bftUnsignedInt32:   AsCardinal := Round(e);

        bftSingle:          AsSingle := e;
        bftDouble:          AsDouble := e;
        bftExtended:        AsExtended := e;
        bftCurrency:        AsCurrency := e;
        else
          raise EACRException.Create(12492, ErrorGNotNumericDataType, ['SIN']);
      end;
    end;
end; // SIN


//------------------------------------------------------------------------------
// COS function
//------------------------------------------------------------------------------
procedure TACRVariant.AcosData;
var e: extended;
begin
  if not IsNull then
    begin
      e := GetDataAsExtended;
      e := ArcCos(e);
      case FDataType of
        bftSignedInt8:      AsShortint := Round(e);
        bftSignedInt16:     AsSmallint := Round(e);
        bftSignedInt32:     AsInteger := Round(e);
        bftSignedInt64:     AsInt64 := Round(e);

        bftUnsignedInt8:    AsByte := Round(e);
        bftUnsignedInt16:   AsWord := Round(e);
        bftUnsignedInt32:   AsCardinal := Round(e);

        bftSingle:          AsSingle := e;
        bftDouble:          AsDouble := e;
        bftExtended:        AsExtended := e;
        bftCurrency:        AsCurrency := e;
        else
          raise EACRException.Create(12495, ErrorGNotNumericDataType, ['ACOS']);
      end;
    end;
end; // ACOS


//------------------------------------------------------------------------------
// ASIN function
//------------------------------------------------------------------------------
procedure TACRVariant.AsinData;
var e: extended;
begin
  if not IsNull then
    begin
      e := GetDataAsExtended;
      e := ArcSin(e);
      case FDataType of
        bftSignedInt8:      AsShortint := Round(e);
        bftSignedInt16:     AsSmallint := Round(e);
        bftSignedInt32:     AsInteger := Round(e);
        bftSignedInt64:     AsInt64 := Round(e);

        bftUnsignedInt8:    AsByte := Round(e);
        bftUnsignedInt16:   AsWord := Round(e);
        bftUnsignedInt32:   AsCardinal := Round(e);

        bftSingle:          AsSingle := e;
        bftDouble:          AsDouble := e;
        bftExtended:        AsExtended := e;
        bftCurrency:        AsCurrency := e;
        else
          raise EACRException.Create(12496, ErrorGNotNumericDataType, ['ASIN']);
      end;
    end;
end; // ASIN


//------------------------------------------------------------------------------
// ATAN function
//------------------------------------------------------------------------------
procedure TACRVariant.AtanData;
var e: extended;
begin
  if not IsNull then
    begin
      e := GetDataAsExtended;
      e := ArcTan(e);
      case FDataType of
        bftSignedInt8:      AsShortint := Round(e);
        bftSignedInt16:     AsSmallint := Round(e);
        bftSignedInt32:     AsInteger := Round(e);
        bftSignedInt64:     AsInt64 := Round(e);

        bftUnsignedInt8:    AsByte := Round(e);
        bftUnsignedInt16:   AsWord := Round(e);
        bftUnsignedInt32:   AsCardinal := Round(e);

        bftSingle:          AsSingle := e;
        bftDouble:          AsDouble := e;
        bftExtended:        AsExtended := e;
        bftCurrency:        AsCurrency := e;
        else
          raise EACRException.Create(12502, ErrorGNotNumericDataType, ['ATAN']);
      end;
    end;
end; // AtanData


//------------------------------------------------------------------------------
// ATAN2 function
//------------------------------------------------------------------------------
procedure TACRVariant.Atan2Data(YCoord: TACRVariant);
var x,y,e: extended;
begin
  if (not IsNull) and (not YCoord.IsNull) then
    begin
      x := GetDataAsExtended;
      y := YCoord.AsExtended;
      e := ArcTan2(x,y);
      case FDataType of
        bftSignedInt8:      AsShortint := Round(e);
        bftSignedInt16:     AsSmallint := Round(e);
        bftSignedInt32:     AsInteger := Round(e);
        bftSignedInt64:     AsInt64 := Round(e);

        bftUnsignedInt8:    AsByte := Round(e);
        bftUnsignedInt16:   AsWord := Round(e);
        bftUnsignedInt32:   AsCardinal := Round(e);

        bftSingle:          AsSingle := e;
        bftDouble:          AsDouble := e;
        bftExtended:        AsExtended := e;
        bftCurrency:        AsCurrency := e;
        else
          raise EACRException.Create(12503, ErrorGNotNumericDataType, ['ATAN2']);
      end;
    end;
end; // Atan2Data


//------------------------------------------------------------------------------
// COT function
//------------------------------------------------------------------------------
procedure TACRVariant.CotData;
var e: extended;
begin
  if not IsNull then
    begin
      e := GetDataAsExtended;
      {$IFDEF D6H}
      e := Cot(e);
      {$ELSE}
      e := Cotan(e);
      {$ENDIF}
      case FDataType of
        bftSignedInt8:      AsShortint := Round(e);
        bftSignedInt16:     AsSmallint := Round(e);
        bftSignedInt32:     AsInteger := Round(e);
        bftSignedInt64:     AsInt64 := Round(e);

        bftUnsignedInt8:    AsByte := Round(e);
        bftUnsignedInt16:   AsWord := Round(e);
        bftUnsignedInt32:   AsCardinal := Round(e);

        bftSingle:          AsSingle := e;
        bftDouble:          AsDouble := e;
        bftExtended:        AsExtended := e;
        bftCurrency:        AsCurrency := e;
        else
          raise EACRException.Create(12506, ErrorGNotNumericDataType, ['COT']);
      end;
    end;
end; // CotData


//------------------------------------------------------------------------------
// TAN function
//------------------------------------------------------------------------------
procedure TACRVariant.TanData;
var e: extended;
begin
  if not IsNull then
    begin
      e := GetDataAsExtended;
      e := Tan(e);
      case FDataType of
        bftSignedInt8:      AsShortint := Round(e);
        bftSignedInt16:     AsSmallint := Round(e);
        bftSignedInt32:     AsInteger := Round(e);
        bftSignedInt64:     AsInt64 := Round(e);

        bftUnsignedInt8:    AsByte := Round(e);
        bftUnsignedInt16:   AsWord := Round(e);
        bftUnsignedInt32:   AsCardinal := Round(e);

        bftSingle:          AsSingle := e;
        bftDouble:          AsDouble := e;
        bftExtended:        AsExtended := e;
        bftCurrency:        AsCurrency := e;
        else
          raise EACRException.Create(12507, ErrorGNotNumericDataType, ['TAN']);
      end;
    end;
end; // TanData


//------------------------------------------------------------------------------
// SQR function
//------------------------------------------------------------------------------
procedure TACRVariant.SqrData;
begin
  if not IsNull then
    begin
      case FDataType of
        bftSignedInt8:      AsWord := Smallint(GetDataAsSignedInt8 * GetDataAsSignedInt8);
        bftSignedInt16:     AsCardinal := Integer(GetDataAsSignedInt16 * GetDataAsSignedInt16);
        bftSignedInt32:     AsInt64 := Int64(GetDataAsSignedInt32 * GetDataAsSignedInt32);
        bftUnsignedInt8:    AsWord := Smallint(GetDataAsUnsignedInt8 * GetDataAsUnsignedInt8);
        bftUnsignedInt16:   AsCardinal := Integer(GetDataAsUnsignedInt16 * GetDataAsUnsignedInt16);
        bftUnsignedInt32:   AsInt64 := Int64(GetDataAsUnsignedInt32 * GetDataAsUnsignedInt32);
        bftSignedInt64:     AsInt64 := Int64(GetDataAsSignedInt64 * GetDataAsSignedInt64);

        bftSingle:          AsExtended := Extended(GetDataAsSingle * GetDataAsSingle);
        bftDouble:          AsExtended := Extended(GetDataAsDouble * GetDataAsDouble);
        bftExtended:        AsExtended := Extended(GetDataAsExtended * GetDataAsExtended);
        bftCurrency:        AsExtended := Extended(GetDataAsCurrency * GetDataAsCurrency);
        else
          raise EACRException.Create(12511, ErrorGNotNumericDataType, ['SQR']);
      end;
    end;
end; // SqrData


//------------------------------------------------------------------------------
// SQRT function
//------------------------------------------------------------------------------
procedure TACRVariant.SqrtData;
var e: extended;
begin
  if not IsNull then
    begin
      e := GetDataAsExtended;
      e := Sqrt(e);
      case FDataType of
        bftSignedInt8:      AsShortint := Round(e);
        bftSignedInt16:     AsSmallint := Round(e);
        bftSignedInt32:     AsInteger := Round(e);
        bftSignedInt64:     AsInt64 := Round(e);

        bftUnsignedInt8:    AsByte := Round(e);
        bftUnsignedInt16:   AsWord := Round(e);
        bftUnsignedInt32:   AsCardinal := Round(e);

        bftSingle:          AsSingle := e;
        bftDouble:          AsDouble := e;
        bftExtended:        AsExtended := e;
        bftCurrency:        AsCurrency := e;
        else
          raise EACRException.Create(12512, ErrorGNotNumericDataType, ['SQRT']);
      end;
    end;
end; // SqrtData


//------------------------------------------------------------------------------
// DEGREES function
//------------------------------------------------------------------------------
procedure TACRVariant.DegreesData;
var e: extended;
begin
  if not IsNull then
    begin
      e := GetDataAsExtended;
      e := e / System.PI * 180.0;
      case FDataType of
        bftSignedInt8:      AsShortint := Round(e);
        bftSignedInt16:     AsSmallint := Round(e);
        bftSignedInt32:     AsInteger := Round(e);
        bftSignedInt64:     AsInt64 := Round(e);

        bftUnsignedInt8:    AsByte := Round(e);
        bftUnsignedInt16:   AsWord := Round(e);
        bftUnsignedInt32:   AsCardinal := Round(e);

        bftSingle:          AsSingle := e;
        bftDouble:          AsDouble := e;
        bftExtended:        AsExtended := e;
        bftCurrency:        AsCurrency := e;
        else
          raise EACRException.Create(12513, ErrorGNotNumericDataType, ['DEGREES']);
      end;
    end;
end; // DegreesData


//------------------------------------------------------------------------------
// RADIANS function
//------------------------------------------------------------------------------
procedure TACRVariant.RadiansData;
var e: extended;
begin
  if not IsNull then
    begin
      e := GetDataAsExtended;
      e := e / 180.0 * System.PI;
      case FDataType of
        bftSignedInt8:      AsShortint := Round(e);
        bftSignedInt16:     AsSmallint := Round(e);
        bftSignedInt32:     AsInteger := Round(e);
        bftSignedInt64:     AsInt64 := Round(e);

        bftUnsignedInt8:    AsByte := Round(e);
        bftUnsignedInt16:   AsWord := Round(e);
        bftUnsignedInt32:   AsCardinal := Round(e);

        bftSingle:          AsSingle := e;
        bftDouble:          AsDouble := e;
        bftExtended:        AsExtended := e;
        bftCurrency:        AsCurrency := e;
        else
          raise EACRException.Create(12514, ErrorGNotNumericDataType, ['RADIANS']);
      end;
    end;
end; // RadiansData


//------------------------------------------------------------------------------
// PI function
//------------------------------------------------------------------------------
procedure TACRVariant.PiData;
begin
  AsExtended := System.Pi;
end; // PI


//------------------------------------------------------------------------------
// Compare with another Variants
//------------------------------------------------------------------------------
function TACRVariant.CompareMemoAndAnsiString(
                              ReverseResult:      Boolean;
                              Str:                TACRVariant;
                              TrueFalseNullLogic: Boolean = True;
                              CaseInsensitive:    Boolean = True;
                              PartialKey:         Boolean = False
                            ): TACRCompareResult;
var buf:        PAnsiChar;
    i,zs:       Integer;
    BufSize:    Integer;
   {$I ACR_cmp_buffers_var.inc}
begin
  if (PartialKey) then
// changed from Min in 4.80
// Partial key always MUST BE IN Str
//        i := min(FDataSize, Str.StrLen)
   CMP_BUF_PartialCompareLength := Str.StrLen
  else
   CMP_BUF_PartialCompareLength := -1;
  CMP_BUF_IgnoreCase := CaseInsensitive;
  CMP_BUF_BaseFieldType1 := Str.DataType;
  CMP_BUF_BaseFieldType2 := CMP_BUF_BaseFieldType1;
{$IFDEF MSWINDOWS}
  CMP_BUF_LocaleID := LOCALE_USER_DEFAULT;
{$ENDIF}          // Check Min Constraint ( Min > Value ==> Raise )
  if (not IsWideStringFieldType(CMP_BUF_BaseFieldType1)) then
  begin
    BufSize := DataSize+1;
    zs := 1;
  end
  else
  begin
    BufSize := DataSize+2;
    zs := 2;
  end;
  buf := MemoryManager.GetMem(BufSize);
  try
    Move(FPData^,buf^,FDataSize);
    FillChar(PAnsiChar(buf+FDataSize)^,zs,$00);
    if (not ReverseResult) then
    begin
     // optimized in v.5.60
     CMP_BUF_Buffer1 := buf;
     CMP_BUF_Buffer2 := Str.FPData;
     CMP_BUF_IsField1Null := IsNull;
     CMP_BUF_IsField2Null := Str.IsNull;
     {$I ACR_cmp_buffers.inc}
     Result := CMP_BUF_Result;
    end
    else
    begin
     // optimized in v.5.60
     CMP_BUF_Buffer1 := Str.FPData;
     CMP_BUF_Buffer2 := buf;
     CMP_BUF_IsField1Null := Str.IsNull;
     CMP_BUF_IsField2Null := IsNull;
     {$I ACR_cmp_buffers.inc}
     Result := CMP_BUF_Result;
    end
  finally
    MemoryManager.FreeAndNilMem(buf);
  end;
end; // CompareMemoAndAnsiString


//------------------------------------------------------------------------------
// Compare with another Variants
//------------------------------------------------------------------------------
function TACRVariant.Compare(Value: TACRVariant; TrueFalseNullLogic, CaseInsensitive, PartialKey: boolean): TACRCompareResult;
var
   {$I ACR_cmp_buffers_var.inc}
begin
  // patch for memo fields
  if (not Value.IsNull) and (not FIsNull) and
     (IsBLOBFieldType(Value.DataType)) and (IsStringFieldType(FDataType)) and
     (not IsBLOBFieldType(FDataType)) then
    Result := Value.CompareMemoAndAnsiString(True,Self,TrueFalseNullLogic,CaseInsensitive,PartialKey)
  else
  if (not Value.IsNull) and (not FIsNull) and
     (IsBLOBFieldType(DataType)) and (IsStringFieldType(Value.DataType)) and
     (not IsBLOBFieldType(Value.DataType)) then
    Result := Self.CompareMemoAndAnsiString(False,Value,TrueFalseNullLogic,CaseInsensitive,PartialKey)
  else
  begin
    // optimized in v.5.60
    if (PartialKey) then
  // changed from Min in 4.80
  // Partial key always MUST BE IN Str
  //        i := min(FDataSize, Str.StrLen)
     CMP_BUF_PartialCompareLength := Value.StrLen
    else
     CMP_BUF_PartialCompareLength := -1;
    CMP_BUF_IgnoreCase := CaseInsensitive;
{$IFDEF MSWINDOWS}
    CMP_BUF_LocaleID := LOCALE_USER_DEFAULT;
{$ENDIF}          // Check Min Constraint ( Min > Value ==> Raise )
    CMP_BUF_BaseFieldType1 := FDataType;
    CMP_BUF_BaseFieldType2 := Value.DataType;
    CMP_BUF_Buffer1 := FPData;
    CMP_BUF_Buffer2 := Value.FPData;
    CMP_BUF_IsField1Null := IsNull;
    CMP_BUF_IsField2Null := Value.IsNull;
    {$I ACR_cmp_buffers.inc}
    Result := CMP_BUF_Result;
  end;
  if (not TrueFalseNullLogic) then
   case Result of
    cmprBothNull:
      Result := cmprEqual;
    cmprLeftNull:
      Result := cmprLower;
    cmprRightNull:
      Result := cmprGreater;
   end;
end;//Compare


//------------------------------------------------------------------------------
// return 32-bit usigned integer hash value for the value stored in FPData or
// ACR_NULL_HASH for null value
//------------------------------------------------------------------------------
function TACRVariant.GetBinaryHash: TACRRecordHashValue;
var CRCSize: Cardinal;
    i:       Integer;
begin
 if (FIsNull) then
  Result := ACR_NULL_HASH
 else
  begin
   if (FIsBlob or (not IsStringDataType)) then
    CRCSize := FDataSize
   else
   if (IsWideStringDataType) then
    CRCSize := StrLen*2
   else
    CRCSize := StrLen;
   Result := TACRRecordHashValue(ACR_CRC32(ACR_FIELD_HASH_BASE,FPData,CRCSize));
   if (CRCSize <= ACR_MAX_SMALL_VALUE_FOR_SIZE) then
    begin
     for i := 0 to CRCSize - 1 do
      Result := TACRRecordHashValue(Result+Cardinal(PByte(FPData+i)^));
    end;
  end;
end; // GetBinaryHash


//------------------------------------------------------------------------------
// convert unicode string to ANSI if it has no Unicode symbols
//------------------------------------------------------------------------------
procedure TACRVariant.ConvertWideStringToAnsiStringIfNotUnicode;
var bUnicode: Boolean;
    i:        Integer;
begin
 if (IsWideStringDataType) then
  begin
   bUnicode := False;
   i := 1;
   while (i < FDataSize) do
    begin
      if (PByte(FPData+i)^ <> 0) then
       begin
         bUnicode := True;
         break;
       end;
      Inc(i,2);
    end;
   if (not bUnicode) then
    begin
     case FDataType of
      bftWideChar,bftWideVarchar: Cast(bftChar);
      bftWideClob:                Cast(bftClob);
     end;
    end;
  end;
end; // ConvertWideStringToAnsiStringIfNotUnicode




////////////////////////////////////////////////////////////////////////////////
//
// TACRSQLParam
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// set name
//------------------------------------------------------------------------------
procedure TACRSQLParam.SetName(NewName: WideString);
begin
 ACRClearString(FName);
 FName := NewName;
 FNameCRC := GetTableNameCRC(NewName,True);
end; // SetName


//------------------------------------------------------------------------------
// LoadFromStream
//------------------------------------------------------------------------------
procedure TACRSQLParam.LoadFromStream(Stream: TStream);
begin
  ACRClearString(FName);
  LoadWideStringFromStream(FName,Stream,11191);
  FNameCRC := GetTableNameCRC(FName);
  inherited LoadFromStream(Stream);
end; // LoadFromStream


//------------------------------------------------------------------------------
// SaveToStream
//------------------------------------------------------------------------------
procedure TACRSQLParam.SaveToStream(Stream: TStream);
begin
  SaveWideStringToStream(FName,Stream,11193);
  inherited SaveToStream(Stream);
end; // SaveToStream


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TACRSQLParam.Assign(
                      Source:       TACRVariant;
                      CopyDataFlag: Boolean;
                      AssignName:      Boolean
                              );
begin
  inherited Assign(Source,CopyDataFlag);
  if (AssignName and (Source is TACRSQLParam)) then
    SetName(TACRSQLParam(Source).Name);
end; // Assign


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TACRSQLParam.Destroy;
begin
  ACRClearString(FName);
  inherited;
end; // Destroy



////////////////////////////////////////////////////////////////////////////////
//
// TACRSQLParams
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// return Count
//------------------------------------------------------------------------------
function TACRSQLParams.GetCount: Integer;
begin
  Result := FParamList.Count;
end;//GetCount


//------------------------------------------------------------------------------
// GetValue
//------------------------------------------------------------------------------
function TACRSQLParams.GetValue(Index: Integer): TACRSQLParam;
begin
  Result := TACRSQLParam(FParamList[Index]);
end;//GetValue


//------------------------------------------------------------------------------
// SetValue
//------------------------------------------------------------------------------
procedure TACRSQLParams.SetValue(Index: Integer; Value: TACRSQLParam);
begin
  TACRSQLParam(FParamList[Index]).Free;
  FParamList[Index] := Value;
end;//SetValue

//------------------------------------------------------------------------------
// SetValue
//------------------------------------------------------------------------------
procedure TACRSQLParams.SetAsVariant(Value: Variant);
var i,l,h,qty: Integer;
    v:         TACRSQLParam;
begin
  if (VarIsNull(Value)) then
  begin
   Clear;
   Exit;
  end;
  if  (VarType(Value) and varArray) <> 0 then
  begin
    l := VarArrayLowBound(Value,1);
    h := VarArrayHighBound(Value,1);
    qty := h-l+1;
    while (FParamList.Count < qty) do
    begin
     v := TACRSQLParam.Create;
     FParamList.Add(v);
    end;
    for i := l to h do
    begin
     v := FParamList[i-l];
     v.AsVariant := Value[i];
    end;
  end
  else
  begin
   if (FParamList.Count = 0) then
   begin
     v := TACRSQLParam.Create;
     FParamList.Add(v);
   end
   else
    v := FParamList[0];
   v.AsVariant := Value;
  end;
end;//SetAsVariant


//------------------------------------------------------------------------------
// get all parameters as variant
//------------------------------------------------------------------------------
function TACRSQLParams.GetAsVariant: Variant;
var i: Integer;
begin
  if (FParamList.Count = 0) then
    Result := Null
  else
  if (FParamList.Count = 1) then
    Result := TACRSQLParam(FParamList[0]).AsVariant
  else
  begin
    Result := VarArrayCreate([0, FParamList.Count-1], varVariant);
    for i := 0 to FParamList.Count-1 do
      Result[i] := TACRSQLParam(FParamList[i]).AsVariant;
  end;
end; // GetAsVariant


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TACRSQLParams.Create;
begin
  FParamList := TACRList.Create;
end;//Create


//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TACRSQLParams.Destroy;
begin
  Clear;
  FParamList.Free;
  inherited;
end;//Destroy


//------------------------------------------------------------------------------
// Clear
//------------------------------------------------------------------------------
procedure TACRSQLParams.Clear;
var i: Integer;
begin
  for i := 0 to Count-1 do
   try
    TACRSQLParam(FParamList[i]).Free;
   except
   end;
  FParamList.Clear;
end; // Clear


//------------------------------------------------------------------------------
// AddCreated
//------------------------------------------------------------------------------
function TACRSQLParams.AddCreated: TACRSQLParam;
begin
  Result := TACRSQLParam.Create;
  FParamList.Add(Result);
end;//AddCreated


//------------------------------------------------------------------------------
// assign
//------------------------------------------------------------------------------
procedure TACRSQLParams.Assign(Source: TACRSQLParams);
var i: Integer;
begin
  if (Source = nil) then
   raise EACRException.Create(12092,ErrorLNilPointer);
  if (not (Source is TACRSQLParams)) then
   raise EACRException.Create(12093,ErrorLInvalidSourceObject,[IntToHex(Integer(Source),8),Source.ClassName]);
  Clear;
  for i := 0 to Source.Count - 1 do
    AddCreated.Assign(Source.Items[i]);
end; // Assign


//------------------------------------------------------------------------------
// GetParamByName
//------------------------------------------------------------------------------
function TACRSQLParams.GetParamByName(Name: WideString): TACRSQLParam;
var i:    Integer;
    crc:  Cardinal;
begin
  Result := nil;
  crc := GetTableNameCRC(Name);
  for i := 0 to Count-1 do
   if (Items[i].FNameCRC = crc) then
    begin
     Result := Items[i];
     Break;
    end;
end;//GetParamByName


//------------------------------------------------------------------------------
// return index of parameter or -1 if not found
//------------------------------------------------------------------------------
function TACRSQLParams.GetParamIndexByName(Name: WideString): Integer;
var i:    Integer;
    crc:  Cardinal;
begin
  Result := -1;
  crc := GetTableNameCRC(Name);
  for i := 0 to Count-1 do
   if (Items[i].FNameCRC = crc) then
    begin
     Result := i;
     Break;
    end;
end; // GetParamIndexByName


//------------------------------------------------------------------------------
// LoadFromStream
//------------------------------------------------------------------------------
procedure TACRSQLParams.LoadFromStream(Stream: TACRStream);
var num,i: Integer;
begin
  LoadDataFromStream(num,SizeOf(num),Stream,11188);
  Clear();
  for i := 0 to num - 1 do
    AddCreated.LoadFromStream(Stream);
end; // LoadFromStream


//------------------------------------------------------------------------------
// SaveToStream
//------------------------------------------------------------------------------
procedure TACRSQLParams.SaveToStream(Stream: TACRStream);
var num,i: Integer;
begin
  num := Count;
  SaveDataToStream(num,SizeOf(num),Stream,11189);
  for i := 0 to num - 1 do
    Items[i].SaveToStream(Stream);
end; // SaveToStream


//------------------------------------------------------------------------------
// return hash value of all parameters
//------------------------------------------------------------------------------
function TACRSQLParams.GetHashValue: TACRRecordHashValue;
var i,n:             Integer;
    ParamHashValues: array of TACRRecordHashValue;
begin
 Result := ACR_RECORD_HASH_BASE;
 n := FParamList.Count;
 if (n > 0) then
  begin
   SetLength(ParamHashValues,n);
   try
     for i := 0 to n-1 do
      begin
        ParamHashValues[i] := TACRSQLParam(FParamList.Items[i]).GetBinaryHash;
        Result := ACRAddCRC(Result,ParamHashValues[i],i);
      end;
   finally
     ParamHashValues := nil;
   end;
  end;
end; // GetHashValue


//------------------------------------------------------------------------------
// return -1 if not found or index of the parameter stored in FParamList
//------------------------------------------------------------------------------
function TACRSQLParams.FindByNameCRC(NameCRC: Cardinal): Integer;
var i: Integer;
begin
  Result := -1;
  for i := 0 to FParamList.Count - 1 do
   if (TACRSQLParam(FParamList.Items[i]).NameCRC = NameCRC) then
    begin
     Result := i;
     Exit;
    end;
end; // FindByNameCRC


//------------------------------------------------------------------------------
// Return Common DataType for 2 types, or ftUnknown
//------------------------------------------------------------------------------
function GetCommonDataType(a,b: TACRBaseFieldType): TACRBaseFieldType;
begin
{  if (a = b) then
    begin
      Result := a;
      Exit;
    end;
}
  Result := bftUnknown;
  case a of
    bftChar:
      case b of
        bftChar:             Result := bftChar;
        bftWideChar:         Result := bftWideChar;
        bftVarchar:          Result := bftVarchar;
        bftWideVarchar:      Result := bftWideVarchar;
        bftClob:             Result := bftChar;
        bftWideClob:         Result := bftWideChar;

        bftSignedInt8:       Result := bftChar;
        bftSignedInt16:      Result := bftChar;
        bftSignedInt32:      Result := bftChar;
        bftSignedInt64:      Result := bftChar;
        bftUnsignedInt8:     Result := bftChar;
        bftUnsignedInt16:    Result := bftChar;
        bftUnsignedInt32:    Result := bftChar;

        bftSingle:           Result := bftChar;
        bftDouble:           Result := bftChar;
        bftExtended:         Result := bftChar;

        bftDate:             Result := bftDate;
        bftTime:             Result := bftTime;
        bftDateTime:         Result := bftDateTime;

        bftLogical:          Result := bftChar;
        bftCurrency:         Result := bftChar;

      end;
    bftWideChar:
      case b of
        bftChar:             Result := bftWideChar;
        bftWideChar:         Result := bftWideChar;
        bftVarchar:          Result := bftWideChar;
        bftWideVarchar:      Result := bftWideVarchar;
        bftClob:             Result := bftChar;
        bftWideClob:         Result := bftWideChar;

        bftSignedInt8:       Result := bftWideChar;
        bftSignedInt16:      Result := bftWideChar;
        bftSignedInt32:      Result := bftWideChar;
        bftSignedInt64:      Result := bftWideChar;
        bftUnsignedInt8:     Result := bftWideChar;
        bftUnsignedInt16:    Result := bftWideChar;
        bftUnsignedInt32:    Result := bftWideChar;

        bftSingle:           Result := bftWideChar;
        bftDouble:           Result := bftWideChar;
        bftExtended:         Result := bftWideChar;

        bftDate:             Result := bftDate;
        bftTime:             Result := bftTime;
        bftDateTime:         Result := bftDateTime;

        bftLogical:          Result := bftWideChar;
        bftCurrency:         Result := bftWideChar;

      end;
    bftVarchar:
      case b of
        bftChar:             Result := bftVarchar;
        bftWideChar:         Result := bftWideChar;
        bftVarchar:          Result := bftVarchar;
        bftWideVarchar:      Result := bftWideVarchar;
        bftClob:             Result := bftChar;
        bftWideClob:         Result := bftWideChar;

        bftSignedInt8:       Result := bftVarchar;
        bftSignedInt16:      Result := bftVarchar;
        bftSignedInt32:      Result := bftVarchar;
        bftSignedInt64:      Result := bftVarchar;
        bftUnsignedInt8:     Result := bftVarchar;
        bftUnsignedInt16:    Result := bftVarchar;
        bftUnsignedInt32:    Result := bftVarchar;

        bftSingle:           Result := bftVarchar;
        bftDouble:           Result := bftVarchar;
        bftExtended:         Result := bftVarchar;

        bftDate:             Result := bftDate;
        bftTime:             Result := bftTime;
        bftDateTime:         Result := bftDateTime;

        bftLogical:          Result := bftVarchar;
        bftCurrency:         Result := bftVarchar;

      end;
    bftWideVarchar:
      case b of
        bftChar:             Result := bftWideVarchar;
        bftWideChar:         Result := bftWideVarchar;
        bftVarchar:          Result := bftWideVarchar;
        bftWideVarchar:      Result := bftWideVarchar;
        bftClob:             Result := bftChar;
        bftWideClob:         Result := bftWideChar;

        bftSignedInt8:       Result := bftWideVarchar;
        bftSignedInt16:      Result := bftWideVarchar;
        bftSignedInt32:      Result := bftWideVarchar;
        bftSignedInt64:      Result := bftWideVarchar;
        bftUnsignedInt8:     Result := bftWideVarchar;
        bftUnsignedInt16:    Result := bftWideVarchar;
        bftUnsignedInt32:    Result := bftWideVarchar;

        bftSingle:           Result := bftWideVarchar;
        bftDouble:           Result := bftWideVarchar;
        bftExtended:         Result := bftWideVarchar;

        bftDate:             Result := bftDate;
        bftTime:             Result := bftTime;
        bftDateTime:         Result := bftDateTime;

        bftLogical:          Result := bftWideVarchar;
        bftCurrency:         Result := bftWideVarchar;

      end;
    bftClob:
      case b of
        bftChar:             Result := bftChar;
        bftWideChar:         Result := bftWideChar;
        bftVarchar:          Result := bftVarchar;
        bftWideVarchar:      Result := bftWideVarchar;
        bftClob:             Result := bftClob;
        bftWideClob:         Result := bftWideClob;
       else
        Result := bftUnknown;
      end;
    bftWideClob:
      case b of
        bftChar:             Result := bftWideChar;
        bftWideChar:         Result := bftWideChar;
        bftVarchar:          Result := bftWideVarchar;
        bftWideVarchar:      Result := bftWideVarchar;
        bftClob:             Result := bftWideClob;
        bftWideClob:         Result := bftWideClob;
       else
        Result := bftUnknown;
      end;
    bftSignedInt8:
      case b of
        bftChar:             Result := bftChar;
        bftWideChar:         Result := bftWideChar;
        bftVarchar:          Result := bftVarchar;
        bftWideVarchar:      Result := bftWideVarchar;

        bftSignedInt8:       Result := bftSignedInt8;
        bftSignedInt16:      Result := bftSignedInt16;
        bftSignedInt32:      Result := bftSignedInt32;
        bftSignedInt64:      Result := bftSignedInt64;
        bftUnsignedInt8:     Result := bftSignedInt16;
        bftUnsignedInt16:    Result := bftUnsignedInt16;
        bftUnsignedInt32:    Result := bftUnsignedInt32;

        bftSingle:           Result := bftSingle;
        bftDouble:           Result := bftDouble;
        bftExtended:         Result := bftExtended;

        bftDate:             Result := bftDate;
        bftTime:             Result := bftTime;
        bftDateTime:         Result := bftDateTime;

        bftLogical:          Result := bftSignedInt8;
        bftCurrency:         Result := bftCurrency;

      end;
    bftSignedInt16:
      case b of
        bftChar:             Result := bftChar;
        bftWideChar:         Result := bftWideChar;
        bftVarchar:          Result := bftVarchar;
        bftWideVarchar:      Result := bftWideVarchar;

        bftSignedInt8:       Result := bftSignedInt16;
        bftSignedInt16:      Result := bftSignedInt16;
        bftSignedInt32:      Result := bftSignedInt32;
        bftSignedInt64:      Result := bftSignedInt64;
        bftUnsignedInt8:     Result := bftSignedInt16;
        bftUnsignedInt16:    Result := bftUnsignedInt16;
        bftUnsignedInt32:    Result := bftUnsignedInt32;

        bftSingle:           Result := bftSingle;
        bftDouble:           Result := bftDouble;
        bftExtended:         Result := bftExtended;

        bftDate:             Result := bftDate;
        bftTime:             Result := bftTime;
        bftDateTime:         Result := bftDateTime;

        bftLogical:          Result := bftSignedInt16;
        bftCurrency:         Result := bftCurrency;

      end;
    bftSignedInt32:
      case b of
        bftChar:             Result := bftChar;
        bftWideChar:         Result := bftWideChar;
        bftVarchar:          Result := bftVarchar;
        bftWideVarchar:      Result := bftWideVarchar;

        bftSignedInt8:       Result := bftSignedInt32;
        bftSignedInt16:      Result := bftSignedInt32;
        bftSignedInt32:      Result := bftSignedInt32;
        bftSignedInt64:      Result := bftSignedInt64;
        bftUnsignedInt8:     Result := bftSignedInt32;
        bftUnsignedInt16:    Result := bftSignedInt32;
        bftUnsignedInt32:    Result := bftSignedInt64;

        bftSingle:           Result := bftSingle;
        bftDouble:           Result := bftDouble;
        bftExtended:         Result := bftExtended;

        bftDate:             Result := bftDate;
        bftTime:             Result := bftTime;
        bftDateTime:         Result := bftDateTime;

        bftLogical:          Result := bftSignedInt32;
        bftCurrency:         Result := bftCurrency;

      end;
    bftSignedInt64:
      case b of
        bftChar:             Result := bftChar;
        bftWideChar:         Result := bftWideChar;
        bftVarchar:          Result := bftVarchar;
        bftWideVarchar:      Result := bftWideVarchar;

        bftSignedInt8:       Result := bftSignedInt64;
        bftSignedInt16:      Result := bftSignedInt64;
        bftSignedInt32:      Result := bftSignedInt64;
        bftSignedInt64:      Result := bftSignedInt64;
        bftUnsignedInt8:     Result := bftSignedInt64;
        bftUnsignedInt16:    Result := bftSignedInt64;
        bftUnsignedInt32:    Result := bftSignedInt64;

        bftSingle:           Result := bftSingle;
        bftDouble:           Result := bftDouble;
        bftExtended:         Result := bftExtended;

        bftDate:             Result := bftDate;
        bftTime:             Result := bftTime;
        bftDateTime:         Result := bftDateTime;

        bftLogical:          Result := bftSignedInt64;
        bftCurrency:         Result := bftCurrency;

      end;
    bftUnsignedInt8:
      case b of
        bftChar:             Result := bftChar;
        bftWideChar:         Result := bftWideChar;
        bftVarchar:          Result := bftVarchar;
        bftWideVarchar:      Result := bftWideVarchar;

        bftSignedInt8:       Result := bftSignedInt16;
        bftSignedInt16:      Result := bftSignedInt16;
        bftSignedInt32:      Result := bftSignedInt32;
        bftSignedInt64:      Result := bftSignedInt64;
        bftUnsignedInt8:     Result := bftUnsignedInt8;
        bftUnsignedInt16:    Result := bftUnsignedInt16;
        bftUnsignedInt32:    Result := bftUnsignedInt32;

        bftSingle:           Result := bftSingle;
        bftDouble:           Result := bftDouble;
        bftExtended:         Result := bftExtended;

        bftDate:             Result := bftDate;
        bftTime:             Result := bftTime;
        bftDateTime:         Result := bftDateTime;

        bftLogical:          Result := bftUnsignedInt8;
        bftCurrency:         Result := bftCurrency;

      end;
    bftUnsignedInt16:
      case b of
        bftChar:             Result := bftChar;
        bftWideChar:         Result := bftWideChar;
        bftVarchar:          Result := bftVarchar;
        bftWideVarchar:      Result := bftWideVarchar;

        bftSignedInt8:       Result := bftSignedInt32;
        bftSignedInt16:      Result := bftSignedInt32;
        bftSignedInt32:      Result := bftSignedInt32;
        bftSignedInt64:      Result := bftSignedInt64;
        bftUnsignedInt8:     Result := bftUnsignedInt16;
        bftUnsignedInt16:    Result := bftUnsignedInt16;
        bftUnsignedInt32:    Result := bftUnsignedInt32;

        bftSingle:           Result := bftSingle;
        bftDouble:           Result := bftDouble;
        bftExtended:         Result := bftExtended;

        bftDate:             Result := bftDate;
        bftTime:             Result := bftTime;
        bftDateTime:         Result := bftDateTime;

        bftLogical:          Result := bftUnsignedInt16;
        bftCurrency:         Result := bftCurrency;

      end;
    bftUnsignedInt32:
      case b of
        bftChar:             Result := bftChar;
        bftWideChar:         Result := bftWideChar;
        bftVarchar:          Result := bftVarchar;
        bftWideVarchar:      Result := bftWideVarchar;

        bftSignedInt8:       Result := bftSignedInt64;
        bftSignedInt16:      Result := bftSignedInt64;
        bftSignedInt32:      Result := bftSignedInt64;
        bftSignedInt64:      Result := bftSignedInt64;
        bftUnsignedInt8:     Result := bftUnsignedInt32;
        bftUnsignedInt16:    Result := bftUnsignedInt32;
        bftUnsignedInt32:    Result := bftUnsignedInt32;

        bftSingle:           Result := bftSingle;
        bftDouble:           Result := bftDouble;
        bftExtended:         Result := bftExtended;

        bftDate:             Result := bftDate;
        bftTime:             Result := bftTime;
        bftDateTime:         Result := bftDateTime;

        bftLogical:          Result := bftUnsignedInt32;
        bftCurrency:         Result := bftCurrency;

      end;

    bftSingle:
      case b of
        bftChar:             Result := bftChar;
        bftWideChar:         Result := bftWideChar;
        bftVarchar:          Result := bftVarchar;
        bftWideVarchar:      Result := bftWideVarchar;

        bftSignedInt8:       Result := bftSingle;
        bftSignedInt16:      Result := bftSingle;
        bftSignedInt32:      Result := bftSingle;
        bftSignedInt64:      Result := bftSingle;
        bftUnsignedInt8:     Result := bftSingle;
        bftUnsignedInt16:    Result := bftSingle;
        bftUnsignedInt32:    Result := bftSingle;

        bftSingle:           Result := bftSingle;
        bftDouble:           Result := bftDouble;
        bftExtended:         Result := bftExtended;

        bftDate:             Result := bftDate;
        bftTime:             Result := bftTime;
        bftDateTime:         Result := bftDateTime;

        bftLogical:          Result := bftSingle;
        bftCurrency:         Result := bftCurrency;

      end;
    bftDouble:
      case b of
        bftChar:             Result := bftChar;
        bftWideChar:         Result := bftWideChar;
        bftVarchar:          Result := bftVarchar;
        bftWideVarchar:      Result := bftWideVarchar;

        bftSignedInt8:       Result := bftDouble;
        bftSignedInt16:      Result := bftDouble;
        bftSignedInt32:      Result := bftDouble;
        bftSignedInt64:      Result := bftDouble;
        bftUnsignedInt8:     Result := bftDouble;
        bftUnsignedInt16:    Result := bftDouble;
        bftUnsignedInt32:    Result := bftDouble;

        bftSingle:           Result := bftDouble;
        bftDouble:           Result := bftDouble;
        bftExtended:         Result := bftExtended;

        bftDate:             Result := bftDate;
        bftTime:             Result := bftTime;
        bftDateTime:         Result := bftDateTime;

        bftLogical:          Result := bftDouble;
        bftCurrency:         Result := bftCurrency;

      end;
    bftExtended:
      case b of
        bftChar:             Result := bftChar;
        bftWideChar:         Result := bftWideChar;
        bftVarchar:          Result := bftVarchar;
        bftWideVarchar:      Result := bftWideVarchar;

        bftSignedInt8:       Result := bftExtended;
        bftSignedInt16:      Result := bftExtended;
        bftSignedInt32:      Result := bftExtended;
        bftSignedInt64:      Result := bftExtended;
        bftUnsignedInt8:     Result := bftExtended;
        bftUnsignedInt16:    Result := bftExtended;
        bftUnsignedInt32:    Result := bftExtended;

        bftSingle:           Result := bftExtended;
        bftDouble:           Result := bftExtended;
        bftExtended:         Result := bftExtended;

        bftDate:             Result := bftDate;
        bftTime:             Result := bftTime;
        bftDateTime:         Result := bftDateTime;

        bftLogical:          Result := bftExtended;
        bftCurrency:         Result := bftCurrency;

      end;

    bftDate:
      case b of
        bftChar:             Result := bftDate;
        bftWideChar:         Result := bftDate;
        bftVarchar:          Result := bftDate;
        bftWideVarchar:      Result := bftDate;

        bftSignedInt8:       Result := bftDate;
        bftSignedInt16:      Result := bftDate;
        bftSignedInt32:      Result := bftDate;
        bftSignedInt64:      Result := bftDate;
        bftUnsignedInt8:     Result := bftDate;
        bftUnsignedInt16:    Result := bftDate;
        bftUnsignedInt32:    Result := bftDate;

        bftSingle:           Result := bftDate;
        bftDouble:           Result := bftDate;
        bftExtended:         Result := bftDate;

        bftDate:             Result := bftDate;
        bftTime:             Result := bftDateTime;
        bftDateTime:         Result := bftDate;
//        bftDateTime:         Result := bftDateTime;

        bftLogical:          Result := bftUnknown;
        bftCurrency:         Result := bftUnknown;

      end;
    bftTime:
      case b of
        bftChar:             Result := bftTime;
        bftWideChar:         Result := bftTime;
        bftVarchar:          Result := bftTime;
        bftWideVarchar:      Result := bftTime;

        bftSignedInt8:       Result := bftTime;
        bftSignedInt16:      Result := bftTime;
        bftSignedInt32:      Result := bftTime;
        bftSignedInt64:      Result := bftTime;
        bftUnsignedInt8:     Result := bftTime;
        bftUnsignedInt16:    Result := bftTime;
        bftUnsignedInt32:    Result := bftTime;

        bftSingle:           Result := bftTime;
        bftDouble:           Result := bftTime;
        bftExtended:         Result := bftTime;

        bftDate:             Result := bftDateTime;
        bftTime:             Result := bftTime;
        bftDateTime:         Result := bftTime;
//        bftDateTime:         Result := bftDateTime;

        bftLogical:          Result := bftUnknown;
        bftCurrency:         Result := bftUnknown;

      end;
    bftDateTime:
      case b of
        bftChar:             Result := bftDateTime;
        bftWideChar:         Result := bftDateTime;
        bftVarchar:          Result := bftDateTime;
        bftWideVarchar:      Result := bftDateTime;

        bftSignedInt8:       Result := bftDateTime;
        bftSignedInt16:      Result := bftDateTime;
        bftSignedInt32:      Result := bftDateTime;
        bftSignedInt64:      Result := bftDateTime;
        bftUnsignedInt8:     Result := bftDateTime;
        bftUnsignedInt16:    Result := bftDateTime;
        bftUnsignedInt32:    Result := bftDateTime;

        bftSingle:           Result := bftDateTime;
        bftDouble:           Result := bftDateTime;
        bftExtended:         Result := bftDateTime;

//        bftDate:             Result := bftDateTime;
//        bftTime:             Result := bftDateTime;
        bftDate:             Result := bftDate;
        bftTime:             Result := bftTime;
        bftDateTime:         Result := bftDateTime;

        bftLogical:          Result := bftUnknown;
        bftCurrency:         Result := bftUnknown;

      end;

    bftLogical:
      case b of
        bftChar:             Result := bftChar;
        bftWideChar:         Result := bftWideChar;
        bftVarchar:          Result := bftVarchar;
        bftWideVarchar:      Result := bftWideVarchar;

        bftSignedInt8:       Result := bftSignedInt8;
        bftSignedInt16:      Result := bftSignedInt16;
        bftSignedInt32:      Result := bftSignedInt32;
        bftSignedInt64:      Result := bftSignedInt64;
        bftUnsignedInt8:     Result := bftUnsignedInt8;
        bftUnsignedInt16:    Result := bftUnsignedInt16;
        bftUnsignedInt32:    Result := bftUnsignedInt32;

        bftSingle:           Result := bftSingle;
        bftDouble:           Result := bftDouble;
        bftExtended:         Result := bftExtended;

        bftDate:             Result := bftUnknown;
        bftTime:             Result := bftUnknown;
        bftDateTime:         Result := bftUnknown;

        bftLogical:          Result := bftLogical;
        bftCurrency:         Result := bftUnknown;

      end;
    bftCurrency:
      case b of
        bftChar:             Result := bftChar;
        bftWideChar:         Result := bftWideChar;
        bftVarchar:          Result := bftVarchar;
        bftWideVarchar:      Result := bftWideVarchar;

        bftSignedInt8:       Result := bftSignedInt8;
        bftSignedInt16:      Result := bftSignedInt16;
        bftSignedInt32:      Result := bftSignedInt32;
        bftSignedInt64:      Result := bftSignedInt64;
        bftUnsignedInt8:     Result := bftUnsignedInt8;
        bftUnsignedInt16:    Result := bftUnsignedInt16;
        bftUnsignedInt32:    Result := bftUnsignedInt32;

        bftSingle:           Result := bftSingle;
        bftDouble:           Result := bftDouble;
        bftExtended:         Result := bftExtended;

        bftDate:             Result := bftUnknown;
        bftTime:             Result := bftUnknown;
        bftDateTime:         Result := bftUnknown;

        bftLogical:          Result := bftUnknown;
        bftCurrency:         Result := bftCurrency;

      end;

  end;
end;//GetCommonDataType


//------------------------------------------------------------------------------
// Return Common DataType for 2 types, or ftUnknown
//------------------------------------------------------------------------------
function GetCommonDataType(a,b: TACRAdvancedFieldType): TACRAdvancedFieldType;
var
   b1,b2, CommonBft: TACRBaseFieldType;
begin
  b1 := AdvancedFieldTypeToBaseFieldType(a);
  b2 := AdvancedFieldTypeToBaseFieldType(b);
  CommonBft := GetCommonDataType(b1, b2);

  if (CommonBft = b1) then
    Result := a
  else if (CommonBft = b2) then
    Result := b
  else
    Result := BaseFieldTypeToAdvancedFieldType(CommonBft);
    
end;//GetCommonDataType

//------------------------------------------------------------------------------
// Allocate new buffer and convert data to it
//------------------------------------------------------------------------------
function CastToNewBuffer(
                          const Buffer;
                          const DataType: TACRBaseFieldType;
                          const NewDataType: TACRBaseFieldType
                        ): PAnsiChar;
var
   Size: Integer;
begin
  Result := CastToNewBuffer(Buffer, DataType, NewDataType, Size);
end;//CastToNewBuffer


//------------------------------------------------------------------------------
// Allocate new buffer and convert data to it
//------------------------------------------------------------------------------
function CastToNewBuffer(
                          const Buffer;
                          const DataType: TACRBaseFieldType;
                          const NewDataType: TACRBaseFieldType;
                          out NewDataSize: Integer
                        ): PAnsiChar;
var

  s: AnsiString;
  ws: WideString;
  si8:  Shortint;
  si16: Smallint;
  si32: Integer;
  si64: Int64;
  ui8:  Byte;
  ui16: Word;
  ui32: Cardinal;
  sng:  Single;
  sng1: Single;
  dbl:  Double;
  dbl1: Double;
  ext:  Extended;
  ext1: Extended;
  dt:   TACRDateTime;
  d:    TACRDate;
  t:    TACRTime;
  b:    TACRLogical;
  cur:  TACRCurrency;
  cur1: TACRCurrency;

  oldSeparator: Char;

begin
  Result := nil;
  try
    case DataType of
      bftChar,
      bftVarchar:  //  from AnsiString
        case NewDataType of
          bftChar,
          bftVarchar:
            begin
              AllocMemAndSetData(bftVarchar, Buffer, Result, NewDataSize);
            end;
          bftWideChar,
          bftWideVarchar:
            begin
              ws := WideString(PAnsiChar(Buffer));
              AllocMemAndSetData(bftWideVarchar, ws, Result, NewDataSize);
            end;
          bftSignedInt8:
            begin
              si8 := StrToInt(PAnsiChar(Buffer));
              AllocMemAndSetData(bftSignedInt8, si8, Result, NewDataSize);
            end;
          bftSignedInt16:
            begin
              si16 := StrToInt(PAnsiChar(Buffer));
              AllocMemAndSetData(bftSignedInt16, si16, Result, NewDataSize);
            end;
          bftSignedInt32:
            begin
              si32 := StrToInt(PAnsiChar(Buffer));
              AllocMemAndSetData(bftSignedInt32, si32, Result, NewDataSize);
            end;
          bftSignedInt64:
            begin
              si64 := StrToInt64(PAnsiChar(Buffer));
              AllocMemAndSetData(bftSignedInt64, si64, Result, NewDataSize);
            end;
          bftUnsignedInt8:
            begin
              ui8 := StrToInt(PAnsiChar(Buffer));
              AllocMemAndSetData(bftUnsignedInt8, ui8, Result, NewDataSize);
            end;
          bftUnsignedInt16:
            begin
              ui16 := StrToInt(PAnsiChar(Buffer));
              AllocMemAndSetData(bftUnsignedInt16, ui16, Result, NewDataSize);
            end;
          bftUnsignedInt32:
            begin
              ui32 := StrToInt(PAnsiChar(Buffer));
              AllocMemAndSetData(bftUnsignedInt32, ui32, Result, NewDataSize);
            end;

          bftSingle:
            begin
{$IFDEF D17H}
              oldSeparator := FormatSettings.DecimalSeparator;
              FormatSettings.DecimalSeparator := '.';
              try
                sng := StrToFloat(PAnsiChar(Buffer));
              finally
                FormatSettings.DecimalSeparator := oldSeparator;
              end;
{$ELSE}
              oldSeparator := DecimalSeparator;
              DecimalSeparator := '.';
              try
                sng := StrToFloat(PAnsiChar(Buffer));
              finally
                DecimalSeparator := oldSeparator;
              end;
{$ENDIF}
              AllocMemAndSetData(bftSingle, sng, Result, NewDataSize);
            end;
          bftDouble:
            begin
{$IFDEF D17H}
              oldSeparator := FormatSettings.DecimalSeparator;
              FormatSettings.DecimalSeparator := '.';
              try
                dbl := StrToFloat(PAnsiChar(Buffer));
              finally
                FormatSettings.DecimalSeparator := oldSeparator;
              end;
{$ELSE}
              oldSeparator := DecimalSeparator;
              DecimalSeparator := '.';
              try
                dbl := StrToFloat(PAnsiChar(Buffer));
              finally
                DecimalSeparator := oldSeparator;
              end;
{$ENDIF}
              AllocMemAndSetData(bftDouble, dbl, Result, NewDataSize);
            end;
          bftExtended:
            begin
{$IFDEF D17H}
              oldSeparator := FormatSettings.DecimalSeparator;
              FormatSettings.DecimalSeparator := '.';
              try
                ext := StrToFloat(PAnsiChar(Buffer));
              finally
                FormatSettings.DecimalSeparator := oldSeparator;
              end;
{$ELSE}
              oldSeparator := DecimalSeparator;
              DecimalSeparator := '.';
              try
                ext := StrToFloat(PAnsiChar(Buffer));
              finally
                DecimalSeparator := oldSeparator;
              end;
{$ENDIF}
              AllocMemAndSetData(bftExtended, ext, Result, NewDataSize);
            end;

          bftDate:
            begin
              d := DateToACRDate(StrToDate(PAnsiChar(Buffer)));
              AllocMemAndSetData(bftDate, d, Result, NewDataSize);
            end;
          bftTime:
            begin
              t := TimeToACRTime(StrToTime(PAnsiChar(Buffer)));
              AllocMemAndSetData(bftTime, t, Result, NewDataSize);
            end;
          bftDateTime:
            begin
              dt := DateTimeToACRDateTime(StrToDateTime(PAnsiChar(Buffer)));
              AllocMemAndSetData(bftDateTime, dt, Result, NewDataSize);
            end;

          bftLogical:
            begin
              s := AnsiUpperCase(PAnsiChar(Buffer));
              b := (s = '1') or (s = 'TRUE');
              AllocMemAndSetData(bftLogical, b, Result, NewDataSize);
            end;
          bftCurrency:
            begin
              cur := StrToCurr(PAnsiChar(Buffer));
              AllocMemAndSetData(bftCurrency, cur, Result, NewDataSize);
            end;
          bftBlob,bftClob,bftWideClob:
            begin
              AllocMemAndSetData(bftVarchar, PAnsiChar(Buffer), Result, NewDataSize);
            end;
        end;

      bftWideChar,
      bftWideVarchar:  // from WideString
        case NewDataType of
          bftChar,
          bftVarchar:
            begin
              s := AnsiString(PWideChar(Buffer));
              AllocMemAndSetData(bftVarchar, s, Result, NewDataSize);
            end;
          bftWideChar,
          bftWideVarchar:
            begin
              ws := WideString(PWideChar(Buffer));
              AllocMemAndSetData(bftWideVarchar, ws, Result, NewDataSize);
            end;
          bftSignedInt8:
            begin
              si8 := StrToInt(PWideChar(Buffer));
              AllocMemAndSetData(bftSignedInt8, si8, Result, NewDataSize);
            end;
          bftSignedInt16:
            begin
              si16 := StrToInt(PWideChar(Buffer));
              AllocMemAndSetData(bftSignedInt16, si16, Result, NewDataSize);
            end;
          bftSignedInt32:
            begin
              si32 := StrToInt(PWideChar(Buffer));
              AllocMemAndSetData(bftSignedInt32, si32, Result, NewDataSize);
            end;
          bftSignedInt64:
            begin
              si64 := StrToInt64(PWideChar(Buffer));
              AllocMemAndSetData(bftSignedInt64, si64, Result, NewDataSize);
            end;
          bftUnsignedInt8:
            begin
              ui8 := StrToInt(PWideChar(Buffer));
              AllocMemAndSetData(bftUnsignedInt8, ui8, Result, NewDataSize);
            end;
          bftUnsignedInt16:
            begin
              ui16 := StrToInt(PWideChar(Buffer));
              AllocMemAndSetData(bftUnsignedInt16, ui16, Result, NewDataSize);
            end;
          bftUnsignedInt32:
            begin
              ui32 := StrToInt(PWideChar(Buffer));
              AllocMemAndSetData(bftUnsignedInt32, ui32, Result, NewDataSize);
            end;

          bftSingle:
            begin
{$IFDEF D17H}
              oldSeparator := FormatSettings.DecimalSeparator;
              FormatSettings.DecimalSeparator := '.';
              try
                sng := StrToFloat(PWideChar(Buffer));
              finally
                FormatSettings.DecimalSeparator := oldSeparator;
              end;
{$ELSE}
              oldSeparator := DecimalSeparator;
              DecimalSeparator := '.';
              try
                sng := StrToFloat(PWideChar(Buffer));
              finally
                DecimalSeparator := oldSeparator;
              end;
{$ENDIF}
              AllocMemAndSetData(bftSingle, sng, Result, NewDataSize);
            end;
          bftDouble:
            begin
{$IFDEF D17H}
              oldSeparator := FormatSettings.DecimalSeparator;
              FormatSettings.DecimalSeparator := '.';
              try
                dbl := StrToFloat(PWideChar(Buffer));
              finally
                FormatSettings.DecimalSeparator := oldSeparator;
              end;
{$ELSE}
              oldSeparator := DecimalSeparator;
              DecimalSeparator := '.';
              try
                dbl := StrToFloat(PWideChar(Buffer));
              finally
                DecimalSeparator := oldSeparator;
              end;
{$ENDIF}
              AllocMemAndSetData(bftDouble, dbl, Result, NewDataSize);
            end;
          bftExtended:
            begin
{$IFDEF D17H}
              oldSeparator := FormatSettings.DecimalSeparator;
              FormatSettings.DecimalSeparator := '.';
              try
                ext := StrToFloat(PWideChar(Buffer));
              finally
                FormatSettings.DecimalSeparator := oldSeparator;
              end;
{$ELSE}
              oldSeparator := DecimalSeparator;
              DecimalSeparator := '.';
              try
                ext := StrToFloat(PWideChar(Buffer));
              finally
                DecimalSeparator := oldSeparator;
              end;
{$ENDIF}
              AllocMemAndSetData(bftExtended, ext, Result, NewDataSize);
            end;

          bftDate:
            begin
              d := DateToACRDate(StrToDate(PWideChar(Buffer)));
              AllocMemAndSetData(bftDate, d, Result, NewDataSize);
            end;
          bftTime:
            begin
              t := TimeToACRTime(StrToTime(PWideChar(Buffer)));
              AllocMemAndSetData(bftTime, t, Result, NewDataSize);
            end;
          bftDateTime:
            begin
              dt := DateTimeToACRDateTime(StrToDateTime(PWideChar(Buffer)));
              AllocMemAndSetData(bftDateTime, dt, Result, NewDataSize);
            end;

          bftLogical:
            begin
              s := AnsiUpperCase(PWideChar(Buffer));
              b := (s = '1') or (s = 'TRUE');
              AllocMemAndSetData(bftLogical, b, Result, NewDataSize);
            end;
          bftCurrency:
            begin
              cur := StrToCurr(PWideChar(Buffer));
              AllocMemAndSetData(bftCurrency, cur, Result, NewDataSize);
            end;
          bftBlob,bftClob,bftWideClob:
            begin
              ws := WideString(PWideChar(Buffer));
              AllocMemAndSetData(bftWideVarchar, ws, Result, NewDataSize);
            end;
        end;


      bftSignedInt8:  // from Shortint
      begin
        Move(PAnsiChar(Buffer)^,si8,1);
        case NewDataType of
          bftChar,
          bftVarchar:
            begin
              s := IntToStr(si8);
              AllocMemAndSetData(bftVarchar, s, Result, NewDataSize);
            end;
          bftWideChar,
          bftWideVarchar:
            begin
              ws := IntToStr(si8);
              AllocMemAndSetData(bftWideVarchar, ws, Result, NewDataSize);
            end;
          bftSignedInt8:
            begin
              AllocMemAndSetData(bftSignedInt8, si8, Result, NewDataSize);
            end;
          bftSignedInt16:
            begin
              si16 := si8;
              AllocMemAndSetData(bftSignedInt16, si16, Result, NewDataSize);
            end;
          bftSignedInt32:
            begin
              si32 := si8;
              AllocMemAndSetData(bftSignedInt32, si32, Result, NewDataSize);
            end;
          bftSignedInt64:
            begin
              si64 := si8;
              AllocMemAndSetData(bftSignedInt64, si64, Result, NewDataSize);
            end;
          bftUnsignedInt8:
            begin
              ui8 := Byte(si8);
              AllocMemAndSetData(bftUnsignedInt8, ui8, Result, NewDataSize);
            end;
          bftUnsignedInt16:
            begin
              ui16 := Word(si8);
              AllocMemAndSetData(bftUnsignedInt16, ui16, Result, NewDataSize);
            end;
          bftUnsignedInt32:
            begin
              ui32 := Cardinal(si8);
              AllocMemAndSetData(bftUnsignedInt32, ui32, Result, NewDataSize);
            end;

          bftSingle:
            begin
              sng := si8;
              AllocMemAndSetData(bftSingle, sng, Result, NewDataSize);
            end;
          bftDouble:
            begin
              dbl := si8;
              AllocMemAndSetData(bftDouble, dbl, Result, NewDataSize);
            end;
          bftExtended:
            begin
              ext := si8;
              AllocMemAndSetData(bftExtended, ext, Result, NewDataSize);
            end;

          bftDate:
            begin
              d := si8;
              AllocMemAndSetData(bftDate, d, Result, NewDataSize);
            end;
          bftTime:
            begin
              t := si8;
              AllocMemAndSetData(bftTime, t, Result, NewDataSize);
            end;
          bftDateTime:
            begin
              dt.Time := TIME_IS_NULL;
              dt.Date := si8;
              AllocMemAndSetData(bftDateTime, dt, Result, NewDataSize);
            end;
          bftLogical:
            begin
              b := not (si8 = 0);
              AllocMemAndSetData(bftLogical, b, Result, NewDataSize);
            end;
          bftCurrency:
            begin
              cur := si8;
              AllocMemAndSetData(bftCurrency, cur, Result, NewDataSize);
            end;
        end; // from ShortInt
      end;

      bftSignedInt16:  // from Smallint
      begin
        Move(PAnsiChar(Buffer)^,si16,2);
        case NewDataType of
          bftChar,
          bftVarchar:
            begin
              s := IntToStr(si16);
              AllocMemAndSetData(bftVarchar, s, Result, NewDataSize);
            end;
          bftWideChar,
          bftWideVarchar:
            begin
              ws := IntToStr(si16);
              AllocMemAndSetData(bftWideVarchar, ws, Result, NewDataSize);
            end;
          bftSignedInt8:
            begin
              si8 := ShortInt(si16);
              AllocMemAndSetData(bftSignedInt8, si8, Result, NewDataSize);
            end;
          bftSignedInt16:
            begin
              AllocMemAndSetData(bftSignedInt16, si16, Result, NewDataSize);
            end;
          bftSignedInt32:
            begin
              si32 := si16;
              AllocMemAndSetData(bftSignedInt32, si32, Result, NewDataSize);
            end;
          bftSignedInt64:
            begin
              si64 := si16;
              AllocMemAndSetData(bftSignedInt64, si64, Result, NewDataSize);
            end;
          bftUnsignedInt8:
            begin
              ui8 := Byte(si16);
              AllocMemAndSetData(bftUnsignedInt8, ui8, Result, NewDataSize);
            end;
          bftUnsignedInt16:
            begin
              ui16 := Word(si16);
              AllocMemAndSetData(bftUnsignedInt16, ui16, Result, NewDataSize);
            end;
          bftUnsignedInt32:
            begin
              ui32 := Cardinal(si16);
              AllocMemAndSetData(bftUnsignedInt32, ui32, Result, NewDataSize);
            end;

          bftSingle:
            begin
              sng := si16;
              AllocMemAndSetData(bftSingle, sng, Result, NewDataSize);
            end;
          bftDouble:
            begin
              dbl := si16;
              AllocMemAndSetData(bftDouble, dbl, Result, NewDataSize);
            end;
          bftExtended:
            begin
              ext := si16;
              AllocMemAndSetData(bftExtended, ext, Result, NewDataSize);
            end;

          bftDate:
            begin
              d := si16;
              AllocMemAndSetData(bftDate, d, Result, NewDataSize);
            end;
          bftTime:
            begin
              t := si16;
              AllocMemAndSetData(bftTime, t, Result, NewDataSize);
            end;
          bftDateTime:
            begin
              dt.Time := TIME_IS_NULL;
              dt.Date := si16;
              AllocMemAndSetData(bftDateTime, dt, Result, NewDataSize);
            end;
          bftLogical:
            begin
              b := not (si16 = 0);
              AllocMemAndSetData(bftLogical, b, Result, NewDataSize);
            end;
          bftCurrency:
            begin
              cur := si16;
              AllocMemAndSetData(bftCurrency, cur, Result, NewDataSize);
            end;
        end;
      end; // from SmallInt

      bftSignedInt32:  // from Integer
      begin
        Move(PAnsiChar(Buffer)^,si32,4);
        case NewDataType of
          bftChar,
          bftVarchar:
            begin
              s := IntToStr(si32);
              AllocMemAndSetData(bftVarchar, s, Result, NewDataSize);
            end;
          bftWideChar,
          bftWideVarchar:
            begin
              ws := IntToStr(si32);
              AllocMemAndSetData(bftWideVarchar, ws, Result, NewDataSize);
            end;
          bftSignedInt8:
            begin
              si8 := ShortInt(si32);
              AllocMemAndSetData(bftSignedInt8, si8, Result, NewDataSize);
            end;
          bftSignedInt16:
            begin
              si16 := SmallInt(si32);
              AllocMemAndSetData(bftSignedInt16, si16, Result, NewDataSize);
            end;
          bftSignedInt32:
            begin
              AllocMemAndSetData(bftSignedInt32, si32, Result, NewDataSize);
            end;
          bftSignedInt64:
            begin
              si64 := Int64(si32);
              AllocMemAndSetData(bftSignedInt64, si64, Result, NewDataSize);
            end;
          bftUnsignedInt8:
            begin
              ui8 := Byte(si32);
              AllocMemAndSetData(bftUnsignedInt8, ui8, Result, NewDataSize);
            end;
          bftUnsignedInt16:
            begin
              ui16 := Word(si32);
              AllocMemAndSetData(bftUnsignedInt16, ui16, Result, NewDataSize);
            end;
          bftUnsignedInt32:
            begin
              ui32 := Cardinal(si32);
              AllocMemAndSetData(bftUnsignedInt32, ui32, Result, NewDataSize);
            end;

          bftSingle:
            begin
              sng := si32;
              AllocMemAndSetData(bftSingle, sng, Result, NewDataSize);
            end;
          bftDouble:
            begin
              dbl := si32;
              AllocMemAndSetData(bftDouble, dbl, Result, NewDataSize);
            end;
          bftExtended:
            begin
              ext := si32;
              AllocMemAndSetData(bftExtended, ext, Result, NewDataSize);
            end;

          bftDate:
            begin
              d := si32;
              AllocMemAndSetData(bftDate, d, Result, NewDataSize);
            end;
          bftTime:
            begin
              t := si32;
              AllocMemAndSetData(bftTime, t, Result, NewDataSize);
            end;
          bftDateTime:
            begin
              dt.Time := TIME_IS_NULL;
              dt.Date := si32;
              AllocMemAndSetData(bftDateTime, dt, Result, NewDataSize);
            end;
          bftLogical:
            begin
              b := not (si32 = 0);
              AllocMemAndSetData(bftLogical, b, Result, NewDataSize);
            end;
          bftCurrency:
            begin
              cur := si32;
              AllocMemAndSetData(bftCurrency, cur, Result, NewDataSize);
            end;
        end;
       end; // from Integer

      bftSignedInt64:  // from int64
      begin
        Move(PAnsiChar(Buffer)^,si64,8);
        case NewDataType of
          bftChar,
          bftVarchar:
            begin
              s := IntToStr(si64);
              AllocMemAndSetData(bftVarchar, s, Result, NewDataSize);
            end;
          bftWideChar,
          bftWideVarchar:
            begin
              ws := IntToStr(si64);
              AllocMemAndSetData(bftWideVarchar, ws, Result, NewDataSize);
            end;
          bftSignedInt8:
            begin
              si8 := ShortInt(si64);
              AllocMemAndSetData(bftSignedInt8, si8, Result, NewDataSize);
            end;
          bftSignedInt16:
            begin
              si16 := smallInt(si64);
              AllocMemAndSetData(bftSignedInt16, si16, Result, NewDataSize);
            end;
          bftSignedInt32:
            begin
              si32 := Integer(si64);
              AllocMemAndSetData(bftSignedInt32, si32, Result, NewDataSize);
            end;
          bftSignedInt64:
            begin
              AllocMemAndSetData(bftSignedInt64, si64, Result, NewDataSize);
            end;
          bftUnsignedInt8:
            begin
              ui8 := Byte(si64);
              AllocMemAndSetData(bftUnsignedInt8, ui8, Result, NewDataSize);
            end;
          bftUnsignedInt16:
            begin
              ui16 := Word(si64);
              AllocMemAndSetData(bftUnsignedInt16, ui16, Result, NewDataSize);
            end;
          bftUnsignedInt32:
            begin
              ui32 := Cardinal(si64);
              AllocMemAndSetData(bftUnsignedInt32, ui32, Result, NewDataSize);
            end;

          bftSingle:
            begin
              sng := si64;
              AllocMemAndSetData(bftSingle, sng, Result, NewDataSize);
            end;
          bftDouble:
            begin
              dbl := si64;
              AllocMemAndSetData(bftDouble, dbl, Result, NewDataSize);
            end;
          bftExtended:
            begin
              ext := si64;
              AllocMemAndSetData(bftExtended, ext, Result, NewDataSize);
            end;

          bftDate:
            begin
              d := TACRDate(si64);
              AllocMemAndSetData(bftDate, d, Result, NewDataSize);
            end;
          bftTime:
            begin
              t := TACRTime(si64);
              AllocMemAndSetData(bftTime, t, Result, NewDataSize);
            end;
          bftDateTime:
            begin
              dt.Time := TIME_IS_NULL;
              dt.Date := TACRDate(si64);
              AllocMemAndSetData(bftDateTime, dt, Result, NewDataSize);
            end;
          bftLogical:
            begin
              b := not (si64 = 0);
              AllocMemAndSetData(bftLogical, b, Result, NewDataSize);
            end;
          bftCurrency:
            begin
              cur := si64;
              AllocMemAndSetData(bftCurrency, cur, Result, NewDataSize);
            end;
        end; // from Int64
      end;

      bftUnsignedInt8:  // from Byte
        case NewDataType of
          bftChar,
          bftVarchar:
            begin
              s := IntToStr(PByte(Buffer)^);
              AllocMemAndSetData(bftVarchar, s, Result, NewDataSize);
            end;
          bftWideChar,
          bftWideVarchar:
            begin
              ws := IntToStr(PByte(Buffer)^);
              AllocMemAndSetData(bftWideVarchar, ws, Result, NewDataSize);
            end;
          bftSignedInt8:
            begin
              si8 := PByte(Buffer)^;
              AllocMemAndSetData(bftSignedInt8, si8, Result, NewDataSize);
            end;
          bftSignedInt16:
            begin
              si16 := PByte(Buffer)^;
              AllocMemAndSetData(bftSignedInt16, si16, Result, NewDataSize);
            end;
          bftSignedInt32:
            begin
              si32 := PByte(Buffer)^;
              AllocMemAndSetData(bftSignedInt32, si32, Result, NewDataSize);
            end;
          bftSignedInt64:
            begin
              si64 := PByte(Buffer)^;
              AllocMemAndSetData(bftSignedInt64, si64, Result, NewDataSize);
            end;
          bftUnsignedInt8:
            begin
              ui8 := PByte(Buffer)^;
              AllocMemAndSetData(bftUnsignedInt8, ui8, Result, NewDataSize);
            end;
          bftUnsignedInt16:
            begin
              ui16 := PByte(Buffer)^;
              AllocMemAndSetData(bftUnsignedInt16, ui16, Result, NewDataSize);
            end;
          bftUnsignedInt32:
            begin
              ui32 := PByte(Buffer)^;
              AllocMemAndSetData(bftUnsignedInt32, ui32, Result, NewDataSize);
            end;

          bftSingle:
            begin
              sng := PByte(Buffer)^;
              AllocMemAndSetData(bftSingle, sng, Result, NewDataSize);
            end;
          bftDouble:
            begin
              dbl := PByte(Buffer)^;
              AllocMemAndSetData(bftDouble, dbl, Result, NewDataSize);
            end;
          bftExtended:
            begin
              ext := PByte(Buffer)^;
              AllocMemAndSetData(bftExtended, ext, Result, NewDataSize);
            end;

          bftDate:
            begin
              d := PByte(Buffer)^;
              AllocMemAndSetData(bftDate, d, Result, NewDataSize);
            end;
          bftTime:
            begin
              t := PByte(Buffer)^;
              AllocMemAndSetData(bftTime, t, Result, NewDataSize);
            end;
          bftDateTime:
            begin
              dt.Time := TIME_IS_NULL;
              dt.Date := PByte(Buffer)^;
              AllocMemAndSetData(bftDateTime, dt, Result, NewDataSize);
            end;
          bftLogical:
            begin
              b := not (PByte(Buffer)^ = 0);
              AllocMemAndSetData(bftLogical, b, Result, NewDataSize);
            end;
          bftCurrency:
            begin
              cur := PByte(Buffer)^;
              AllocMemAndSetData(bftCurrency, cur, Result, NewDataSize);
            end;
        end;

      bftUnsignedInt16:  // from Word
        case NewDataType of
          bftChar,
          bftVarchar:
            begin
              s := IntToStr(PWord(Buffer)^);
              AllocMemAndSetData(bftVarchar, s, Result, NewDataSize);
            end;
          bftWideChar,
          bftWideVarchar:
            begin
              ws := IntToStr(PWord(Buffer)^);
              AllocMemAndSetData(bftWideVarchar, ws, Result, NewDataSize);
            end;
          bftSignedInt8:
            begin
              si8 := PWord(Buffer)^;
              AllocMemAndSetData(bftSignedInt8, si8, Result, NewDataSize);
            end;
          bftSignedInt16:
            begin
              si16 := PWord(Buffer)^;
              AllocMemAndSetData(bftSignedInt16, si16, Result, NewDataSize);
            end;
          bftSignedInt32:
            begin
              si32 := PWord(Buffer)^;
              AllocMemAndSetData(bftSignedInt32, si32, Result, NewDataSize);
            end;
          bftSignedInt64:
            begin
              si64 := PWord(Buffer)^;
              AllocMemAndSetData(bftSignedInt64, si64, Result, NewDataSize);
            end;
          bftUnsignedInt8:
            begin
              ui8 := PWord(Buffer)^;
              AllocMemAndSetData(bftUnsignedInt8, ui8, Result, NewDataSize);
            end;
          bftUnsignedInt16:
            begin
              ui16 := PWord(Buffer)^;
              AllocMemAndSetData(bftUnsignedInt16, ui16, Result, NewDataSize);
            end;
          bftUnsignedInt32:
            begin
              ui32 := PWord(Buffer)^;
              AllocMemAndSetData(bftUnsignedInt32, ui32, Result, NewDataSize);
            end;

          bftSingle:
            begin
              sng := PWord(Buffer)^;
              AllocMemAndSetData(bftSingle, sng, Result, NewDataSize);
            end;
          bftDouble:
            begin
              dbl := PWord(Buffer)^;
              AllocMemAndSetData(bftDouble, dbl, Result, NewDataSize);
            end;
          bftExtended:
            begin
              ext := PWord(Buffer)^;
              AllocMemAndSetData(bftExtended, ext, Result, NewDataSize);
            end;

          bftDate:
            begin
              d := PWord(Buffer)^;
              AllocMemAndSetData(bftDate, d, Result, NewDataSize);
            end;
          bftTime:
            begin
              t := PWord(Buffer)^;
              AllocMemAndSetData(bftTime, t, Result, NewDataSize);
            end;
          bftDateTime:
            begin
              dt.Time := TIME_IS_NULL;
              dt.Date := PWord(Buffer)^;
              AllocMemAndSetData(bftDateTime, dt, Result, NewDataSize);
            end;
          bftLogical:
            begin
              b := not (PWord(Buffer)^ = 0);
              AllocMemAndSetData(bftLogical, b, Result, NewDataSize);
            end;
          bftCurrency:
            begin
              cur := PWord(Buffer)^;
              AllocMemAndSetData(bftCurrency, cur, Result, NewDataSize);
            end;
        end;

      bftUnsignedInt32:  // from Cardinal
        case NewDataType of
          bftChar,
          bftVarchar:
            begin
              s := IntToStr(PCardinal(Buffer)^);
              AllocMemAndSetData(bftVarchar, s, Result, NewDataSize);
            end;
          bftWideChar,
          bftWideVarchar:
            begin
              ws := IntToStr(PCardinal(Buffer)^);
              AllocMemAndSetData(bftWideVarchar, ws, Result, NewDataSize);
            end;
          bftSignedInt8:
            begin
              si8 := PCardinal(Buffer)^;
              AllocMemAndSetData(bftSignedInt8, si8, Result, NewDataSize);
            end;
          bftSignedInt16:
            begin
              si16 := PCardinal(Buffer)^;
              AllocMemAndSetData(bftSignedInt16, si16, Result, NewDataSize);
            end;
          bftSignedInt32:
            begin
              si32 := PCardinal(Buffer)^;
              AllocMemAndSetData(bftSignedInt32, si32, Result, NewDataSize);
            end;
          bftSignedInt64:
            begin
              si64 := PCardinal(Buffer)^;
              AllocMemAndSetData(bftSignedInt64, si64, Result, NewDataSize);
            end;
          bftUnsignedInt8:
            begin
              ui8 := PCardinal(Buffer)^;
              AllocMemAndSetData(bftUnsignedInt8, ui8, Result, NewDataSize);
            end;
          bftUnsignedInt16:
            begin
              ui16 := PCardinal(Buffer)^;
              AllocMemAndSetData(bftUnsignedInt16, ui16, Result, NewDataSize);
            end;
          bftUnsignedInt32:
            begin
              ui32 := PCardinal(Buffer)^;
              AllocMemAndSetData(bftUnsignedInt32, ui32, Result, NewDataSize);
            end;

          bftSingle:
            begin
              sng := PCardinal(Buffer)^;
              AllocMemAndSetData(bftSingle, sng, Result, NewDataSize);
            end;
          bftDouble:
            begin
              dbl := PCardinal(Buffer)^;
              AllocMemAndSetData(bftDouble, dbl, Result, NewDataSize);
            end;
          bftExtended:
            begin
              ext := PCardinal(Buffer)^;
              AllocMemAndSetData(bftExtended, ext, Result, NewDataSize);
            end;

          bftDate:
            begin
              d := PCardinal(Buffer)^;
              AllocMemAndSetData(bftDate, d, Result, NewDataSize);
            end;
          bftTime:
            begin
              t := PCardinal(Buffer)^;
              AllocMemAndSetData(bftTime, t, Result, NewDataSize);
            end;
          bftDateTime:
            begin
              dt.Time := TIME_IS_NULL;
              dt.Date := PCardinal(Buffer)^;
              AllocMemAndSetData(bftDateTime, dt, Result, NewDataSize);
            end;
          bftLogical:
            begin
              b := not (PCardinal(Buffer)^ = 0);
              AllocMemAndSetData(bftLogical, b, Result, NewDataSize);
            end;
          bftCurrency:
            begin
              cur := PCardinal(Buffer)^;
              AllocMemAndSetData(bftCurrency, cur, Result, NewDataSize);
            end;
        end;

      bftSingle:  // from Single
        case NewDataType of
          bftChar,
          bftVarchar:
            begin
              s := FloatToStr(PSingle(Buffer)^);
              AllocMemAndSetData(bftVarchar, s, Result, NewDataSize);
            end;
          bftWideChar,
          bftWideVarchar:
            begin
              ws := FloatToStr(PSingle(Buffer)^);
              AllocMemAndSetData(bftWideVarchar, ws, Result, NewDataSize);
            end;
          bftSignedInt8:
            begin
              si8 := Trunc(PSingle(Buffer)^);
              AllocMemAndSetData(bftSignedInt8, si8, Result, NewDataSize);
            end;
          bftSignedInt16:
            begin
              si16 := Trunc(PSingle(Buffer)^);
              AllocMemAndSetData(bftSignedInt16, si16, Result, NewDataSize);
            end;
          bftSignedInt32:
            begin
              si32 := Trunc(PSingle(Buffer)^);
              AllocMemAndSetData(bftSignedInt32, si32, Result, NewDataSize);
            end;
          bftSignedInt64:
            begin
              si64 := Trunc(PSingle(Buffer)^);
              AllocMemAndSetData(bftSignedInt64, si64, Result, NewDataSize);
            end;
          bftUnsignedInt8:
            begin
              ui8 := Trunc(PSingle(Buffer)^);
              AllocMemAndSetData(bftUnsignedInt8, ui8, Result, NewDataSize);
            end;
          bftUnsignedInt16:
            begin
              ui16 := Trunc(PSingle(Buffer)^);
              AllocMemAndSetData(bftUnsignedInt16, ui16, Result, NewDataSize);
            end;
          bftUnsignedInt32:
            begin
              ui32 := Trunc(PSingle(Buffer)^);
              AllocMemAndSetData(bftUnsignedInt32, ui32, Result, NewDataSize);
            end;

          bftSingle:
            begin
              sng := PSingle(Buffer)^;
              AllocMemAndSetData(bftSingle, sng, Result, NewDataSize);
            end;
          bftDouble:
            begin
              dbl := PSingle(Buffer)^;
              AllocMemAndSetData(bftDouble, dbl, Result, NewDataSize);
            end;
          bftExtended:
            begin
              ext := PSingle(Buffer)^;
              AllocMemAndSetData(bftExtended, ext, Result, NewDataSize);
            end;

          bftDate:
            begin
              d := Trunc(PSingle(Buffer)^);
              AllocMemAndSetData(bftDate, d, Result, NewDataSize);
            end;
          bftTime:
            begin
              t := Trunc(PSingle(Buffer)^) mod MILSECS_IN_DAY;
              AllocMemAndSetData(bftTime, t, Result, NewDataSize);
            end;
          bftDateTime:
            begin
              dt.Time := Trunc(Frac(PSingle(Buffer)^)*MILSECS_IN_DAY);
              dt.Date := Trunc(PSingle(Buffer)^);
              AllocMemAndSetData(bftDateTime, dt, Result, NewDataSize);
            end;
          bftLogical:
            begin
              b := not (PSingle(Buffer)^ = 0);
              AllocMemAndSetData(bftLogical, b, Result, NewDataSize);
            end;
          bftCurrency:
            begin
              cur := PSingle(Buffer)^;
              AllocMemAndSetData(bftCurrency, cur, Result, NewDataSize);
            end;
        end;

      bftDouble:  // From Double
        case NewDataType of
          bftChar,
          bftVarchar:
            begin
              s := FloatToStr(PDouble(Buffer)^);
              AllocMemAndSetData(bftVarchar, s, Result, NewDataSize);
            end;
          bftWideChar,
          bftWideVarchar:
            begin
              ws := FloatToStr(PDouble(Buffer)^);
              AllocMemAndSetData(bftWideVarchar, ws, Result, NewDataSize);
            end;
          bftSignedInt8:
            begin
              si8 := Trunc(PDouble(Buffer)^);
              AllocMemAndSetData(bftSignedInt8, si8, Result, NewDataSize);
            end;
          bftSignedInt16:
            begin
              si16 := Trunc(PDouble(Buffer)^);
              AllocMemAndSetData(bftSignedInt16, si16, Result, NewDataSize);
            end;
          bftSignedInt32:
            begin
              si32 := Trunc(PDouble(Buffer)^);
              AllocMemAndSetData(bftSignedInt32, si32, Result, NewDataSize);
            end;
          bftSignedInt64:
            begin
              si64 := Trunc(PDouble(Buffer)^);
              AllocMemAndSetData(bftSignedInt64, si64, Result, NewDataSize);
            end;
          bftUnsignedInt8:
            begin
              ui8 := Trunc(PDouble(Buffer)^);
              AllocMemAndSetData(bftUnsignedInt8, ui8, Result, NewDataSize);
            end;
          bftUnsignedInt16:
            begin
              ui16 := Trunc(PDouble(Buffer)^);
              AllocMemAndSetData(bftUnsignedInt16, ui16, Result, NewDataSize);
            end;
          bftUnsignedInt32:
            begin
              ui32 := Trunc(PDouble(Buffer)^);
              AllocMemAndSetData(bftUnsignedInt32, ui32, Result, NewDataSize);
            end;

          bftSingle:
            begin
              sng := PDouble(Buffer)^;
              AllocMemAndSetData(bftSingle, sng, Result, NewDataSize);
            end;
          bftDouble:
            begin
              dbl := PDouble(Buffer)^;
              AllocMemAndSetData(bftDouble, dbl, Result, NewDataSize);
            end;
          bftExtended:
            begin
              ext := PDouble(Buffer)^;
              AllocMemAndSetData(bftExtended, ext, Result, NewDataSize);
            end;

          bftDate:
            begin
              d := Trunc(PDouble(Buffer)^);
              AllocMemAndSetData(bftDate, d, Result, NewDataSize);
            end;
          bftTime:
            begin
// fixed in 4.97
//              t := Trunc(PDouble(Buffer)^) mod MILSECS_IN_DAY;
              t := Round(PDouble(Buffer)^) mod MILSECS_IN_DAY;
              AllocMemAndSetData(bftTime, t, Result, NewDataSize);
            end;
          bftDateTime:
            begin
              dbl := Frac(PDouble(Buffer)^);
              dbl1 := Trunc(dbl);
              dbl1 := dbl * MILSECS_IN_DAY;
// fixed in 4.97
//              dt.Time := Trunc(Frac(PDouble(Buffer)^)*MILSECS_IN_DAY);
              dt.Time := Round(Frac(PDouble(Buffer)^)*MILSECS_IN_DAY);
              dt.Date := Trunc(PDouble(Buffer)^);
              AllocMemAndSetData(bftDateTime, dt, Result, NewDataSize);
            end;
          bftLogical:
            begin
              b := not (PDouble(Buffer)^ = 0);
              AllocMemAndSetData(bftLogical, b, Result, NewDataSize);
            end;
          bftCurrency:
            begin
              cur := PDouble(Buffer)^;
              AllocMemAndSetData(bftCurrency, cur, Result, NewDataSize);
            end;
        end;

      bftExtended: // From Extended
        case NewDataType of
          bftChar,
          bftVarchar:
            begin
              s := FloatToStr(PExtended(Buffer)^);
              AllocMemAndSetData(bftVarchar, s, Result, NewDataSize);
            end;
          bftWideChar,
          bftWideVarchar:
            begin
              ws := FloatToStr(PExtended(Buffer)^);
              AllocMemAndSetData(bftWideVarchar, ws, Result, NewDataSize);
            end;
          bftSignedInt8:
            begin
              si8 := Trunc(PExtended(Buffer)^);
              AllocMemAndSetData(bftSignedInt8, si8, Result, NewDataSize);
            end;
          bftSignedInt16:
            begin
              si16 := Trunc(PExtended(Buffer)^);
              AllocMemAndSetData(bftSignedInt16, si16, Result, NewDataSize);
            end;
          bftSignedInt32:
            begin
              si32 := Trunc(PExtended(Buffer)^);
              AllocMemAndSetData(bftSignedInt32, si32, Result, NewDataSize);
            end;
          bftSignedInt64:
            begin
              si64 := Trunc(PExtended(Buffer)^);
              AllocMemAndSetData(bftSignedInt64, si64, Result, NewDataSize);
            end;
          bftUnsignedInt8:
            begin
              ui8 := Trunc(PExtended(Buffer)^);
              AllocMemAndSetData(bftUnsignedInt8, ui8, Result, NewDataSize);
            end;
          bftUnsignedInt16:
            begin
              ui16 := Trunc(PExtended(Buffer)^);
              AllocMemAndSetData(bftUnsignedInt16, ui16, Result, NewDataSize);
            end;
          bftUnsignedInt32:
            begin
              ui32 := Trunc(PExtended(Buffer)^);
              AllocMemAndSetData(bftUnsignedInt32, ui32, Result, NewDataSize);
            end;

          bftSingle:
            begin
              sng := PExtended(Buffer)^;
              AllocMemAndSetData(bftSingle, sng, Result, NewDataSize);
            end;
          bftDouble:
            begin
              dbl := PExtended(Buffer)^;
              AllocMemAndSetData(bftDouble, dbl, Result, NewDataSize);
            end;
          bftExtended:
            begin
              ext := PExtended(Buffer)^;
              AllocMemAndSetData(bftExtended, ext, Result, NewDataSize);
            end;

          bftDate:
            begin
              d := Trunc(PExtended(Buffer)^);
              AllocMemAndSetData(bftDate, d, Result, NewDataSize);
            end;
          bftTime:
            begin
              t := Trunc(PExtended(Buffer)^) mod MILSECS_IN_DAY;
              AllocMemAndSetData(bftTime, t, Result, NewDataSize);
            end;
          bftDateTime:
            begin
              dt.Time := Trunc(Frac(PExtended(Buffer)^)*MILSECS_IN_DAY);
              dt.Date := Trunc(PExtended(Buffer)^);
              AllocMemAndSetData(bftDateTime, dt, Result, NewDataSize);
            end;
          bftLogical:
            begin
              b := not (PExtended(Buffer)^ = 0);
              AllocMemAndSetData(bftLogical, b, Result, NewDataSize);
            end;
          bftCurrency:
            begin
              cur := PExtended(Buffer)^;
              AllocMemAndSetData(bftCurrency, cur, Result, NewDataSize);
            end;
        end;


      bftDate:  // from Date
        case NewDataType of
          bftChar,
          bftVarchar:
            begin
              d := PACRDate(Buffer)^;
              if (d = DATE_IS_NULL) then
                s := ''
              else
                s := DateToStr(ACRDateToDate(d));
              AllocMemAndSetData(bftVarchar, s, Result, NewDataSize);
            end;
          bftWideChar,
          bftWideVarchar:
            begin
              d := PACRDate(Buffer)^;
              if (d = DATE_IS_NULL) then
                ws := ''
              else
                ws := DateToStr(ACRDateToDate(d));
              AllocMemAndSetData(bftWideVarchar, ws, Result, NewDataSize);
            end;
          bftSignedInt8:
            begin
              si8 := PACRDate(Buffer)^;
              AllocMemAndSetData(bftSignedInt8, si8, Result, NewDataSize);
            end;
          bftSignedInt16:
            begin
              si16 := PACRDate(Buffer)^;
              AllocMemAndSetData(bftSignedInt16, si16, Result, NewDataSize);
            end;
          bftSignedInt32:
            begin
              si32 := PACRDate(Buffer)^;
              AllocMemAndSetData(bftSignedInt32, si32, Result, NewDataSize);
            end;
          bftSignedInt64:
            begin
              si64 := PACRDate(Buffer)^;
              AllocMemAndSetData(bftSignedInt64, si64, Result, NewDataSize);
            end;
          bftUnsignedInt8:
            begin
              ui8 := PACRDate(Buffer)^;
              AllocMemAndSetData(bftUnsignedInt8, ui8, Result, NewDataSize);
            end;
          bftUnsignedInt16:
            begin
              ui16 := PACRDate(Buffer)^;
              AllocMemAndSetData(bftUnsignedInt16, ui16, Result, NewDataSize);
            end;
          bftUnsignedInt32:
            begin
              ui32 := PACRDate(Buffer)^;
              AllocMemAndSetData(bftUnsignedInt32, ui32, Result, NewDataSize);
            end;

          bftSingle:
            begin
              sng := PACRDate(Buffer)^;
              AllocMemAndSetData(bftSingle, sng, Result, NewDataSize);
            end;
          bftDouble:
            begin
              dbl := PACRDate(Buffer)^;
              AllocMemAndSetData(bftDouble, dbl, Result, NewDataSize);
            end;
          bftExtended:
            begin
              ext := PACRDate(Buffer)^;
              AllocMemAndSetData(bftExtended, ext, Result, NewDataSize);
            end;

          bftDate:
            begin
              d := PACRDate(Buffer)^;
              AllocMemAndSetData(bftDate, d, Result, NewDataSize);
            end;
          bftTime:
            begin
              t := PACRDate(Buffer)^ mod MILSECS_IN_DAY;
              AllocMemAndSetData(bftTime, t, Result, NewDataSize);
            end;
          bftDateTime:
            begin
              dt.Time := TIME_IS_NULL;
              dt.Date := PACRDate(Buffer)^;
              AllocMemAndSetData(bftDateTime, dt, Result, NewDataSize);
            end;
          bftLogical:
            begin
              b := not (PACRDate(Buffer)^ = DATE_IS_NULL);
              AllocMemAndSetData(bftLogical, b, Result, NewDataSize);
            end;
          bftCurrency:
            begin
              cur := PACRDate(Buffer)^;
              AllocMemAndSetData(bftCurrency, cur, Result, NewDataSize);
            end;
        end;


      bftTime:  // from Time
        case NewDataType of
          bftChar,
          bftVarchar:
            begin
              t := PACRTime(Buffer)^;
              if (t = TIME_IS_NULL) then
                s := ''
              else
                s := TimeToStr(ACRTimeToTime(t));
              AllocMemAndSetData(bftVarchar, s, Result, NewDataSize);
            end;
          bftWideChar,
          bftWideVarchar:
            begin
              t := PACRTime(Buffer)^;
              if (t = TIME_IS_NULL) then
                ws := ''
              else
                ws := TimeToStr(ACRTimeToTime(T));
              AllocMemAndSetData(bftWideVarchar, ws, Result, NewDataSize);
            end;
          bftSignedInt8:
            begin
              si8 := PACRTime(Buffer)^;
              AllocMemAndSetData(bftSignedInt8, si8, Result, NewDataSize);
            end;
          bftSignedInt16:
            begin
              si16 := PACRTime(Buffer)^;
              AllocMemAndSetData(bftSignedInt16, si16, Result, NewDataSize);
            end;
          bftSignedInt32:
            begin
              si32 := PACRTime(Buffer)^;
              AllocMemAndSetData(bftSignedInt32, si32, Result, NewDataSize);
            end;
          bftSignedInt64:
            begin
              si64 := PACRTime(Buffer)^;
              AllocMemAndSetData(bftSignedInt64, si64, Result, NewDataSize);
            end;
          bftUnsignedInt8:
            begin
              ui8 := PACRTime(Buffer)^;
              AllocMemAndSetData(bftUnsignedInt8, ui8, Result, NewDataSize);
            end;
          bftUnsignedInt16:
            begin
              ui16 := PACRTime(Buffer)^;
              AllocMemAndSetData(bftUnsignedInt16, ui16, Result, NewDataSize);
            end;
          bftUnsignedInt32:
            begin
              ui32 := PACRTime(Buffer)^;
              AllocMemAndSetData(bftUnsignedInt32, ui32, Result, NewDataSize);
            end;

          bftSingle:
            begin
              sng := PACRTime(Buffer)^;
              AllocMemAndSetData(bftSingle, sng, Result, NewDataSize);
            end;
          bftDouble:
            begin
              dbl := PACRTime(Buffer)^;
              AllocMemAndSetData(bftDouble, dbl, Result, NewDataSize);
            end;
          bftExtended:
            begin
              ext := PACRTime(Buffer)^;
              AllocMemAndSetData(bftExtended, ext, Result, NewDataSize);
            end;

          bftDate:
            begin
              d := PACRTime(Buffer)^;
              AllocMemAndSetData(bftDate, d, Result, NewDataSize);
            end;
          bftTime:
            begin
              t := PACRTime(Buffer)^;
              AllocMemAndSetData(bftTime, t, Result, NewDataSize);
            end;
          bftDateTime:
            begin
              dt.Time := PACRTime(Buffer)^;
              dt.Date := DATE_IS_NULL;
              AllocMemAndSetData(bftDateTime, dt, Result, NewDataSize);
            end;
          bftLogical:
            begin
              b := not (PACRTime(Buffer)^ = TIME_IS_NULL);
              AllocMemAndSetData(bftLogical, b, Result, NewDataSize);
            end;
          bftCurrency:
            begin
              cur := PACRTime(Buffer)^;
              AllocMemAndSetData(bftCurrency, cur, Result, NewDataSize);
            end;
        end;


      bftDateTime:  // from DateTime
        case NewDataType of
          bftChar,
          bftVarchar:
            begin
              dt := PACRDateTime(Buffer)^;
              if (dt.Date = DATE_IS_NULL) and (dt.Time = TIME_IS_NULL) then
                s := ''
              else
                s := DateTimeToStr(ACRDateTimeToDateTime(dt));
              AllocMemAndSetData(bftVarchar, s, Result, NewDataSize);
            end;
          bftWideChar,
          bftWideVarchar:
            begin
              dt := PACRDateTime(Buffer)^;
              if (dt.Date = DATE_IS_NULL) and (dt.Time = TIME_IS_NULL) then
                ws := ''
              else
                ws := DateTimeToStr(ACRDateTimeToDateTime(dt));
              AllocMemAndSetData(bftWideVarchar, ws, Result, NewDataSize);
            end;
          bftSignedInt8:
            begin
              si8 := PACRDateTime(Buffer)^.Date;
              AllocMemAndSetData(bftSignedInt8, si8, Result, NewDataSize);
            end;
          bftSignedInt16:
            begin
              si16 := PACRDateTime(Buffer)^.Date;
              AllocMemAndSetData(bftSignedInt16, si16, Result, NewDataSize);
            end;
          bftSignedInt32:
            begin
              si32 := PACRDateTime(Buffer)^.Date;
              AllocMemAndSetData(bftSignedInt32, si32, Result, NewDataSize);
            end;
          bftSignedInt64:
            begin
              si64 := PACRDateTime(Buffer)^.Date;
              AllocMemAndSetData(bftSignedInt64, si64, Result, NewDataSize);
            end;
          bftUnsignedInt8:
            begin
              ui8 := PACRDateTime(Buffer)^.Date;
              AllocMemAndSetData(bftUnsignedInt8, ui8, Result, NewDataSize);
            end;
          bftUnsignedInt16:
            begin
              ui16 := PACRDateTime(Buffer)^.Date;
              AllocMemAndSetData(bftUnsignedInt16, ui16, Result, NewDataSize);
            end;
          bftUnsignedInt32:
            begin
              ui32 := PACRDateTime(Buffer)^.Date;
              AllocMemAndSetData(bftUnsignedInt32, ui32, Result, NewDataSize);
            end;

          bftSingle:
            begin
              sng := 0;
              if (PACRDateTime(Buffer)^.Date <> DATE_IS_NULL) then
                sng := sng + PACRDateTime(Buffer)^.Date;
// fixed in 4.97
//                sng := sng + MILSECS_IN_DAY / PACRDateTime(Buffer)^.Time;
              if (PACRDateTime(Buffer)^.Time <> TIME_IS_NULL) then
               begin
                sng1 := MILSECS_IN_DAY;
                sng1 := PACRDateTime(Buffer)^.Time / sng1;
                sng := sng + sng1;
               end;
              AllocMemAndSetData(bftSingle, sng, Result, NewDataSize);
            end;
          bftDouble:
            begin
              dbl := 0;
              if (PACRDateTime(Buffer)^.Date <> DATE_IS_NULL) then
                dbl := dbl + PACRDateTime(Buffer)^.Date;
// fixed in 4.97
//              if (PACRDateTime(Buffer)^.Time <> TIME_IS_NULL) then
//                dbl := dbl + MILSECS_IN_DAY / PACRDateTime(Buffer)^.Time;
              if (PACRDateTime(Buffer)^.Time <> TIME_IS_NULL) then
               begin
                dbl1 := MILSECS_IN_DAY;
                dbl1 := PACRDateTime(Buffer)^.Time / dbl1;
                dbl := dbl + dbl1;
               end;
              AllocMemAndSetData(bftDouble, dbl, Result, NewDataSize);
            end;
          bftExtended:
            begin
              ext := 0;
              if (PACRDateTime(Buffer)^.Date <> DATE_IS_NULL) then
                ext := ext + PACRDateTime(Buffer)^.Date;
// fixed in 4.97
//                ext := ext + MILSECS_IN_DAY / PACRDateTime(Buffer)^.Time;
              if (PACRDateTime(Buffer)^.Time <> TIME_IS_NULL) then
               begin
                ext1 := MILSECS_IN_DAY;
                ext1 := PACRDateTime(Buffer)^.Time / dbl1;
                ext := ext + ext;
               end;
              AllocMemAndSetData(bftExtended, ext, Result, NewDataSize);
            end;

          bftDate:
            begin
              d := PACRDateTime(Buffer)^.Date;
              AllocMemAndSetData(bftDate, d, Result, NewDataSize);
            end;
          bftTime:
            begin
              t := PACRDateTime(Buffer)^.Time;
              AllocMemAndSetData(bftTime, t, Result, NewDataSize);
            end;
          bftDateTime:
            begin
              dt := PACRDateTime(Buffer)^;
              AllocMemAndSetData(bftDateTime, dt, Result, NewDataSize);
            end;
          bftLogical:
            begin
              b := not ((PACRDateTime(Buffer)^.Date = DATE_IS_NULL) and
                        (PACRDateTime(Buffer)^.Time = TIME_IS_NULL) );
              AllocMemAndSetData(bftLogical, b, Result, NewDataSize);
            end;
          bftCurrency:
            begin
              ext := 0;
              if (PACRDateTime(Buffer)^.Date <> DATE_IS_NULL) then
                ext := ext + PACRDateTime(Buffer)^.Date;
// fixed in 4.97
//                ext := ext + MILSECS_IN_DAY / PACRDateTime(Buffer)^.Time;
              if (PACRDateTime(Buffer)^.Time <> TIME_IS_NULL) then
               begin
                ext1 := MILSECS_IN_DAY;
                ext1 := PACRDateTime(Buffer)^.Time / dbl1;
                ext := ext + ext;
               end;
              cur := FloatToCurr(ext);
              AllocMemAndSetData(bftCurrency, cur, Result, NewDataSize);
            end;
        end;


      bftLogical:  // From Logical
        case NewDataType of
          bftChar,
          bftVarchar:
            begin
              s := BoolToStr(PACRLogical(Buffer)^, true);
              AllocMemAndSetData(bftVarchar, s, Result, NewDataSize);
            end;
          bftWideChar,
          bftWideVarchar:
            begin
              ws := BoolToStr(PACRLogical(Buffer)^, true);
              AllocMemAndSetData(bftWideVarchar, ws, Result, NewDataSize);
            end;
          bftSignedInt8:
            begin
              if PACRLogical(Buffer)^ then
                si8 := 1
              else
                si8 := 0;
              AllocMemAndSetData(bftSignedInt8, si8, Result, NewDataSize);
            end;
          bftSignedInt16:
            begin
              if PACRLogical(Buffer)^ then
                si16 := 1
              else
                si16 := 0;
              AllocMemAndSetData(bftSignedInt16, si16, Result, NewDataSize);
            end;
          bftSignedInt32:
            begin
              if PACRLogical(Buffer)^ then
                si32 := 1
              else
                si32 := 0;
              AllocMemAndSetData(bftSignedInt32, si32, Result, NewDataSize);
            end;
          bftSignedInt64:
            begin
              if PACRLogical(Buffer)^ then
                si64 := 1
              else
                si64 := 0;
              AllocMemAndSetData(bftSignedInt64, si64, Result, NewDataSize);
            end;
          bftUnsignedInt8:
            begin
              if PACRLogical(Buffer)^ then
                ui8 := 1
              else
                ui8 := 0;
              AllocMemAndSetData(bftUnsignedInt8, ui8, Result, NewDataSize);
            end;
          bftUnsignedInt16:
            begin
              if PACRLogical(Buffer)^ then
                ui16 := 1
              else
                ui16 := 0;
              AllocMemAndSetData(bftUnsignedInt16, ui16, Result, NewDataSize);
            end;
          bftUnsignedInt32:
            begin
              if PACRLogical(Buffer)^ then
                ui32 := 1
              else
                ui32 := 0;
              AllocMemAndSetData(bftUnsignedInt32, ui32, Result, NewDataSize);
            end;

          bftSingle:
            begin
              if PACRLogical(Buffer)^ then
                sng := 1
              else
                sng := 0;
              AllocMemAndSetData(bftSingle, sng, Result, NewDataSize);
            end;
          bftDouble:
            begin
              if PACRLogical(Buffer)^ then
                dbl := 1
              else
                dbl := 0;
              AllocMemAndSetData(bftDouble, dbl, Result, NewDataSize);
            end;
          bftExtended:
            begin
              if PACRLogical(Buffer)^ then
                ext := 1
              else
                ext := 0;
              AllocMemAndSetData(bftExtended, ext, Result, NewDataSize);
            end;

          bftDate:;      // No CAST
          bftTime:;
          bftDateTime:;

          bftLogical:
            begin
              b := PACRLogical(Buffer)^;
              AllocMemAndSetData(bftLogical, b, Result, NewDataSize);
            end;
          bftCurrency: ; // No CAST
        end;

      bftCurrency:  // from Currency
        case NewDataType of
          bftChar,
          bftVarchar:
            begin
              s := CurrToStr(PACRCurrency(Buffer)^);
              AllocMemAndSetData(bftVarchar, s, Result, NewDataSize);
            end;
          bftWideChar,
          bftWideVarchar:
            begin
              ws := CurrToStr(PACRCurrency(Buffer)^);
              AllocMemAndSetData(bftWideVarchar, ws, Result, NewDataSize);
            end;
          bftSignedInt8:
            begin
              si8 := Trunc(PACRCurrency(Buffer)^);
              AllocMemAndSetData(bftSignedInt8, si8, Result, NewDataSize);
            end;
          bftSignedInt16:
            begin
              si16 := Trunc(PACRCurrency(Buffer)^);
              AllocMemAndSetData(bftSignedInt16, si16, Result, NewDataSize);
            end;
          bftSignedInt32:
            begin
              si32 := Trunc(PACRCurrency(Buffer)^);
              AllocMemAndSetData(bftSignedInt32, si32, Result, NewDataSize);
            end;
          bftSignedInt64:
            begin
              si64 := Trunc(PACRCurrency(Buffer)^);
              AllocMemAndSetData(bftSignedInt64, si64, Result, NewDataSize);
            end;
          bftUnsignedInt8:
            begin
              ui8 := Trunc(PACRCurrency(Buffer)^);
              AllocMemAndSetData(bftUnsignedInt8, ui8, Result, NewDataSize);
            end;
          bftUnsignedInt16:
            begin
              ui16 := Trunc(PACRCurrency(Buffer)^);
              AllocMemAndSetData(bftUnsignedInt16, ui16, Result, NewDataSize);
            end;
          bftUnsignedInt32:
            begin
              ui32 := Trunc(PACRCurrency(Buffer)^);
              AllocMemAndSetData(bftUnsignedInt32, ui32, Result, NewDataSize);
            end;

          bftSingle:
            begin
              sng := PACRCurrency(Buffer)^;
              AllocMemAndSetData(bftSingle, sng, Result, NewDataSize);
            end;
          bftDouble:
            begin
              dbl := PACRCurrency(Buffer)^;
              AllocMemAndSetData(bftDouble, dbl, Result, NewDataSize);
            end;
          bftExtended:
            begin
              ext := PACRCurrency(Buffer)^;
              AllocMemAndSetData(bftExtended, ext, Result, NewDataSize);
            end;

          bftDate:;     // No CAST
          bftTime:;
          bftDateTime:;
          bftLogical:
            begin
              b := not (PACRCurrency(Buffer)^ = 0);
              AllocMemAndSetData(bftLogical, b, Result, NewDataSize);
            end;
          bftCurrency:
            begin
              cur := PACRCurrency(Buffer)^;
              AllocMemAndSetData(bftCurrency, cur, Result, NewDataSize);
            end;
        end;

      bftBlob,bftClob,bftWideClob:  //  from Blob
        case NewDataType of
          bftChar,
          bftVarchar:
            begin
              AllocMemAndSetData(bftVarchar, Buffer, Result, NewDataSize);
            end;
          bftWideChar,
          bftWideVarchar:
            begin
              ws := WideString(PAnsiChar(Buffer));
              AllocMemAndSetData(bftWideVarchar, ws, Result, NewDataSize);
            end;
          bftSignedInt8:
            begin
              si8 := StrToInt(PAnsiChar(Buffer));
              AllocMemAndSetData(bftSignedInt8, si8, Result, NewDataSize);
            end;
          bftSignedInt16:
            begin
              si16 := StrToInt(PAnsiChar(Buffer));
              AllocMemAndSetData(bftSignedInt16, si16, Result, NewDataSize);
            end;
          bftSignedInt32:
            begin
              si32 := StrToInt(PAnsiChar(Buffer));
              AllocMemAndSetData(bftSignedInt32, si32, Result, NewDataSize);
            end;
          bftSignedInt64:
            begin
              si64 := StrToInt64(PAnsiChar(Buffer));
              AllocMemAndSetData(bftSignedInt64, si64, Result, NewDataSize);
            end;
          bftUnsignedInt8:
            begin
              ui8 := StrToInt(PAnsiChar(Buffer));
              AllocMemAndSetData(bftUnsignedInt8, ui8, Result, NewDataSize);
            end;
          bftUnsignedInt16:
            begin
              ui16 := StrToInt(PAnsiChar(Buffer));
              AllocMemAndSetData(bftUnsignedInt16, ui16, Result, NewDataSize);
            end;
          bftUnsignedInt32:
            begin
              ui32 := StrToInt(PAnsiChar(Buffer));
              AllocMemAndSetData(bftUnsignedInt32, ui32, Result, NewDataSize);
            end;

          bftSingle:
            begin
{$IFDEF D17H}
              oldSeparator := FormatSettings.DecimalSeparator;
              FormatSettings.DecimalSeparator := '.';
              try
                sng := StrToFloat(PAnsiChar(Buffer));
              finally
                FormatSettings.DecimalSeparator := oldSeparator;
              end;
{$ELSE}
              oldSeparator := DecimalSeparator;
              DecimalSeparator := '.';
              try
                sng := StrToFloat(PAnsiChar(Buffer));
              finally
                DecimalSeparator := oldSeparator;
              end;
{$ENDIF}
              AllocMemAndSetData(bftSingle, sng, Result, NewDataSize);
            end;
          bftDouble:
            begin
{$IFDEF D17H}
              oldSeparator := FormatSettings.DecimalSeparator;
              FormatSettings.DecimalSeparator := '.';
              try
                dbl := StrToFloat(PAnsiChar(Buffer));
              finally
                FormatSettings.DecimalSeparator := oldSeparator;
              end;
{$ELSE}
              oldSeparator := DecimalSeparator;
              DecimalSeparator := '.';
              try
                dbl := StrToFloat(PAnsiChar(Buffer));
              finally
                DecimalSeparator := oldSeparator;
              end;
{$ENDIF}
              AllocMemAndSetData(bftDouble, dbl, Result, NewDataSize);
            end;
          bftExtended:
            begin
{$IFDEF D17H}
              oldSeparator := FormatSettings.DecimalSeparator;
              FormatSettings.DecimalSeparator := '.';
              try
                ext := StrToFloat(PAnsiChar(Buffer));
              finally
                FormatSettings.DecimalSeparator := oldSeparator;
              end;
{$ELSE}
              oldSeparator := DecimalSeparator;
              DecimalSeparator := '.';
              try
                ext := StrToFloat(PAnsiChar(Buffer));
              finally
                DecimalSeparator := oldSeparator;
              end;
{$ENDIF}
              AllocMemAndSetData(bftExtended, ext, Result, NewDataSize);
            end;

          bftDate:
            begin
              d := DateToACRDate(StrToDate(PAnsiChar(Buffer)));
              AllocMemAndSetData(bftDate, d, Result, NewDataSize);
            end;
          bftTime:
            begin
              t := TimeToACRTime(StrToTime(PAnsiChar(Buffer)));
              AllocMemAndSetData(bftTime, t, Result, NewDataSize);
            end;
          bftDateTime:
            begin
              dt := DateTimeToACRDateTime(StrToDateTime(PAnsiChar(Buffer)));
              AllocMemAndSetData(bftDateTime, dt, Result, NewDataSize);
            end;

          bftLogical:
            begin
              s := AnsiUpperCase(PAnsiChar(Buffer));
              b := (s = '1') or (s = 'TRUE');
              AllocMemAndSetData(bftLogical, b, Result, NewDataSize);
            end;
          bftCurrency:
            begin
              cur := StrToCurr(PAnsiChar(Buffer));
              AllocMemAndSetData(bftCurrency, cur, Result, NewDataSize);
            end;
          bftBlob,bftClob,bftWideClob:
            begin
              AllocMemAndSetData(bftVarchar, PAnsiChar(Buffer), Result, NewDataSize);
            end;
        end;

      //else raise EACRException.Create
    end;
  except
    raise EACRException.Create(30051, ErrorGCastError,
                                   [BftToStr(DataType), BftToStr(NewDataType)]);
  end;

  if (Result = nil) then
    raise EACRException.Create(30052, ErrorGCastError,
                                  [BftToStr(DataType), BftToStr(NewDataType)]);
end;//Cast


//------------------------------------------------------------------------------
// return ture if Cast is not needed for CompareValueBuffers
//------------------------------------------------------------------------------
function ACRIsCastNotNeeded(BaseFieldType1,BaseFieldType2: TACRBaseFieldType):Boolean;
var is1,is2,iws1,iws2: Boolean;
begin
  is1 := IsStringFieldType(BaseFieldType1);
  is2 := IsStringFieldType(BaseFieldType2);
  iws1 := IsWideStringFieldType(BaseFieldType1);
  iws2 := IsWideStringFieldType(BaseFieldType2);
  Result := (is1 and is2 and (not iws1) and (not iws2)) or
            (iws1 and iws2);
end; // ACRIsCastNotNeeded


initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ACRVariant> initialized');
{$ENDIF}
  ACRMemoryIncUseCount;

finalization

  ACRMemoryDecUseCount;


end.

