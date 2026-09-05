unit ESFSCommon;

{$I ESFSVer.Inc}

{$ifdef FPC}
{$mode objfpc}{$H+}
{$endif}

interface

Uses SysUtils,ESFSTypes;

type
  TAlloc = function(Data: Pointer; Items, Size: Integer): Pointer; cdecl;
  TFree = procedure(Data: Pointer; Block: Pointer); cdecl;

function ESFSAlloc(opaque: Pointer; Size: SizeInt): Pointer; cdecl;
procedure ESFSFree(opaque: Pointer; address: Pointer); cdecl;
procedure ESFSMemcpy(Dest, Source: Pointer; Count: Integer); cdecl;

implementation

function ESFSAlloc(opaque: Pointer; Size: SizeInt): Pointer; cdecl;
begin
  Result := AllocMem(Size);
end;

procedure ESFSFree(opaque: Pointer; address: Pointer); cdecl;
begin
     FreeMem(address);
end;

procedure ESFSMemcpy(Dest, Source: Pointer; Count: Integer); cdecl;
begin
  Move(Source^, Dest^, Count);
end;

end.

