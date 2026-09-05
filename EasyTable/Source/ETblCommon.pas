{$I ETblVer.inc}

unit ETblCommon;

interface

uses Windows, Classes, DB, SysUtils, ETblExcept, ETblStrFunc, Math, ETblConst
,ESFSDecUtil
{$IFDEF D6H}
,Variants
{$ENDIF}
{$IFDEF D12H}
     ,ETbl_d12h
{$ENDIF}
;

type
 TETblCompareResult = (ecrEqual,ecrGreater,ecrLower,ecrLeftNull,ecrRightNull,
  ecrBothNull);

 // join type
 TETblJoinType = (ejtCross, ejtInner, ejtUnion, ejtLeftOuter,
                 ejtRightOuter, ejtFullOuter);

 // union type
 TETblUnionType = (eutUnion, eutIntersect, eutExcept);

  // pointers to standart data types
  pByte = ^Byte;
  pInteger = ^Integer;
  pSmallint = ^Smallint;
  pLargeInt = ^Int64;
  pWord = ^Word;
  pBoolean = ^Boolean;
  pFloat = ^Double;
  pCurrency = ^Double;
  pDateTime = ^TDateTime;

 // unary / binary data operators
 TETblDataOperator = (
    doUNDEFINED,                       // error
    //George doCMP,                             // compare <0,=0,>0
    {Comparison}
    doEQ,                              // equal
    doNE,                              // NOT equal
    doGT,                              // greater than
    doLT,                              // less than
    doGE,                              // greater or equal
    doLE,                              // less or equal
    {Boolean}
    doNOT,                             // NOT
    doAND,                             // AND
    doOR,                              // OR
    doIN,                              // in (a,b,c, ...)
    doNOTIN,                           // not in (a,b,c, ...)
    doBETWEEN,                         // between (a,b)
    doNOTBETWEEN,                      // not between (a,b)
    doLIKE,                            // like 'a?b%'
    doNOTLIKE,                         // not like
    doISNULLFUNCTION,                  // IsNull( expression [,replacement]) function
    doISNULL,                          // is null
    doISNOTNULL,                       // is not null
    doTRUE,                            // TRUE const
    doFALSE,                           // FALSE const
    {Arithmetic}
    doADD,                             // addition
    doSUB,                             // subtraction
    doMUL,                             // multiplication
    doDIV,                             // division
    {Functions}
    doPOSITION,                        // Position (str1) in (str2)
    doCONCAT,                          // str1 || str2
    doUPPER,                           // Upper(str)
    doLOWER,                           // Lower(str)
    doTRIM,                            // TRIM
    doLTRIM,                           // LTRIM
    doRTRIM,                           // RTRIM
    doLENGTH,                          // LENGTH(str)
    doPOS,                             // POS(substr in|, str) { 1 - first char, 0 - not found }
    doSUBSTRING,                       // SUBSTRING(str from|, startindex [for|, length])
    {aggregated functions}
    doSUM,                             // SUM([distinct]expression)
    doAVG,                             // AVG([distinct]expression)
    doMIN,                             // min(expression)
    doMAX,                             // max(expression)
    doCOUNT,                           // COUNT([distinct]expression)
    doCOUNTALL,                        // count(*)
    {datetime functions}
    doSYSDATE,                         // SYSDATE - return current DateTime
    doCURRENT_DATE,                    // CURRENT_DATE
    doCURRENT_TIME,                    // CURRENT_TIME
    doTODATE,                          // TODATE(string, format)
    doTOSTRING,                        // TOSTRING(date, format)
    doYEAR,
    doQUARTER,
    doMONTH,
    doDAY,
    doWEEKDAY,
    doDAYOFWEEK,
    doDAYNAME,
    doMONTHNAME,
    doHOUR,
    doMINUTE,
    doSECOND,
    doMSECOND,

    doABS,
    doCEILING,
    doFLOOR,
    doMOD,
    doPOWER,
    doRANDOM,
    doROUND,
    doSIGN,
    doTRUNCATE,
    doBitwiseNOT,
    doBitwiseAND,
    doBitwiseOR,
    doSHL,
    doSHR,
    doXOR,
    doHEX,
    {cast types}
    doCAST                             // Cast(expression, type)
 );

 // data value (of any data type)
 TETblDataValue = record
    DataType: TFieldType; // type of data
    DataSize: Integer;    // size of data value
    IsNull: Boolean;      // NULL or NOT NULL?
    pData: PAnsiChar;         // Binary data representation
    IsDataLinked: Boolean;    // freemem required?
 end;

 PETblDataValue = ^TETblDataValue;


 // initialize internal record vars
 procedure InitDataValue(var value: TETblDataValue);

 // free memory if necessary
 procedure FinalizeDataValue(var value: TETblDataValue);

 // copies data
 procedure CopyDataValue(SrcValue: TETblDataValue;
                         var DestValue: TETblDataValue);

 // set data value as integer
 procedure SetDataValueAsNull(var DataValue: TETblDataValue; const DataType: TFieldType = ftUnknown);

 // set data value as integer
 procedure SetDataValueAsInteger(var DataValue: TETblDataValue; IntValue: integer);
 // get data value as integer
 function GetDataValueAsInteger(const DataValue: TETblDataValue): Integer;

 // set data value as float
 procedure SetDataValueAsFloat(var DataValue: TETblDataValue; FloatValue: double);
 // get data value as float
 function GetDataValueAsFloat(const DataValue: TETblDataValue): Double;

 // set data value as SmallInt
 procedure SetDataValueAsSmallInt(var DataValue: TETblDataValue; Value: SmallInt);
 function GetDataValueAsSmallInt(const DataValue: TETblDataValue): SmallInt;

 // set data value as Word
 procedure SetDataValueAsWord(var DataValue: TETblDataValue; Value: Word);
 function GetDataValueAsWord(const DataValue: TETblDataValue): Word;

 // set data value as LargeInt
 procedure SetDataValueAsLargeInt(var DataValue: TETblDataValue; Value: int64);
 function GetDataValueAsLargeInt(const DataValue: TETblDataValue): LargeInt;

 // set data value as boolean
 procedure SetDataValueAsBoolean(var DataValue: TETblDataValue; Value: boolean);

 // Getdata value as boolean
 function GetDataValueAsBoolean(const DataValue: TETblDataValue) : boolean;

 // set data value as Currency
 procedure SetDataValueAsCurrency(var DataValue: TETblDataValue; Value: double);

 // set data value as Date
 procedure SetDataValueAsDate(var DataValue: TETblDataValue; Value: TDateTime);

 // set data value as Time
 procedure SetDataValueAsTime(var DataValue: TETblDataValue; Value: TDateTime);

 // set data value as DateTime
 procedure SetDataValueAsDateTime(var DataValue: TETblDataValue; Value: TDateTime);
 // get data value as DateTime
 function GetDataValueAsDateTime(const DataValue: TETblDataValue): TDateTime;

 // set data value as AnsiString
 procedure SetDataValueAsString(var DataValue: TETblDataValue; StrValue: AnsiString);
 // get data value as AnsiString
 function GetDataValueAsString(const DataValue: TETblDataValue): AnsiString;

 // set data value as AnsiString
 procedure SetDataValueAsWideString(var DataValue: TETblDataValue; const Value: WideString);
 // get data value as AnsiString
 function GetDataValueAsWideString(const DataValue: TETblDataValue): WideString;

 // get data value as variant
 function GetDataValueAsVariant(const DataValue: TETblDataValue): variant;

 // returns random temporary name
 function GetTemporaryName(BaseName: AnsiString = ''): AnsiString;

 // compares two values and raises exception if types are different
 function CompareDataValues(var value1: TETblDataValue;
                            var value2: TETblDataValue;
                            JoinType: TETblJoinType = ejtInner;
                            bIgnoreCase: Boolean = false;
                            bPartialCompare: Boolean = false
    ):  TETblCompareResult;

 // Return common DataType for the types
 function getCommonDataType(a,b: TFieldType): TFieldType;

 // cast types. If impossible then raise
 procedure Cast(var Value: TETblDataValue; FieldType: TFieldType);

 // value1 := value1 + value2
 procedure AddDataValues(var value1: TETblDataValue;
                         const value2: TETblDataValue;
                         IgnoreNULL: boolean = false);

 // value := -value
 procedure NegativeDataValues(var value: TETblDataValue);

 // value1 := value1 * value2
 procedure MulDataValues(var value1: TETblDataValue;
                         const value2: TETblDataValue);

 // value1 := value1 / value2
 procedure DivDataValues(var value1: TETblDataValue;
                         const value2: TETblDataValue);

 // value1 := Abs(value1)
 procedure AbsDataValues(var value1: TETblDataValue);
 // value1 := Ceiling(value1)
 procedure CeilingDataValues(var value1: TETblDataValue);
 // value1 := Floor(value1)
 procedure FloorDataValues(var value1: TETblDataValue);
 // value1 := value1 % value2
 procedure ModDataValues(var value1: TETblDataValue;
                         const value2: TETblDataValue);
 // value1 := sign(value1)
 procedure SignDataValues(var value1: TETblDataValue);
 // value1 := Random ([value1])
 procedure RandomDataValues(var value1: TETblDataValue; ByRange: Boolean = false);
 // value1 := value1 ^ value2
 procedure PowerDataValues(var value1: TETblDataValue;
                         const value2: TETblDataValue);
 // value1 := Round(value1 [,value2])
 procedure RoundDataValues(var value1:   TETblDataValue;
                           const value2: TETblDataValue;
                           UsePrecision: Boolean = false
                         );
 // value1 := Truncate(value1 [,value2])
 procedure TruncateDataValues(var value1:   TETblDataValue;
                           const value2: TETblDataValue;
                           UsePrecision: Boolean = false
                         );
 // value1 := value1 AND value2
 procedure AndDataValues(var value1: TETblDataValue;
                         const value2: TETblDataValue);
 // value1 := value1 OR value2
 procedure OrDataValues(var value1: TETblDataValue;
                         const value2: TETblDataValue);
 // value1 := NOT value1
 procedure NotDataValues(var value1: TETblDataValue);
 // value1 := value1 SHL value2
 procedure ShlDataValues(var value1: TETblDataValue;
                         const value2: TETblDataValue);
 // value1 := value1 SHR value2
 procedure ShrDataValues(var value1: TETblDataValue;
                         const value2: TETblDataValue);
 // value1 := value1 XOR value2
 procedure XorDataValues(var value1: TETblDataValue;
                         const value2: TETblDataValue);
 // value1 := Hex(value1 [, value2])
 procedure HexDataValues(var value1: TETblDataValue;
                         const value2: TETblDataValue;
                         const ModeExists: Boolean
                        );

 // get data type name
 function GetDataTypeName(dt: TFieldType): AnsiString;
 // get operator name
 function GetOperatorName(op: TETblDataOperator): AnsiString;
 // Return true, if DataType is Numeric (int,word, float,...)
 function IsNumericDataType(dt: TFieldType): boolean;
// Return true, if DataType is integer (int,word, float,...)
 function IsIntegerDataType(dt: TFieldType): boolean;
 // return true if string
 function IsStringDataType(dt: TFieldType): boolean;
 // Return FieldType
 function GetFieldType(const TypeName: AnsiString): TFieldType;
 // return length of null-terminated AnsiString
 function GetStrLength(Buffer: PAnsiChar; bUnicode: Boolean): Integer;
 function StrToHexValue(Text: PAnsiChar; Size: Integer): AnsiString;

implementation


 // initialize internal record vars
 procedure InitDataValue(var value: TETblDataValue);
 begin
  value.pData := nil;
  value.IsNull := true;
  value.DataType := ftUnknown;
  value.DataSize := 0;
  value.IsDataLinked := false;
 end;


 // free memory if necessary
 procedure FinalizeDataValue(var value: TETblDataValue);
begin
  if (value.pData <> nil) then
   if (not value.IsDataLinked) then
    FreeMem(value.pData);
  value.pData := nil;
  value.IsNull := true;
  value.DataType := ftUnknown;
  value.DataSize := 0;
