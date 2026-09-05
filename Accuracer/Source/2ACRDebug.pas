//==============================================================================
// Unit name: ACRDebug
// Copyright 2000-2008 AidAim Software.
// Debug library, contains time measurement routines.
// Date: 07/12/2008
//==============================================================================
unit ACRDebug;

{$I ACRVer.inc}
{DEFINE DEBUG_LOG}

interface

{$DEFINE DEBUG_SEPARATE_LOG_FOR_EACH_THREAD}
{DEFINE DEBUG_CRITICAL_SECTIONS}
{DEFINE DEBUG_FORMS}
{DEFINE DEBUG_DELETE_LOG}

uses
{$IFDEF MSWINDOWS}
 Windows,
 Dialogs,
{$ENDIF}
{$IFDEF LINUX}
 Libc,
 QDialogs,
{$ENDIF}
{$IFDEF DEBUG_FORMS}
 Forms,
{$ENDIF}
 Classes, SysUtils;

var DebugOff:       Boolean = False;
    DebugStarted:   Boolean = False;
    InMemory:       Boolean = False;
//    InMemory:       Boolean = True;

type
  TACRTestTime = record
   name:          AnsiString;
   startTime:     Integer;
   stopTime:      Integer;
   timeStarted:   Boolean;
   timeRestarted: Boolean;
  end;

  TACRCounter = record
   name:          AnsiString;
   Value:         Int64;
  end;

var
    FCSect:         TRTLCriticalSection;
    ms:             TMemoryStream;
    startTime, stopTime : Integer;
    timeStarted   : Boolean = false; // if true - time is counting, else - pause
    timeRestarted : Boolean = false; // if true - restart time counting
    DefaultCounter: TACRCounter;
    Counter1:       TACRCounter;
    Counter2:       TACRCounter;
    Counter3:       TACRCounter;
    Counter4:       TACRCounter;
    Counter5:       TACRCounter;
    Counter6:       TACRCounter;
    Counter7:       TACRCounter;
    Counter8:       TACRCounter;
    Counter9:       TACRCounter;
    Counter10:       TACRCounter;

    TimeNo: Integer;
    time1,time2,time3,time4,time5: TACRTestTime;
    time6,time7,time8,time9,time10: TACRTestTime;
    time11,time12,time13,time14,time15: TACRTestTime;
    time16,time17,time18,time19,time20: TACRTestTime;

    memAvail1,memAvail2,memAvail3,memAvail4 : LongWord;

{$IFDEF LINUX}
const logName = '/home/guest/MsgCommunicator/log.txt';
{$ENDIF}
{$IFDEF MSWINDOWS}
var logFileName: AnsiString;
const logPath = 's:\';
{$ENDIF}

function aaGetTickCount: Cardinal;

procedure aaSaveMemAvail(var memAvail: LongWord);
function aaGetMemDiff(const memAvail1: LongWord; const memAvail2: LongWord): Longword;
// gets counted time in milliseconds (based on aaGetTickCount)
function aaGetTime : Integer; overload;
function aaGetTime(var TimeRec: TACRTestTime): Integer; overload;
// inits time counting
procedure aaInitTime; overload;
procedure aaInitTime(var TimeRec: TACRTestTime); overload;
// starts time counting from current time
procedure aaStartTime; overload;
procedure aaStartTime(var TimeRec: TACRTestTime); overload;
// stops time counting
procedure aaStopTime; overload;
procedure aaStopTime(var TimeRec: TACRTestTime); overload;
// shows time
procedure aaShowTime; overload;
procedure aaShowTime(var TimeRec: TACRTestTime); overload;
// write time to log
procedure aaWriteTime; overload;
procedure aaWriteTime(var TimeRec: TACRTestTime); overload;

function aaGetLogFileName: AnsiString;
// writes AnsiString to log file
procedure aaWriteToLog(s : AnsiString); // writes AnsiString to log file
procedure aaWriteBufferToLog(Buffer: PAnsiChar; BufferSize: Integer);
// delete log
procedure EmptyLog;

