unit SQLMemTypesThread;

interface

{$I SQLMemVer.inc}

uses
     SysUtils, Classes,
{$IFDEF MSWINDOWS}
     Controls,
     Windows,
{$ENDIF}

// SQLMemTable units
{$IFDEF LINUX}
     SQLMemLinux,
{$ENDIF}
     {$IFDEF DEBUG_LOG}
     SQLMemDebug,
     {$ENDIF}
     SQLMemConst,
     SQLMemTypes,
     SQLMemCriticalSection,
     SQLMemExcept;


type

//------------------------------------------------------------------------------
// Delphi 4,5 types
//------------------------------------------------------------------------------

{$IFNDEF D6H}
 PWord = ^Word;
 PInteger = ^Integer;
 PByte = ^Byte;
 PCardinal = ^Cardinal;
{$ENDIF}


////////////////////////////////////////////////////////////////////////////////
//
// TMsgThread
//
////////////////////////////////////////////////////////////////////////////////

  TSQLMemThread = class(TThread)
  public
    FFinished: Boolean;
    FRecreate: Boolean;
  public
    constructor Create(Suspended: Boolean);
    destructor Destroy; override;
    function IsTerminated: Boolean;
    property Terminated;
  end;// TSQLMemThread

  PTSQLMemThread = ^TSQLMemThread;

  function FindThread(ThreadID: Cardinal): TSQLMemThread;


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemThreadIntArray
//
////////////////////////////////////////////////////////////////////////////////

type

 TSQLMemThreadIntArray = class(TSQLMemIntegerArray)
   private
    FThreadSync: TSQLMemReadWriteThreadSync;
   public
    constructor Create(
      size: Integer = 0;
      DefaultAllocBy: Integer = 10;
      MaximumAllocBy: Integer = 100
                        );
    destructor Destroy; override;
    procedure Lock(WriteMode: Boolean = true);
    procedure Unlock;
 end; // TSQLMemThreadIntArray


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemThreadList
//
////////////////////////////////////////////////////////////////////////////////

 TSQLMemThreadList = class(TSQLMemList)
  private
    FLock: TRTLCriticalSection;
    FCheckEnter: Boolean;
  public
    constructor Create(
      Owner: AnsiString = '';
      Log: Boolean = False;
      size: Integer = 0;
      DefaultAllocBy: Integer = 10;
      MaximumAllocBy: Integer = 100;
      CheckEnter: Boolean = False
                       );
    destructor Destroy; override;
    procedure Clear;
    function  LockList: TSQLMemList;
    procedure Add(Item: Pointer);
    procedure Remove(Item: Pointer);
    procedure Delete(Index: Integer); override;
    procedure UnlockList;
 end; // TSQLMemThreadList


 var
  FAllThreads:      TThreadList;
  AllThreads:       TList;
  MainThreadID:     Cardinal;
  i:                Integer;
  Err:              Boolean;

implementation

