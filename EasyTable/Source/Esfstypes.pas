unit ESFSTypes;

interface

{$I ESFSVer.Inc}

type
{$ifdef DCC}
    SizeInt = NativeUInt;
{$else}
  {$IFDEF X64_ON}
    SizeInt = NativeUInt;
   {$ELSE}
    SizeInt = Cardinal;
   {$ENDIF}
{$endif}

implementation

end.