end;


 // copies data
 procedure CopyDataValue(SrcValue: TETblDataValue;
                         var DestValue: TETblDataValue);
 begin
   FinalizeDataValue(DestValue);
   DestValue.DataType := SrcValue.DataType;
   DestValue.DataSize := SrcValue.DataSize;
   DestValue.IsNull := SrcValue.IsNull;
//   DestValue.IsDataLinked := SrcValue.IsDataLinked;
   // data is allocated
   DestValue.IsDataLinked := False;
   // copy binary data
   if (SrcValue.pData <> nil) then
    begin
     DestValue.pData := AllocMem(DestValue.DataSize);
     Move(SrcValue.pData^, DestValue.pData^, DestValue.DataSize);
    end
   else
    DestValue.pData := nil;
 end;


procedure SetDataValueAsNull(var DataValue: TETblDataValue;
                             const DataType: TFieldType = ftUnknown);
begin
   FinalizeDataValue(DataValue);
   DataValue.DataType := DataType;
   DataValue.DataSize := 0;
   DataValue.IsNull := true;
end;

 // set data value as integer
 procedure SetDataValueAsInteger(var DataValue: TETblDataValue; IntValue: integer);
 begin
   FinalizeDataValue(DataValue);
   DataValue.DataType := ftInteger;
   DataValue.DataSize := SizeOf(Integer);
   DataValue.IsNull := False;
   DataValue.pData := AllocMem(DataValue.DataSize);
   PInteger(DataValue.pData)^ := IntValue;
   DataValue.IsDataLinked := False;
 end;

 function GetDataValueAsInteger(const DataValue: TETblDataValue): Integer;
 begin
   if not DataValue.IsNull and (DataValue.DataType in [ftInteger,ftAutoInc]) then
     Result := pInteger(DataValue.pData)^
   else
     raise ETblException.Create(02107);
 end;

 // set data value as float
 procedure SetDataValueAsFloat(var DataValue: TETblDataValue; FloatValue: double);
 begin
   FinalizeDataValue(DataValue);
   DataValue.DataType := ftFloat;
   DataValue.DataSize := SizeOf(double);
   DataValue.IsNull := False;
   DataValue.pData := AllocMem(DataValue.DataSize);
   PFloat(DataValue.pData)^ := FloatValue;
   DataValue.IsDataLinked := False;
 end;

 // get data value as float
 function GetDataValueAsFloat(const DataValue: TETblDataValue): Double;
 begin
   if not DataValue.IsNull and (DataValue.DataType in [ftFloat,ftCurrency]) then
     Result := pDouble(DataValue.pData)^
   else
     raise ETblException.Create(00060);
 end;

 // set data value as SmallInt
 procedure SetDataValueAsSmallInt(var DataValue: TETblDataValue; Value: SmallInt);
 begin
   FinalizeDataValue(DataValue);
   DataValue.DataType := ftSmallint;
   DataValue.DataSize := SizeOf(SmallInt);
   DataValue.IsNull := False;
   DataValue.pData := AllocMem(DataValue.DataSize);
   PSmallInt(DataValue.pData)^ := Value;
   DataValue.IsDataLinked := False;
 end;

 function GetDataValueAsSmallInt(const DataValue: TETblDataValue): SmallInt;
 begin
   if not DataValue.IsNull and (DataValue.DataType = ftSmallInt) then
     Result := pSmallInt(DataValue.pData)^
   else
     raise ETblException.Create(00061);
 end;

 // set data value as Word
 procedure SetDataValueAsWord(var DataValue: TETblDataValue; Value: Word);
 begin
   FinalizeDataValue(DataValue);
   DataValue.DataType := ftWord;
   DataValue.DataSize := SizeOf(Word);
   DataValue.IsNull := False;
   DataValue.pData := AllocMem(DataValue.DataSize);
   PWord(DataValue.pData)^ := Value;
   DataValue.IsDataLinked := False;
 end;

 function GetDataValueAsWord(const DataValue: TETblDataValue): Word;
 begin
   if not DataValue.IsNull and (DataValue.DataType = ftWord) then
     Result := pWord(DataValue.pData)^
   else
     raise ETblException.Create(00063);
 end;

 // set data value as LargeInt
 procedure SetDataValueAsLargeInt(var DataValue: TETblDataValue; Value: int64); overload;
 begin
   FinalizeDataValue(DataValue);
   DataValue.DataType := ftLargeint;
   DataValue.DataSize := SizeOf(int64);
   DataValue.IsNull := False;
   DataValue.pData := AllocMem(DataValue.DataSize);
   PLargeInt(DataValue.pData)^ := Value;
   DataValue.IsDataLinked := False;
 end;

 function GetDataValueAsLargeInt(const DataValue: TETblDataValue): LargeInt;
 begin
   if not DataValue.IsNull and (DataValue.DataType = ftLargeInt) then
     Result := pLargeInt(DataValue.pData)^
   else
     raise ETblException.Create(00062);
 end;

 // set data value as boolean
 procedure SetDataValueAsBoolean(var DataValue: TETblDataValue; Value: boolean); overload;
 begin
   FinalizeDataValue(DataValue);
   DataValue.DataType := ftBoolean;
   DataValue.DataSize := SizeOf(boolean);
   DataValue.IsNull := False;
   DataValue.pData := AllocMem(DataValue.DataSize);
   PBoolean(DataValue.pData)^ := Value;
   DataValue.IsDataLinked := False;
 end;

//------------------------------------------------------------------------------
// get data value as boolean
//------------------------------------------------------------------------------
function GetDataValueAsBoolean(const DataValue: TETblDataValue) : boolean;
begin
  if not DataValue.IsNull and (DataValue.DataType = ftBoolean) then
    Result := pBoolean(DataValue.pData)^
  else
    raise ETblException.Create(02113);
end;//GetDataValueAsBoolean


 // set data value as Currency
 procedure SetDataValueAsCurrency(var DataValue: TETblDataValue; Value: double);
 begin
   FinalizeDataValue(DataValue);
   DataValue.DataType := ftCurrency;
   DataValue.DataSize := SizeOf(double);
   DataValue.IsNull := False;
   DataValue.pData := AllocMem(DataValue.DataSize);
   PCurrency(DataValue.pData)^ := Value;
   DataValue.IsDataLinked := False;
 end;


//------------------------------------------------------------------------------
 // set data value as Date
//------------------------------------------------------------------------------
 procedure SetDataValueAsDate(var DataValue: TETblDataValue; Value: TDateTime);
 begin
   FinalizeDataValue(DataValue);
   DataValue.DataType := ftDate;
   DataValue.DataSize := SizeOf(TDateTime);
   DataValue.IsNull := False;
   DataValue.pData := AllocMem(DataValue.DataSize);
  TDateTimeRec(PDateTime(DataValue.pData)^).Date :=
    DateTimeToTimeStamp(Value).Date;
   DataValue.IsDataLinked := False;
end;//SetDataValueAsDate


//------------------------------------------------------------------------------
 // set data value as Time
//------------------------------------------------------------------------------
 procedure SetDataValueAsTime(var DataValue: TETblDataValue; Value: TDateTime);
 begin
   FinalizeDataValue(DataValue);
   DataValue.DataType := ftTime;
   DataValue.DataSize := SizeOf(TDateTime);
   DataValue.IsNull := False;
   DataValue.pData := AllocMem(DataValue.DataSize);
  TDateTimeRec(PDateTime(DataValue.pData)^).Time :=
    DateTimeToTimeStamp(Value).Time;
   DataValue.IsDataLinked := False;
end;//SetDataValueAsTime


//------------------------------------------------------------------------------
 // set data value as DateTime
//------------------------------------------------------------------------------
 procedure SetDataValueAsDateTime(var DataValue: TETblDataValue; Value: TDateTime);
 begin
   FinalizeDataValue(DataValue);
   DataValue.DataType := ftDateTime;
   DataValue.DataSize := SizeOf(TDateTime);
   DataValue.IsNull := False;
   DataValue.pData := AllocMem(DataValue.DataSize);
  PDateTime(DataValue.pData)^ := TimeStampToMSecs(DateTimeToTimeStamp(Value));
   DataValue.IsDataLinked := False;
end;//SetDataValueAsDateTime


//------------------------------------------------------------------------------
// get data value as DateTime
//------------------------------------------------------------------------------
function GetDataValueAsDateTime(const DataValue: TETblDataValue): TDateTime;
var TimeStamp: TTimeStamp;
begin
  case DataValue.DataType of
   ftDateTime:
     begin
      Result := TimeStampToDateTime(MSecsToTimeStamp(pDateTime(DataValue.pData)^));
 end;
   ftDate:
     begin
      TimeStamp.Time := 0;
      TimeStamp.Date := TDateTimeRec(pDateTime(DataValue.pData)^).Date;
      Result := TimeStampToDateTime(TimeStamp);
     end;
   ftTime:
     begin
      TimeStamp.Time := TDateTimeRec(pDateTime(DataValue.pData)^).Time;
      TimeStamp.Date := DateDelta;
      Result := TimeStampToDateTime(TimeStamp);
     end;
   else
    raise ETblException.Create(02140);
  end;
end;//GetDataValueAsDateTime


//------------------------------------------------------------------------------
 // set data value as string
//------------------------------------------------------------------------------
 procedure SetDataValueAsString(var DataValue: TETblDataValue; StrValue: AnsiString);
 begin
   FinalizeDataValue(DataValue);
   DataValue.DataType := ftString;
   if (Length(StrValue) <= 0) then
    begin
     DataValue.DataSize := 0;
     DataValue.IsNull := True;
    end
   else
    begin
     DataValue.DataSize := Length(StrValue)+1;
     DataValue.IsNull := False;
     DataValue.pData := AllocMem(DataValue.DataSize);
     Move(PAnsiChar(StrValue)^, DataValue.pData^, DataValue.DataSize);
    end;
   DataValue.IsDataLinked := False;
 end;


//------------------------------------------------------------------------------
 // get data value as string
//------------------------------------------------------------------------------
function GetDataValueAsString(const DataValue: TETblDataValue): AnsiString;
 begin
   case DataValue.DataType of
    ftInteger:
       Result := IntToStr(PInteger(DataValue.pData)^);
    ftFloat:
       Result := FloatToStr(PDouble(DataValue.pData)^);
    ftString,ftMemo,ftFmtMemo:
       Result := AnsiString(DataValue.pData);
    else
     Result := '';
   end;
end;//GetDataValueAsString


//------------------------------------------------------------------------------
// set data value as string
//------------------------------------------------------------------------------
procedure SetDataValueAsWideString(var DataValue: TETblDataValue; const Value: WideString);
begin
  FinalizeDataValue(DataValue);
  DataValue.DataType := ftWideString;
   if (Length(Value) <= 0) then
    begin
     DataValue.DataSize := 0;
     DataValue.IsNull := True;
    end
   else
    begin
      DataValue.DataSize := (Length(Value)+1)*2;
      DataValue.IsNull := False;
      DataValue.pData := AllocMem(DataValue.DataSize);
      Move(PWideChar(Value)^, DataValue.pData^, DataValue.DataSize);
    end;
  DataValue.IsDataLinked := False;
end;//SetDataValueAsWideString


//------------------------------------------------------------------------------
// Get data value as string
//------------------------------------------------------------------------------
function GetDataValueAsWideString(const DataValue: TETblDataValue): WideString;
begin
  Result := WideString(pWideChar(DataValue.pData));
end;//GetDataValueAsString


