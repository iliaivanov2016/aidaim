//------------------------------------------------------------------------------
// return true if null flag is set (bit = 1)
//------------------------------------------------------------------------------
{
if ((PByte(CHECK_NULL_FLAG_NullFlags+(CHECK_NULL_FLAG_BitNo div 8))^) and
		 (1 shl (CHECK_NULL_FLAG_BitNo mod 8)) <> 0) then
  CHECK_NULL_FLAG_Result := True
else
  CHECK_NULL_FLAG_Result := False;
}

CHECK_NULL_FLAG_Result :=
Boolean((PByte(CHECK_NULL_FLAG_NullFlags+(CHECK_NULL_FLAG_BitNo shr 3))^
shr (CHECK_NULL_FLAG_BitNo and $07))
and $01);




