//------------------------------------------------------------------------------
// set or clear a null flag
//------------------------------------------------------------------------------
{
procedure SetNullFlag(
          ToSet:       Boolean; // if true - set bit = 1, otherwise set bit = 0
          BitNo:       Cardinal; // number of bit to check
          NullFlags:   PAnsiChar // pointer to bits of null flags
                     );
}
{
  if (SET_NULL_FLAG_ToSet) then
    PByte(SET_NULL_FLAG_NullFlags + (SET_NULL_FLAG_BitNo div 8))^ :=
      PByte(SET_NULL_FLAG_NullFlags + (SET_NULL_FLAG_BitNo div 8))^ or
	  	(1 shl (SET_NULL_FLAG_BitNo mod 8))
  else
    PByte(SET_NULL_FLAG_NullFlags + (SET_NULL_FLAG_BitNo div 8))^ :=
      PByte(SET_NULL_FLAG_NullFlags + (SET_NULL_FLAG_BitNo div 8))^ and
		(not (1 shl (SET_NULL_FLAG_BitNo mod 8)));
}

if (SET_NULL_FLAG_ToSet) then
  PByte(SET_NULL_FLAG_NullFlags+(SET_NULL_FLAG_BitNo shr 3))^ :=
   PByte(SET_NULL_FLAG_NullFlags+(SET_NULL_FLAG_BitNo shr 3))^ or
   Byte($01 shl (SET_NULL_FLAG_BitNo and $07))
else
  PByte(SET_NULL_FLAG_NullFlags+(SET_NULL_FLAG_BitNo shr 3))^ :=
   PByte(SET_NULL_FLAG_NullFlags+(SET_NULL_FLAG_BitNo shr 3))^ and
   Byte(not ($01 shl (SET_NULL_FLAG_BitNo and $07)));

