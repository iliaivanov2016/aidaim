 findValIns_i := findValIns_recCount shr 1;
 findValIns_dx := findValIns_i;
 findValIns_result := findValIns_recCount;
if (findValIns_recCount > 0) then
begin
 findValIns_f := 0;
 cmpRecBuf_bPartialCompare := findValIns_partialCompare;
 cmpRecBuf_res := 2;
 cmpRecBuf_buffer2 := findValIns_recordBuffer;
 cmpRecBuf_ignoreCase := findValIns_ignoreCase;
// if (findValIns_search) then
//  cmpRecBuf_ignoreCase := true;
 cmpRecBuf_pIndexHeader := findValIns_pIndex;
 while (true) do
  begin
   findValIns_dx := findValIns_dx shr 1;
   if (findValIns_dx < 1) then findValIns_dx := 1;
   findValIns_oldRes := cmpRecBuf_res;

   cmpRecBuf_buffer1 := PAnsiChar(DMHandle.allRecBuffer.GetRecordDataPtr(
          findValIns_array[findValIns_i]));
   {$include compare.inc}
   if (cmpRecBuf_res < 0) then
    begin
   //  element in index array for record buffer should be higher then current buffer (+->0)
     findValIns_i := findValIns_i - findValIns_dx;
    end
   else
   if (cmpRecBuf_res > 0) then
    begin
   //  element in index array for record buffer should be lower then current buffer (0->+)
     findValIns_i := findValIns_i + findValIns_dx;
    end
   else // index values are equal
    begin
     findValIns_result := findValIns_i;
     break;
    end;
   if  (findValIns_i < 0) and (findValIns_dx = 1) then
    begin
     findValIns_result := 0;
     break;
    end;
   if  (findValIns_i > findValIns_recCount-1) and (findValIns_dx = 1) then
    begin
     findValIns_result := findValIns_recCount;
     break;
    end;

   if  findValIns_i > findValIns_recCount-1 then
    findValIns_i := findValIns_recCount-1;
   if  findValIns_i < 0 then findValIns_i := 0;

   if (findValIns_dx = 1)and(findValIns_f > 1) then
    begin
    // dx minimum

   cmpRecBuf_buffer1 := PAnsiChar(DMHandle.allRecBuffer.GetRecordDataPtr(
          findValIns_array[findValIns_i]));
     {$include compare.inc}
     if (cmpRecBuf_res < 0) and (findValIns_oldRes > 0) then
      findValIns_result := findValIns_i;
     if (cmpRecBuf_res > 0) and (findValIns_oldRes < 0) then
      findValIns_result := findValIns_i+1;
     if (cmpRecBuf_res = findValIns_oldRes) then continue;
     break;
    end;// last step
   if (cmpRecBuf_res <> findValIns_oldRes) and (findValIns_dx = 1)
      and (findValIns_oldRes <> 2) then
        inc(findValIns_f);
  end;//while dx
end; // if reccount > 0
