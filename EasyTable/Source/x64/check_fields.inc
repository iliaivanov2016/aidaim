if ((pByte(chkfld_buffer+(chkfld_fieldNum div 8))^) and 
		(1 shl (chkfld_fieldNum mod 8)) <> 0) then
 chkfld_result := true
else
 chkfld_result := false;

