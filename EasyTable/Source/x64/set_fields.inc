chkfld_buffer := PAnsiChar(chkfld_buffer+(chkfld_fieldNum div 8));
if (chkfld_set) then
  pByte(chkfld_buffer)^ := pByte(chkfld_buffer)^ or
		(1 shl (chkfld_fieldNum mod 8))
 else
  pByte(chkfld_buffer)^ := pByte(chkfld_buffer)^ and
		(not (1 shl (chkfld_fieldNum mod 8)));

