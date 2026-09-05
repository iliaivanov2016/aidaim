unit MsgCriticalSection;

interface

{$I MsgVer.inc}

uses
{$IFDEF LINUX}
  Libc,
{$ENDIF}

{$IFDEF MSWINDOWS}
  Windows,
{$ENDIF}

  Classes

{$IFDEF DEBUG_LOG_INIT}
  ,MsgDebug
{$ENDIF}
{$IFDEF LOG_CSECT}
  ,SysUtils
 {$IFNDEF DEBUG_LOG_INIT}
  ,MsgDebug
 {$ENDIF}
{$ENDIF}
  ;

{$IFDEF MSWINDOWS}
const
  kernel = 'kernel32.dll';
{$ENDIF}

type

////////////////////////////////////////////////////////////////////////////////
//
// Critical Section Declarations
//
////////////////////////////////////////////////////////////////////////////////

{$IFDEF MSWINDOWS}
  TRTLCriticalSection = packed record
    DebugInfo: Pointer;
    LockCount: Longint;
    RecursionCount: Longint;
    OwningThread: Integer;
    LockSemaphore: Integer;
    Reserved: DWORD;
  end;
{$ENDIF}
 PRTLCriticalSection = ^TRTLCriticalSection;

 TMsgCriticalSection = packed record
   CSect:            PRTLCriticalSection;
   Log:              Boolean;
   Owner:            AnsiString;
 end;
 PMsgCriticalSection = ^TMsgCriticalSection;

procedure InitCSect(var CSect: TRTLCriticalSection; Owner: AnsiString = ''; Log: Boolean = False);
procedure EnterCSect(var CSect: TRTLCriticalSection);
procedure LeaveCSect(var CSect: TRTLCriticalSection);
procedure LeaveAllCSect(ThreadID: Cardinal);
procedure DeleteCSect(var CSect: TRTLCriticalSection);

function FindCSect(var CSect: TRTLCriticalSection): PMsgCriticalSection;

{$IFDEF MSWINDOWS}
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

var
 CriticalSections: TThreadList;

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

procedure InitCSect(var CSect: TRTLCriticalSection; Owner: AnsiString = ''; Log: Boolean = False);
var
 CSection:  PMsgCriticalSection;
begin
{$IFDEF LOG_CSECT}
if Log then
aaWriteToLog('!!! InitCSect, Owner = ' + Owner);
{$ENDIF}
 New(CSection);
 CSection.CSect := @CSect;
 CSection.Log := Log;
 CSection.Owner := Owner;
 if CriticalSections <> nil then
   CriticalSections.Add(CSection);
 InitializeCriticalSection(CSect);
{$IFDEF LOG_CSECT}
if Log then
aaWriteToLog('### InitCSect, Owner = ' + Owner);
{$ENDIF}
end;

procedure EnterCSect(var CSect: TRTLCriticalSection);
var
 CSection: PMsgCriticalSection;
begin
{$IFDEF LOG_CSECT}
//aaWriteToLog('>>> EnterCSect');
 CSection := FindCSect(CSect);
 if CSection <> nil then
  if CSection.Log then
    aaWriteToLog('>>> Critical Section '+IntToStr(Integer(@CSect))
                  +' Owner = '+CSection.Owner+' Enter... Locked '
                  +IntToStr(CSect.LockCount)+' times in '
                  +IntToStr(CSect.RecursionCount)+' recursion by Thread '
                  +IntToStr(CSect.OwningThread));
{$ENDIF}
 EnterCriticalSection(CSect);
{$IFDEF LOG_CSECT}
 if CSection <> nil then
  if CSection.Log then
    aaWriteToLog('### Critical Section '+IntToStr(Integer(@CSect))
                  +' Owner = '+CSection.Owner+' Entered! Locked '
                  +IntToStr(CSect.LockCount)+' times in '
                  +IntToStr(CSect.RecursionCount)+' recursion by Thread '
                  +IntToStr(CSect.OwningThread));
// aaWriteToLog('### EnterCSect');
{$ENDIF}
end;

procedure LeaveCSect(var CSect: TRTLCriticalSection);
var
 CSection: PMsgCriticalSection;
