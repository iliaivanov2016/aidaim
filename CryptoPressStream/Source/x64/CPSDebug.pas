//==============================================================================
// Unit name: CPSDebug
// Copyright 2000-2003 AidAim Software.
// Debug library, contains time measurement routines.
// Date: 04/18/2003
//==============================================================================
unit CPSDebug;

{$I CPSVer.inc}

interface

uses
{$IFDEF MSWINDOWS}
 Windows,
 Dialogs,
{$ENDIF}
{$IFDEF LINUX}
 Libc,
 QDialogs,
{$ENDIF}
 Classes, SysUtils;

var DebugOff:       Boolean = False;
    DebugStarted:   Boolean = False;

type
  TCPSTestTime = record
   name:          AnsiString;
   startTime:     Integer;
   stopTime:      Integer;
   timeStarted:   Boolean;
   timeRestarted: Boolean;
  end;

  TCPSCounter = record
   name:          AnsiString;
   Value:         Int64;
  end;

var
//    FCSect:         TRTLCriticalSection;
    startTime, stopTime : Integer;
    timeStarted   : Boolean = false; // if true - time is counting, else - pause
    timeRestarted : Boolean = false; // if true - restart time counting
    DefaultCounter: TCPSCounter;
    Counter1:       TCPSCounter;
    Counter2:       TCPSCounter;
    Counter3:       TCPSCounter;
    Counter4:       TCPSCounter;
    Counter5:       TCPSCounter;
    Counter6:       TCPSCounter;
    Counter7:       TCPSCounter;
    Counter8:       TCPSCounter;
    Counter9:       TCPSCounter;
    Counter10:       TCPSCounter;

    TimeNo: Integer;
    time1,time2,time3,time4,time5: TCPSTestTime;
    time6,time7,time8,time9,time10: TCPSTestTime;

{$IFDEF LINUX}
const logName = '/home/guest/Accuracer/log.txt';
{$ENDIF}
{$IFDEF MSWINDOWS}
var logFileName: AnsiString;
const logPath = 's:\';
{$ENDIF}

function aaGetTickCount: Cardinal;

// gets counted time in milliseconds (based on aaGetTickCount)
function aaGetTime : Integer; overload;
function aaGetTime(var TimeRec: TCPSTestTime): Integer; overload;
// inits time counting
procedure aaInitTime; overload;
procedure aaInitTime(var TimeRec: TCPSTestTime); overload;
// starts time counting from current time
procedure aaStartTime; overload;
procedure aaStartTime(var TimeRec: TCPSTestTime); overload;
// stops time counting
procedure aaStopTime; overload;
procedure aaStopTime(var TimeRec: TCPSTestTime); overload;
// shows time
procedure aaShowTime; overload;
procedure aaShowTime(var TimeRec: TCPSTestTime); overload;
// write time to log
procedure aaWriteTime; overload;
procedure aaWriteTime(var TimeRec: TCPSTestTime); overload;

function aaGetLogFileName: AnsiString;
// writes AnsiString to log file
procedure aaWriteToLog(s : AnsiString); // writes AnsiString to log file
procedure aaWriteBufferToLog(Buffer: PAnsiChar; BufferSize: Integer; FileName: String='');
// delete log
procedure EmptyLog;

procedure aaInitCounter;  overload;
procedure aaIncCounter(Increment: Int64 = 1);  overload;
procedure aaDecCounter(Decrement: Int64 = 1);  overload;
function aaGetCounter: Int64;  overload;
procedure aaSetCounter(Value: Int64);  overload;
procedure aaShowCounter;  overload;

procedure aaInitCounter(var Counter: TCPSCounter; Name: AnsiString); overload;
procedure aaIncCounter(var Counter: TCPSCounter; Increment: Int64 = 1);  overload;
procedure aaDecCounter(var Counter: TCPSCounter; Decrement: Int64 = 1);  overload;
function aaGetCounter(var Counter: TCPSCounter): Int64;  overload;
procedure aaSetCounter(var Counter: TCPSCounter; Value: Int64);  overload;
procedure aaShowCounter(var Counter: TCPSCounter);  overload;

