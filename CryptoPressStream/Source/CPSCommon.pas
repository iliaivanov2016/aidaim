unit CPSCommon;

{$I CPSVer.Inc}

{$ifdef FPC}
{$mode objfpc}{$H+}
{$endif}

interface

Uses SysUtils,CPSTypes;

type
  TAlloc = function(Data: Pointer; Items, Size: Integer): Pointer; cdecl;
  TFree = procedure(Data: Pointer; Block: Pointer); cdecl;

function CPSAlloc(opaque: Pointer; Size: SizeInt): Pointer; cdecl;
procedure CPSFree(opaque: Pointer; address: Pointer); cdecl;
procedure CPSMemcpy(Dest, Source: Pointer; Count: Integer); cdecl;

implementation

function CPSAlloc(opaque: Pointer; Size: SizeInt): Pointer; cdecl;
begin
  Result := AllocMem(Size);
end;

procedure CPSFree(opaque: Pointer; address: Pointer); cdecl;
begin
     FreeMem(address);
end;

procedure CPSMemcpy(Dest, Source: Pointer; Count: Integer); cdecl;
begin
  Move(Source^, Dest^, Count);
end;

end.

