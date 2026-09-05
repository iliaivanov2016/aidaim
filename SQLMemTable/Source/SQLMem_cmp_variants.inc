// replacement for TSQLMemVariant.compare

if (CMP_VAR_PartialKey) then
// changed from Min in 4.80
//    CMP_VAR_PartialKeyLength := min(StrLen, Value.StrLen)
// Partial key always MUST BE IN Value
 CMP_BUF_PartialCompareLength := CMP_VAR_Value2.StrLen
else
 CMP_BUF_PartialCompareLength := -1;
// patch for memo fields
if (not CMP_VAR_Value1.IsNull) and (not CMP_VAR_Value2.IsNull) and
   (IsBLOBFieldType(CMP_VAR_Value2.DataType)) and (IsStringFieldType(CMP_VAR_Value1.DataType)) and
   (not IsBLOBFieldType(CMP_VAR_Value1.DataType)) then
  CMP_VAR_Result := CMP_VAR_Value2.CompareMemoAndAnsiString(
      True,CMP_VAR_Value1,CMP_VAR_TrueFalseNullLogic,
      CMP_VAR_CaseInsensitive,CMP_VAR_PartialKey)
else
if (not CMP_VAR_Value1.IsNull) and (not CMP_VAR_Value2.IsNull) and
   (IsBLOBFieldType(CMP_VAR_Value1.DataType)) and (IsStringFieldType(CMP_VAR_Value2.DataType)) and
   (not IsBLOBFieldType(CMP_VAR_Value2.DataType)) then
  CMP_VAR_Result := CMP_VAR_Value1.CompareMemoAndAnsiString(
    False,CMP_VAR_Value2,CMP_VAR_TrueFalseNullLogic,CMP_VAR_CaseInsensitive,CMP_VAR_PartialKey)
else
begin
{
  if (PInteger(CMP_VAR_Value1.PData)^ = PInteger(CMP_VAR_Value2.PData)^) then
   CMP_VAR_Result := cmprEqual
  else
  if (PInteger(CMP_VAR_Value1.PData)^ > PInteger(CMP_VAR_Value2.PData)^) then
   CMP_VAR_Result := cmprGreater
  else
   CMP_VAR_Result := cmprLower;
}
end;

// set params
CMP_BUF_Buffer1 := CMP_VAR_Value1.PData;
CMP_BUF_Buffer2 := CMP_VAR_Value2.PData;
CMP_BUF_BaseFieldType1 := CMP_VAR_Value1.FDataType;
CMP_BUF_BaseFieldType2 := CMP_VAR_Value2.FDataType;
CMP_BUF_IsField1Null := CMP_VAR_Value1.FIsNull;
CMP_BUF_IsField2Null := CMP_VAR_Value2.FIsNull;
//CMP_BUF_PartialCompareLength  already set
CMP_BUF_IgnoreCase := CMP_VAR_CaseInsensitive;
{$IFDEF MSWINDOWS}
CMP_BUF_LocaleID := LOCALE_USER_DEFAULT;
{$ENDIF}
{$I SQLMem_cmp_buffers.Inc}
CMP_VAR_Result := CMP_BUF_Result;
{
  CMP_VAR_Result := CompareValueBuffers(CMP_VAR_Value1.PData, CMP_VAR_Value2.PData,
                              CMP_VAR_Value1.DataType, CMP_VAR_Value2.DataType,
                              CMP_VAR_Value1.IsNull, CMP_VAR_Value2.IsNull,
                              CMP_BUF_PartialCompareLength, CMP_VAR_CaseInsensitive);
}
if (not CMP_VAR_TrueFalseNullLogic) then
case CMP_VAR_Result of
  cmprBothNull:
    CMP_VAR_Result := cmprEqual;
  cmprLeftNull:
    CMP_VAR_Result := cmprLower;
  cmprRightNull:
    CMP_VAR_Result := cmprGreater;
end; // True/False logic (not TrueFalseNull)


{
//------------------------------------------------------------------------------
// Compare with another Variants
//------------------------------------------------------------------------------
function TSQLMemVariant.CompareMemoAndAnsiString(
                              ReverseResult: Boolean;
                              Str: TSQLMemVariant;
                              TrueFalseNullLogic: boolean = True;
                              CaseInsensitive: boolean = True;
                              PartialKey: boolean = False
                            ): TSQLMemCompareResult;
var buf:  PAnsiChar;
    i:    Integer;
begin
  if (not IsWideStringFieldType(Str.DataType)) then
   begin
    buf := MemoryManager.GetMem(DataSize+1);
    try
      Move(FPData^,buf^,FDataSize);
      FillChar(PAnsiChar(buf+FDataSize)^,1,$00);
      if (PartialKey) then
  // changed from Min in 4.80
// Partial key always MUST BE IN Str
//        i := min(FDataSize, Str.StrLen)
       i := Str.StrLen
      else
        i := -1;
      if (not ReverseResult) then
       Result := CompareValueBuffers(buf, Str.FPData,
                                Str.DataType, Str.DataType,
                                IsNull, Str.IsNull,
                                i, CaseInsensitive)
      else
       Result := CompareValueBuffers(Str.FPData,buf,
                                Str.DataType, Str.DataType,
                                Str.IsNull, IsNull,
                                i, CaseInsensitive)
    finally
      MemoryManager.FreeAndNilMem(buf);
    end;
   end // AnsiString
  else
   begin
    buf := MemoryManager.GetMem(DataSize+2);
    try
      Move(FPData^,buf^,FDataSize);
      FillChar(PAnsiChar(buf+FDataSize)^,2,$00);
      if (PartialKey) then
  // changed from Min in 4.80
// Partial key always MUST BE IN Str
//        i := min((FDataSize div 2), Str.StrLen)
        i := Str.StrLen
      else
        i := -1;
      if (not ReverseResult) then
       Result := CompareValueBuffers(buf, Str.FPData,
                                Str.DataType, Str.DataType,
                                IsNull, Str.IsNull,
                                i, CaseInsensitive)
      else
       Result := CompareValueBuffers(Str.FPData,buf,
                                Str.DataType, Str.DataType,
                                Str.IsNull, IsNull,
                                i, CaseInsensitive)
    finally
      MemoryManager.FreeAndNilMem(buf);
    end;
   end; // wide AnsiString

end; // CompareMemoAndAnsiString



}