//------------------------------------------------------------------------------
// get data value as variant
//------------------------------------------------------------------------------
function GetDataValueAsVariant(const DataValue: TETblDataValue): variant;
begin
  if (DataValue.IsNull) then
   Result := varNull
  else
   case (DataValue.DataType) of
      ftAutoInc,ftInteger:
        Result := GetDataValueAsInteger(DataValue);
      ftWord:
        Result := GetDataValueAsWord(DataValue);
      ftSmallInt:
        Result := GetDataValueAsSmallInt(DataValue);
      ftLargeInt:
{$IFDEF D6H}
        Result := GetDataValueAsLargeInt(DataValue);
{$ELSE}
        Result := GetDataValueAsInteger(DataValue);
{$ENDIF}        
      ftString:
        Result := GetDataValueAsString(DataValue);
      ftWideString:
        Result := GetDataValueAsWideString(DataValue);
      ftTime,
      ftDate,
      ftDateTime:
        Result := GetDataValueAsDateTime(DataValue);
      ftFloat,
      ftCurrency:
        Result := GetDataValueAsFloat(DataValue);
      ftBoolean:
        Result := GetDataValueAsBoolean(DataValue);
    else
     Result := varNull;
   end;
end; // GetDataValueAsVariant


// returns random temporary name
function GetTemporaryName(BaseName: AnsiString = ''): AnsiString;
begin
 result := BaseName +  IntToStr(Random(MAXINT));
end;

// compares two values and raises exception if types are different
function CompareDataValues(var value1: TETblDataValue;
                           var value2: TETblDataValue;
                           JoinType: TETblJoinType = ejtInner;
                           bIgnoreCase: Boolean = false;
                           bPartialCompare: Boolean = false
                           ):  TETblCompareResult;
var valueType: TFieldType;
//--------------------- CompareRecordBuffer -----------------------------------

 cmpRecBuf_res  : integer;
 cmpRecBuf_p_int1, cmpRecBuf_p_int2 : pInteger;
 cmpRecBuf_p_small1, cmpRecBuf_p_small2		: pSmallint;
 cmpRecBuf_p_float1, cmpRecBuf_p_float2		: pFloat;
 cmpRecBuf_p_curr1, cmpRecBuf_p_curr2  		: pCurrency;
 cmpRecBuf_p_str1, cmpRecBuf_p_str2	      : PAnsiChar;
 cmpRecBuf_p_wstr1, cmpRecBuf_p_wstr2	    : PWideChar;
 cmpRecBuf_p_date1, cmpRecBuf_p_date2 		: pDateTime;
 cmpRecBuf_date1, cmpRecBuf_date2 		: TDateTime;
 cmpRecBuf_p_bool1, cmpRecBuf_p_bool2    	: pBoolean;
 cmpRecBuf_p_word1, cmpRecBuf_p_word2     : pWord;
 cmpRecBuf_p_largeInt1, cmpRecBuf_p_largeInt2   : pLargeInt;
 cmpRecBuf_TimeStamp : TTimeStamp;
 cmpRecBuf_TimeStamp1 : TTimeStamp;
 cmpRecBuf_TimeStamp2 : TTimeStamp;
 cmpRecBuf_find: Boolean;
begin
// result := ecrBothNull;
 cmpRecBuf_find := True; // compare like filter

 if (value1.IsNull or value2.IsNull) then
  begin
     if (value1.IsNull and value2.IsNull) then
      result := ecrBothNull
     else
     if (value1.IsNull) then
       result := ecrLeftNull
     else
       result := ecrRightNull;
  {
   if (JoinType = ejtInner) then
    begin
     // inner
    end; // inner
   }
 {
   if (JoinType = ejtLeftOuter) then
    if (not value1.IsNull) then
     result := ecrGreater;
   if (JoinType = ejtRightOuter) then
    if (not value2.IsNull) then
     result := ecrLower;
}
   Exit;
  end;


 valueType := GetCommonDataType(value1.DataType,value2.DataType);
 if (((value1.DataType = ftString) and (value2.DataType = ftDate)) or
     ((value2.DataType = ftString) and (value1.DataType = ftDate))) then
   valueType := ftDate;
 if (((value1.DataType = ftString) and (value2.DataType = ftTime)) or
     ((value2.DataType = ftString) and (value1.DataType = ftTime))) then
   valueType := ftTime;
 if (((value1.DataType = ftString) and (value2.DataType = ftDateTime)) or
     ((value2.DataType = ftString) and (value1.DataType = ftDateTime))) then
   valueType := ftDateTime;

 if (valueType = ftUnknown) then
  raise ETblException.Create(00025,[],nil);
 if (valueType <> value1.DataType) then
  Cast(value1,valueType);
 if (valueType <> value2.DataType) then
  Cast(value2,valueType);
{
 if (valueType <> value2.DataType) then
  begin
    if (valueType = ftAutoInc) or (value2.DataType = ftAutoInc) then
     valueType := ftInteger
    else
     raise ETblException.Create(00025,[],nil);
   end;
}
   case valueType of
        ftAutoInc,
        ftSmallInt,
        ftInteger,
        ftWord,
        ftLargeInt,
        ftBoolean,
        ftFloat,
        ftBCD,
        ftCurrency,
        ftString,
        ftWideString,
        ftDateTime, ftTime, ftDate : ;
        else
         raise ETblException.Create(00028,[],nil);
       end;
       
  cmpRecBuf_res := 0;
  case valueType of
     ftSmallint :
      begin
       cmpRecBuf_p_small1 := pSmallInt(value1.pData);
       cmpRecBuf_p_small2 := pSmallInt(value2.pData);
	     if (cmpRecBuf_p_small1^ = cmpRecBuf_p_small2^)
  	    then cmpRecBuf_res := 0  // 1 = 2
	     else
	     if (cmpRecBuf_p_small1^ > cmpRecBuf_p_small2^)
	      then cmpRecBuf_res := 1  // 1 > 2
	     else
	      cmpRecBuf_res := -1; // 1 < 2
      end;
     ftInteger,ftAutoInc :
      begin
         cmpRecBuf_p_int1 := pInteger(value1.pData);
         cmpRecBuf_p_int2 := pInteger(value2.pData);
	     if (cmpRecBuf_p_int1^ = cmpRecBuf_p_int2^)
  	    then cmpRecBuf_res := 0  // 1 = 2
	     else
	     if (cmpRecBuf_p_int1^ > cmpRecBuf_p_int2^)
	      then cmpRecBuf_res := 1  // 1 > 2
	     else
	      cmpRecBuf_res := -1; // 1 < 2
      end;
     ftWord :
      begin
       cmpRecBuf_p_word1 := pWord(value1.pData);
       cmpRecBuf_p_word2 := pWord(value2.pData);
	     if (cmpRecBuf_p_word1^ = cmpRecBuf_p_word2^)
  	    then cmpRecBuf_res := 0  // 1 = 2
	     else
	     if (cmpRecBuf_p_word1^ > cmpRecBuf_p_word2^)
	      then cmpRecBuf_res := 1  // 1 > 2
	     else
	      cmpRecBuf_res := -1; // 1 < 2
      end;
     ftLargeInt :
      begin
       cmpRecBuf_p_largeInt1 := plargeInt(value1.pData);
       cmpRecBuf_p_largeInt2 := plargeInt(value2.pData);
	     if (cmpRecBuf_p_largeInt1^ = cmpRecBuf_p_largeInt2^)
  	    then cmpRecBuf_res := 0  // 1 = 2
	     else
	     if (cmpRecBuf_p_largeInt1^ > cmpRecBuf_p_largeInt2^)
	      then cmpRecBuf_res := 1  // 1 > 2
	     else
	      cmpRecBuf_res := -1; // 1 < 2
      end;
     ftBoolean :
      begin
       cmpRecBuf_p_bool1 := pBoolean(value1.pData);
       cmpRecBuf_p_bool2 := pBoolean(value2.pData);
       if (cmpRecBuf_p_bool1^ = cmpRecBuf_p_bool2^) then
        cmpRecBuf_res := 0
       else
       if (cmpRecBuf_p_bool1^) then
        cmpRecBuf_res := 1
       else
        cmpRecBuf_res := -1;
      end;
     ftString :
      begin
       cmpRecBuf_p_str1 := pAnsiChar(value1.pData);
       cmpRecBuf_p_str2 := pAnsiChar(value2.pData);
       //compare AnsiString
       if (bIgnoreCase) then
        begin
         if (bPartialCompare) then
          cmpRecBuf_res := Q_AnsiCompTextL(cmpRecBuf_p_str1,cmpRecBuf_p_str2,Length(cmpRecBuf_p_str2))
         else
          cmpRecBuf_res := Q_AnsiPCompText(cmpRecBuf_p_str1,cmpRecBuf_p_str2);
        end
       else
        begin
         if (bPartialCompare) then
          cmpRecBuf_res := Q_AnsiCompStrL(cmpRecBuf_p_str1,cmpRecBuf_p_str2,Length(cmpRecBuf_p_str2))
         else
          cmpRecBuf_res := Q_AnsiPCompStr(cmpRecBuf_p_str1,cmpRecBuf_p_str2);
        end; //string
      end;

     ftWideString :
      begin
       cmpRecBuf_p_wstr1 := PWideChar(value1.pData);
       cmpRecBuf_p_wstr2 := PWideChar(value2.pData);
       //compare string
       if (bIgnoreCase) then
        begin
         if (bPartialCompare) then
          cmpRecBuf_res :=
               Windows.CompareStringW(LOCALE_USER_DEFAULT,
                        NORM_IGNORECASE + SORT_STRINGSORT,
                        cmpRecBuf_p_wstr1,
                        Math.Min(Length(cmpRecBuf_p_wstr1),Length(cmpRecBuf_p_wstr2)),
                        cmpRecBuf_p_wstr2,
                        Length(cmpRecBuf_p_wstr2))-2
         else
          cmpRecBuf_res :=
               Windows.CompareStringW(LOCALE_USER_DEFAULT,
                        NORM_IGNORECASE + SORT_STRINGSORT,
                        cmpRecBuf_p_wstr1,
                        Length(cmpRecBuf_p_wstr1),
                        cmpRecBuf_p_wstr2,
                        Length(cmpRecBuf_p_wstr2))-2;
        end
       else
        begin
         if (bPartialCompare) then
          cmpRecBuf_res :=
               Windows.CompareStringW(LOCALE_USER_DEFAULT,
                        SORT_STRINGSORT,
                        cmpRecBuf_p_wstr1,
                        Math.Min(Length(cmpRecBuf_p_wstr1),Length(cmpRecBuf_p_wstr2)),
                        cmpRecBuf_p_wstr2,
                        Length(cmpRecBuf_p_wstr2))-2
         else
          cmpRecBuf_res :=
               Windows.CompareStringW(LOCALE_USER_DEFAULT,
                        SORT_STRINGSORT,
                        cmpRecBuf_p_wstr1,
                        Length(cmpRecBuf_p_wstr1),
                        cmpRecBuf_p_wstr2,
                        Length(cmpRecBuf_p_wstr2))-2;
        end; //wide string
      end;

     ftDateTime:
      begin
       cmpRecBuf_p_date1 := pDateTime(value1.pData);
       cmpRecBuf_p_date2 := pDateTime(value2.pData);

       cmpRecBuf_TimeStamp1 := MSecsToTimeStamp(cmpRecBuf_p_date1^);
       cmpRecBuf_date1 := TimeStampToDateTime(cmpRecBuf_TimeStamp1);

       cmpRecBuf_TimeStamp2 := MSecsToTimeStamp(cmpRecBuf_p_date2^);
       cmpRecBuf_date2 := TimeStampToDateTime(cmpRecBuf_TimeStamp2);
       if (cmpRecBuf_find) then
        begin
//  	     if (Trunc(Double(cmpRecBuf_date1)*86400) = Trunc(Double(cmpRecBuf_date2)*86400))
  	     if ((cmpRecBuf_TimeStamp1.Time = cmpRecBuf_TimeStamp2.Time) and
             (cmpRecBuf_TimeStamp1.Date = cmpRecBuf_TimeStamp2.Date)) then
               cmpRecBuf_res := 0  // 1 = 2
  	     else
          begin
           // decoding
    	     if (cmpRecBuf_date1 > cmpRecBuf_date2)
  	        then cmpRecBuf_res := 1  // 1 > 2
  	       else
  	        cmpRecBuf_res := -1; // 1 < 2
          end; // not equal
        end // find
       else
        begin
         if (Abs(Double(cmpRecBuf_date1) - Double(cmpRecBuf_date2)) < 0.00000001) then
          cmpRecBuf_res := 0
         else
          // date and time values are not equal
