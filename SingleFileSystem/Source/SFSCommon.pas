unit SFSCommon;

{$I SFSVer.Inc}

{$ifdef FPC}
{$mode objfpc}{$H+}
{$endif}

interface

Uses SysUtils,SFSTypes;

type
  TAlloc = function(Data: Pointer; Items, Size: Integer): Pointer; cdecl;
  TFree = procedure(Data: Pointer; Block: Pointer); cdecl;

function SFSAlloc(opaque: Pointer; Size: SizeInt): Pointer; cdecl;
procedure SFSFree(opaque: Pointer; address: Pointer); cdecl;
procedure SFSMemcpy(Dest, Source: Pointer; Count: Integer); cdecl;

implementation

function SFSAlloc(opaque: Pointer; Size: SizeInt): Pointer; cdecl;
begin
  Result := AllocMem(Size);
end;

procedure SFSFree(opaque: Pointer; address: Pointer); cdecl;
begin
     FreeMem(address);
end;

procedure SFSMemcpy(Dest, Source: Pointer; Count: Integer); cdecl;
begin
  Move(Source^, Dest^, Count);
end;

end.

