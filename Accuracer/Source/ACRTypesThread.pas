unit ACRTypesThread;

interface

{$I ACRVer.inc}

uses
     SysUtils, Classes,
{$IFDEF MSWINDOWS}
     Controls,
     Windows,
{$ENDIF}

// Accuracer units
{$IFDEF LINUX}
     ACRLinux,
{$ENDIF}
     {$IFDEF DEBUG_LOG}
     ACRDebug,
     {$ENDIF}
     ACRConst,
     ACRTypes,
     ACRCriticalSection,
     ACRExcept;


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

  TACRThread = class(TThread)
  public
    FFinished: Boolean;
    FRecreate: Boolean;
  public
    constructor Create(Suspended: Boolean);
    destructor Destroy; override;
    function IsTerminated: Boolean;
    property Terminated;
  end;// TACRThread

  PTACRThread = ^TACRThread;

  function FindThread(ThreadID: Cardinal): TACRThread;


////////////////////////////////////////////////////////////////////////////////
//
// TACRThreadIntArray
//
////////////////////////////////////////////////////////////////////////////////

type

 TACRThreadIntArray = class(TACRIntegerArray)
   private
    FThreadSync: TACRReadWriteThreadSync;
   public
    constructor Create(
      size: Integer = 0;
      DefaultAllocBy: Integer = 10;
      MaximumAllocBy: Integer = 100
                        );
    destructor Destroy; override;
    procedure Lock(WriteMode: Boolean = true);
    procedure Unlock;
 end; // TACRThreadIntArray


////////////////////////////////////////////////////////////////////////////////
//
// TACRThreadList
//
////////////////////////////////////////////////////////////////////////////////

 TACRThreadList = class(TACRList)
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
    function  LockList: TACRList;
    procedure Add(Item: Pointer);
    procedure Remove(Item: Pointer);
    procedure Delete(Index: Integer); override;
    procedure UnlockList;
 end; // TACRThreadList


 var
  FAllThreads:      TThreadList;
  AllThreads:       TList;
  MainThreadID:     Cardinal;
  i:                Integer;
  Err:              Boolean;

implementation

uses ACRMemory;


