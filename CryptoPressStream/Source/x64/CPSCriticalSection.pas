unit CPSCriticalSection;

interface

{$I CPSVer.inc}

{$IFDEF LINUX}
uses Libc
{$ENDIF}

{$IFDEF MSWINDOWS}
uses Windows
{$ENDIF}

{$IFDEF DEBUG_LOG_INIT}
  ,CPSDebug
{$ENDIF}
  ;

{$IFDEF MSWINDOWS}
const
  kernel = 'kernel32.dll';
         
{$IFDEF X64_ON}
// no need to redeclare it
{$ELSE}
type
  TRTLCriticalSection = packed record
    DebugInfo: Pointer;
    LockCount: Longint;
    RecursionCount: Longint;
    OwningThread: Integer;
    LockSemaphore: Integer;
    Reserved: DWORD;
  end;
{$ENDIF}

procedure InitializeCriticalSection(var lpCriticalSection: TRTLCriticalSection); stdcall;
  external kernel name 'InitializeCriticalSection';
procedure EnterCriticalSection(var lpCriticalSection: TRTLCriticalSection); stdcall;
  external kernel name 'EnterCriticalSection';
procedure LeaveCriticalSection(var lpCriticalSection: TRTLCriticalSection); stdcall;
  external kernel name 'LeaveCriticalSection';
procedure DeleteCriticalSection(var lpCriticalSection: TRTLCriticalSection); stdcall;
  external kernel name 'DeleteCriticalSection';
{$ENDIF}

{$IFDEF LINUX}
procedure InitializeCriticalSection(var lpCriticalSection: TRTLCriticalSection);
procedure EnterCriticalSection(var lpCriticalSection: TRTLCriticalSection);
procedure LeaveCriticalSection(var lpCriticalSection: TRTLCriticalSection);
procedure DeleteCriticalSection(var lpCriticalSection: TRTLCriticalSection);
{$ENDIF}

implementation

{$IFDEF LINUX}
procedure InitializeCriticalSection(var lpCriticalSection: TRTLCriticalSection);
var
 i: Integer;
begin
 i := Libc.InitializeCriticalSection(lpCriticalSection);
end;

procedure EnterCriticalSection(var lpCriticalSection: TRTLCriticalSection);
var
 i: Integer;
begin
 i := Libc.EnterCriticalSection(lpCriticalSection);
end;

procedure LeaveCriticalSection(var lpCriticalSection: TRTLCriticalSection);
var
 i: Integer;
begin
 i := Libc.LeaveCriticalSection(lpCriticalSection);
end;

procedure DeleteCriticalSection(var lpCriticalSection: TRTLCriticalSection);
var
 i: Integer;
begin
 i := Libc.DeleteCriticalSection(lpCriticalSection);
end;
{$ENDIF}

initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('CPSCriticalSection> initialized');
{$ENDIF}

end.