// Leo Martin, 5.40
// - sign should not be used when date parts are equal
          begin
           if (Trunc(Double(cmpRecBuf_date1)) = Trunc(Double(cmpRecBuf_date2))) then
            begin
             // date values are equal, let's compare time values
             // date values are not equal
             if (Abs(Double(cmpRecBuf_date1)) > Abs(Double(cmpRecBuf_date2))) then
              cmpRecBuf_res := 1
             else
             if (Abs(Double(cmpRecBuf_date1)) < Abs(Double(cmpRecBuf_date2))) then
              cmpRecBuf_res := -1;
            end
           else
            begin
             // date values are not equal
         if (Double(cmpRecBuf_date1) > Double(cmpRecBuf_date2)) then
          cmpRecBuf_res := 1
         else
         if (Double(cmpRecBuf_date1) < Double(cmpRecBuf_date2)) then
          cmpRecBuf_res := -1;
        end;
          end;           // date and time values are not equal
        end; // index, not find
      end; // date time

     ftDate:
      begin
       cmpRecBuf_p_date1 := pDateTime(value1.pData);
       cmpRecBuf_p_date2 := pDateTime(value2.pData);

       cmpRecBuf_TimeStamp.Time := 0;
       cmpRecBuf_TimeStamp.Date := TDateTimeRec(cmpRecBuf_p_date1^).Date;
// Leo Martin, 5.40
// - TimeStamp.Date should be >= 1
       if (cmpRecBuf_TimeStamp.Date <= 0) then
        cmpRecBuf_TimeStamp.Date := 1;
       cmpRecBuf_date1 := TimeStampToDateTime(cmpRecBuf_TimeStamp);

       cmpRecBuf_TimeStamp.Time := 0;
       cmpRecBuf_TimeStamp.Date := TDateTimeRec(cmpRecBuf_p_date2^).Date;
// Leo Martin, 5.40
// - TimeStamp.Date should be >= 1
       if (cmpRecBuf_TimeStamp.Date <= 0) then
        cmpRecBuf_TimeStamp.Date := 1;
       cmpRecBuf_date2 := TimeStampToDateTime(cmpRecBuf_TimeStamp);
       if (cmpRecBuf_find) then
        begin
  	     if (Trunc(Double(cmpRecBuf_date1)) = Trunc(Double(cmpRecBuf_date2)))
    	    then cmpRecBuf_res := 0  // 1 = 2
  	     else
          begin
           // decoding
    	     if (cmpRecBuf_date1 > cmpRecBuf_date2)
  	        then cmpRecBuf_res := 1  // 1 > 2
  	       else
  	        cmpRecBuf_res := -1; // 1 < 2
          end; // not equal
        end
       else
        begin
         if (Abs(Double(cmpRecBuf_date1) - Double(cmpRecBuf_date2)) < 0.00000001) then
          cmpRecBuf_res := 0
         else
         if (Double(cmpRecBuf_date1) > Double(cmpRecBuf_date2)) then
          cmpRecBuf_res := 1
         else
         if (Double(cmpRecBuf_date1) < Double(cmpRecBuf_date2)) then
          cmpRecBuf_res := -1;
        end;
      end;

     ftTime:
      begin
       cmpRecBuf_p_date1 := pDateTime(value1.pData);
       cmpRecBuf_p_date2 := pDateTime(value2.pData);

       cmpRecBuf_TimeStamp1.Time := TDateTimeRec(cmpRecBuf_p_date1^).Time;
       cmpRecBuf_TimeStamp1.Date := DateDelta;
//       cmpRecBuf_date1 := TimeStampToDateTime(cmpRecBuf_TimeStamp1);

       cmpRecBuf_TimeStamp2.Time := TDateTimeRec(cmpRecBuf_p_date2^).Time;
       cmpRecBuf_TimeStamp2.Date := DateDelta;
//       cmpRecBuf_date2 := TimeStampToDateTime(cmpRecBuf_TimeStamp2);

       if (cmpRecBuf_find) then
        begin
  	     if (cmpRecBuf_TimeStamp1.Time = cmpRecBuf_TimeStamp2.Time)
    	    then cmpRecBuf_res := 0  // 1 = 2
  	     else
          begin
           // decoding
    	     if (cmpRecBuf_TimeStamp1.Time > cmpRecBuf_TimeStamp2.Time)
  	        then cmpRecBuf_res := 1  // 1 > 2
  	       else
  	        cmpRecBuf_res := -1; // 1 < 2
          end; // not equal
        end
       else
        begin
  	     if (cmpRecBuf_TimeStamp1.Time = cmpRecBuf_TimeStamp2.Time) then
          cmpRecBuf_res := 0
         else
         if (cmpRecBuf_TimeStamp1.Time > cmpRecBuf_TimeStamp2.Time) then
          cmpRecBuf_res := 1
         else
         if (cmpRecBuf_TimeStamp1.Time < cmpRecBuf_TimeStamp2.Time) then
          cmpRecBuf_res := -1;
        end;
      end;

     ftFloat :
      begin
       cmpRecBuf_p_float1 := pFloat(value1.pData);
       cmpRecBuf_p_float2 := pFloat(value2.pData);
	     if (cmpRecBuf_p_float1^ = cmpRecBuf_p_float2^)
  	    then cmpRecBuf_res := 0  // 1 = 2
	     else
	     if (cmpRecBuf_p_float1^ > cmpRecBuf_p_float2^)
	      then cmpRecBuf_res := 1  // 1 > 2
	     else
	      cmpRecBuf_res := -1; // 1 < 2
      end;
     ftCurrency :
      begin
       cmpRecBuf_p_curr1 := pCurrency(value1.pData);
       cmpRecBuf_p_curr2 := pCurrency(value2.pData);
	     if (cmpRecBuf_p_curr1^ = cmpRecBuf_p_curr2^)
  	    then cmpRecBuf_res := 0  // 1 = 2
	     else
	     if (cmpRecBuf_p_curr1^ > cmpRecBuf_p_curr2^)
	      then cmpRecBuf_res := 1  // 1 > 2
	     else
	      cmpRecBuf_res := -1; // 1 < 2
      end;
    end; // case
  if (cmpRecBuf_res = 0) then
   result := ecrEqual
  else
  if (cmpRecBuf_res < 0) then
   result := ecrLower
  else
   result := ecrGreater;
end; // CompareDataValues


//------------------------------------------------------------------------------
// // Return Common DataType for 2 types, or ftUnknown
//------------------------------------------------------------------------------
function getCommonDataType(a,b: TFieldType): TFieldType;
begin
  Result := ftUnknown;
  case a of
    ftAutoInc,
    ftInteger:
        case b of
          ftAutoInc,
          ftInteger,
          ftSmallInt,
          ftWord:         Result := ftInteger;
          ftLargeInt:     Result := ftLargeInt;
          ftFloat:        Result := ftFloat;
          ftBoolean:      Result := ftInteger;
          ftDate,
          ftTime,
          ftDateTime:     Result := ftDateTime;
          ftCurrency:     Result := ftCurrency;
          ftString:       Result := ftString;
          ftWideString:   Result := ftWideString;
        end;
    ftSmallInt:
        case b of
          ftAutoInc,
          ftInteger:      Result := ftInteger;
          ftSmallInt:     Result := ftSmallInt;
          ftWord:         Result := ftInteger;
          ftLargeInt:     Result := ftLargeInt;
          ftFloat:        Result := ftFloat;
          ftBoolean:      Result := ftSmallInt;
          ftDate,
          ftTime,
          ftDateTime:     Result := ftDateTime;
          ftCurrency:     Result := ftCurrency;
          ftString:       Result := ftString;
          ftWideString:   Result := ftWideString;
        end;
    ftWord:
        case b of
          ftAutoInc,
          ftInteger,
          ftSmallInt:     Result := ftSmallInt;
          ftWord:         Result := ftWord;
          ftLargeInt:     Result := ftLargeInt;
          ftFloat:        Result := ftFloat;
          ftBoolean:      Result := ftWord;
          ftDate,
          ftTime,
          ftDateTime:     Result := ftDateTime;
          ftCurrency:     Result := ftCurrency;
          ftString:       Result := ftString;
          ftWideString:   Result := ftWideString;
        end;
    ftLargeInt:
        case b of
          ftAutoInc,
          ftInteger,
          ftSmallInt,
          ftWord,
          ftLargeInt:     Result := ftLargeInt;
          ftFloat:        Result := ftFloat;
          ftBoolean:      Result := ftLargeInt;
          ftDate,
          ftTime,
          ftDateTime:     Result := ftDateTime;
          ftCurrency:     Result := ftCurrency;
          ftString:       Result := ftString;
          ftWideString:   Result := ftWideString;
        end;
    ftFloat:
        case b of
          ftAutoInc,
          ftInteger,
          ftSmallInt,
          ftWord,
          ftLargeInt,
          ftFloat:        Result := ftFloat;
          ftBoolean:      Result := ftFloat;
          ftDate,
          ftTime,
          ftDateTime:     Result := ftDateTime;
          ftCurrency:     Result := ftCurrency;
          ftString:       Result := ftString;
          ftWideString:   Result := ftWideString;
        end;
    ftBoolean:
        case b of
          ftAutoInc,
          ftInteger:      Result := ftInteger;
          ftSmallInt:     Result := ftSmallInt;
          ftWord:         Result := ftWord;
          ftLargeInt:     Result := ftLargeInt;
          ftFloat:        Result := ftFloat;
          ftBoolean:      Result := ftBoolean;
          ftDate,
          ftTime,
          ftDateTime,
          ftCurrency:     Result := ftUnknown;
          ftString:       Result := ftString;
          ftWideString:   Result := ftWideString;
        end;
    ftCurrency:
        case b of
          ftAutoInc,
          ftInteger,
          ftSmallInt,
          ftWord,
          ftLargeInt,
          ftFloat,
          ftBoolean:      Result := ftCurrency;
          ftDate,
          ftTime,
          ftDateTime:     Result := ftUnknown;
          ftCurrency:     Result := ftCurrency;
          ftString:       Result := ftString;
          ftWideString:   Result := ftWideString;
        end;
    ftDate:
        case b of
          ftAutoInc,
          ftInteger,
          ftSmallInt,
          ftWord,
          ftLargeInt,
          ftTime,
          ftFloat,
          ftDateTime,
          ftBoolean:      Result := ftDateTime;
          ftDate:         Result := ftDate;
          ftCurrency:     Result := ftUnknown;
          ftString:       Result := ftString;
          ftWideString:   Result := ftWideString;
        end;
    ftTime:
        case b of
          ftAutoInc,
          ftInteger,
          ftSmallInt,
          ftWord,
          ftLargeInt,
          ftDate,
          ftDateTime,
          ftFloat,
          ftBoolean:      Result := ftDateTime;
          ftTime:         Result := ftTime;
          ftCurrency:     Result := ftUnknown;
          ftString:       Result := ftString;
          ftWideString:   Result := ftWideString;
        end;
    ftDateTime:
        case b of
          ftAutoInc,
          ftInteger,
          ftSmallInt,
          ftWord,
          ftLargeInt,
          ftFloat:        Result := ftDateTime;
          ftBoolean:      Result := ftDateTime;
          ftDate,
          ftTime,
          ftDateTime:     Result := ftDateTime;
          ftCurrency:     Result := ftUnknown;
          ftString:       Result := ftString;
          ftWideString:   Result := ftWideString;
        end;
    ftString:
        case b of
          ftAutoInc,
          ftInteger,
          ftSmallInt,
          ftWord,
          ftLargeInt,
          ftFloat,
          ftBoolean,
          ftDate,
          ftTime,
          ftDateTime,
          ftCurrency,
          ftMemo,
          ftFmtMemo,
          ftString:       Result := ftString;
          ftWideString:   Result := ftWideString;
        end;
    ftWideString:
        case b of
          ftAutoInc,
          ftInteger,
          ftSmallInt,
          ftWord,
          ftLargeInt,
          ftFloat,
          ftBoolean,
          ftCurrency,
          ftDate,
          ftTime,
          ftDateTime,
          ftString,
          ftMemo,
          ftFmtMemo,
          ftWideString:   Result := ftWideString;
        end;
     ftMemo:
        case b of
          ftString:       Result := ftString;
          ftWideString:   Result := ftWideString;
        end;
     ftFmtMemo:
        case b of
          ftString:       Result := ftString;
          ftWideString:   Result := ftWideString;
        end;
  end;