procedure aaInitCounter;  overload;
procedure aaIncCounter(Increment: Int64 = 1);  overload;
procedure aaDecCounter(Decrement: Int64 = 1);  overload;
function aaGetCounter: Int64;  overload;
procedure aaSetCounter(Value: Int64);  overload;
procedure aaShowCounter;  overload;

procedure aaInitCounter(var Counter: TACRCounter; Name: AnsiString); overload;
procedure aaIncCounter(var Counter: TACRCounter; Increment: Int64 = 1);  overload;
procedure aaDecCounter(var Counter: TACRCounter; Decrement: Int64 = 1);  overload;
function aaGetCounter(var Counter: TACRCounter): Int64;  overload;
procedure aaSetCounter(var Counter: TACRCounter; Value: Int64);  overload;
procedure aaShowCounter(var Counter: TACRCounter);  overload;

function aaGetCurrentTimeAsString: AnsiString;
procedure aaInitAll;
procedure aaWriteLogToDisk;
procedure aaWriteAllTimesToLog;
procedure aaWriteallCountersToLog;
procedure aaWriteComponentState(Component: TComponent);
{$IFDEF DEBUG_FORMS}
procedure aaWriteFormState(Component: TForm);
{$ENDIF}
implementation


//------------------------------------------------------------------------------
// aaGetTickCount
//------------------------------------------------------------------------------
{$IFDEF LINUX}
function aaGetTickCount: Cardinal;
var
  tv: timeval;
begin
  gettimeofday(tv, nil);
  {$RANGECHECKS OFF}
  Result := int64(tv.tv_sec) * 1000 + tv.tv_usec div 1000;
end; // aaGetTickCount
{$ENDIF}

{$IFDEF MSWINDOWS}
function aaGetTickCount: Cardinal;
begin
  Result := Windows.GetTickCount;
end; // aaGetTickCount
{$ENDIF}

//-------------------------------- DEBUG ---------------------------------------

// save availPhys of GlobalMemoryStatus to variable
procedure aaSaveMemAvail(var memAvail: LongWord);
var lp: TMemoryStatus;
begin
 GlobalMemoryStatus(lp);
 memAvail := lp.dwAvailPhys;
end; // aaSaveMemAvail


// return difference between 2 saved availPhys
function aaGetMemDiff(const memAvail1: LongWord; const memAvail2: LongWord): Longword;
begin
 Result := 0;
 if (memAvail1 > memAvail2) then
  Result := (memAvail1 - memAvail2);
end; // aaGetMemDiff


// gets counted time in milliseconds (based on aaGetTickCount)
function aaGetTime : Integer;
begin
 if (timeStarted) then
  Result := aaGetTickCount - startTime
 else
  Result := stopTime - startTime;
end; // aaGetTime

function aaGetTime(var TimeRec: TACRTestTime): Integer;
begin
 if (TimeRec.timeStarted) then
  Result := aaGetTickCount - TimeRec.startTime
 else
  Result := TimeRec.stopTime - TimeRec.startTime;
end; // aaGetTime



// inits time counting
procedure aaInitTime;
begin
 timeRestarted := true;
 startTime := 0;
 stopTime := 0;
 timeStarted := false;
end;


// inits time counting
procedure aaInitTime(var TimeRec: TACRTestTime);
begin
 if (TimeRec.name = '') then
  begin
   Inc(TimeNo);
   TimeRec.name := 'Time '+IntToStr(TimeNo);
  end;
 TimeRec.timeRestarted := true;
 TimeRec.startTime := 0;
 TimeRec.stopTime := 0;
 TimeRec.timeStarted := false;
end;


// starts time counting from current time
procedure aaStartTime;
begin
 if (timeRestarted) then
  begin
   startTime := aaGetTickCount;
   timeRestarted := false;
   timeStarted := true;
  end
 else
  if (not timeStarted) then
   begin
    startTime := startTime + aaGetTickCount - stopTime;
   end;