uses SQLMemMemory;


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemThread
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TSQLMemThread.Create(Suspended: Boolean);
begin
{$IFDEF LOG_TSQLMemTHREAD}
aaWriteToLog(Self.ClassName+' - CREATING...   Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
 FFinished := False;
 FRecreate := False;
 inherited Create(Suspended);
 Priority := tpNormal;
 FreeOnTerminate := True;
 FAllThreads.Add(Self);
{$IFDEF LOG_TSQLMemTHREAD}
aaWriteToLog(Self.ClassName+' - CREATED!      Self = '+IntToHex(Integer(Self),8)+#9+'ThreadID = '+IntToStr(ThreadID));
{$ENDIF}
end; // Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TSQLMemThread.Destroy;
begin
{$IFDEF LOG_TSQLMemTHREAD}
aaWriteToLog('TSQLMemThread.Destroy - start');
aaWriteToLog(Self.ClassName+' - DESTROYING... Self = '+IntToHex(Integer(Self),8)+#9+'ThreadID = '+IntToStr(ThreadID));
{$ENDIF}
 LeaveAllCSect(ThreadID);
{$IFDEF LOG_TSQLMemTHREAD}
aaWriteToLog(Self.ClassName+' - All CSect left, inherited...');
{$ENDIF}
 inherited Destroy;
 FFinished := True;
 FAllThreads.Remove(Self);
{$IFDEF LOG_TSQLMemTHREAD}
aaWriteToLog(Self.ClassName+' - DESTROYED!    Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
end; // Destroy


//------------------------------------------------------------------------------
// IsTerminated
//------------------------------------------------------------------------------
function TSQLMemThread.IsTerminated: Boolean;
begin
 Result := Terminated;
end;


function FindThread(ThreadID: Cardinal): TSQLMemThread;
var
 i:         Integer;
 Threads:   TList;
 ID:        Cardinal;
begin
  Result := nil;
  if (FAllThreads = nil) then Exit;
  Threads := FAllThreads.LockList;
// aaWriteToLog('FindThread> Count='+IntToStr(Threads.Count));
// aaWriteToLog('1');
  try
   for i := Threads.Count-1 downto 0 do
    begin
// aaWriteToLog('2');
     ID := TSQLMemThread(Threads.Items[i]).ThreadID;
// aaWriteToLog('3');
     if ThreadID = ID then
      begin
// aaWriteToLog('4');
       Result := TSQLMemThread(Threads.Items[i]);
       break;
      end;
    end;
  finally
// aaWriteToLog('4.5');
   FAllThreads.UnlockList;
// aaWriteToLog('5');
  end;
// aaWriteToLog('6');
end;


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemThreadIntArray
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Construct array of specified size
//------------------------------------------------------------------------------
constructor TSQLMemThreadIntArray.Create(
                                size: Integer;
                                DefaultAllocBy: Integer;
                                MaximumAllocBy: Integer
                                    );
begin
  inherited Create(size, DefaultAllocBy, MaximumAllocBy);
  FThreadSync := TSQLMemReadWriteThreadSyncByCriticalSections.Create(False,Self);
end;//TSQLMemThreadIntArray.Create


//------------------------------------------------------------------------------
// Destruct array (free mem)
//------------------------------------------------------------------------------
destructor TSQLMemThreadIntArray.Destroy;
begin
  FThreadSync.Free;
  inherited Destroy;
end;//TSQLMemThreadIntArray.Destroy;


//------------------------------------------------------------------------------
// Lock
//------------------------------------------------------------------------------
procedure TSQLMemThreadIntArray.Lock(WriteMode: Boolean);
begin
  FThreadSync.Lock(WriteMode);
end;//TSQLMemThreadIntArray.Lock;


//------------------------------------------------------------------------------
// Unlock
//------------------------------------------------------------------------------
procedure TSQLMemThreadIntArray.Unlock;
begin
  FThreadSync.Unlock;
end;//TSQLMemThreadIntArray.Unlock;




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemThreadList
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// TSQLMemThreadList.Create
//------------------------------------------------------------------------------
constructor TSQLMemThreadList.Create(
      Owner: AnsiString = '';
      Log: Boolean = False;
      size: Integer = 0;
      DefaultAllocBy: Integer = 10;
      MaximumAllocBy: Integer = 100;
      CheckEnter: Boolean = False
                       );
begin
  inherited Create(size,DefaultAllocBy,MaximumAllocBy);
  FCheckEnter := CheckEnter;
  InitCSect(FLock,Owner,Log);
end; // TSQLMemThreadList


//------------------------------------------------------------------------------
// TSQLMemThreadList.Destroy
//------------------------------------------------------------------------------
destructor TSQLMemThreadList.Destroy;
begin
  LockList;    // Make sure nobody else is inside the list.
  try
    inherited Destroy;
  finally
    UnlockList;
    DeleteCSect(FLock);
  end;
end; // TSQLMemThreadList.Destroy


//------------------------------------------------------------------------------
// clear list
//------------------------------------------------------------------------------
procedure TSQLMemThreadList.Clear;
begin
  LockList;
  try
    inherited Clear;
  finally
    UnlockList;
  end;
end;


//------------------------------------------------------------------------------
// lock list and return it as TSQLMemList for compatibility with TThreadList
//------------------------------------------------------------------------------
function TSQLMemThreadList.LockList: TSQLMemList;
begin
  EnterCSect(FLock,FCheckEnter);
  Result := TSQLMemList(Self);
end; // LockList


//------------------------------------------------------------------------------
// add item
//------------------------------------------------------------------------------
procedure TSQLMemThreadList.Add(Item: Pointer);
begin
  LockList;
  try
    inherited Add(Item);
  finally
    UnlockList;
  end;
end; // Add


//------------------------------------------------------------------------------
// remove item
//------------------------------------------------------------------------------
procedure TSQLMemThreadList.Remove(Item: Pointer);
begin
  LockList;
  try
   inherited Remove(Item);
   if (Count = 0) then
    Capacity := 0;
  finally
    UnlockList;
  end;
end; // Remove


//------------------------------------------------------------------------------
// delete item by index
//------------------------------------------------------------------------------
procedure TSQLMemThreadList.Delete(Index: Integer);
begin
  LockList;
  try
   inherited Delete(Index);
   if (Count = 0) then
    Capacity := 0;
  finally
    UnlockList;
  end;
end; // Delete


//------------------------------------------------------------------------------
// unlock list
//------------------------------------------------------------------------------
procedure TSQLMemThreadList.UnlockList;
begin
  LeaveCSect(FLock);
end; // UnlockList

// TSQLMemThreadList


initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('> SQLMemTypesThread initialized');
{$ENDIF}
  SQLMemMemoryIncUseCount;

  FAllThreads := TThreadList.Create; // ('AllThreads',true);
  MainThreadID := GetCurrentThreadID;;

finalization

  SQLMemMemoryDecUseCount;

{$IFDEF LOG_THREADS_COUNT}
 if FAllThreads <> nil then
  begin
   AllThreads := FAllThreads.LockList;
   try
aaWriteToLog('SQLMemTypesThread> Threads Rest Count = '+IntToStr(AllThreads.Count));
   finally
    FAllThreads.UnlockList;
   end;
  end;
{$ENDIF}

{$IFDEF LOG_THREADS_COUNT}
aaWriteToLog('SQLMemTypesThread> Terminate all network threads...');
{$ENDIF}
  AllThreads := FAllThreads.LockList;
{$IFDEF LOG_THREADS_COUNT}
aaWriteToLog('SQLMemTypesThread> Hang Count='+IntToStr(AllThreads.Count));
{$ENDIF}
  try
   for i:= AllThreads.Count-1 downto 0 do
    begin
{$IFDEF LOG_THREADS_COUNT}
aaWriteToLog('SQLMemTypesThread> Thread #'+IntToStr(TThread(AllThreads[i]).ThreadID)+'/'+IntToStr(TThread(AllThreads[i]).Handle));
{$ENDIF}
     if TThread(AllThreads[i]) <> nil then
      begin
{$IFDEF LOG_THREADS_COUNT}
aaWriteToLog('SQLMemTypesThread> Ask Thread to Terminate...');
{$ENDIF}
       TThread(AllThreads[i]).Terminate;
      end;
    end;
   sleep(1);
   for i:= AllThreads.Count-1 downto 0 do
    begin
     if TThread(AllThreads[i]) <> nil then
      begin
{$IFDEF LOG_THREADS_COUNT}
aaWriteToLog('SQLMemTypesThread> TerminateThread...');
{$ENDIF}
       Err := TerminateThread(TThread(AllThreads[i]).Handle, 0);
      end;
     if not Err then
      begin
{$IFDEF LOG_THREADS_COUNT}
aaWriteToLog('SQLMemTypesThread> TerminateThread failed. '+ErrorRCannotKillThread+IntToStr(Integer(Err)));
{$ENDIF}
      end;
     if TThread(AllThreads[i]) <> nil then
      if TThread(AllThreads[i]).Handle <> 0 then
       begin
{$IFDEF LOG_THREADS_COUNT}
aaWriteToLog('SQLMemTypesThread> CloseHandle...');
{$ENDIF}
        Err := CloseHandle(TThread(AllThreads[i]).Handle);
       end;
     if not Err then
      begin
{$IFDEF LOG_THREADS_COUNT}
aaWriteToLog('SQLMemTypesThread> CloseHandle failed. '+ErrorRCannotKillThread+IntToStr(Integer(Err)));
{$ENDIF}
      end;
(*
     if TThread(AllThreads[i]) <> nil then
       begin
{$IFDEF LOG_THREADS_COUNT}
aaWriteToLog('SQLMemTypesThread> free...');
{$ENDIF}
        TThread(AllThreads[i]).Free;
       end;
*)
     AllThreads.Delete(i);
{$IFDEF LOG_THREADS_COUNT}
aaWriteToLog('SQLMemTypesThread> Count='+IntToStr(AllThreads.Count));
{$ENDIF}
    end;
  finally
   FAllThreads.UnlockList;
  end;
{$IFDEF LOG_THREADS_COUNT}
  sleep(1);
  AllThreads := FAllThreads.LockList;
  try
aaWriteToLog('SQLMemTypesThread> Rest Count='+IntToStr(AllThreads.Count));
  finally
   FAllThreads.UnlockList;
  end;
{$ENDIF}

  FAllThreads.Free;
  FAllThreads := nil;

end.
