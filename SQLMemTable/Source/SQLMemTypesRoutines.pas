unit SQLMemTypesRoutines;

interface

{$I SQLMemVer.Inc}

uses
     SQLMemTypes,
     SQLMemConverts,
     SQLMemExcept,
     SQLMemConst,
     SQLMemMemory
     ;


//  Return DataSize
function GetDataSizeInMemory(DataType: TSQLMemBaseFieldType; Length: Integer = 0): Integer; overload;

//  Return DataSize
function GetDataSizeInMemory(DataType: TSQLMemBaseFieldType; Data: Pointer): Integer; overload;

// Allocate Memory and Set Data
procedure AllocMemAndSetData(DataType: TSQLMemBaseFieldType; const Value; out Buffer; out BufferSize: Integer);


implementation


//------------------------------------------------------------------------------
//  Return DataSize
//------------------------------------------------------------------------------
function GetDataSizeInMemory(DataType: TSQLMemBaseFieldType; Length: Integer): Integer;
begin
  case DataType of
    bftChar,            // AsciZ
    bftVarchar:         Result := Length + 1;
    bftWideChar,
    bftWideVarchar:     Result := (Length + 1) * 2;

    bftSignedInt8:      Result := SizeOf(Shortint);
    bftSignedInt16:     Result := SizeOf(Smallint);
    bftSignedInt32:     Result := SizeOf(Integer);
    bftSignedInt64:     Result := SizeOf(Int64);
    bftUnSignedInt8:    Result := SizeOf(Byte);
    bftUnSignedInt16:   Result := SizeOf(Word);
    bftUnSignedInt32:   Result := SizeOf(Cardinal);

    bftSingle:          Result := SizeOf(Single);
    bftDouble:          Result := SizeOf(Double);
    bftExtended:        Result := SizeOf(Extended);

    bftDate:            Result := SizeOf(TSQLMemDate);
    bftTime:            Result := SizeOf(TSQLMemTime);
    bftDateTime:        Result := SizeOf(TSQLMemDateTime);

    // fixed in v.12.10 - 64 bit pointers
{$IFDEF X64_ON}
    bftBlob,
    bftClob,
    bftWideClob:        Result := SizeOf(Int64)+SizeOf(Word); // 10
{$ELSE}
    bftBlob,
    bftClob,
    bftWideClob:        Result := SizeOf(Int64); // 10
{$ENDIF}

    bftLogical:         Result := SizeOf(TSQLMemLogical);
    bftCurrency:        Result := SizeOf(TSQLMemCurrency);
    bftBytes:           Result := Length;
    bftVarBytes:        Result := Length;
    else
      raise ESQLMemException.Create(30050, ErrorGUnknownDataType, [BftToStr(DataType)]);
  end;
end;//GetDataSizeInMemory


//------------------------------------------------------------------------------
//  Return DataSize
//------------------------------------------------------------------------------
function GetDataSizeInMemory(DataType: TSQLMemBaseFieldType; Data: Pointer): Integer; overload;
begin
//  Result := -1;
  case DataType of
    bftChar,
    bftVarchar:
        Result := GetDataSizeInMemory(DataType, Length(PAnsiChar(Data)));
    bftWideChar,
    bftWideVarchar:
        Result := GetDataSizeInMemory(DataType, Length(PWideChar(Data)));
    else
        Result := GetDataSizeInMemory(DataType);
  end;
end;//GetDataSizeInMemory


//------------------------------------------------------------------------------
// Allocate Memory and Set Data
//------------------------------------------------------------------------------
procedure AllocMemAndSetData(DataType: TSQLMemBaseFieldType;
                             const Value;
                             out Buffer;
                             out BufferSize: Integer);
const w: Word = 0;
var len: Integer;
    ws:  WideString;
    s:   AnsiString;
begin
  Pointer(Buffer) := nil;
  try
    case DataType of
      bftChar,
      bftVarchar:
        begin
          s := AnsiString(Value);
          len := Length(s);
//          len := GetStrLength(@s[1],aftChar);
          if (len = 0) then
           begin
            BufferSize := 0;
           end
          else
           begin
// changed in 4.80
            BufferSize := GetDataSizeInMemory(DataType,len);
            Pointer(Buffer) := MemoryManager.AllocMem(BufferSize);
//            Move(PAnsiChar(Value)^, PAnsiChar(Buffer)^, BufferSize);
            Move(PAnsiChar(@s[1])^, PAnsiChar(Buffer)^, len);

//            Move(PAnsiChar(AnsiString(Value))^, PAnsiChar(Buffer)^, len);
//            FillChar(PAnsiChar(PAnsiChar(Buffer)+BufferSize-1)^,1,$00);
//            Move(PAnsiChar(AnsiString(Value))^, PAnsiChar(Buffer)^, BufferSize);
           end;
        end;
      bftWideChar,
      bftWideVarchar:
        begin
          ws := WideString(Value);
//          len := GetStrLength(@ws[1],aftWideChar) div 2;
          len := Length(ws);
          if (len = 0) then
           begin
            BufferSize := 0;
           end
          else
           begin
// changed in 4.80
{
            BufferSize := len+2;
            Pointer(Buffer) := MemoryManager.GetMem(BufferSize);
            Move(Value, PAnsiChar(Buffer)^, BufferSize-2);
            Move(w, PAnsiChar(PAnsiChar(Buffer)+BufferSize-2)^, 2);
}
//            BufferSize := GetDataSizeInMemory(DataType,len);
            BufferSize := GetDataSizeInMemory(DataType,len);
            Pointer(Buffer) := MemoryManager.AllocMem(BufferSize);
            Move(ws[1], PAnsiChar(Buffer)^, len*2);
//            Move(PWideChar(Value)^, PAnsiChar(Buffer)^, BufferSize);

           end;
        end;
      else
        begin
          BufferSize := GetDataSizeInMemory(DataType);
          Pointer(Buffer) := MemoryManager.GetMem(BufferSize);
          case BufferSize of
{
// commented in 4.40
            1:      PByte(Buffer)^ := Byte(Value);
            2:      PWord(Buffer)^ := Word(Value);
            4:      PInteger(Buffer)^ := Integer(Value);
            8:      PInt64(Buffer)^ := Int64(Value);
}
            10:     PExtended(Buffer)^ := Extended(Value);
            else    Move(Value, PAnsiChar(Buffer)^, BufferSize);
          end;
        end;
    end;
  except
    if Pointer(Buffer) <> nil then
      raise ESQLMemException.Create(30054, ErrorGCannotCopyDataIntoNewMemory);
  end;
end;//AllocMemAndSetData

initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('SQLMemTypesRoutines> initialized');
{$ENDIF}
  SQLMemMemoryIncUseCount;

finalization

  SQLMemMemoryDecUseCount;


end.

