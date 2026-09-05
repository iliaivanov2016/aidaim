unit Msg_d12h;

interface

{$I MsgVer.inc}

uses SysUtils;

function aaStrLen(const Str: PAnsiChar): Cardinal;

implementation

function aaStrLen(const Str: PAnsiChar): Cardinal;
begin
 Result := StrLen(Str);
end;


end.