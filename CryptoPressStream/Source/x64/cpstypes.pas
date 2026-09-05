unit CPSTypes;

interface

{$I CPSVer.Inc}

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