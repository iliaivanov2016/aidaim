unit SQLMem_d12h;

interface

{$I SQLMemVer.inc}

uses SysUtils;

function aaStrLen(const Str: PAnsiChar): Cardinal;

implementation

function aaStrLen(const Str: PAnsiChar): Cardinal;
begin
 Result := StrLen(Str);
end;


end.