end;//getCommonDataType


//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
procedure Cast(var Value: TETblDataValue; FieldType: TFieldType);
begin
  try
    if Value.IsNull then
      Value.DataType := FieldType
    else
    case Value.DataType of
      ftAutoInc,
      ftInteger:
          case FieldType of
            ftAutoInc,
            ftInteger:
               Value.DataType := FieldType;
            ftSmallInt:
               SetDataValueAsSmallInt(Value, pInteger(Value.pData)^);
            ftWord:
               SetDataValueAsWord(Value, pInteger(Value.pData)^);
            ftLargeInt:
               SetDataValueAsLargeInt(Value, pInteger(Value.pData)^);
            ftFloat:
               SetDataValueAsFloat(Value, pInteger(Value.pData)^);
            ftBoolean:
               SetDataValueAsBoolean(Value, pInteger(Value.pData)^<>0);
            ftCurrency:
               SetDataValueAsCurrency(Value, pInteger(Value.pData)^);
            ftDate:
               SetDataValueAsDate(Value, pInteger(Value.pData)^);
            ftTime:
               SetDataValueAsTime(Value, pInteger(Value.pData)^);
            ftDateTime:
               SetDataValueAsDateTime(Value, pInteger(Value.pData)^);
            ftString:
               SetDataValueAsString(Value, IntToStr(pInteger(Value.pData)^));
            ftWideString:
               SetDataValueAsWideString(Value, IntToStr(pInteger(Value.pData)^));
          end;
      ftSmallInt:
          case FieldType of
            ftAutoInc,
            ftInteger:
               SetDataValueAsInteger(Value, pSmallInt(Value.pData)^);
            ftSmallInt:
               Exit;
            ftWord:
               SetDataValueAsWord(Value, pSmallInt(Value.pData)^);
            ftLargeInt:
               SetDataValueAsLargeInt(Value, pSmallInt(Value.pData)^);
            ftFloat:
               SetDataValueAsFloat(Value, pSmallInt(Value.pData)^);
            ftBoolean:
               SetDataValueAsBoolean(Value, pSmallInt(Value.pData)^<>0);
            ftCurrency:
               SetDataValueAsCurrency(Value, pSmallInt(Value.pData)^);
            ftDate:
               SetDataValueAsDate(Value, pSmallInt(Value.pData)^);
            ftTime:
               SetDataValueAsTime(Value, pSmallInt(Value.pData)^);
            ftDateTime:
               SetDataValueAsDateTime(Value, pSmallInt(Value.pData)^);
            ftString:
               SetDataValueAsString(Value, IntToStr(pSmallInt(Value.pData)^));
            ftWideString:
               SetDataValueAsWideString(Value, IntToStr(pSmallInt(Value.pData)^));
          end;
      ftWord:
          case FieldType of
            ftAutoInc,
            ftInteger:
               SetDataValueAsInteger(Value, pWord(Value.pData)^);
            ftSmallInt:
               SetDataValueAsSmallInt(Value, pWord(Value.pData)^);
            ftWord:
               Exit;
            ftLargeInt:
               SetDataValueAsLargeInt(Value, pWord(Value.pData)^);
            ftFloat:
               SetDataValueAsFloat(Value, pWord(Value.pData)^);
            ftBoolean:
               SetDataValueAsBoolean(Value, pWord(Value.pData)^<>0);
            ftCurrency:
               SetDataValueAsCurrency(Value, pWord(Value.pData)^);
            ftDate:
               SetDataValueAsDate(Value, pWord(Value.pData)^);
            ftTime:
               SetDataValueAsTime(Value, pWord(Value.pData)^);
            ftDateTime:
               SetDataValueAsDateTime(Value, pWord(Value.pData)^);
            ftString:
               SetDataValueAsString(Value, IntToStr(pWord(Value.pData)^));
            ftWideString:
               SetDataValueAsWideString(Value, IntToStr(pWord(Value.pData)^));
          end;
      ftLargeInt:
          case FieldType of
            ftAutoInc,
            ftInteger:
               SetDataValueAsInteger(Value, pLargeInt(Value.pData)^);
            ftSmallInt:
               SetDataValueAsSmallInt(Value, pLargeInt(Value.pData)^);
            ftWord:
               SetDataValueAsWord(Value, pLargeInt(Value.pData)^);
            ftLargeInt:
               SetDataValueAsLargeInt(Value, pLargeInt(Value.pData)^);
            ftFloat:
               SetDataValueAsFloat(Value, pLargeInt(Value.pData)^);
            ftBoolean:
               SetDataValueAsBoolean(Value, pLargeInt(Value.pData)^<>0);
            ftCurrency:
               SetDataValueAsCurrency(Value, pLargeInt(Value.pData)^);
            ftDate:
               SetDataValueAsDate(Value, pLargeInt(Value.pData)^);
            ftTime:
               SetDataValueAsTime(Value, pLargeInt(Value.pData)^);
            ftDateTime:
               SetDataValueAsDateTime(Value, pLargeInt(Value.pData)^);
            ftString:
               SetDataValueAsString(Value, IntToStr(pLargeInt(Value.pData)^));
            ftWideString:
               SetDataValueAsWideString(Value, IntToStr(pLargeInt(Value.pData)^));
          end;
      ftFloat:
          case FieldType of
            ftAutoInc,
            ftInteger:
               SetDataValueAsInteger(Value, Round(pFloat(Value.pData)^));
            ftSmallInt:
               SetDataValueAsSmallInt(Value, Round(pFloat(Value.pData)^));
            ftWord:
               SetDataValueAsWord(Value, Round(pFloat(Value.pData)^));
            ftLargeInt:
               SetDataValueAsLargeInt(Value, Round(pFloat(Value.pData)^));
            ftFloat:
               Exit;
            ftBoolean:
               SetDataValueAsBoolean(Value, pFloat(Value.pData)^<>0);
            ftCurrency:
               SetDataValueAsCurrency(Value, pFloat(Value.pData)^);
            ftDate:
               SetDataValueAsDate(Value, pFloat(Value.pData)^);
            ftTime:
               SetDataValueAsTime(Value, pFloat(Value.pData)^);
            ftDateTime:
               SetDataValueAsDateTime(Value, pFloat(Value.pData)^);
            ftString:
               SetDataValueAsString(Value, FloatToStr(pFloat(Value.pData)^));
            ftWideString:
               SetDataValueAsWideString(Value, FloatToStr(pFloat(Value.pData)^));
          end;
      ftBoolean:
          case FieldType of
            ftAutoInc,
            ftInteger:
               if pBoolean(Value.pData)^ then
                 SetDataValueAsInteger(Value, 1)
               else
                 SetDataValueAsInteger(Value, 0);
            ftSmallInt:
               if pBoolean(Value.pData)^ then
                 SetDataValueAsSmallInt(Value, 1)
               else
                 SetDataValueAsSmallInt(Value, 0);
            ftWord:
               if pBoolean(Value.pData)^ then
                 SetDataValueAsWord(Value, 1)
               else
                 SetDataValueAsWord(Value, 0);
            ftLargeInt:
               if pBoolean(Value.pData)^ then
                 SetDataValueAsLargeInt(Value, 1)
               else
                 SetDataValueAsLargeInt(Value, 0);
            ftFloat:
               if pBoolean(Value.pData)^ then
                 SetDataValueAsFloat(Value, 1)
               else
                 SetDataValueAsFloat(Value, 0);
            ftBoolean:
               Exit;
            ftCurrency,
            ftDate,
            ftTime,
            ftDateTime:
               raise ETblException.Create(-1);
            ftString:
               if pBoolean(Value.pData)^ then
                 SetDataValueAsString(Value, 'true')
               else
                 SetDataValueAsString(Value, 'false');
            ftWideString:
               if pBoolean(Value.pData)^ then
                 SetDataValueAsWideString(Value, 'true')
               else
                 SetDataValueAsWideString(Value, 'false');
          end;
      ftCurrency:
          case FieldType of
            ftAutoInc,
            ftInteger:
               SetDataValueAsInteger(Value, Round(pCurrency(Value.pData)^));
            ftSmallInt:
               SetDataValueAsSmallInt(Value, Round(pCurrency(Value.pData)^));
            ftWord:
               SetDataValueAsWord(Value, Round(pCurrency(Value.pData)^));
            ftLargeInt:
               SetDataValueAsLargeInt(Value, Round(pCurrency(Value.pData)^));
            ftFloat:
               SetDataValueAsFloat(Value, pCurrency(Value.pData)^);
            ftBoolean:
               SetDataValueAsBoolean(Value, pCurrency(Value.pData)^<>0);
            ftCurrency:
               Exit;
            ftDate,
            ftTime,
            ftDateTime:
               raise ETblException.Create(-1);
            ftString:
               SetDataValueAsString(Value, FloatToStr(pCurrency(Value.pData)^));
            ftWideString:
               SetDataValueAsWideString(Value, FloatToStr(pCurrency(Value.pData)^));
          end;
      ftDate,
      ftDateTime:
          case FieldType of
            ftAutoInc,
            ftInteger:
               SetDataValueAsInteger(Value, Round(GetDataValueAsDateTime(Value)));
            ftSmallInt:
               SetDataValueAsSmallInt(Value, Round(GetDataValueAsDateTime(Value)));
            ftWord:
               SetDataValueAsWord(Value, Round(GetDataValueAsDateTime(Value)));
            ftLargeInt:
               SetDataValueAsLargeInt(Value, Round(GetDataValueAsDateTime(Value)));
            ftFloat:
               SetDataValueAsFloat(Value, GetDataValueAsDateTime(Value));
            ftBoolean:
               SetDataValueAsBoolean(Value, GetDataValueAsDateTime(Value)<>0);
            ftCurrency:
               SetDataValueAsCurrency(Value, GetDataValueAsDateTime(Value));
            ftDate:
               SetDataValueAsDate(Value, GetDataValueAsDateTime(Value));
            ftTime:
               SetDataValueAsTime(Value, GetDataValueAsDateTime(Value));
            ftDateTime:
               SetDataValueAsDateTime(Value, GetDataValueAsDateTime(Value));
            ftString:
               SetDataValueAsString(Value, DateTimeToStr(GetDataValueAsDateTime(Value)));
            ftWideString:
               SetDataValueAsWideString(Value, DateTimeToStr(GetDataValueAsDateTime(Value)));
          end;
      ftTime:
          case FieldType of
            ftAutoInc,
            ftInteger:
               SetDataValueAsInteger(Value, 0);
            ftSmallInt:
               SetDataValueAsSmallInt(Value, 0);
            ftWord:
               SetDataValueAsWord(Value, 0);
            ftLargeInt:
               SetDataValueAsLargeInt(Value, 0);
            ftFloat:
               SetDataValueAsFloat(Value, GetDataValueAsDateTime(Value));
            ftBoolean:
               SetDataValueAsBoolean(Value, GetDataValueAsDateTime(Value)<>0);
            ftCurrency:
               SetDataValueAsCurrency(Value, GetDataValueAsDateTime(Value));
            ftDate:
               SetDataValueAsDate(Value, GetDataValueAsDateTime(Value));
            ftTime:
               SetDataValueAsTime(Value, GetDataValueAsDateTime(Value));
            ftDateTime:
               SetDataValueAsDateTime(Value, GetDataValueAsDateTime(Value));
            ftString:
               SetDataValueAsString(Value, TimeToStr(GetDataValueAsDateTime(Value)));
            ftWideString:
               SetDataValueAsWideString(Value, TimeToStr(GetDataValueAsDateTime(Value)));
          end;
      ftString:
          case FieldType of
            ftAutoInc,
            ftInteger:
               SetDataValueAsInteger(Value, StrToInt(GetDataValueAsString(Value)));
            ftSmallInt:
               SetDataValueAsSmallInt(Value, StrToInt(GetDataValueAsString(Value)));
            ftWord:
               SetDataValueAsWord(Value, StrToInt(GetDataValueAsString(Value)));
            ftLargeInt:
               SetDataValueAsLargeInt(Value, StrToInt(GetDataValueAsString(Value)));
            ftFloat:
               SetDataValueAsFloat(Value, StrToFloat(GetDataValueAsString(Value)));
            ftBoolean:
               if AnsiCompareText(GetDataValueAsString(Value), 'true') = 0 then
                 SetDataValueAsBoolean(Value, true)
               else
                 SetDataValueAsBoolean(Value, false);
            ftCurrency:
               SetDataValueAsCurrency(Value, StrToFloat(GetDataValueAsString(Value)));
            ftDate:
               SetDataValueAsDate(Value, StrToDate(GetDataValueAsString(Value)));
            ftTime:
               SetDataValueAsTime(Value, StrToTime(GetDataValueAsString(Value)));
            ftDateTime:
               SetDataValueAsDateTime(Value, StrToDateTime(GetDataValueAsString(Value)));
            ftString:
               Exit;
            ftWideString:
               SetDataValueAsWideString(Value, GetDataValueAsString(Value));
            ftMemo:
               Value.DataType := ftMemo;
            ftFmtMemo:
               Value.DataType := ftFmtMemo;
          end;
      ftWideString:
          case FieldType of
            ftAutoInc,
            ftInteger:
               SetDataValueAsInteger(Value, StrToInt(GetDataValueAsWideString(Value)));
            ftSmallInt:
               SetDataValueAsSmallInt(Value, StrToInt(GetDataValueAsWideString(Value)));
            ftWord:
               SetDataValueAsWord(Value, StrToInt(GetDataValueAsWideString(Value)));
            ftLargeInt:
               SetDataValueAsLargeInt(Value, StrToInt(GetDataValueAsWideString(Value)));
            ftFloat:
               SetDataValueAsFloat(Value, StrToFloat(GetDataValueAsWideString(Value)));
            ftBoolean:
               if AnsiCompareText(GetDataValueAsWideString(Value), 'true') = 0 then
                 SetDataValueAsBoolean(Value, true)
               else
                 SetDataValueAsBoolean(Value, false);
            ftCurrency:
               SetDataValueAsCurrency(Value, StrToFloat(GetDataValueAsWideString(Value)));
            ftDate:
               SetDataValueAsDate(Value, StrToDate(GetDataValueAsWideString(Value)));
            ftTime:
               SetDataValueAsTime(Value, StrToTime(GetDataValueAsWideString(Value)));
            ftDateTime:
               SetDataValueAsDateTime(Value, StrToDateTime(GetDataValueAsWideString(Value)));
            ftString,ftMemo,ftFmtMemo:
               SetDataValueAsString(Value, GetDataValueAsWideString(Value));
            ftWideString:
               Exit;
          end;
      ftMemo,ftFmtMemo:
          case FieldType of
            ftString:
             begin
               Value.DataType := ftString;
               if (not Value.IsNull) then
                begin
                 ReallocMem(Value.pData,Value.DataSize+1);
                 Inc(Value.DataSize);
                 PAnsiChar(Value.pData+Value.DataSize-1)^ := #0;
                end;
             end;
            ftWideString:
               SetDataValueAsWideString(Value, GetDataValueAsString(Value));
            ftMemo,ftFmtMemo:
               Exit;
          end;
    end;
  except
    raise ETblException.Create(02093,[GetDataTypeName(Value.DataType),
                                      GetDataTypeName(FieldType)], nil);
  end;
  // Cast complit?
  if (Value.DataType <> FieldType ) then
    raise ETblException.Create(02092,
       [GetDataTypeName(Value.DataType), GetDataTypeName(FieldType)], nil);
