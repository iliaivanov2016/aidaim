 CMP_BUF_Result := cmprEqual;
 // Check NULLs
 if (CMP_BUF_IsField1Null or CMP_BUF_IsField2Null) then
 begin
   if (CMP_BUF_IsField1Null and CMP_BUF_IsField2Null) then
    CMP_BUF_Result := cmprBothNull
   else
   if (CMP_BUF_IsField1Null) then
     CMP_BUF_Result := cmprLeftNull
   else
     CMP_BUF_Result := cmprRightNull;
 end // Null
 else
 begin
  CMP_BUF_NewBuffer1 := nil;
  CMP_BUF_NewBuffer2 := nil;
  try
  // Cast both to common Type
  if (CMP_BUF_BaseFieldType1 = CMP_BUF_BaseFieldType2) then
   begin
     CMP_BUF_Value1 := CMP_BUF_Buffer1;
     CMP_BUF_Value2 := CMP_BUF_Buffer2;
     CMP_BUF_CommonType := CMP_BUF_BaseFieldType1;
   end
  else
   begin
     CMP_BUF_CommonType := GetCommonDataType(CMP_BUF_BaseFieldType1, CMP_BUF_BaseFieldType2);
     // Cannot compare
     if (CMP_BUF_CommonType = bftUnknown) then
       raise ESQLMemException.Create(30044, ErrorGCatnnotCompareIncompatibleDataTypes,
                                  [bftToStr(CMP_BUF_BaseFieldType1), bftToStr(CMP_BUF_BaseFieldType2)]);
     // Optimized in v.4.80
     CMP_BUF_bDoNotCast := SQLMemIsCastNotNeeded(CMP_BUF_CommonType,CMP_BUF_BaseFieldType1);
     // Cast 1-st parameter
     if ((not CMP_BUF_bDoNotCast) and (CMP_BUF_CommonType <> CMP_BUF_BaseFieldType1)) then
       begin
         CMP_BUF_NewBuffer1 := CastToNewBuffer(CMP_BUF_Buffer1, CMP_BUF_BaseFieldType1, CMP_BUF_CommonType);
         CMP_BUF_Value1 := CMP_BUF_NewBuffer1;
       end
     else
       CMP_BUF_Value1 := CMP_BUF_Buffer1;

     // fixed in 5.01
     CMP_BUF_bDoNotCast := SQLMemIsCastNotNeeded(CMP_BUF_CommonType,CMP_BUF_BaseFieldType2);
     // Cast 2-nd parameter
     if ((not CMP_BUF_bDoNotCast) and (CMP_BUF_CommonType <> CMP_BUF_BaseFieldType2)) then
       begin
         CMP_BUF_NewBuffer2 := CastToNewBuffer(CMP_BUF_Buffer2, CMP_BUF_BaseFieldType2, CMP_BUF_CommonType);
         CMP_BUF_Value2 := CMP_BUF_NewBuffer2;
       end
     else
       CMP_BUF_Value2 := CMP_BUF_Buffer2;
   end;//Cast both to common Type

  if ((CMP_BUF_Value1 = nil) or (CMP_BUF_Value2 = nil)) then
    raise ESQLMemException.Create(30140, ErrorGValueIsNull);

  case CMP_BUF_CommonType of
    bftChar,
    bftClob,
    bftVarchar:
      begin
        CMP_BUF_StrCmpFlags := SORT_STRINGSORT;
        if CMP_BUF_IgnoreCase then
          CMP_BUF_StrCmpFlags := CMP_BUF_StrCmpFlags + NORM_IGNORECASE;
{$IFDEF MSWINDOWS}
        // bug fix for Chezh WinVista - added in 4.80
{
        if (SQLMem_OS_Type = osWinVista) then
//        if (SQLMem_OS_Type = osWinXP) then
         begin
           l1 := GetStrLength(Value1,BaseFieldTypeToAdvancedFieldType(CommonType));
           l2 := GetStrLength(Value2,BaseFieldTypeToAdvancedFieldType(CommonType));
           if l1 < l2 then
             len := l1
           else
             len := l2;

           StrCmpResult := 1;
           for i:=0 to len-1 do
           begin
             StrCmpResult := Windows.CompareStringA(LOCALE_USER_DEFAULT,
                   SORT_STRINGSORT,
                   PAnsiChar(Value1)+i, 1,
                   PAnsiChar(Value2)+i, 1);
             if StrCmpResult <> 2 then
               break;
           end;
         end
        else
}
         CMP_BUF_StrCmpResult := Windows.CompareStringA(CMP_BUF_LocaleID, CMP_BUF_StrCmpFlags,
                                              CMP_BUF_Value1, CMP_BUF_PartialCompareLength,
                                              CMP_BUF_Value2, CMP_BUF_PartialCompareLength);
{$ENDIF}
{$IFDEF LINUX}
        if (CMP_BUF_PartialCompareLength > 0) then
          begin
           if CMP_BUF_IgnoreCase then
             CMP_BUF_StrCmpResult := SysUtils.AnsiStrLIComp(
                                            CMP_BUF_Value1, CMP_BUF_Value2,
                                            CMP_BUF_PartialCompareLength
                                                       )
            else
             CMP_BUF_StrCmpResult := SysUtils.AnsiStrLComp(
                                            CMP_BUF_Value1, CMP_BUF_Value2,
                                            CMP_BUF_PartialCompareLength
                                                      );
          end
         else
          begin
{ TODO -oAlex : uncomment it, debug and comment your code}
{
 if (IgnoreCase) then
  StrCmpResult := SysUtils.WideCompareText(WideString(PWideChar(Value1)^),
                                           WideString(PWideChar(Value2)^))
 else
  StrCmpResult := SysUtils.WideCompareStr(WideString(PWideChar(Value1)^),
                                           WideString(PWideChar(Value2)^));
}
           SetLength(CMP_BUF_Str1, MAX_STRING_LENGTH);
           SetLength(CMP_BUF_Str2, MAX_STRING_LENGTH);
           StrCopy(PAnsiChar(CMP_BUF_Str1), CMP_BUF_Value1);
           StrCopy(PAnsiChar(CMP_BUF_Str2), CMP_BUF_Value2);
           if CMP_BUF_IgnoreCase then
             CMP_BUF_StrCmpResult := SysUtils.AnsiCompareText(CMP_BUF_Str1, CMP_BUF_Str2)
           else
             CMP_BUF_StrCmpResult := SysUtils.AnsiCompareStr(CMP_BUF_Str1, CMP_BUF_Str2);
          end;
        if (CMP_BUF_StrCmpResult < 0) then
          CMP_BUF_StrCmpResult := 1 else
        if (CMP_BUF_StrCmpResult = 0) then
          CMP_BUF_StrCmpResult := 2
         else
          CMP_BUF_StrCmpResult := 3; // (StrCmpResult > 0)
{$ENDIF}
        case CMP_BUF_StrCmpResult of
          1:   CMP_BUF_Result := cmprLower;
          2:   CMP_BUF_Result := cmprEqual;
          3:   CMP_BUF_Result := cmprGreater;
         else raise ESQLMemException.Create(30045, ErrorGUnknownReturnCode, [CMP_BUF_StrCmpResult]);
        end;
      end;
    bftWideChar,
    bftWideClob,
    bftWideVarchar:
      begin
        CMP_BUF_StrCmpFlags := SORT_STRINGSORT;
        if CMP_BUF_IgnoreCase then
          CMP_BUF_StrCmpFlags := CMP_BUF_StrCmpFlags + NORM_IGNORECASE;
{$IFDEF MSWINDOWS}
        CMP_BUF_StrCmpResult := Windows.CompareStringW(CMP_BUF_LocaleID, CMP_BUF_StrCmpFlags,
                                               CMP_BUF_Value1, CMP_BUF_PartialCompareLength,
                                               CMP_BUF_Value2, CMP_BUF_PartialCompareLength);
{$ENDIF}
{$IFDEF LINUX}
{ TODO -oAlex : uncomment it, debug and comment your code}
{
 if (IgnoreCase) then
  StrCmpResult := SysUtils.WideCompareText(WideString(PWideChar(Value1)^),
                                           WideString(PWideChar(Value2)^))
 else
  StrCmpResult := SysUtils.WideCompareStr(WideString(PWideChar(Value1)^),
                                           WideString(PWideChar(Value2)^));
}

        if (CMP_BUF_PartialCompareLength > 0) then
          begin
           SetLength(CMP_BUF_WStr1, CMP_BUF_PartialCompareLength * 2);
           SetLength(CMP_BUF_WStr2, CMP_BUF_PartialCompareLength * 2);
           Move(CMP_BUF_Value1^, PAnsiChar(CMP_BUF_WStr1)^, CMP_BUF_PartialCompareLength * 2);
           Move(CMP_BUF_Value2^, PAnsiChar(CMP_BUF_WStr2)^, CMP_BUF_PartialCompareLength * 2);
          end
         else
          begin
           SetLength(CMP_BUF_WStr1, MAX_STRING_LENGTH);
           SetLength(CMP_BUF_WStr2, MAX_STRING_LENGTH);
           StrCopy(PAnsiChar(CMP_BUF_WStr1), CMP_BUF_Value1);
           StrCopy(PAnsiChar(CMP_BUF_WStr2), CMP_BUF_Value2);
          end;
        if CMP_BUF_IgnoreCase then
          CMP_BUF_StrCmpResult := SysUtils.WideCompareText(CMP_BUF_WStr1, CMP_BUF_WStr2) // WideAnsiUpperCase in SysUtils does not work correctly
         else
          CMP_BUF_StrCmpResult := SysUtils.WideCompareStr(CMP_BUF_WStr1, CMP_BUF_WStr2);
        if (CMP_BUF_StrCmpResult < 0) then
          CMP_BUF_StrCmpResult := 1 else
        if (CMP_BUF_StrCmpResult = 0) then
          CMP_BUF_StrCmpResult := 2
         else
          CMP_BUF_StrCmpResult := 3; // (StrCmpResult > 0)
{$ENDIF}
        case CMP_BUF_StrCmpResult of
          1:   CMP_BUF_Result := cmprLower;
          2:   CMP_BUF_Result := cmprEqual;
          3:   CMP_BUF_Result := cmprGreater;
         else raise ESQLMemException.Create(30046, ErrorGUnknownReturnCode, [CMP_BUF_StrCmpResult]);
        end;
      end;
    bftSignedInt8:
      begin
        if (PShortInt(CMP_BUF_Value1)^ = PShortInt(CMP_BUF_Value2)^) then
          CMP_BUF_Result := cmprEqual
        else
        if (PShortInt(CMP_BUF_Value1)^ > PShortInt(CMP_BUF_Value2)^) then
          CMP_BUF_Result := cmprGreater
        else
          CMP_BUF_Result := cmprLower;
      end;
    bftSignedInt16:
      begin
        if (PSmallInt(CMP_BUF_Value1)^ = PSmallInt(CMP_BUF_Value2)^) then
          CMP_BUF_Result := cmprEqual
        else
        if (PSmallInt(CMP_BUF_Value1)^ > PSmallInt(CMP_BUF_Value2)^) then
          CMP_BUF_Result := cmprGreater
        else
          CMP_BUF_Result := cmprLower;
      end;
    bftSignedInt32:
      begin
        if (PInteger(CMP_BUF_Value1)^ = PInteger(CMP_BUF_Value2)^) then
          CMP_BUF_Result := cmprEqual
        else
        if (PInteger(CMP_BUF_Value1)^ > PInteger(CMP_BUF_Value2)^) then
          CMP_BUF_Result := cmprGreater
        else
          CMP_BUF_Result := cmprLower;
      end;
    bftSignedInt64:
      begin
        if (PInt64(CMP_BUF_Value1)^ = PInt64(CMP_BUF_Value2)^) then
          CMP_BUF_Result := cmprEqual
        else
        if (PInt64(CMP_BUF_Value1)^ > PInt64(CMP_BUF_Value2)^) then
          CMP_BUF_Result := cmprGreater
        else
          CMP_BUF_Result := cmprLower;
      end;
    bftUnSignedInt8:
      begin
        if (pByte(CMP_BUF_Value1)^ = pByte(CMP_BUF_Value2)^) then
          CMP_BUF_Result := cmprEqual
        else
          if (pByte(CMP_BUF_Value1)^ > pByte(CMP_BUF_Value2)^) then
            CMP_BUF_Result := cmprGreater
          else
            CMP_BUF_Result := cmprLower;
      end;
    bftUnSignedInt16:
      begin
        if (pWord(CMP_BUF_Value1)^ = pWord(CMP_BUF_Value2)^) then
          CMP_BUF_Result := cmprEqual
        else
          if (pWord(CMP_BUF_Value1)^ > pWord(CMP_BUF_Value2)^) then
            CMP_BUF_Result := cmprGreater
          else
            CMP_BUF_Result := cmprLower;
      end;
    bftUnSignedInt32:
      begin
        if (pLongword(CMP_BUF_Value1)^ = pLongword(CMP_BUF_Value2)^) then
          CMP_BUF_Result := cmprEqual
        else
          if (pLongword(CMP_BUF_Value1)^ > pLongword(CMP_BUF_Value2)^) then
            CMP_BUF_Result := cmprGreater
          else
            CMP_BUF_Result := cmprLower;
      end;
    bftSingle:
      begin
        if (pSingle(CMP_BUF_Value1)^ = pSingle(CMP_BUF_Value2)^) then
          CMP_BUF_Result := cmprEqual
        else
          if (pSingle(CMP_BUF_Value1)^ > pSingle(CMP_BUF_Value2)^) then
            CMP_BUF_Result := cmprGreater
          else
            CMP_BUF_Result := cmprLower;
      end;
    bftDouble:
      begin
        if (pDouble(CMP_BUF_Value1)^ = pDouble(CMP_BUF_Value2)^) then
          CMP_BUF_Result := cmprEqual
        else
          if (pDouble(CMP_BUF_Value1)^ > pDouble(CMP_BUF_Value2)^) then
            CMP_BUF_Result := cmprGreater
          else
            CMP_BUF_Result := cmprLower;
      end;
    bftExtended:
      begin
        if (pExtended(CMP_BUF_Value1)^ = pExtended(CMP_BUF_Value2)^) then
          CMP_BUF_Result := cmprEqual
        else
          if (pExtended(CMP_BUF_Value1)^ > pExtended(CMP_BUF_Value2)^) then
            CMP_BUF_Result := cmprGreater
          else
            CMP_BUF_Result := cmprLower;
      end;
    bftDate:
      begin
        if (PSQLMemDate(CMP_BUF_Value1)^ = PSQLMemDate(CMP_BUF_Value2)^) then
          CMP_BUF_Result := cmprEqual
        else
          if (PSQLMemDate(CMP_BUF_Value1)^ > PSQLMemDate(CMP_BUF_Value2)^) then
            CMP_BUF_Result := cmprGreater
          else
            CMP_BUF_Result := cmprLower;
      end;
    bftTime:
      begin
        if (PSQLMemTime(CMP_BUF_Value1)^ = PSQLMemTime(CMP_BUF_Value2)^) then
          CMP_BUF_Result := cmprEqual
        else
          if (PSQLMemTime(CMP_BUF_Value1)^ > PSQLMemTime(CMP_BUF_Value2)^) then
            CMP_BUF_Result := cmprGreater
          else
            CMP_BUF_Result := cmprLower;
      end;
    bftDateTime:
      begin
        // Comparing Date perts
        if (PSQLMemDateTime(CMP_BUF_Value1)^.Date = PSQLMemDateTime(CMP_BUF_Value2)^.Date) then
          // Time part IS NULL --> result = ???
          //if ( (PSQLMemDateTime(Value1)^.Time = TIME_IS_NULL) or
          //     (PSQLMemDateTime(Value2)^.Time = TIME_IS_NULL) then ;

          // date1 = date2. Comparing times
          if (PSQLMemDateTime(CMP_BUF_Value1)^.Time = PSQLMemDateTime(CMP_BUF_Value2)^.Time) then
            // Time1 = Time 2
            CMP_BUF_Result := cmprEqual
          else
            // Time1 <> Time 2
            if (PSQLMemDateTime(CMP_BUF_Value1)^.Time > PSQLMemDateTime(CMP_BUF_Value2)^.Time) then
              CMP_BUF_Result := cmprGreater
            else
              CMP_BUF_Result := cmprLower
        else
          // Date1 <> Date2
          if (PSQLMemTime(CMP_BUF_Value1)^ > PSQLMemTime(CMP_BUF_Value2)^) then
            CMP_BUF_Result := cmprGreater
          else
            CMP_BUF_Result := cmprLower;
      end;
    bftLogical:
      begin
        if (PSQLMemLogical(CMP_BUF_Value1)^ = PSQLMemLogical(CMP_BUF_Value2)^) then
          CMP_BUF_Result := cmprEqual
        else
          if (PSQLMemLogical(CMP_BUF_Value1)^ > PSQLMemLogical(CMP_BUF_Value2)^) then
            CMP_BUF_Result := cmprGreater
          else
            CMP_BUF_Result := cmprLower;
      end;
    bftCurrency:
      begin
        if (PSQLMemCurrency(CMP_BUF_Value1)^ = PSQLMemCurrency(CMP_BUF_Value2)^) then
          CMP_BUF_Result := cmprEqual
        else
          if (PSQLMemCurrency(CMP_BUF_Value1)^ > PSQLMemCurrency(CMP_BUF_Value2)^) then
            CMP_BUF_Result := cmprGreater
          else
            CMP_BUF_Result := cmprLower;
      end;

    else
        raise ESQLMemException.Create(30047, ErrorGUnknownDataType, [BftToStr(CMP_BUF_CommonType)]);
    end;
  finally
    if CMP_BUF_NewBuffer1 <> nil then
      MemoryManager.FreeAndNilMem(CMP_BUF_NewBuffer1);
    if CMP_BUF_NewBuffer2 <> nil then
      MemoryManager.FreeAndNilMem(CMP_BUF_NewBuffer2);
  end;
 end; // Not Null

