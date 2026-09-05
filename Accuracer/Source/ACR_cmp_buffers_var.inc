// params
    CMP_BUF_Buffer1, CMP_BUF_Buffer2:               Pointer;
    CMP_BUF_BaseFieldType1, CMP_BUF_BaseFieldType2: TACRBaseFieldType;
    CMP_BUF_IsField1Null, CMP_BUF_IsField2Null:     Boolean;
    CMP_BUF_PartialCompareLength:                   Integer;// := -1
    CMP_BUF_IgnoreCase:                             Boolean;// := false
{$IFDEF MSWINDOWS}
    CMP_BUF_LocaleID:                               LCID;// := LOCALE_USER_DEFAULT;
{$ENDIF}    
// result
    CMP_BUF_Result:                                 TACRCompareResult;
// local variables
   CMP_BUF_Value1,CMP_BUF_Value2:                   Pointer;
   CMP_BUF_NewBuffer1, CMP_BUF_NewBuffer2:          Pointer;
   CMP_BUF_i,CMP_BUF_len,CMP_BUF_l1,CMP_BUF_l2:     Integer; // added in v.4.80 - bug fix for Chezh Vista
   CMP_BUF_CommonType:                              TACRBaseFieldType;
   CMP_BUF_bDoNotCast:                              Boolean;
   CMP_BUF_StrCmpResult:                            Integer;
   CMP_BUF_StrCmpFlags:                             DWORD;
{$IFDEF LINUX}
   CMP_BUF_Str1, CMP_BUF_Str2:                      AnsiString;
   CMP_BUF_WStr1, CMP_BUF_WStr2:                    WideString;
{$ENDIF}