end;//Cast

//------------------------------------------------------------------------------
// value1 := value1 + value2
//------------------------------------------------------------------------------
procedure AddDataValues(var value1: TETblDataValue;
                        const value2: TETblDataValue;
                        IgnoreNULL: boolean = false);
var
  Data: TETblDataValue;
  CommonType: TFieldType;
begin
 // if one of operands is null
 if value1.IsNull or value2.IsNull then
  begin
   if IgnoreNULL then // N + NULL = N
    if value1.IsNull then CopyDataValue(value2, value1)
   else // N + NULL = NULL
    FinalizeDataValue(value1);
   Exit;
  end;

  InitDataValue(Data);
  CopyDataValue(value2, Data);
  // Types not equals
  if value1.DataType <> Data.DataType then
   begin
    CommonType := getCommonDataType(value1.DataType, Data.DataType);
    if value1.DataType <> CommonType then
         Cast(value1, CommonType);
    if Data.DataType <> CommonType then
       Cast(Data, CommonType);
   end;
   // Adding...
   case value1.DataType of
    ftSmallint: Inc(pSmallInt(value1.pData)^, pSmallInt(Data.pData)^);
    ftInteger,
    ftAutoInc:  Inc(pInteger(value1.pData)^, pInteger(Data.pData)^);
    ftWord:     Inc(pWord(value1.pData)^, pWord(Data.pData)^);
    ftLargeInt: Inc(pLargeInt(value1.pData)^, pLargeInt(Data.pData)^);
    ftFloat:    pFloat(value1.pData)^:= pFloat(value1.pData)^ +
                                      pFloat(Data.pData)^;
    ftCurrency: pCurrency(value1.pData)^:= pCurrency(value1.pData)^ +
                                      pCurrency(Data.pData)^;
    ftString:   SetDataValueAsString(value1, GetDataValueAsString(value1) +
                                          GetDataValueAsString(Data));
    ftWideString: SetDataValueAsWideString(value1, GetDataValueAsWideString(value1) +
                                             GetDataValueAsWideString(Data));
    ftDate:     SetDataValueAsDate(value1, GetDataValueAsDateTime(value1) +
                                           GetDataValueAsDateTime(Data));
    ftTime:     SetDataValueAsTime(value1, GetDataValueAsDateTime(value1) +
                                           GetDataValueAsDateTime(Data));
    ftDateTime: SetDataValueAsDateTime(value1, GetDataValueAsDateTime(value1) +
                                               GetDataValueAsDateTime(Data));
    else raise ETblException.Create(02091,['+'],nil);
  end;
  FinalizeDataValue(Data);
end;//AddDataValues


//------------------------------------------------------------------------------
// value := -value
//------------------------------------------------------------------------------
procedure NegativeDataValues(var value: TETblDataValue);
begin
 if value.IsNull then Exit;
 case value.DataType of
  ftSmallint: pSmallInt(value.pData)^ := -pSmallInt(value.pData)^;
  ftInteger,ftAutoInc:  pInteger(value.pData)^ := -pInteger(value.pData)^;
  ftWord:     pWord(value.pData)^ := -pWord(value.pData)^;
  ftLargeInt: pLargeInt(value.pData)^ := -pLargeInt(value.pData)^;
  ftFloat:    pFloat(value.pData)^ := -pFloat(value.pData)^;
  else raise ETblException.Create(02089,['-'],nil);
 end;
end;//NegativeDataValues


//------------------------------------------------------------------------------
// value1 := value1 * value2
//------------------------------------------------------------------------------
procedure MulDataValues(var value1: TETblDataValue;
                        const value2: TETblDataValue);
var
  Data: TETblDataValue;
  CommonType: TFieldType;
begin
  // if one of operands is null
  if ((value1.IsNull or value2.IsNull) or
      (not IsNumericDataType(value1.DataType)) or
      (not IsNumericDataType(value2.DataType))) then
   begin
    FinalizeDataValue(value1);
    Exit;
   end;

  InitDataValue(Data);
  CopyDataValue(value2, Data);
  // Types not equals
  if value1.DataType <> Data.DataType then
   begin
    CommonType := getCommonDataType(value1.DataType, Data.DataType);
    if value1.DataType <> CommonType then
         Cast(value1, CommonType);
    if Data.DataType <> CommonType then
       Cast(Data, CommonType);
   end;
   // Adding...
   case value1.DataType of
    ftSmallint:
      pSmallInt(value1.pData)^ := pSmallInt(value1.pData)^ *
                                  pSmallInt(Data.pData)^;
    ftInteger:
      pInteger(value1.pData)^ :=  pInteger(value1.pData)^ *
                                  pInteger(Data.pData)^;
    ftWord:
      pWord(value1.pData)^ := pWord(value1.pData)^ *
                              pWord(Data.pData)^;
    ftLargeInt:
      pLargeInt(value1.pData)^ := pLargeInt(value1.pData)^ *
                                  pLargeInt(Data.pData)^;
    ftFloat,
    ftCurrency:
      pFloat(value1.pData)^ := pFloat(value1.pData)^ *
                                      pFloat(Data.pData)^;
    else raise ETblException.Create(02091,['*'],nil);
  end;
  FinalizeDataValue(Data);
end;//MulDataValues


//------------------------------------------------------------------------------
// value1 := value1 / value2
//------------------------------------------------------------------------------
procedure DivDataValues(var value1: TETblDataValue;
                        const value2: TETblDataValue);
var
  Data: TETblDataValue;
begin
  // if one of operands is null
  if ((value1.IsNull or value2.IsNull) or
      (not IsNumericDataType(value1.DataType)) or
      (not IsNumericDataType(value2.DataType))) then
   begin
    FinalizeDataValue(value1);
    Exit;
   end;

  InitDataValue(Data);
  CopyDataValue(value2, Data);
  if ((value1.DataType = ftInteger) or (value1.DataType = ftAutoInc)) and
     ((Data.DataType = ftInteger) or (Data.DataType = ftAutoInc)) then
   begin
    // Process integer division
    pInteger(value1.pData)^:= pInteger(value1.pData)^ div pInteger(Data.pData)^;
   end
  else
   begin
    // cast all agrument to Float
    if value1.DataType <> ftFloat then Cast(value1, ftFloat);
    if Data.DataType <> ftFloat then Cast(Data, ftFloat);
    // Process division
    pFloat(value1.pData)^:= pFloat(value1.pData)^ / pFloat(Data.pData)^;
   end;
  FinalizeDataValue(Data);
end;//DivDataValues


//------------------------------------------------------------------------------
// value1 := Abs(value1)
//------------------------------------------------------------------------------
procedure AbsDataValues(var value1: TETblDataValue);
begin
  // if one of operands is null
  if (value1.IsNull or (not IsNumericDataType(value1.DataType)))  then
   begin
    FinalizeDataValue(value1);
    Exit;
   end;
 case value1.DataType of
  ftSmallint: if (pSmallInt(value1.pData)^ < 0) then
                pSmallInt(value1.pData)^ := -pSmallInt(value1.pData)^;
  ftInteger,
  ftAutoInc:  if (pInteger(value1.pData)^ < 0) then
                pInteger(value1.pData)^ := -pInteger(value1.pData)^;
  ftLargeInt: if (pLargeInt(value1.pData)^ < 0) then
                pLargeInt(value1.pData)^ := -pLargeInt(value1.pData)^;
  ftFloat:    if (pDouble(value1.pData)^ < 0) then
                pDouble(value1.pData)^ := -pDouble(value1.pData)^;
 end;
end; // AbsDataValues


//------------------------------------------------------------------------------
// value1 := Ceiling(value1)
//------------------------------------------------------------------------------
procedure CeilingDataValues(var value1: TETblDataValue);
var x: Integer;
begin
  // if one of operands is null
  if (value1.IsNull or (not IsNumericDataType(value1.DataType)))  then
   begin
    FinalizeDataValue(value1);
    Exit;
   end;
  if (not IsIntegerDataType(value1.DataType)) then
   begin
    x := Ceil(pDouble(value1.pData)^);
    SetDataValueAsNull(value1,ftInteger);
    SetDataValueAsInteger(value1,x);
   end;
