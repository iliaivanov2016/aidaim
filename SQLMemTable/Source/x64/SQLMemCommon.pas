unit SQLMemCommon;



{$I SQLMemVer.Inc}



{$ifdef FPC}
{$mode objfpc}{$H+}
{$endif}



interface


Uses SysUtils,SQLMemCompTypes;


type
  TAlloc = function(Data: Pointer; Items, Size: Integer): Pointer; cdecl;
  
TFree = procedure(Data: Pointer; Block: Pointer); cdecl;


function SQLMemAlloc(opaque: Pointer; Size: SizeInt): Pointer; cdecl;

procedure SQLMemFree(opaque: Pointer; address: Pointer); cdecl;

procedure SQLMemMemcpy(Dest, Source: Pointer; Count: Integer); cdecl;



implementation



function SQLMemAlloc(opaque: Pointer; Size: SizeInt): Pointer; cdecl;

begin
  
	Result := AllocMem(Size);

end;



procedure SQLMemFree(opaque: Pointer; address: Pointer); cdecl;

begin
     
	FreeMem(address);

end;



procedure SQLMemMemcpy(Dest, Source: Pointer; Count: Integer); cdecl;

begin
  
	Move(Source^, Dest^, Count);

end;



end.