function aaGetCurrentTimeAsString: AnsiString;
procedure aaInitAll;

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
// gets counted time in milliseconds (based on aaGetTickCount)
function aaGetTime : Integer;
begin
 if (timeStarted) then
  Result := aaGetTickCount - startTime
 else
  Result := stopTime - startTime;
end; // aaGetTime

function aaGetTime(var TimeRec: TCPSTestTime): Integer;
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
procedure aaInitTime(var TimeRec: TCPSTestTime);
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
procedure aaStartTime(var TimeRec: TCPSTestTime);
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
procedure aaStopTime(var TimeRec: TCPSTestTime);
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
procedure aaShowTime(var TimeRec: TCPSTestTime);
begin
 ShowMessage(TimeRec.name + ' = ' + inttostr(aaGetTime(TimeRec)));
end;


// write time to log
procedure aaWriteTime;
begin
 aaWriteToLog('time = '+inttostr(aaGetTime));
end;


procedure aaWriteTime(var TimeRec: TCPSTestTime);
begin
 aaWriteToLog(TimeRec.name + inttostr(aaGetTime(TimeRec)));
end;


//-------------------------------- DEBUG ---------------------------------------
// writes AnsiString to log file

function aaGetLogFileName: AnsiString;
begin
// Result := LogPath + 'log_'+ExtractFileName(ParamStr(0))+

 Result := ExtractFilePath(ParamStr(0)) + 'log_'+ExtractFileName(ParamStr(0))+
 '.txt';

// Result := 'S:\CPS.log'
end;

procedure aaWriteToLog(s : AnsiString);
var f : Text;
begin
{$IFNDEF DEBUG_LOG}
 Exit;
{$ENDIF}
 if (DebugOff) then
   Exit;

 Assign(f,logFileName);
 if (FileExists(logFileName)) then
  Append(f)
 else
  ReWrite(f);
 Writeln(f,s);
 Close(f);

end;

procedure aaWriteBufferToLog(Buffer: PAnsiChar; BufferSize: Integer; FileName: String);
var fs: TFileStream;
begin
 aaWriteToLog('--------- Buffer Size = '+IntToStr(BufferSize)+' ---------');
// EnterCriticalSection(FCSect);
 if (Length(FileName)<=0) then
 begin
  FileName := logFileName;
  fs := TFileStream.Create(FileName,fmOpenReadWrite);
 end
 else
 begin
  DeleteFile(FileName);
  fs := TFileStream.Create(FileName,fmCreate);
 end;
 try
  fs.Position := fs.Size;
  fs.WriteBuffer(Buffer^,BufferSize);
 finally
  fs.Free;
 end;
// LeaveCriticalSection(FCSect);
 aaWriteToLog(#13#10+'------------------------------------');
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

procedure aaInitCounter(var Counter: TCPSCounter; Name: AnsiString);
begin
 Counter.Name := Name;
 Counter.Value := 0;
end;

procedure aaIncCounter(var Counter: TCPSCounter; Increment: Int64 = 1);
begin
 Inc(Counter.Value, Increment);
end;



procedure aaDecCounter(var Counter: TCPSCounter; Decrement: Int64 = 1);
begin
 Dec(Counter.Value, Decrement);
end;

function aaGetCounter(var Counter: TCPSCounter): Int64;
begin
 Result := Counter.Value;
end; //


procedure aaSetCounter(var Counter: TCPSCounter; Value: Int64);
begin
 Counter.Value := Value;
end;


procedure aaShowCounter(var Counter: TCPSCounter);
begin
 ShowMessage(Counter.Name + ' = '+IntToStr(Counter.Value));
end; //


function aaGetCurrentTimeAsString: AnsiString;
begin
 Result := IntToStr(aaGetTickCount)+',';
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


initialization

// ShowMessage('CPSDebug initialization started');

// InitializeCriticalSection(FCSect);

 aaInitAll;

{$IFDEF LINUX}
 logFileName := logName;
{$ENDIF}
{$IFDEF MSWINDOWS}
 logFileName := aaGetLogFileName;
{$ENDIF}
 // Delete Old Log !
 DeleteFile(logFileName);

{$IFDEF DEBUG_LOG_INIT}
 aaWriteToLog('CPSDebug initialization - OK');
{$ENDIF}

// DeleteCriticalSection(FCSect);

end.