end; // CeilingDataValues


//------------------------------------------------------------------------------
// value1 := Floor(value1)
//------------------------------------------------------------------------------
procedure FloorDataValues(var value1: TETblDataValue);
var x: Integer;
begin
  // if one of operands is null
  if (value1.IsNull or (not IsNumericDataType(value1.DataType)))  then
   begin
    FinalizeDataValue(value1);
    Exit;
   end;
  if (not IsIntegerDataType(value1.DataType)) then
   begin
    x := Floor(pDouble(value1.pData)^);
    SetDataValueAsNull(value1,ftInteger);
    SetDataValueAsInteger(value1,x);
   end;
end; // FloorDataValues


// value1 := value1 % value2
procedure ModDataValues(var value1: TETblDataValue;
                         const value2: TETblDataValue);
var
  Data: TETblDataValue;
begin
  // if one of operands is null or not numeric
  if ((value1.IsNull or value2.IsNull) or
      (not IsNumericDataType(value1.DataType)) or
      (not IsNumericDataType(value2.DataType))) then
   begin
    FinalizeDataValue(value1);
    Exit;
   end;

  InitDataValue(Data);
  CopyDataValue(value2, Data);
  try
    if (value1.DataType <> ftLargeint) then
     Cast(value1, ftLargeint);
    if (Data.DataType <> ftLargeint) then
     Cast(Data, ftLargeint);
    SetDataValueAsLargeInt(value1,pLargeInt(value1.pData)^ mod pLargeInt(Data.pData)^);
  finally
    FinalizeDataValue(Data);
  end;
end; // ModData


//------------------------------------------------------------------------------
// value1 := sign(value1)
//------------------------------------------------------------------------------
procedure SignDataValues(var value1: TETblDataValue);
var x: Integer;
begin
  // if one of operands is null
  x := 0;
  if (value1.IsNull or (not IsNumericDataType(value1.DataType)))  then
   begin
    FinalizeDataValue(value1);
    Exit;
   end;
  if (not IsIntegerDataType(value1.DataType)) then
   begin
    if (pDouble(value1.pData)^ > 0) then
     x := 1
    else
    if (pDouble(value1.pData)^ < 0) then
     x := -1;
   end
  else
   begin
    if (value1.DataType <> ftLargeInt) then
     Cast(value1,ftLargeInt);
    if (pLargeInt(value1.pData)^ > 0) then
     x := 1
    else
    if (pLargeInt(value1.pData)^ < 0) then
     x := -1;
   end;
 SetDataValueAsNull(value1,ftInteger);
 SetDataValueAsInteger(value1,x);
end; // SignDataValues


//------------------------------------------------------------------------------
// value1 := Random ([value1])
//------------------------------------------------------------------------------
procedure RandomDataValues(var value1: TETblDataValue; ByRange: Boolean = false);
var x: Integer;
begin
 if (ByRange) then
  begin
   if (value1.DataType <> ftLargeint) then
    Cast(value1, ftLargeint);
   x := Random(pLargeInt(value1.pData)^);
   SetDataValueAsNull(value1,ftLargeint);
   SetDataValueAsLargeInt(value1,x);
  end
 else
  begin
   SetDataValueAsNull(value1,ftFloat);
   SetDataValueAsFloat(value1,Random);
  end;
end; // RandomDataValues


//------------------------------------------------------------------------------
// value1 := value1 ^ value2
//------------------------------------------------------------------------------
procedure PowerDataValues(var value1: TETblDataValue;
                         const value2: TETblDataValue);
var
  Data: TETblDataValue;
  e:    Extended;
begin
  // if one of operands is null or not numeric
  if ((value1.IsNull or value2.IsNull) or
      (not IsNumericDataType(value1.DataType)) or
      (not IsNumericDataType(value2.DataType))) then
   begin
    FinalizeDataValue(value1);
    Exit;
   end;

  InitDataValue(Data);
  CopyDataValue(value2, Data);
  try
    if (IsIntegerDataType(value1.DataType)) then
     begin
      if (value1.DataType <> ftLargeint) then
       Cast(value1, ftLargeint);
      if (Data.DataType <> ftLargeint) then
       Cast(Data, ftLargeint);
      e := Power(pLargeInt(value1.pData)^,pLargeInt(Data.pData)^);
      SetDataValueAsNull(value1,ftLargeint);
      SetDataValueAsLargeInt(value1,Round(e));
     end
    else
     begin
      if (value1.DataType <> ftFloat) then
       Cast(value1, ftFloat);
      if (Data.DataType <> ftFloat) then
       Cast(Data, ftFloat);
      e := Power(pDouble(value1.pData)^,pDouble(Data.pData)^);
      SetDataValueAsNull(value1,ftFloat);
      SetDataValueAsFloat(value1,e);
     end;
  finally
    FinalizeDataValue(Data);
  end;
end; // PowerDataValues


//------------------------------------------------------------------------------
// value1 := Round(value1 [,value2])
//------------------------------------------------------------------------------
procedure RoundDataValues(var value1:   TETblDataValue;
                           const value2: TETblDataValue;
                           UsePrecision: Boolean
                         );
var
  Data: TETblDataValue;
  e:     Double;
  x:     Int64;
  p,y,i: Integer;
begin
  // if one of operands is null or not numeric
  if ((value1.IsNull or value2.IsNull) or
      (not IsNumericDataType(value1.DataType)) or
      (IsIntegerDataType(value1.DataType)) or
      (not IsNumericDataType(value2.DataType))) then
   begin
    FinalizeDataValue(value1);
    Exit;
   end;
  if (UsePrecision) then
   begin
     InitDataValue(Data);
     try
      CopyDataValue(value2,Data);
      if (value1.DataType <> ftFloat) then
       Cast(value1, ftFloat);
      if (Data.DataType <> ftInteger) then
       Cast(Data, ftInteger);
      p := pInteger(Data.pData)^;
      e := 0.5;
      y := 1;
      for i := 1 to p do
       begin
        e := e / 10;
        y := y * 10;
       end;
      e := pDouble(value1.pData)^ + e;
      e := Trunc(e * y) / y;
      SetDataValueAsNull(value1,ftFloat);
      SetDataValueAsFloat(value1,e);
    finally
      FinalizeDataValue(Data);
    end;
   end
  else
   begin
    if (value1.DataType <> ftFloat) then
     Cast(value1, ftFloat);
    x := Trunc(pDouble(value1.pData)^ + 0.5);
    SetDataValueAsNull(value1,ftLargeint);
    SetDataValueAsLargeInt(value1,x);
   end;
end; // RoundDataValues


//------------------------------------------------------------------------------
// value1 := Truncate(value1 [,value2])
//------------------------------------------------------------------------------
procedure TruncateDataValues(var value1:   TETblDataValue;
                           const value2: TETblDataValue;
                           UsePrecision: Boolean
                         );
var
  Data: TETblDataValue;
  e:     Double;
  x:     Int64;
  p,y,i: Integer;
begin
  // if one of operands is null or not numeric
  if ((value1.IsNull or value2.IsNull) or
      (not IsNumericDataType(value1.DataType)) or
      (IsIntegerDataType(value1.DataType)) or
      (not IsNumericDataType(value2.DataType))) then
   begin
    FinalizeDataValue(value1);
    Exit;
   end;
  if (UsePrecision) then
   begin
     InitDataValue(Data);
     try
      CopyDataValue(value2,Data);
      if (value1.DataType <> ftFloat) then
       Cast(value1, ftFloat);
      if (Data.DataType <> ftInteger) then
       Cast(Data, ftInteger);
      p := pInteger(Data.pData)^;
      y := 1;
      for i := 1 to p do
       begin
        e := e / 10;
        y := y * 10;
       end;
      e := pDouble(value1.pData)^;
      e := Trunc(e * y) / y;
      SetDataValueAsNull(value1,ftFloat);
      SetDataValueAsFloat(value1,e);
    finally
      FinalizeDataValue(Data);
    end;
   end
  else
   begin
    if (value1.DataType <> ftFloat) then
     Cast(value1, ftFloat);
    x := Trunc(pDouble(value1.pData)^ );
    SetDataValueAsNull(value1,ftLargeint);
    SetDataValueAsLargeInt(value1,x);
   end;
end; // Truncate


// value1 := value1 AND value2
procedure AndDataValues(var value1: TETblDataValue;
                         const value2: TETblDataValue);
var
  Data:       TETblDataValue;
  CommonType: TFieldType;
begin
  if ((value1.IsNull or value2.IsNull) or
     ((not IsIntegerDataType(value1.DataType)) or
       (not IsIntegerDataType(value2.DataType)))) then
   begin
    FinalizeDataValue(value1);
    Exit;
   end;
   // integer
  InitDataValue(Data);
  CopyDataValue(value2, Data);
  try
    // Types not equals
    if value1.DataType <> Data.DataType then
     begin
      CommonType := getCommonDataType(value1.DataType, Data.DataType);
      if value1.DataType <> CommonType then
           Cast(value1, CommonType);
      if Data.DataType <> CommonType then
         Cast(Data, CommonType);
     end;
    case value1.DataType of
      ftSmallint: pSmallInt(value1.pData)^ := pSmallInt(value1.pData)^ AND
                                              pSmallInt(Data.pData)^;
      ftInteger,
      ftAutoInc:  pInteger(value1.pData)^ := pInteger(value1.pData)^ AND
                                             pInteger(Data.pData)^;
      ftWord:     pWord(value1.pData)^ := pWord(value1.pData)^ AND
                                          pWord(Data.pData)^;
      ftLargeInt: pLargeInt(value1.pData)^ := pLargeInt(value1.pData)^ AND
                                              pLargeInt(Data.pData)^;
    end;
  finally
    FinalizeDataValue(Data);
  end;
end; // AndData


// value1 := value1 OR value2
procedure OrDataValues(var value1: TETblDataValue;
                         const value2: TETblDataValue);
var
  Data:       TETblDataValue;
  CommonType: TFieldType;
begin
  if ((value1.IsNull or value2.IsNull) or
     ((not IsIntegerDataType(value1.DataType)) or
       (not IsIntegerDataType(value2.DataType)))) then
    begin
     FinalizeDataValue(value1);
     Exit;
    end;

  InitDataValue(Data);
  CopyDataValue(value2, Data);
  try
    // Types not equals
    if value1.DataType <> Data.DataType then
     begin
      CommonType := getCommonDataType(value1.DataType, Data.DataType);
      if value1.DataType <> CommonType then
           Cast(value1, CommonType);
      if Data.DataType <> CommonType then
         Cast(Data, CommonType);
     end;
    case value1.DataType of
      ftSmallint: pSmallInt(value1.pData)^ := pSmallInt(value1.pData)^ OR
                                              pSmallInt(Data.pData)^;
      ftInteger,
      ftAutoInc:  pInteger(value1.pData)^ := pInteger(value1.pData)^ OR
                                             pInteger(Data.pData)^;
      ftWord:     pWord(value1.pData)^ := pWord(value1.pData)^ OR
                                          pWord(Data.pData)^;
      ftLargeInt: pLargeInt(value1.pData)^ := pLargeInt(value1.pData)^ OR
                                              pLargeInt(Data.pData)^;
    end;
  finally
    FinalizeDataValue(Data);
  end;
end; // OrData


// value1 := NOT value1
procedure NotDataValues(var value1: TETblDataValue);
var
  b:          Boolean;
begin
  // if one of operands is null or not numeric
  if (value1.IsNull or
     (not IsIntegerDataType(value1.DataType))) then
   begin
    FinalizeDataValue(value1);
    Exit;
   end;
  // Types not equals
  case value1.DataType of
    ftSmallint: pSmallInt(value1.pData)^ := NOT pSmallInt(value1.pData)^;
    ftInteger,
    ftAutoInc:  pInteger(value1.pData)^ := NOT pInteger(value1.pData)^;
    ftWord:     pWord(value1.pData)^ := NOT pWord(value1.pData)^;
    ftLargeInt: pLargeInt(value1.pData)^ := NOT pLargeInt(value1.pData)^;
   else
    SetDataValueAsNull(value1,ftInteger);
  end;
