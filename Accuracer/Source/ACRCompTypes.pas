unit ACRCompTypes;

interface

{$I ACRVer.Inc}

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