cmpRecBuf_indCount := cmpRecBuf_pIndexHeader^.indexCount-1;
// allocating memory for field values
cmpRecBuf_i := 0;
cmpRecBuf_res := 0;
while cmpRecBuf_i <= cmpRecBuf_indCount do
//while (true) do
begin
 // field number
 cmpRecBuf_k := cmpRecBuf_pIndexHeader^.indexFields[cmpRecBuf_i];
if (cmpRecBuf_k < 0) then
 begin
    // primary key - always ascending
     cmpRecBuf_p_LongWord1 := pLongWord(cmpRecBuf_buffer1+DMHandle.recordSize);
     cmpRecBuf_p_LongWord2 := pLongWord(cmpRecBuf_buffer2+DMHandle.recordSize);
     if (cmpRecBuf_p_LongWord1^ = cmpRecBuf_p_LongWord2^)
      then cmpRecBuf_res := 0  // 1 = 2
     else
     if (cmpRecBuf_p_LongWord1^ > cmpRecBuf_p_LongWord2^)
      then
       begin
        cmpRecBuf_res := -1;  // 1 > 2
        break;
       end
     else
      begin
       cmpRecBuf_res := 1; // 1 < 2
       break;
      end;
 end // primary key
else
 begin
 // compare started
  //check indexOrders and indexCaseIns
  chkfld_buffer := cmpRecBuf_pIndexHeader^.indexOrders;
  chkfld_fieldNum := cmpRecBuf_i;
  {$include check_fields.inc}
  cmpRecBuf_indexAsc := chkfld_result;
  chkfld_buffer := cmpRecBuf_pIndexHeader^.indexCaseIns;
  {$include check_fields.inc}
  cmpRecBuf_indexCaseIns := chkfld_result;
  if (cmpRecBuf_pIndexHeader^.ignoreCase) then
   cmpRecBuf_indexCaseIns := true;
  if (cmpRecBuf_pIndexHeader^.descending) then
   cmpRecBuf_indexAsc := false;

  chkfld_fieldNum := cmpRecBuf_k;
  // check null
  chkfld_buffer := pAnsiChar(cmpRecBuf_buffer1+DMHandle.recNullOffset);
  {$include check_fields.inc}
  cmpRecBuf_isNull1 := chkfld_result;
  chkfld_buffer := pAnsiChar(cmpRecBuf_buffer2+DMHandle.recNullOffset);
  {$include check_fields.inc}
  cmpRecBuf_isNull2 := chkfld_result;

 if (cmpRecBuf_isNull1) and (cmpRecBuf_isNull2) then
  begin
   cmpRecBuf_res :=  0; // 2 null value is equal
  end
 else
 // null value < any not null value
  if (cmpRecBuf_isNull1 ) and (not cmpRecBuf_isNull2) then
   cmpRecBuf_res := -1
  else
  if (not cmpRecBuf_isNull1) and (cmpRecBuf_isNull2) then
   cmpRecBuf_res := 1
  else
   begin
   //both value not null
    cmpRecBuf_offset := DMHandle.fieldOffsets[cmpRecBuf_k];
    case pFieldHeaderType(DMHandle.fieldHeaderList.Items[cmpRecBuf_k])^.fieldType of
     ftSmallint :
      begin
       cmpRecBuf_p_small1 := pSmallInt(cmpRecBuf_buffer1+cmpRecBuf_offset);
       cmpRecBuf_p_small2 := pSmallInt(cmpRecBuf_buffer2+cmpRecBuf_offset);
	     if (cmpRecBuf_p_small1^ = cmpRecBuf_p_small2^)
  	    then cmpRecBuf_res := 0  // 1 = 2
	     else
	     if (cmpRecBuf_p_small1^ > cmpRecBuf_p_small2^)
	      then cmpRecBuf_res := 1  // 1 > 2
	     else
	      cmpRecBuf_res := -1; // 1 < 2
      end;
     ftInteger :
      begin
         cmpRecBuf_p_int1 := pInteger(cmpRecBuf_buffer1+cmpRecBuf_offset);
         cmpRecBuf_p_int2 := pInteger(cmpRecBuf_buffer2+cmpRecBuf_offset);
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
       cmpRecBuf_p_word1 := pWord(cmpRecBuf_buffer1+cmpRecBuf_offset);
       cmpRecBuf_p_word2 := pWord(cmpRecBuf_buffer2+cmpRecBuf_offset);
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
       cmpRecBuf_p_largeInt1 := plargeInt(cmpRecBuf_buffer1+cmpRecBuf_offset);
       cmpRecBuf_p_largeInt2 := plargeInt(cmpRecBuf_buffer2+cmpRecBuf_offset);
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
       cmpRecBuf_p_bool1 := pBoolean(cmpRecBuf_buffer1+cmpRecBuf_offset);
       cmpRecBuf_p_bool2 := pBoolean(cmpRecBuf_buffer2+cmpRecBuf_offset);
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
       cmpRecBuf_p_str1 := PAnsiChar(cmpRecBuf_buffer1+cmpRecBuf_offset);
       cmpRecBuf_p_str2 := PAnsiChar(cmpRecBuf_buffer2+cmpRecBuf_offset);
       //compare string
       if (cmpRecBuf_ignoreCase) then
         cmpRecBuf_noCase := true
       else
	     if (cmpRecBuf_indexCaseIns) then
         cmpRecBuf_noCase := true
        else
         cmpRecBuf_noCase := false;
       if (cmpRecBuf_noCase) then
        begin
         if (cmpRecBuf_bPartialCompare) then
          cmpRecBuf_res := Q_AnsiCompTextL(cmpRecBuf_p_str1,cmpRecBuf_p_str2,Length(cmpRecBuf_p_str2))
         else
          cmpRecBuf_res := Q_AnsiPCompText(cmpRecBuf_p_str1,cmpRecBuf_p_str2);
        end
       else
        begin
         if (cmpRecBuf_bPartialCompare) then
          cmpRecBuf_res := Q_AnsiCompStrL(cmpRecBuf_p_str1,cmpRecBuf_p_str2,Length(cmpRecBuf_p_str2))
         else
          cmpRecBuf_res := Q_AnsiPCompStr(cmpRecBuf_p_str1,cmpRecBuf_p_str2);
        end; //string
      end;

     ftWideString :
      begin
       cmpRecBuf_p_wstr1 := PWideChar(cmpRecBuf_buffer1+cmpRecBuf_offset);
       cmpRecBuf_p_wstr2 := PWideChar(cmpRecBuf_buffer2+cmpRecBuf_offset);
       //compare string
       if (cmpRecBuf_ignoreCase) then
         cmpRecBuf_noCase := true
       else
	     if (cmpRecBuf_indexCaseIns) then
         cmpRecBuf_noCase := true
        else
         cmpRecBuf_noCase := false;
       if (cmpRecBuf_noCase) then
        begin
         if (cmpRecBuf_bPartialCompare) then
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
         if (cmpRecBuf_bPartialCompare) then
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
       cmpRecBuf_p_date1 := pDateTime(cmpRecBuf_buffer1+cmpRecBuf_offset);
       cmpRecBuf_p_date2 := pDateTime(cmpRecBuf_buffer2+cmpRecBuf_offset);

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
       cmpRecBuf_p_date1 := pDateTime(cmpRecBuf_buffer1+cmpRecBuf_offset);
       cmpRecBuf_p_date2 := pDateTime(cmpRecBuf_buffer2+cmpRecBuf_offset);

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
       cmpRecBuf_p_date1 := pDateTime(cmpRecBuf_buffer1+cmpRecBuf_offset);
       cmpRecBuf_p_date2 := pDateTime(cmpRecBuf_buffer2+cmpRecBuf_offset);

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
       cmpRecBuf_p_float1 := pFloat(cmpRecBuf_buffer1+cmpRecBuf_offset);
       cmpRecBuf_p_float2 := pFloat(cmpRecBuf_buffer2+cmpRecBuf_offset);
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
       cmpRecBuf_p_curr1 := pCurrency(cmpRecBuf_buffer1+cmpRecBuf_offset);
       cmpRecBuf_p_curr2 := pCurrency(cmpRecBuf_buffer2+cmpRecBuf_offset);
	     if (cmpRecBuf_p_curr1^ = cmpRecBuf_p_curr2^)
  	    then cmpRecBuf_res := 0  // 1 = 2
	     else
	     if (cmpRecBuf_p_curr1^ > cmpRecBuf_p_curr2^)
	      then cmpRecBuf_res := 1  // 1 > 2
	     else
	      cmpRecBuf_res := -1; // 1 < 2
      end;
    end; // case
   end; // not null values

     if (cmpRecBuf_res = 0) then
      begin
       inc(cmpRecBuf_i);
       continue;
      end;
     if (cmpRecBuf_res > 0) then
      begin
       if (cmpRecBuf_indexAsc) then
        cmpRecBuf_res := -1; // asc
       break;
      end // 1 > 2
     else
      begin
      // 1 < 2
       if (cmpRecBuf_indexAsc) then
        cmpRecBuf_res := 1; // asc
       break;
      end
 end; // not primary key
 inc(cmpRecBuf_i);
end; // for index fields
// to fix bug in find_ind.inc where old value of cmpRecBuf_res compares with new one
// string comparison may return numbers > 1 or < -1
if (cmpRecBuf_res < 0) then
 cmpRecBuf_res := -1
else
if (cmpRecBuf_res > 0) then
 cmpRecBuf_res := 1;
// cmpRecBuf_res = 0 if equal, cmpRecBuf_res = 1 if cmpRecBuf_buffer1 < cmpRecBuf_buffer2 , else -1