end; // NotData


// value1 := value1 SHL value2
procedure ShlDataValues(var value1: TETblDataValue;
                         const value2: TETblDataValue);
var
  Data:       TETblDataValue;
  CommonType: TFieldType;
begin
  // if one of operands is null or not numeric
  if ((value1.IsNull or value2.IsNull) or
      (not IsIntegerDataType(value1.DataType)) or
      (not IsIntegerDataType(value2.DataType))) then
   begin
    FinalizeDataValue(value1);
    Exit;
   end;
  InitDataValue(Data);
  CopyDataValue(value2, Data);
  try
    // Types not equals
    if value1.DataType <> Data.DataType then
     begin
      CommonType := getCommonDataType(value1.DataType, Data.DataType);
      if value1.DataType <> CommonType then
           Cast(value1, CommonType);
      if Data.DataType <> CommonType then
         Cast(Data, CommonType);
     end;
    case value1.DataType of
      ftSmallint: pSmallInt(value1.pData)^ := pSmallInt(value1.pData)^ SHL
                                              pSmallInt(Data.pData)^;
      ftInteger,
      ftAutoInc:  pInteger(value1.pData)^ := pInteger(value1.pData)^ SHL
                                             pInteger(Data.pData)^;
      ftWord:     pWord(value1.pData)^ := pWord(value1.pData)^ SHL
                                          pWord(Data.pData)^;
      ftLargeInt: pLargeInt(value1.pData)^ := pLargeInt(value1.pData)^ SHL
                                              pLargeInt(Data.pData)^;
    end;
  finally
    FinalizeDataValue(Data);
  end;
end; // ShlData


// value1 := value1 SHR value2
procedure ShrDataValues(var value1: TETblDataValue;
                         const value2: TETblDataValue);
var
  Data:       TETblDataValue;
  CommonType: TFieldType;
begin
  // if one of operands is null or not numeric
  if ((value1.IsNull or value2.IsNull) or
      (not IsIntegerDataType(value1.DataType)) or
      (not IsIntegerDataType(value2.DataType))) then
   begin
    FinalizeDataValue(value1);
    Exit;
   end;

  InitDataValue(Data);
  CopyDataValue(value2, Data);
  try
    // Types not equals
    if value1.DataType <> Data.DataType then
     begin
      CommonType := getCommonDataType(value1.DataType, Data.DataType);
      if value1.DataType <> CommonType then
           Cast(value1, CommonType);
      if Data.DataType <> CommonType then
         Cast(Data, CommonType);
     end;
    case value1.DataType of
      ftSmallint: pSmallInt(value1.pData)^ := pSmallInt(value1.pData)^ SHR
                                              pSmallInt(Data.pData)^;
      ftInteger,
      ftAutoInc:  pInteger(value1.pData)^ := pInteger(value1.pData)^ SHR
                                             pInteger(Data.pData)^;
      ftWord:     pWord(value1.pData)^ := pWord(value1.pData)^ SHR
                                          pWord(Data.pData)^;
      ftLargeInt: pLargeInt(value1.pData)^ := pLargeInt(value1.pData)^ SHR
                                              pLargeInt(Data.pData)^;
    end;
  finally
    FinalizeDataValue(Data);
  end;
end; // ShrData


// value1 := value1 XOR value2
procedure XorDataValues(var value1: TETblDataValue;
                         const value2: TETblDataValue);
var
  Data:       TETblDataValue;
  CommonType: TFieldType;
begin
  // if one of operands is null or not numeric
  if ((value1.IsNull or value2.IsNull) or
      (not IsIntegerDataType(value1.DataType)) or
      (not IsIntegerDataType(value2.DataType))) then
   begin
    FinalizeDataValue(value1);
    Exit;
   end;

  InitDataValue(Data);
  CopyDataValue(value2, Data);
  try
    // Types not equals
    if value1.DataType <> Data.DataType then
     begin
      CommonType := getCommonDataType(value1.DataType, Data.DataType);
      if value1.DataType <> CommonType then
           Cast(value1, CommonType);
      if Data.DataType <> CommonType then
         Cast(Data, CommonType);
     end;
    case value1.DataType of
      ftSmallint: pSmallInt(value1.pData)^ := pSmallInt(value1.pData)^ XOR
                                              pSmallInt(Data.pData)^;
      ftInteger,
      ftAutoInc:  pInteger(value1.pData)^ := pInteger(value1.pData)^ XOR
                                             pInteger(Data.pData)^;
      ftWord:     pWord(value1.pData)^ := pWord(value1.pData)^ XOR
                                          pWord(Data.pData)^;
      ftLargeInt: pLargeInt(value1.pData)^ := pLargeInt(value1.pData)^ XOR
                                              pLargeInt(Data.pData)^;
    end;
  finally
    FinalizeDataValue(Data);
  end;
end; // XorData


//------------------------------------------------------------------------------
// value1 := Hex(value1 [, value2])
//------------------------------------------------------------------------------
procedure HexDataValues(var value1: TETblDataValue;
                         const value2: TETblDataValue;
                         const ModeExists: Boolean
                        );
var
  Format:     Integer;
  Res:        AnsiString;
begin
  // if one of operands is null or not numeric

  if ((value1.IsNull) or
      ((not IsStringDataType(value1.DataType)) and (not IsIntegerDataType(value1.DataType)))
     ) then
   begin
    FinalizeDataValue(value1);
    Exit;
   end;
   Format := 0;
   if (ModeExists) then
    Format := GetDataValueAsInteger(value2);

   if (Format = 1) then
    Res := '$'
   else
   if (Format = 2) then
    Res := '0x'
   else
    Res := '';
   case value1.DataType of
      ftSmallint: Res := Res + IntToHex(pSmallInt(value1.pData)^,4);
      ftInteger,
      ftAutoInc:  Res := Res + IntToHex(pInteger(value1.pData)^,8);
      ftWord:     Res := Res + IntToHex(pWord(value1.pData)^,4);
      ftLargeInt: Res := Res + IntToHex(pLargeInt(value1.pData)^,16);
      ftString,ftWideString: Res := Res +
                  StrToHexValue(value1.pData,
                    GetStrLength(value1.pData,(value1.DataType = ftWideString)));
   end;
//   SetDataValueAsNull(value1,ftString);
   if (Format = 2) then
    Res := LowerCase(Res);
   SetDataValueAsString(value1,Res);
end; // HexData


//------------------------------------------------------------------------------
// get data type name
//------------------------------------------------------------------------------
function GetDataTypeName(dt: TFieldType): AnsiString;
begin
  Result:='unknown';
  case dt of
    ftAutoInc:      Result := 'AutoInc';
    ftInteger:      Result := 'Integer';
    ftSmallInt:     Result := 'SmallInt';
    ftWord:         Result := 'Word';
    ftLargeInt:     Result := 'LargeInt';
    ftFloat:        Result := 'Float';
    ftBoolean:      Result := 'Boolean';
    ftCurrency:     Result := 'Currency';
    ftDate:         Result := 'Date';
    ftTime:         Result := 'Time';
    ftDateTime:     Result := 'DateTime';
    ftString:       Result := 'String';
    ftWideString:   Result := 'WideString';
  end;
end;//GetDataTypeName

// get operator name
function GetOperatorName(op: TETblDataOperator): AnsiString;
begin
  case op of
    doNOT:          Result := 'NOT';
    doAND:          Result := 'AND';
    doOR:           Result := 'OR';
    doEQ:           Result := '=';
    doNE:           Result := '<>';
    doLT:           Result := '<';
    doGT:           Result := '>';
    doLE:           Result := '<=';
    doGE:           Result := '>=';
    doLIKE:         Result := 'LIKE';
    doNOTLIKE:      Result := 'NOT LIKE';
    doISNULL:       Result := 'IS NULL';
    doISNULLFUNCTION: Result := 'ISNULL';
    doISNOTNULL:    Result := 'IS NOT NULL';
    doADD:          Result := '+';
    doSUB:          Result := '-';
    doMUL:          Result := '*';
    doDIV:          Result := '/';
    doCONCAT:       Result := '||';
    // 6.10
    doUPPER:        Result := 'UPPER';
    doLOWER:        Result := 'LOWER';
    doTRIM:         Result := 'TRIM';
    doLTRIM:        Result := 'LTRIM';
    doRTRIM:        Result := 'RTRIM';
    doSUM:          Result := 'SUM';
    doAVG:          Result := 'AVG';
    doMIN:          Result := 'MIN';
    doMAX:          Result := 'MAX';
    doCOUNT:        Result := 'COUNT';
    doCOUNTALL:     Result := 'COUNT(*)';
    doYEAR:         Result := 'YEAR';
    doQUARTER:      Result := 'QUARTER';
    doMONTH:        Result := 'MONTH';
    doDAY:          Result := 'DAY';
    doWEEKDAY:      Result := 'WEEKDAY';
    doDAYOFWEEK:    Result := 'DAYOFWEEK';
    doDAYNAME:      Result := 'DAYNAME';
    doMONTHNAME:    Result := 'MONTHNAME';
    doHOUR:         Result := 'HOUR';
    doMINUTE:       Result := 'MINUTE';
    doSECOND:       Result := 'SECOND';
    doMSECOND:      Result := 'MSECOND';
    //6.30
    doABS:          Result := 'ABS';
    doCEILING:      Result := 'CEILING';
    doFLOOR:        Result := 'FLOOR';
    doMOD:          Result := 'MOD';
    doPOWER:        Result := 'POWER';
    doRANDOM:       Result := 'RANDOM';
    doROUND:        Result := 'ROUND';
    doSIGN:         Result := 'SIGN';
    doTRUNCATE:     Result := 'TRUNCATE';
    doSHL:          Result := 'SHL';
    doSHR:          Result := 'SHR';
    doXOR:          Result := 'XOR';
    doHEX:          Result := 'HEX'
    else            Result:='unknown';
  end;
end;//GetOperatorName


// Return true, if DataType is Numeric (int,word, float,...)
function IsNumericDataType(dt: TFieldType): boolean;
begin
 Result:=false;
 if dt in [ftAutoInc, ftInteger, ftSmallInt,
           ftWord, ftLargeInt, ftFloat, ftCurrency] then
   Result := true;
end;

// Return true, if DataType is integer (int,word, ...)
function IsIntegerDataType(dt: TFieldType): boolean;
begin
 Result:=false;
 if dt in [ftAutoInc, ftInteger, ftSmallInt,
           ftWord, ftLargeInt] then
   Result := true;
end;

// return true if string
function IsStringDataType(dt: TFieldType): boolean;
begin
 Result:=false;
 if dt in [ftstring, ftWideString] then
   Result := true;
end;

//------------------------------------------------------------------------------
// Return FieldType
//------------------------------------------------------------------------------
function GetFieldType(const TypeName: AnsiString): TFieldType;
var
  i: Integer;
  s: AnsiString;
begin
  Result := ftUnknown;
  s := UpperCase(TypeName);
  if s = 'BOOLEAN' then s := 'LOGICAL';
  if (s = 'CHAR') or (s = 'VARCHAR') or (s = 'VARCHAR2') then s := 'STRING';
  for i:=1 to MAX_SUPPORTED_FIELD_TYPES do
    if SUPPORTED_FIELD_TYPES[i].sqlName = s then
      begin
        Result := SUPPORTED_FIELD_TYPES[i].fieldType;
        break;
      end;
end;//GetFieldType


//------------------------------------------------------------------------------
// return length of null-terminated string
//------------------------------------------------------------------------------
function GetStrLength(Buffer: PAnsiChar; bUnicode: Boolean): Integer;
var i: Integer;
begin
 if (bUnicode) then
  begin
    //Result := Length(WideCharToAnsiString(PWideChar(Buffer))) * 2
    i := 0;
    while (True) do
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


function StrToHexValue(Text: PAnsiChar; Size: Integer): AnsiString;
begin
 // dec util
 Result := StrToFormat(Text,Size,fmtHEX);
end;

end.