begin
{$IFDEF LOG_CSECT}
// aaWriteToLog('>>> LeaveCSect');
 CSection := FindCSect(CSect);
 if CSection <> nil then
  if CSection.Log then
    aaWriteToLog('<<< Critical Section '+IntToStr(Integer(@CSect))
                  +' Owner = '+CSection.Owner+' Leave... Locked '
                  +IntToStr(CSect.LockCount)+' times in '
                  +IntToStr(CSect.RecursionCount)+' recursion by Thread '
                  +IntToStr(CSect.OwningThread));
{$ENDIF}
{$IFNDEF LOG_CSECT}
{
 if ( (CSect.OwningThread <> 0)
  and (CSect.LockCount >= -1)
  and (CSect.RecursionCount >= 0) ) then // to avoid leaving without entering
}
{$ENDIF}
   LeaveCriticalSection(CSect);
{$IFDEF LOG_CSECT}
 if CSection <> nil then
  if CSection.Log then
    aaWriteToLog('### Critical Section '+IntToStr(Integer(@CSect))
                  +' Owner = '+CSection.Owner+' Left!    Locked '
                  +IntToStr(CSect.LockCount)+' times in '
                  +IntToStr(CSect.RecursionCount)+' recursion by Thread '
                  +IntToStr(CSect.OwningThread));
//aaWriteToLog('### LeaveCSect');
{$ENDIF}
end;

procedure LeaveAllCSect(ThreadID: Cardinal);
var
  i: Integer;
  CSection: PMsgCriticalSection;
  CSect: PRTLCriticalSection;
  CSections: TList;
begin
{$IFDEF LOG_CSECT}
aaWriteToLog('>>> LeaveAllCSect');
{$ENDIF}
 try
 if CriticalSections = nil then Exit;
 CSections := CriticalSections.LockList;
  try
{$IFDEF LOG_CSECT}
//aaWriteToLog('LeaveAllCSect start: Rest Count = '+IntToStr(CSections.Count));
{$ENDIF}
   for i := CSections.Count-1 downto 0 do
    begin
{$IFDEF LOG_CSECT}
//    aaWriteToLog('LeaveAllCSect: i = '+IntToStr(i));
{$ENDIF}
     CSection := CSections.Items[i];
     CSect := CSection.CSect;
     if CSect.OwningThread = ThreadID then
      begin
{$IFDEF LOG_CSECT}
if CSection.Log then
aaWriteToLog('LeaveAllCSect: by current ThreadID = '+IntToStr(CSect.OwningThread)+', unlock...');
{$ENDIF}
       if CSect.LockCount < 0 then
        begin
{$IFDEF LOG_CSECT}
if CSection.Log then
aaWriteToLog('LeaveAllCSect: not locked! LockCount = '+IntToStr(CSect.LockCount));
{$ENDIF}
        end
       else
        while CSect.RecursionCount > 0 do
         begin
{$IFDEF LOG_CSECT}
if CSection.Log then
aaWriteToLog('LeaveAllCSect: Critical Section '+IntToStr(Integer(CSect))
                  +' Owner = '+CSection.Owner+' LeaveAll Locked '
                  +IntToStr(CSect.LockCount)+' times in '
                  +IntToStr(CSect.RecursionCount)+' recursion by Thread '
                  +IntToStr(CSect.OwningThread));
{$ENDIF}
          LeaveCriticalSection(CSect^);
{$IFDEF LOG_CSECT}
if CSection.Log then
aaWriteToLog('LeaveAllCSect: Critical Section '+IntToStr(Integer(CSect))
                  +' Owner = '+CSection.Owner+' LeftAll  Locked '
                  +IntToStr(CSect.LockCount)+' times in '
                  +IntToStr(CSect.RecursionCount)+' recursion by Thread '
                  +IntToStr(CSect.OwningThread));
{$ENDIF}
         end;
      end
     else
      begin
{$IFDEF LOG_CSECT}
if CSection.Log then
aaWriteToLog('LeaveAllCSect: Skip - foreign ThreadID = '+IntToStr(CSect.OwningThread)
                  +' Owner = '+CSection.Owner+', Locked '
                  +IntToStr(CSect.LockCount)+' times');
{$ENDIF}
      end;
    end;
  finally
{$IFDEF LOG_CSECT}
//aaWriteToLog('LeaveAllCSect finally: Rest Count = '+IntToStr(CSections.Count));
{$ENDIF}
   CriticalSections.UnlockList;
{$IFDEF LOG_CSECT}
//aaWriteToLog('### LeaveAllCSect');
{$ENDIF}
  end;
 except
{$IFDEF LOG_CSECT}
//aaWriteToLog('LeaveAllCSect: exception!!!');
{$ENDIF}
 end;
