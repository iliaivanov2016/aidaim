unit ACRCommon;



{$I ACRVer.Inc}



{$ifdef FPC}
{$mode objfpc}{$H+}
{$endif}



interface


Uses SysUtils,ACRCompTypes;


type
  TAlloc = function(Data: Pointer; Items, Size: Integer): Pointer; cdecl;
  
TFree = procedure(Data: Pointer; Block: Pointer); cdecl;


function ACRAlloc(opaque: Pointer; Size: SizeInt): Pointer; cdecl;

procedure ACRFree(opaque: Pointer; address: Pointer); cdecl;

procedure ACRMemcpy(Dest, Source: Pointer; Count: Integer); cdecl;



implementation



function ACRAlloc(opaque: Pointer; Size: SizeInt): Pointer; cdecl;

begin
  
	Result := AllocMem(Size);

end;



procedure ACRFree(opaque: Pointer; address: Pointer); cdecl;

begin
     
	FreeMem(address);

end;



procedure ACRMemcpy(Dest, Source: Pointer; Count: Integer); cdecl;

begin
  
	Move(Source^, Dest^, Count);

end;



end.