end;


// starts time counting from current time
procedure aaStartTime(var TimeRec: TACRTestTime);
begin
 if (TimeRec.timeRestarted) then
  begin
   TimeRec.startTime := aaGetTickCount;
   TimeRec.timeRestarted := false;
   TimeRec.timeStarted := true;
  end
 else
  if (not TimeRec.timeStarted) then
   begin
    TimeRec.startTime := TimeRec.startTime + aaGetTickCount - TimeRec.stopTime;
   end;
end;


// stops time counting
procedure aaStopTime;
begin
 timeStarted := false;
 stopTime := aaGetTickCount;
end;


// stops time counting
procedure aaStopTime(var TimeRec: TACRTestTime);
begin
 TimeRec.timeStarted := false;
 TimeRec.stopTime := aaGetTickCount;
end;


// shows time
procedure aaShowTime;
begin
 ShowMessage('time = '+inttostr(aaGetTime));
end;


// shows time
procedure aaShowTime(var TimeRec: TACRTestTime);
begin
 ShowMessage(TimeRec.name + ' = ' + inttostr(aaGetTime(TimeRec)));
end;


// write time to log
procedure aaWriteTime;
begin
 aaWriteToLog('time = '+inttostr(aaGetTime));
end;


procedure aaWriteTime(var TimeRec: TACRTestTime);
begin
 aaWriteToLog(TimeRec.name + inttostr(aaGetTime(TimeRec)));
end;


//-------------------------------- DEBUG ---------------------------------------
// writes AnsiString to log file

function aaGetLogFileName: AnsiString;
begin
// Result := LogPath + 'log_'+ExtractFileName(ParamStr(0))+

 Result := ExtractFilePath(ParamStr(0)) + 'acr_log_'+ExtractFileName(ParamStr(0))+
 '.txt';

// Result := 'S:\msg.log'
end;

procedure aaWriteToLog(s : AnsiString);
var
    s1:   AnsiString;
    name: AnsiString;
    fh:   Integer;
begin
{$IFNDEF DEBUG_LOG}
 Exit;
{$ENDIF}
 if (DebugOff) then
   Exit;
{$IFDEF DEBUG_CRITICAL_SECTIONS}
 EnterCriticalSection(FCSect);
{$ENDIF}
try
 s1 := aaGetCurrentTimeAsString+s+ #13#10;
 if (InMemory) then
  begin
   ms.Position := ms.Size;
   ms.Write(s1[1],Length(s1));
   Exit;
  end;
 fh := -1;
 {$IFDEF DEBUG_SEPARATE_LOG_FOR_EACH_THREAD}
 name := StringReplace(logFileName,'.txt','_'+IntToStr(GetCurrentThreadId)+'.txt',[rfReplaceAll,rfIgnoreCase]);
 {$ELSE}
 name := logFileName;
 {$ENDIF}
 while (fh < 0) do
  try
   if (SysUtils.FileExists(name)) then
    fh := SysUtils.FileOpen(name,fmOpenReadWrite or fmShareDenyWrite)
   else
    fh := SysUtils.FileCreate(name);
  except
   fh := -1;
   sleep(0);
  end;
 try
  FileSeek(fh,0,soFromEnd);
  FileWrite(fh,s1[1],Length(s1));
 finally
  if (fh >= 0) then
   SysUtils.FileClose(fh);
 end;
finally
 {$IFDEF DEBUG_CRITICAL_SECTIONS}
  LeaveCriticalSection(FCSect);
 {$ENDIF}
end;

end;