end;

procedure DeleteCSect(var CSect: TRTLCriticalSection);
var
 CSection: PMsgCriticalSection;
begin
{$IFDEF LOG_CSECT}
aaWriteToLog('>>> DeleteCSect');
{$ENDIF}
 CSection := FindCSect(CSect);
{$IFDEF LOG_CSECT}
 if CSection <> nil then
  if CSection.Log then
    aaWriteToLog('!!! Critical Section '+IntToStr(Integer(@CSect))+' Delete.. Locked '
                  +IntToStr(CSect.LockCount)+' times in '
                  +IntToStr(CSect.RecursionCount)+' recursion by Thread '
                  +IntToStr(CSect.OwningThread));
{$ENDIF}
 DeleteCriticalSection(CSect);
{$IFDEF LOG_CSECT}
 if CSection <> nil then
  if CSection.Log then
    aaWriteToLog('### Critical Section '+IntToStr(Integer(@CSect))+' Deleted!');
{$ENDIF}
 if CriticalSections <> nil then
   CriticalSections.Remove(CSection);
 Dispose(CSection);
{$IFDEF LOG_CSECT}
aaWriteToLog('### DeleteCSect');
{$ENDIF}
end;

function FindCSect(var CSect: TRTLCriticalSection): PMsgCriticalSection;
var
 i:         Integer;
 CSections: TList;
 CSection:  PRTLCriticalSection;
begin
{$IFDEF LOG_CSECT}
//aaWriteToLog('  > FindCSect, CSect = '+IntToStr(Integer(@CSect)));
{$ENDIF}
 try
  Result := nil;
  if CriticalSections = nil then Exit;
  CSections := CriticalSections.lockList;
  try
{$IFDEF LOG_CSECT}
//aaWriteToLog('CSections.Count...');
//aaWriteToLog('CSections.Count = '+IntToStr(CSections.Count));
{$ENDIF}
   for i := CSections.Count-1 downto 0 do
    begin
{$IFDEF LOG_CSECT}
// aaWriteToLog('i = '+IntToStr(i));
{$ENDIF}
     CSection := PMsgCriticalSection(CSections.Items[i]).CSect;
     if CSection = @CSect then
      begin
       Result := CSections.Items[i];
{$IFDEF LOG_CSECT}
       if Result.Log then
aaWriteToLog(' -> Found, i  = '+IntToStr(i)+', Owner = '+PMsgCriticalSection(CSections.Items[i]).Owner);
{$ENDIF}
       break;
      end;
    end;
  finally
   CriticalSections.UnlockList;
{$IFDEF LOG_CSECT}
//aaWriteToLog('  # FindCSect');
{$ENDIF}
  end;
 except
{$IFDEF LOG_CSECT}
aaWriteToLog('FindCSect: exception!!!');
{$ENDIF}
 end;
end;

var
 CSections: TList;
 CSect:     PRTLCriticalSection;
 i:         Integer;


initialization

{$IFDEF DEBUG_LOG_INIT}
// aaWriteToLog(#13#10+FOwnerName+' '+IntToHex(Integer(FOwner),8)+' :'+#13#10+'ACRCriticalSection> try to initialize...');
{$ENDIF}
{$IFDEF LOG_CSECT}
aaWriteToLog('MsgCriticalSection> try to initialize...');
{$ENDIF}

 CriticalSections := TThreadList.Create;

{$IFDEF DEBUG_LOG_INIT}
// aaWriteToLog(#13#10+FOwnerName+' '+IntToHex(Integer(FOwner),8)+' :'+#13#10+'ACRCriticalSection> initialized');
{$ENDIF}
{$IFDEF LOG_CSECT}
aaWriteToLog('MsgCriticalSection> initialized');
{$ENDIF}

finalization

{$IFDEF LOG_CSECT}
 if CriticalSections <> nil then
  begin
   CSections := CriticalSections.LockList;
   try
aaWriteToLog('MsgCriticalSection> Rest Count = '+IntToStr(CSections.Count));
   finally
    CriticalSections.UnlockList;
   end;
  end;
{$ENDIF}

 CriticalSections.free;
 CriticalSections := nil;

end.
