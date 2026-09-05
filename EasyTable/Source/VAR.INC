var
//--------------------- CompareRecordBuffer -----------------------------------
 cmpRecBuf_indCount,cmpRecBuf_l,cmpRecBuf_i,
 cmpRecBuf_k, cmpRecBuf_res,cmpRecBuf_offset  : integer;
 cmpRecBuf_isNull1, cmpRecBuf_isNull2 : Boolean;
 cmpRecBuf_buffer1,cmpRecBuf_buffer2 : PChar;
// ascending order an case insensitive string comparison
 cmpRecBuf_indexAsc, cmpRecBuf_indexCaseIns : Boolean;
 cmpRecBuf_pIndexHeader : pIndexHeaderType;
 cmpRecBuf_noCase, cmpRecBuf_ignoreCase, cmpRecBuf_bPartialCompare : Boolean;

 cmpRecBuf_p_int1, cmpRecBuf_p_int2 : pInteger;
 cmpRecBuf_p_small1, cmpRecBuf_p_small2		: pSmallint;
 cmpRecBuf_p_float1, cmpRecBuf_p_float2		: pFloat;
 cmpRecBuf_p_curr1, cmpRecBuf_p_curr2  		: pCurrency;
 cmpRecBuf_p_str1, cmpRecBuf_p_str2	      : PChar;
 cmpRecBuf_p_wstr1, cmpRecBuf_p_wstr2	    : PWideChar;
 cmpRecBuf_p_date1, cmpRecBuf_p_date2 		: pDateTime;
 cmpRecBuf_date1, cmpRecBuf_date2 		: TDateTime;
 cmpRecBuf_p_bool1, cmpRecBuf_p_bool2    	: pBoolean;
 cmpRecBuf_p_word1, cmpRecBuf_p_word2     : pWord;
 cmpRecBuf_p_largeInt1, cmpRecBuf_p_largeInt2   : pLargeInt;
 cmpRecBuf_find : Boolean;
 cmpRecBuf_TimeStamp : TTimeStamp;
 cmpRecBuf_TimeStamp1 : TTimeStamp;
 cmpRecBuf_TimeStamp2 : TTimeStamp;

//---------------------  FindIndexValueForInsert -------------------------------
var findValIns_i,findValIns_dx,findValIns_f,
    findValIns_oldRes : Integer;

    findValIns_recordBuffer: PChar; // record buffer
    findValIns_pIndex    	 : pIndexHeaderType; // index header
    findValIns_recCount		: Integer; // record Count
    findValIns_ignoreCase	: Boolean=false;	// if true - case is ignored
    findValIns_array : ainteger;
    findValIns_result : Integer;
    findValIns_search : Boolean;

//---------------------  Fields flags  -----------------------------------------
var chkfld_result : Boolean;
    chkfld_buffer : pChar;
    chkfld_fieldNum : Integer;
    chkfld_set    : Boolean;

