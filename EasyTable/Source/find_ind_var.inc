//---------------------  FindIndexValueForInsert -------------------------------
{$I compare_var.inc}
var
    findValIns_i,findValIns_dx,findValIns_f,
    findValIns_oldRes : Integer;                    
    findValIns_recordBuffer: PAnsiChar; // record buffer
    findValIns_pIndex    	 : pIndexHeaderType; // index header
    findValIns_recCount		: Integer; // record Count
    findValIns_ignoreCase	: Boolean;	// if true - case is ignored
    findValIns_partialCompare: Boolean;	// if true - partial compare
    findValIns_array : ainteger;
    findValIns_result : Integer;
    findValIns_search : Boolean;