////////////////////////////////////////////////////////////////////////////////
//
// TACRThread
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TACRThread.Create(Suspended: Boolean);
begin
{$IFDEF LOG_TACRTHREAD}
aaWriteToLog(Self.ClassName+' - CREATING...   Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
 FFinished := False;
 FRecreate := False;
 inherited Create(Suspended);
 Priority := tpNormal;
 FreeOnTerminate := True;
 FAllThreads.Add(Self);
{$IFDEF LOG_TACRTHREAD}
aaWriteToLog(Self.ClassName+' - CREATED!      Self = '+IntToHex(Integer(Self),8)+#9+'ThreadID = '+IntToStr(ThreadID));
{$ENDIF}
end; // Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TACRThread.Destroy;
begin
{$IFDEF LOG_TACRTHREAD}
aaWriteToLog('TACRThread.Destroy - start');
aaWriteToLog(Self.ClassName+' - DESTROYING... Self = '+IntToHex(Integer(Self),8)+#9+'ThreadID = '+IntToStr(ThreadID));
{$ENDIF}
 LeaveAllCSect(ThreadID);
{$IFDEF LOG_TACRTHREAD}
aaWriteToLog(Self.ClassName+' - All CSect left, inherited...');
{$ENDIF}
 inherited Destroy;
 FFinished := True;
 FAllThreads.Remove(Self);
{$IFDEF LOG_TACRTHREAD}
aaWriteToLog(Self.ClassName+' - DESTROYED!    Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
end; // Destroy


//------------------------------------------------------------------------------
// IsTerminated
//------------------------------------------------------------------------------
function TACRThread.IsTerminated: Boolean;
begin
 Result := Terminated;
end;


function FindThread(ThreadID: Cardinal): TACRThread;
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
     ID := TACRThread(Threads.Items[i]).ThreadID;
// aaWriteToLog('3');
     if ThreadID = ID then
      begin
// aaWriteToLog('4');
       Result := TACRThread(Threads.Items[i]);
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
// TACRThreadIntArray
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Construct array of specified size
//------------------------------------------------------------------------------
constructor TACRThreadIntArray.Create(
                                size: Integer;
                                DefaultAllocBy: Integer;
                                MaximumAllocBy: Integer
                                    );
begin
  inherited Create(size, DefaultAllocBy, MaximumAllocBy);
  FThreadSync := TACRReadWriteThreadSyncByCriticalSections.Create(False,Self);
end;//TACRThreadIntArray.Create


//------------------------------------------------------------------------------
// Destruct array (free mem)
//------------------------------------------------------------------------------
destructor TACRThreadIntArray.Destroy;
begin
  FThreadSync.Free;
  inherited Destroy;
end;//TACRThreadIntArray.Destroy;


//------------------------------------------------------------------------------
// Lock
//------------------------------------------------------------------------------
procedure TACRThreadIntArray.Lock(WriteMode: Boolean);
begin
  FThreadSync.Lock(WriteMode);
end;//TACRThreadIntArray.Lock;


//------------------------------------------------------------------------------
// Unlock
//------------------------------------------------------------------------------
procedure TACRThreadIntArray.Unlock;
begin
  FThreadSync.Unlock;
end;//TACRThreadIntArray.Unlock;




////////////////////////////////////////////////////////////////////////////////
//
// TACRThreadList
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// TACRThreadList.Create
//------------------------------------------------------------------------------
constructor TACRThreadList.Create(
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
end; // TACRThreadList


//------------------------------------------------------------------------------
// TACRThreadList.Destroy
//------------------------------------------------------------------------------
destructor TACRThreadList.Destroy;
begin
  LockList;    // Make sure nobody else is inside the list.
  try
    inherited Destroy;
  finally
    UnlockList;
    DeleteCSect(FLock);
  end;
end; // TACRThreadList.Destroy


//------------------------------------------------------------------------------
// clear list
//------------------------------------------------------------------------------
procedure TACRThreadList.Clear;
begin
  LockList;
  try
    inherited Clear;
  finally
    UnlockList;
  end;
end;


//------------------------------------------------------------------------------
// lock list and return it as TACRList for compatibility with TThreadList
//------------------------------------------------------------------------------
function TACRThreadList.LockList: TACRList;
begin
  EnterCSect(FLock,FCheckEnter);
  Result := TACRList(Self);
end; // LockList


//------------------------------------------------------------------------------
// add item
//------------------------------------------------------------------------------
procedure TACRThreadList.Add(Item: Pointer);
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
procedure TACRThreadList.Remove(Item: Pointer);
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
procedure TACRThreadList.Delete(Index: Integer);
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
procedure TACRThreadList.UnlockList;
begin
  LeaveCSect(FLock);
end; // UnlockList

// TACRThreadList


initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('> ACRTypesThread initialized');
{$ENDIF}
  ACRMemoryIncUseCount;

  FAllThreads := TThreadList.Create; // ('AllThreads',true);
  MainThreadID := GetCurrentThreadID;;

finalization

  ACRMemoryDecUseCount;

{$IFDEF LOG_THREADS_COUNT}
 if FAllThreads <> nil then
  begin
   AllThreads := FAllThreads.LockList;
   try
aaWriteToLog('ACRTypesThread> Threads Rest Count = '+IntToStr(AllThreads.Count));
   finally
    FAllThreads.UnlockList;
   end;
  end;
{$ENDIF}

{$IFDEF LOG_THREADS_COUNT}
aaWriteToLog('ACRTypesThread> Terminate all network threads...');
{$ENDIF}
  AllThreads := FAllThreads.LockList;
{$IFDEF LOG_THREADS_COUNT}
aaWriteToLog('ACRTypesThread> Hang Count='+IntToStr(AllThreads.Count));
{$ENDIF}
  try
   for i:= AllThreads.Count-1 downto 0 do
    begin
{$IFDEF LOG_THREADS_COUNT}
aaWriteToLog('ACRTypesThread> Thread #'+IntToStr(TThread(AllThreads[i]).ThreadID)+'/'+IntToStr(TThread(AllThreads[i]).Handle));
{$ENDIF}
     if TThread(AllThreads[i]) <> nil then
      begin
{$IFDEF LOG_THREADS_COUNT}
aaWriteToLog('ACRTypesThread> Ask Thread to Terminate...');
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
aaWriteToLog('ACRTypesThread> TerminateThread...');
{$ENDIF}
       Err := TerminateThread(TThread(AllThreads[i]).Handle, 0);
      end;
     if not Err then
      begin
{$IFDEF LOG_THREADS_COUNT}
aaWriteToLog('ACRTypesThread> TerminateThread failed. '+ErrorRCannotKillThread+IntToStr(Integer(Err)));
{$ENDIF}
      end;
     if TThread(AllThreads[i]) <> nil then
      if TThread(AllThreads[i]).Handle <> 0 then
       begin
{$IFDEF LOG_THREADS_COUNT}
aaWriteToLog('ACRTypesThread> CloseHandle...');
{$ENDIF}
        Err := CloseHandle(TThread(AllThreads[i]).Handle);
       end;
     if not Err then
      begin
{$IFDEF LOG_THREADS_COUNT}
aaWriteToLog('ACRTypesThread> CloseHandle failed. '+ErrorRCannotKillThread+IntToStr(Integer(Err)));
{$ENDIF}
      end;
(*
     if TThread(AllThreads[i]) <> nil then
       begin
{$IFDEF LOG_THREADS_COUNT}
aaWriteToLog('ACRTypesThread> free...');
{$ENDIF}
        TThread(AllThreads[i]).Free;
       end;
*)
     AllThreads.Delete(i);
{$IFDEF LOG_THREADS_COUNT}
aaWriteToLog('ACRTypesThread> Count='+IntToStr(AllThreads.Count));
{$ENDIF}
    end;
  finally
   FAllThreads.UnlockList;
  end;
{$IFDEF LOG_THREADS_COUNT}
  sleep(1);
  AllThreads := FAllThreads.LockList;
  try
aaWriteToLog('ACRTypesThread> Rest Count='+IntToStr(AllThreads.Count));
  finally
   FAllThreads.UnlockList;
  end;
{$ENDIF}

  FAllThreads.Free;
  FAllThreads := nil;

end.
