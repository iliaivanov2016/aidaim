unit ACRLinux;

interface

uses
{$IFNDEF D6H}
  Windows
{$ELSE}
{$IFDEF MSWINDOWS}
  Windows
{$ENDIF}
{$IFDEF LINUX}
  Libc
{$ENDIF}
{$ENDIF}
  ;

function GetTickCount: Cardinal;

implementation

//------------------------------------------------------------------------------
// GetTickCount
//------------------------------------------------------------------------------
{$IFDEF D6H}
{$IFDEF LINUX}
function GetTickCount: Cardinal;
var
  tv: timeval;
begin
  gettimeofday(tv, nil);
  {$RANGECHECKS OFF}
  Result := int64(tv.tv_sec) * 1000 + tv.tv_usec div 1000;
end; // GetTickCount
{$ENDIF}

{$IFDEF MSWINDOWS}
function GetTickCount: Cardinal;
begin
  Result := Windows.GetTickCount;
end; // GetTickCount
{$ENDIF}
{$ENDIF}

{$IFNDEF D6H}
function GetTickCount: Cardinal;
begin
  Result := Windows.GetTickCount;
end; // GetTickCount
{$ENDIF}

end.