procedure aaWriteBufferToLog(Buffer: PAnsiChar; BufferSize: Integer);
var fh: Integer;
begin
{$IFDEF DEBUG_CRITICAL_SECTIONS}
EnterCriticalSection(FCSect);
{$ENDIF}
try
 aaWriteToLog('--------- Buffer Size = '+IntToStr(BufferSize)+' ---------');
 if (InMemory) then
  begin
   ms.Position := ms.Size;
   ms.Write(Buffer^,BufferSize);
  end
 else
  begin
    // EnterCriticalSection(FCSect);
     if (BufferSize > 0) then
      begin
       fh := -1;
       while (fh < 0) do
        try
         if (SysUtils.FileExists(logFileName)) then
          fh := SysUtils.FileOpen(logFileName,fmOpenReadWrite or fmShareDenyWrite)
         else
          fh := SysUtils.FileCreate(logFileName);
        except
         fh := -1;
         sleep(0);
        end;
       try
        FileSeek(fh,0,soFromEnd);
        FileWrite(fh,Buffer^,BufferSize);
       finally
        if (fh >= 0) then
         SysUtils.FileClose(fh);
       end;
      end;
    // LeaveCriticalSection(FCSect);
  end;
 aaWriteToLog(#13#10+'------------------------------------');
finally
 {$IFDEF DEBUG_CRITICAL_SECTIONS}
  LeaveCriticalSection(FCSect);
 {$ENDIF}
end;
end;

procedure EmptyLog;
var f: text;
begin
 Assign(f,logFileName);
 ReWrite(f);
 Close(f);
end;


procedure aaInitCounter;
begin
 DefaultCounter.Name := 'Default Counter';
 DefaultCounter.Value := 0;
end; //


procedure aaIncCounter(Increment: Int64);
begin
 Inc(DefaultCounter.Value, Increment);
end; //


procedure aaDecCounter(Decrement: Int64);
begin
 Dec(DefaultCounter.Value, Decrement);
end; //


function aaGetCounter: Int64;
begin
 Result := DefaultCounter.Value;
end; //

procedure aaSetCounter(Value: Int64);
begin
 DefaultCounter.Value := Value;
end;

procedure aaShowCounter;
begin
 ShowMessage(DefaultCounter.Name + ' = '+IntToStr(DefaultCounter.Value));
end; //

procedure aaInitCounter(var Counter: TACRCounter; Name: AnsiString);
begin
 Counter.Name := Name;
 Counter.Value := 0;
end;

procedure aaIncCounter(var Counter: TACRCounter; Increment: Int64 = 1);
begin
 Inc(Counter.Value, Increment);
end;



procedure aaDecCounter(var Counter: TACRCounter; Decrement: Int64 = 1);
begin
 Dec(Counter.Value, Decrement);
end;

function aaGetCounter(var Counter: TACRCounter): Int64;
begin
 Result := Counter.Value;
end; //


procedure aaSetCounter(var Counter: TACRCounter; Value: Int64);
begin
 Counter.Value := Value;
end;


procedure aaShowCounter(var Counter: TACRCounter);
begin
 ShowMessage(Counter.Name + ' = '+IntToStr(Counter.Value));
end; //


function aaGetCurrentTimeAsString: AnsiString;
begin
 Result := IntToStr(aaGetTickCount)+#9+'PrID = '+IntToStr(GetCurrentProcessId)+', ThID = '+IntToStr(GetCurrentThreadId)+':'+#9;
end;

procedure aaInitAll;
begin
 TimeNo := 0;
 aaInitTime;
 aaInitTime(time1);
 aaInitTime(time2);
 aaInitTime(time3);
 aaInitTime(time4);
 aaInitTime(time5);
 aaInitTime(time6);
 aaInitTime(time7);
 aaInitTime(time8);
 aaInitTime(time9);
 aaInitTime(time10);
 aaInitTime(time11);
 aaInitTime(time12);
 aaInitTime(time13);
 aaInitTime(time14);
 aaInitTime(time15);
 aaInitTime(time16);
 aaInitTime(time17);
 aaInitTime(time18);
 aaInitTime(time19);
 aaInitTime(time20);
 aaInitCounter;
 aaInitCounter(Counter1,'counter1');
 aaInitCounter(Counter2,'counter2');
 aaInitCounter(Counter3,'counter3');
 aaInitCounter(Counter4,'counter4');
 aaInitCounter(Counter5,'counter5');
 aaInitCounter(Counter6,'counter6');
 aaInitCounter(Counter7,'counter7');
 aaInitCounter(Counter8,'counter8');
 aaInitCounter(Counter9,'counter9');
 aaInitCounter(Counter10,'counter10');
end;

procedure aaWriteLogToDisk;
begin
 if (not InMemory) then
  Exit;
 {$IFDEF DEBUG_CRITICAL_SECTIONS}
  EnterCriticalSection(FCSect);
 {$ENDIF}
 try
   if (FileExists(logFileName)) then
    SysUtils.DeleteFile(logFileName);
   ms.Position := 0;
   ms.SaveToFile(logFileName);
 finally
 {$IFDEF DEBUG_CRITICAL_SECTIONS}
  LeaveCriticalSection(FCSect);
 {$ENDIF}
 end;
end;


procedure aaWriteAllTimesToLog;
begin
aaWriteToLog('Overall time = '+IntToStr(aaGetTime));
aaWriteToLog('time1 = '+IntToStr(aaGetTime(time1)));
aaWriteToLog('time2 = '+IntToStr(aaGetTime(time2)));
aaWriteToLog('time3 = '+IntToStr(aaGetTime(time3)));
aaWriteToLog('time4 = '+IntToStr(aaGetTime(time4)));
aaWriteToLog('time5 = '+IntToStr(aaGetTime(time5)));
aaWriteToLog('time6 = '+IntToStr(aaGetTime(time6)));
aaWriteToLog('time7 = '+IntToStr(aaGetTime(time7)));
aaWriteToLog('time8 = '+IntToStr(aaGetTime(time8)));
aaWriteToLog('time9 = '+IntToStr(aaGetTime(time9)));
aaWriteToLog('time10 = '+IntToStr(aaGetTime(time10)));
aaWriteToLog('time11 = '+IntToStr(aaGetTime(time11)));
aaWriteToLog('time12 = '+IntToStr(aaGetTime(time12)));
aaWriteToLog('time13 = '+IntToStr(aaGetTime(time13)));
aaWriteToLog('time14 = '+IntToStr(aaGetTime(time14)));
aaWriteToLog('time15 = '+IntToStr(aaGetTime(time15)));
aaWriteToLog('time16 = '+IntToStr(aaGetTime(time16)));
aaWriteToLog('time17 = '+IntToStr(aaGetTime(time17)));
aaWriteToLog('time18 = '+IntToStr(aaGetTime(time18)));
aaWriteToLog('time19 = '+IntToStr(aaGetTime(time19)));
aaWriteToLog('time20 = '+IntToStr(aaGetTime(time20)));
end;

procedure aaWriteallCountersToLog;
begin
aaWriteToLog('counter = '+IntToStr(aaGetCounter));
aaWriteToLog('counter1 = '+IntToStr(aaGetCounter(counter1)));
aaWriteToLog('counter2 = '+IntToStr(aaGetCounter(counter2)));
aaWriteToLog('counter3 = '+IntToStr(aaGetCounter(counter3)));
aaWriteToLog('counter4 = '+IntToStr(aaGetCounter(counter4)));
aaWriteToLog('counter5 = '+IntToStr(aaGetCounter(counter5)));
aaWriteToLog('counter6 = '+IntToStr(aaGetCounter(counter6)));
aaWriteToLog('counter7 = '+IntToStr(aaGetCounter(counter7)));
aaWriteToLog('counter8 = '+IntToStr(aaGetCounter(counter8)));
aaWriteToLog('counter9 = '+IntToStr(aaGetCounter(counter9)));
aaWriteToLog('counter10 = '+IntToStr(aaGetCounter(counter10)));
end;

procedure aaWriteComponentState(Component: TComponent);
begin
{
  TComponentState = set of (csLoading, csReading, csWriting, csDestroying,
    csDesigning, csAncestor, csUpdating, csFixups, csFreeNotification,
    csInline, csDesignInstance);

}
 aaWriteToLog('aaWriteComponentState. '+#13#10+'time = '+IntToStr(aaGetTickCount));
 if (Component = nil) then
  aaWriteToLog('aaWriteComponentState - nil pointer')
 else
  begin
   aaWriteToLog('Name = '+Component.Name+#13#10+'ClassName = '+Component.ClassName);
   aaWriteToLog('csAncestor         = '+BoolToStr(csAncestor in Component.ComponentState,true));
   aaWriteToLog('csDesigning        = '+BoolToStr(csDesigning in Component.ComponentState,true));
   aaWriteToLog('csDestroying       = '+BoolToStr(csDestroying in Component.ComponentState,true));
   aaWriteToLog('csFixups           = '+BoolToStr(csFixups in Component.ComponentState,true));
   aaWriteToLog('csFreeNotification = '+BoolToStr(csFreeNotification in Component.ComponentState,true));
   aaWriteToLog('csInline           = '+BoolToStr(csInline in Component.ComponentState,true));
   aaWriteToLog('csLoading          = '+BoolToStr(csLoading in Component.ComponentState,true));
   aaWriteToLog('csReading          = '+BoolToStr(csReading in Component.ComponentState,true));
   aaWriteToLog('csUpdating         = '+BoolToStr(csUpdating in Component.ComponentState,true));
   aaWriteToLog('csWriting          = '+BoolToStr(csWriting in Component.ComponentState,true));
   aaWriteToLog('csDesignInstance   = '+BoolToStr(csDesignInstance in Component.ComponentState,true));
  end;
end;

{$IFDEF DEBUG_FORMS}
procedure aaWriteFormState(Component: TForm);
begin
 aaWriteToLog('aaWriteFormState. '+#13#10+'time = '+IntToStr(aaGetTickCount));
 if (Component = nil) then
  aaWriteToLog('aaWriteFormState - nil pointer')
 else
 if (not (Component is TForm)) then
  aaWriteToLog('aaWriteFormState - not form. ClassName = '+TComponent(Component).ClassName)
 else
  begin
   aaWriteToLog('Name = '+Component.Name+#13#10+'ClassName = '+Component.ClassName);
   aaWriteToLog('fsCreating	         = '+BoolToStr(fsCreating	 in Component.FormState,true));
   aaWriteToLog('fsVisible	         = '+BoolToStr(fsVisible	 in Component.FormState,true));
   aaWriteToLog('fsShowing	         = '+BoolToStr(fsShowing		 in Component.FormState,true));
   aaWriteToLog('fsCreatedMDIChild	 = '+BoolToStr(fsCreatedMDIChild	in Component.FormState,true));
   aaWriteToLog('fsActivated         = '+BoolToStr(fsActivated	in Component.FormState,true));
  end;
end;
{$ENDIF}

initialization

// ShowMessage('MsgDebug initialization started');
 {$IFDEF DEBUG_CRITICAL_SECTIONS}
 InitializeCriticalSection(FCSect);
 {$ENDIF}
 aaInitAll;
// if (inMemory) then
  ms := TMemoryStream.Create;
// else
//  ms := nil;

{$IFDEF LINUX}
 logFileName := logName;
{$ENDIF}
{$IFDEF MSWINDOWS}
 logFileName := aaGetLogFileName;
//logFileName := 's:\log.txt';
{$ENDIF}
 // Delete Old Log !
{$IFDEF DEBUG_DELETE_LOG}
 DeleteFile(logFileName);
{$ENDIF}

{$IFDEF DEBUG_LOG_INIT}
 aaWriteToLog('MsgDebug initialization - OK');
{$ENDIF}
finalization
  if (ms <> nil) then
   begin
    aaWriteLogToDisk;
    ms.Free;
    ms := nil;
   end;
{$IFDEF DEBUG_CRITICAL_SECTIONS}
 DeleteCriticalSection(FCSect);
{$ENDIF}

end.
