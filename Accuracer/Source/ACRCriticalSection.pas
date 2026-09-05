unit ACRCriticalSection;

interface

{$I ACRVer.inc}

{$IFDEF DEBUG_WRITE_LOGS}
{DEFINE DEBUG_TRACE_THREAD_SYNC}
{DEFINE DEBUG_TRACE_THREAD_SYNC_STATS}
{$ENDIF}

{$IFDEF LINUX}
uses Libc,
{$ELSE}
uses Windows,
{$ENDIF}

  SysUtils, Classes,
  ACRConst, ACRTypes, ACRExcept
{$IFDEF DEBUG_LOG}
 ,ACRDebug
{$ENDIF}
  ;

{$IFDEF MSWINDOWS}
const kernel = 'kernel32.dll';
{$ENDIF}
const ACRMaxReaderWaitTime = 2000; // 2 second

type
{$IFDEF MSWINDOWS}
 {$IFDEF X64_ON}
// no need to redeclare it
 {$ELSE}
  TRTLCriticalSection = packed record
    DebugInfo: Pointer;
    LockCount: Longint;
    RecursionCount: Longint;
    OwningThread: Integer;
    LockSemaphore: Integer;
    Reserved: DWORD;
  end;
 {$ENDIF}
{$ENDIF}
 PRTLCriticalSection = ^TRTLCriticalSection;

 

////////////////////////////////////////////////////////////////////////////////
//
// TACRReadWriteThreadSync - base class for thread sync (using lock / unlock)
//
////////////////////////////////////////////////////////////////////////////////


 TACRReadWriteThreadSync = class (TObject)
  private
   FOwner:                  TObject;
   FOwnerName:              AnsiString;
{$IFDEF DEBUG_LOG}
  protected
   FWriteToLog:             Boolean;
{$IFDEF DEBUG_TRACE_THREAD_SYNC_STATS}
   FReadLockCount:   Integer;
   FWriteLockCount:  Integer;
   FUnLockCount:     Integer;
   FReadWaitCount:   Integer;
   FWriteWaitCount:  Integer;
   FReadWaitTime:    Cardinal;
   FWriteWaitTime:   Cardinal;
{$ENDIF}
{$ENDIF}
  protected
   procedure SetOwner(aOwner: TObject; OwnerDesc: AnsiString);
  public
   procedure WaitAndLockForRead; virtual; abstract;
   procedure WaitAndLockForWrite; virtual; abstract;
   procedure Lock(Exclusive: Boolean);
   procedure Unlock; virtual; abstract;
   property Owner: TObject read FOwner;
{$IFDEF DEBUG_LOG}
   property WriteToLog: Boolean read  FWriteToLog write FWriteToLog;
{$ENDIF}
 end;


////////////////////////////////////////////////////////////////////////////////
//
// TACRReadWriteThreadSyncByCriticalSections - for separate READ / WRITE locks
//
////////////////////////////////////////////////////////////////////////////////


 TACRReadWriteThreadSyncByCriticalSections = class (TACRReadWriteThreadSync)
  private
   FSect:                     TRTLCriticalSection;
   FNumWantToRead:            Integer;
   FNumWantToWrite:           Integer;
   FActive:                   Integer; // > 0 - active readers, < 0 - active writer, = 0 - not used
   FIsReadActive:             Boolean;
   FMaxWaitReadLevel:         Byte;
   FMaxWaitWriteLevel:        Byte;
   FLastReadTime:             Cardinal;
   FActiveThreadID:           Integer;
   FAllowNestedLocks:         Boolean; // if set to true - we can call Lock multiple times without unlock
                                       // works much slower as must store arrays of thread locks
   FActiveThreads:            TACRIntegerArray; // stores GetCurrentThreadID value for each thread
   FActiveThreadsNumLocks:    TACRInt64Array; // stores number of uses for each thread
  protected
{$IFDEF DEBUG_LOG}
   procedure WriteActiveThreads;
{$ENDIF}
   procedure InternalWaitAndLockForReadNested;
   procedure InternalWaitAndLockForReadSingle;
   procedure InternalWaitAndLockForWriteNested;
   procedure InternalWaitAndLockForWriteSingle;
   procedure InternalUnlockNested;
   procedure InternalUnlockSingle;
  public
   // Constructor
   constructor Create(bAllowNestedLocks: Boolean; pOwner: TObject = nil; OwnerDesc: AnsiString = '');
//   constructor Create(bAllowNestedLocks: Boolean = True; pOwner: TObject = nil);
   // Destructor
   destructor Destroy; override;
   procedure WaitAndLockForRead; override;
   procedure WaitAndLockForWrite; override;
   procedure Unlock; override;
 end; // TACRReadWriteThreadSyncByCriticalSections




////////////////////////////////////////////////////////////////////////////////
//
// TACRReadWriteThreadSyncBySingleCriticalSection - for EXCLUSIVE locks
//
////////////////////////////////////////////////////////////////////////////////


 TACRReadWriteThreadSyncBySingleCriticalSection = class (TACRReadWriteThreadSync)
  private
    FSect:        TRTLCriticalSection;
  public
   // Constructor
   constructor Create;
   // Destructor
   destructor Destroy; override;
   procedure WaitAndLockForRead; override;
   procedure WaitAndLockForWrite; override;
   procedure Unlock; override;
 end; // TACRReadWriteThreadSyncBySingleCriticalSection




////////////////////////////////////////////////////////////////////////////////
//
// TACRThreadIntArray
//
////////////////////////////////////////////////////////////////////////////////

 TACRThreadIntArray = class(TACRIntegerArray)
   private
    FThreadSync:  TACRReadWriteThreadSync;
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
// Critical Section Declarations
//
////////////////////////////////////////////////////////////////////////////////

 TACRCriticalSection = packed record
   CSect:            PRTLCriticalSection;
   Log:              Boolean;
   Owner:            AnsiString;
 end;
 PACRCriticalSection = ^TACRCriticalSection;

procedure InitCSect(var CSect: TRTLCriticalSection; Owner: AnsiString = ''; Log: Boolean = False);
procedure EnterCSect(var CSect: TRTLCriticalSection; CheckEnter: Boolean = true);
procedure LeaveCSect(var CSect: TRTLCriticalSection);
procedure LeaveAllCSect(ThreadID: Cardinal);
procedure DeleteCSect(var CSect: TRTLCriticalSection);

function FindCSect(var CSect: TRTLCriticalSection): PACRCriticalSection;

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

uses
  ACRTypesThread;


////////////////////////////////////////////////////////////////////////////////
//
// TACRReadWriteThreadSync
//
////////////////////////////////////////////////////////////////////////////////

procedure TACRReadWriteThreadSync.SetOwner(aOwner: TObject; OwnerDesc: AnsiString);
begin
 FOwner := aOwner;
 if (aOwner <> nil) then
  FOwnerName := FOwner.ClassName
 else
  FOwnerName := 'NULL Pointer';
 if (OwnerDesc <> '') then
  FOwnerName := FOwnerName + ' - '+OwnerDesc;
 FOwnerName := FOwnerName + ' - '+IntToHex(Integer(FOwner),8);
{$IFDEF DEBUG_LOG}

// FWriteToLog := True;
// if (FOwnerName = 'TACRDiskTableData') or
//    (FOwnerName = 'TACRTableLocksManager') then

// if (FOwnerName = 'TACRMemoryTableData') then
// if (FOwnerName = 'TACRDiskTableData') then
// if (FOwnerName = 'TACRMemoryDatabaseData') then
// if (FOwnerName = 'TACRWideStringList') then
// FWriteToLog := True;

//  FWriteToLog := True;
{$ENDIF}
end;


procedure TACRReadWriteThreadSync.Lock(Exclusive: Boolean);
begin
  if (Exclusive) then
   WaitAndLockForWrite
  else
   WaitAndLockForRead;
end; // Lock




////////////////////////////////////////////////////////////////////////////////
//
// TACRReadWriteThreadSyncByCriticalSections
//
////////////////////////////////////////////////////////////////////////////////


{$IFDEF DEBUG_LOG}
procedure TACRReadWriteThreadSyncByCriticalSections.WriteActiveThreads;
var i,n: Integer;
    s: AnsiString;
begin
  if (FAllowNestedLocks) then
   n := FActiveThreads.ItemCount
  else
   n := 0;
  s :=
      #13#10+'============================================================================'+
      #13#10+'Self = '+ IntTOHex(Integer(Self),8)+
      #13#10+'Owner = '+ IntTOHex(Integer(Owner),8)+
      #13#10+'OwnerName = '+ FOwnerName +
      #13#10+'FAllowNestedLocks = '+ BoolToStr(FAllowNestedLocks,True)+
      #13#10+'FActive = '+ IntToStr(FActive)+
      #13#10+'FActiveThreadID = '+ IntToStr(FActiveThreadID)+
      #13#10+'FNumWantToRead = '+ IntToStr(FNumWantToRead)+
      #13#10+'FNumWantToWrite = '+ IntToStr(FNumWantToWrite)+
      #13#10+'FMaxWaitReadLevel = '+ IntToStr(FMaxWaitReadLevel)+
      #13#10+'FMaxWaitWriteLevel = '+ IntToStr(FMaxWaitWriteLevel)+
      #13#10+#13#10+'Active Threads Count: '+IntToStr(n);
  if (FAllowNestedLocks) then
   for i := 0 to n-1 do
    begin
     s := s + #13#10+'#'+IntToStr(i)+': '+#9+
         'ThreadID = '+IntToStr(FActiveThreads.Items[i])+#9+
         'Locks = '+IntToStr(FActiveThreadsNumLocks.Items[i]);
    end;
  s := s+#13#10+#13#10+
'============================================================================'+#13#10;
  aaWriteToLog(s);
end; // WriteActiveThreads
{$ENDIF}


//------------------------------------------------------------------------------
// lock for read nested mode
//------------------------------------------------------------------------------
procedure TACRReadWriteThreadSyncByCriticalSections.InternalWaitAndLockForReadNested;
var bWritersExists, bFirst: Boolean;
    bCurThreadActive:       Boolean;
    curThread,index:        Integer;
{$IFDEF DEBUG_TRACE_THREAD_SYNC_STATS}
    t:                      Cardinal;
{$ENDIF}
begin
{$IFDEF DEBUG_TRACE_InternalWaitAndLockForReadNested}
aaWriteToLog('> TACRReadWriteThreadSyncByCriticalSections.InternalWaitAndLockForReadNested, OwnerName = '+FOwnerName);
try
{$ENDIF}
 bFirst := true;
 repeat
   EnterCriticalSection(FSect);
//   try
{$IFDEF DEBUG_TRACE_THREAD_SYNC}
curThread := Integer(GetCurrentThreadId);
index := FActiveThreads.IndexOf(curThread);
if (FWriteToLog) then
  WriteActiveThreads;
{$ENDIF}
     curThread := Integer(GetCurrentThreadId);
     if (FActive <> 0) then
       begin
         index := FActiveThreads.IndexOf(curThread);
         bCurThreadActive := (index >= 0);
       end
     else
       begin
         bCurThreadActive := false;
       end;
     if (bFirst) then
      begin
{$IFDEF DEBUG_TRACE_THREAD_SYNC_STATS}
Inc(FReadLockCount);
{$ENDIF}
        Inc(FNumWantToRead);
        bFirst := false;
      end;
//     bWritersExists := (FNumWantToWrite > 0) or (FActive < 0);
     bWritersExists := (FActive < 0);
//   finally
     if ((not bCurThreadActive) and (bWritersExists)) then
      begin
{$IFDEF DEBUG_TRACE_THREAD_SYNC_STATS}
Inc(FReadWaitCount);
{$ENDIF}
       LeaveCriticalSection(FSect);
{$IFDEF DEBUG_TRACE_THREAD_SYNC_STATS}
t := GetTickCount;
{$ENDIF}
       Sleep(0);
{$IFDEF DEBUG_TRACE_THREAD_SYNC_STATS}
t := ACRGetTickCountDiff(GetTickCount,t);
if (t > 0) then Inc(FReadWaitTime,t);
{$ENDIF}
      end
     else
      begin
       Dec(FNumWantToRead);
       if (bCurThreadActive) then
        Inc(FActiveThreadsNumLocks.Items[index])
       else
        begin
         FActiveThreads.Append(curThread);
         FActiveThreadsNumLocks.Append(1);
         Inc(FActive);
        end;
       LeaveCriticalSection(FSect);
       break;
      end;
  until (false);
{$IFDEF DEBUG_TRACE_InternalWaitAndLockForReadNested}
aaWriteToLog('< TACRReadWriteThreadSyncByCriticalSections.InternalWaitAndLockForReadNested, OwnerName = '+FOwnerName);
except
 on e: Exception do
  begin
WriteActiveThreads;
aaWriteToLog('Error in  TACRReadWriteThreadSyncByCriticalSections.InternalWaitAndLockForReadNested, OwnerName = '+FOwnerName+#13#10+e.Message);
raise;
  end;
end;
{$ENDIF}
end; // InternalWaitAndLockForReadNested


//------------------------------------------------------------------------------
// lock for read single mode
//------------------------------------------------------------------------------
procedure TACRReadWriteThreadSyncByCriticalSections.InternalWaitAndLockForReadSingle;
var t,st:       Cardinal;
    waitLevel:  Byte;
begin
{$IFDEF DEBUG_TRACE_InternalWaitAndLockForReadSingle}
aaWriteToLog('> TACRReadWriteThreadSyncByCriticalSections.InternalWaitAndLockForReadSingle, OwnerName = '+FOwnerName);
try
{$ENDIF}
  st := aaGetTickCount;
  t := st;
  while (True) do
   begin
    EnterCriticalSection(FSect);
    try
{$IFDEF DEBUG_TRACE_InternalWaitAndLockForReadSingle_FULL}
if (FWriteToLog) then
begin
aaWriteToLog('1. TACRReadWriteThreadSyncByCriticalSections.InternalWaitAndLockForReadSingle:');
WriteActiveThreads;
end;
{$ENDIF}
      waitLevel := ACRGetWaitLevel(st,ACR_MAX_WAIT_FOR_CRITICAL_SECTION_LOCK);
{$IFDEF DEBUG_TRACE_FULL_Single}
if (FWriteToLog) then
aaWriteToLog('Read: waitLevel = '+IntToStr(waitLevel)+#13#10+'FMaxWaitReadLevel = '+IntToStr(FMaxWaitReadLevel)+#13#10+'FMaxWaitWriteLevel = '+IntToStr(FMaxWaitWriteLevel)+#13#10+'FActive = '+IntToStr(FActive)+#13#10+'FActiveThreadID = '+IntToStr(FActiveThreadID)+#13#10+'FOwnerName = '+FOwnerName);
{$ENDIF}
      if ((waitLevel >= FMaxWaitReadLevel) and ((waitLevel >= FMaxWaitWriteLevel) or (FNumWantToWrite = 0))) then
      if ((FActive >= 0) or (FActiveThreadID = Integer(GetCurrentThreadId))) then
       begin
        if (FActive < 0) then
         Dec(FActive)
        else
         begin
          Inc(FActive);
          if (FActiveThreadID = Integer(INVALID_HANDLE_VALUE)) then
           FActiveThreadID := Integer(GetCurrentThreadId);
         end;
        FMaxWaitReadLevel := 0;
{$IFDEF DEBUG_TRACE_FULL_Single}
if (FWriteToLog) then
aaWriteToLog('Read - OK: waitLevel = '+IntToStr(waitLevel)+#13#10+'FMaxWaitReadLevel = '+IntToStr(FMaxWaitReadLevel)+#13#10+'FMaxWaitWriteLevel = '+IntToStr(FMaxWaitWriteLevel)+#13#10+'FActive = '+IntToStr(FActive)+#13#10+'FActiveThreadID = '+IntToStr(FActiveThreadID)+#13#10+'FOwnerName = '+FOwnerName);
{$ENDIF}
        Break;
       end;
      if (waitLevel > FMaxWaitReadLevel) then
       FMaxWaitReadLevel := waitLevel;
{$IFDEF DEBUG_TRACE_FULL_Single}
if (FWriteToLog) then
aaWriteToLog('Read - Sleep: waitLevel = '+IntToStr(waitLevel)+#13#10+'FMaxWaitReadLevel = '+IntToStr(FMaxWaitReadLevel)+#13#10+'FMaxWaitWriteLevel = '+IntToStr(FMaxWaitWriteLevel)+#13#10+'FActive = '+IntToStr(FActive)+#13#10+'FActiveThreadID = '+IntToStr(FActiveThreadID)+#13#10+'FOwnerName = '+FOwnerName);
{$ENDIF}
    finally
      LeaveCriticalSection(FSect);
    end;
    // wait for other threads
    if (aaGetTickCount > t) then
     begin
      Sleep(1);
      t := aaGetTickCount;
      if (ACRGetTickCountDiff(t,st) > ACR_MAX_WAIT_FOR_CRITICAL_SECTION_LOCK) then
       begin
{$IFDEF DEBUG_TRACE_InternalWaitAndLockForReadSingle_FULL}
aaWriteToLog('2. TACRReadWriteThreadSyncByCriticalSections.InternalWaitAndLockForReadSingle - Error');
WriteActiveThreads;
{$ENDIF}
{$IFDEF DEBUG_TRACE_FULL_Single}
aaWriteToLog('2. TACRReadWriteThreadSyncByCriticalSections.InternalWaitAndLockForReadSingle - Error');
WriteActiveThreads;
{$ENDIF}
        raise EACRException.Create(12362,ErrorLCriticalSectionTimeOutExceeded,[ACRGetTickCountDiff(t,st),ACR_MAX_WAIT_FOR_CRITICAL_SECTION_LOCK]);
       end;
     end;
   end; // wait for lock
{$IFDEF DEBUG_TRACE_InternalWaitAndLockForReadSingle}
aaWriteToLog('< TACRReadWriteThreadSyncByCriticalSections.InternalWaitAndLockForReadSingle, OwnerName = '+FOwnerName);
except
 on e: Exception do
  begin
WriteActiveThreads;
aaWriteToLog('Error in  TACRReadWriteThreadSyncByCriticalSections.InternalWaitAndLockForReadSingle, OwnerName = '+FOwnerName+#13#10+e.Message);
raise;
  end;
end;
{$ENDIF}
end; // InternalWaitAndLockForReadSingle


//------------------------------------------------------------------------------
// lock for write nested mode
//------------------------------------------------------------------------------
procedure TACRReadWriteThreadSyncByCriticalSections.InternalWaitAndLockForWriteNested;
var bActiveUsersExists: Boolean;
    bFirst:             Boolean;
    bCurThreadActive:   Boolean;
    curThread,index:    Integer;
{$IFDEF DEBUG_TRACE_THREAD_SYNC_STATS}
    t:                  Cardinal;
{$ENDIF}
begin
{$IFDEF DEBUG_TRACE_InternalWaitAndLockForWriteNested}
aaWriteToLog('> TACRReadWriteThreadSyncByCriticalSections.InternalWaitAndLockForWriteNested, OwnerName = '+FOwnerName);
try
{$ENDIF}
 bFirst := true;
 repeat
{$IFDEF DEBUG_TRACE_THREAD_SYNC}
if (FWriteToLog) then
begin
aaWriteToLog(#13#10+'--------------------------------------------------------------------------------'
+#13#10+'> TACRReadWriteThreadSyncByCriticalSections.WaitAndLockForWrite '
+FOwnerName+' '+IntToHex(Integer(FOwner),8)+' :'
+#13#10+'curThread = '+IntToStr(Integer(GetCurrentThreadId))
);
end;
{$ENDIF}
   EnterCriticalSection(FSect);
   curThread := Integer(GetCurrentThreadId);
//   try
{$IFDEF DEBUG_TRACE_THREAD_SYNC}
if (FWriteToLog) then
begin
index := FActiveThreads.IndexOf(curThread);
if (index >= FActiveThreads.ItemCount) then
 aaWriteToLog('0. TACRReadWriteThreadSyncByCriticalSections.WaitAndLockForWrite - Error searching thread. Index = '+IntTostr(index))
else
if (index < 0) then
 aaWriteToLog('0. TACRReadWriteThreadSyncByCriticalSections.WaitAndLockForWrite - Thread is not in active threads list. Index = '+IntTostr(index))
else
 begin
   aaWriteToLog('0. TACRReadWriteThreadSyncByCriticalSections.WaitAndLockForWrite - Thread locks = '+IntToStr(FActiveThreadsNumLocks.Items[index]))
 end;
aaWriteToLog('0. WRITE '+FOwnerName+' '+IntToHex(Integer(FOwner),8)+' :'
+#13#10+'curThread = '+IntToStr(curThread)
+#13#10+'count = '+IntToStr(FActiveThreads.ItemCount)
+#13#10+'FActive = '+IntToStr(FActive)
+#13#10+'NumWriters = '+IntToStr(FNumWantToWrite)
+#13#10+'NumReaders = '+IntToStr(FNumWantToRead)
+#13#10+'bFirst = '+BoolToStr(bFirst,True)
);
end;
{$ENDIF}
   bActiveUsersExists := (FActive <> 0);
   if (FActive <> 0) then
     begin
       index := FActiveThreads.IndexOf(curThread);
       bCurThreadActive := (index >= 0);
     end
   else
     begin
       bCurThreadActive := false;
     end;
   if (bFirst) then
    begin
{$IFDEF DEBUG_TRACE_THREAD_SYNC_STATS}
Inc(FWriteLockCount);
{$ENDIF}
      Inc(FNumWantToWrite);
      bFirst := false;
    end;
   if ((not bActiveUsersExists) or
       (bCurThreadActive and (FActiveThreads.ItemCount = 1)))  then
     // this writer can write
    bActiveUsersExists := false
   else
    // active readers or writer exists - this writer must wait
    bActiveUsersExists := true;
//   finally
{$IFDEF DEBUG_TRACE_THREAD_SYNC}
if (FWriteToLog) then
begin
aaWriteToLog('TACRReadWriteThreadSyncByCriticalSections.WaitAndLockForWrite - before checking active user exists'
+#13#10+'curThread = '+IntToStr(curThread)
+#13#10+'count = '+IntToStr(FActiveThreads.ItemCount)
+#13#10+'bActiveUsersExists = '+BoolToStr(bActiveUsersExists,True)
+#13#10+'bCurThreadActive = '+BoolToStr(bCurThreadActive,True)
+#13#10+'NumWriters = '+IntToStr(FNumWantToWrite)
+#13#10+'NumReaders = '+IntToStr(FNumWantToRead)
);
end;
{$ENDIF}
   if (bActiveUsersExists) then
    begin
{$IFDEF DEBUG_TRACE_THREAD_SYNC}
if (FWriteToLog) then
begin
if (index >= FActiveThreads.ItemCount) then
 aaWriteToLog('1. TACRReadWriteThreadSyncByCriticalSections.WaitAndLockForWrite - Error searching thread. Index = '+IntTostr(index))
else
if (index < 0) then
 aaWriteToLog('1. TACRReadWriteThreadSyncByCriticalSections.WaitAndLockForWrite - Thread is not in active threads list. Index = '+IntTostr(index))
else
 begin
   aaWriteToLog('1. TACRReadWriteThreadSyncByCriticalSections.WaitAndLockForWrite - Thread locks = '+IntToStr(FActiveThreadsNumLocks.Items[index]))
 end;
aaWriteToLog('1. WRITE - SLEEP '+FOwnerName+' '+IntToHex(Integer(FOwner),8)+' :'
+#13#10+'curThread = '+IntToStr(curThread)
+#13#10+'count = '+IntToStr(FActiveThreads.ItemCount)
+#13#10+'FActive = '+IntToStr(FActive)
+#13#10+'NumWriters = '+IntToStr(FNumWantToWrite)
+#13#10+'NumReaders = '+IntToStr(FNumWantToRead)
+#13#10+'bFirst = '+BoolToStr(bFirst,True)
+#13#10+'--------------------------------------------------------------------------------'+#13#10
);
WriteActiveThreads;
end;
{$ENDIF}
{$IFDEF DEBUG_TRACE_THREAD_SYNC_STATS}
Inc(FWriteWaitCount);
{$ENDIF}
     LeaveCriticalSection(FSect);
{$IFDEF DEBUG_TRACE_THREAD_SYNC_STATS}
t := GetTickCount;
{$ENDIF}
     Sleep(0);
{$IFDEF DEBUG_TRACE_THREAD_SYNC_STATS}
t := ACRGetTickCountDiff(GetTickCount,t);
if (t > 0) then Inc(FWriteWaitTime,t);
{$ENDIF}
{$IFDEF DEBUG_TRACE_THREAD_SYNC}
if (FWriteToLog) then
  aaWriteToLog('TACRReadWriteThreadSyncByCriticalSections.WaitAndLockForWrite - Wait Finished!');
{$ENDIF}
    end // active users exists - leave critical section and wait
   else
    begin
     Dec(FNumWantToWrite);
     FActive := -1;
     if (bCurThreadActive) then
      Inc(FActiveThreadsNumLocks.Items[index])
     else
      begin
       FActiveThreads.Append(curThread);
       FActiveThreadsNumLocks.Append(1);
      end;
{$IFDEF DEBUG_TRACE_THREAD_SYNC}
if (FWriteToLog) then
begin
if (index >= FActiveThreads.ItemCount) then
 aaWriteToLog('2. TACRReadWriteThreadSyncByCriticalSections.WaitAndLockForWrite - Error searching thread. Index = '+IntTostr(index))
else
if (index < 0) then
 aaWriteToLog('2. TACRReadWriteThreadSyncByCriticalSections.WaitAndLockForWrite - Thread is not in active threads list. Index = '+IntTostr(index))
else
 begin
   aaWriteToLog('2. TACRReadWriteThreadSyncByCriticalSections.WaitAndLockForWrite - Thread locks = '+IntToStr(FActiveThreadsNumLocks.Items[index]))
 end;
aaWriteToLog('< TACRReadWriteThreadSyncByCriticalSections.WaitAndLockForWrite - '
+FOwnerName+' '+IntToHex(Integer(FOwner),8)+' :'
+#13#10+'curThread = '+IntToStr(curThread)
+#13#10+'count = '+IntToStr(FActiveThreads.ItemCount)
+#13#10+'FActive = '+IntToStr(FActive)
+#13#10+'NumWriters = '+IntToStr(FNumWantToWrite)
+#13#10+'NumReaders = '+IntToStr(FNumWantToRead)
+#13#10+'bFirst = '+BoolToStr(bFirst,True)
+#13#10+'--------------------------------------------------------------------------------'+#13#10
);
end;
{$ENDIF}
     LeaveCriticalSection(FSect);
     break;
    end;
//   end;
 until (false);
// until (not bActiveUsersExists);
{$IFDEF DEBUG_TRACE_InternalWaitAndLockForWriteNested}
aaWriteToLog('< TACRReadWriteThreadSyncByCriticalSections.InternalWaitAndLockForReadSingle, OwnerName = '+FOwnerName);
except
 on e: Exception do
  begin
WriteActiveThreads;
aaWriteToLog('Error in  TACRReadWriteThreadSyncByCriticalSections.InternalWaitAndLockForReadSingle, OwnerName = '+FOwnerName+#13#10+e.Message);
raise;
  end;
end;
{$ENDIF}
end; // InternalWaitAndLockForWriteNested


//------------------------------------------------------------------------------
// lock for write single mode
//------------------------------------------------------------------------------
procedure TACRReadWriteThreadSyncByCriticalSections.InternalWaitAndLockForWriteSingle;
var t,st:       Cardinal;
    waitLevel:  Byte;
begin
{$IFDEF DEBUG_TRACE_InternalWaitAndLockForWriteSingle}
aaWriteToLog('> TACRReadWriteThreadSyncByCriticalSections.InternalWaitAndLockForWriteSingle, OwnerName = '+FOwnerName);
try
{$ENDIF}
  st := aaGetTickCount;
  t := st;
//  Inc(FNumWantToWrite);
  while (True) do
   begin
    EnterCriticalSection(FSect);
    try
{$IFDEF DEBUG_TRACE_InternalWaitAndLockForWriteSingle_FULL}
if (FWriteToLog) then
begin
aaWriteToLog('1. TACRReadWriteThreadSyncByCriticalSections.InternalWaitAndLockForWriteSingle');
WriteActiveThreads;
end;
{$ENDIF}
      waitLevel := ACRGetWaitLevel(st,ACR_MAX_WAIT_FOR_CRITICAL_SECTION_LOCK);
{$IFDEF DEBUG_TRACE_FULL_Single}
if (FWriteToLog) then
aaWriteToLog('Write: waitLevel = '+IntToStr(waitLevel)+#13#10+'FMaxWaitReadLevel = '+IntToStr(FMaxWaitReadLevel)+#13#10+'FMaxWaitWriteLevel = '+IntToStr(FMaxWaitWriteLevel)+#13#10+'FActive = '+IntToStr(FActive)+#13#10+'FActiveThreadID = '+IntToStr(FActiveThreadID)+#13#10+'FOwnerName = '+FOwnerName);
{$ENDIF}
      if (((waitLevel >= FMaxWaitReadLevel) or (FNumWantToRead = 0)) and (waitLevel >= FMaxWaitWriteLevel)) then
      if (FActive = 0) or ((FActive < 0) and (FActiveThreadID = GetCurrentThreadId)) then
       begin
        Dec(FActive);
        if (FActiveThreadID = Integer(INVALID_HANDLE_VALUE)) then
         FActiveThreadID := Integer(GetCurrentThreadId);
//        Dec(FNumWantToWrite);
        FMaxWaitWriteLevel := 0;
{$IFDEF DEBUG_TRACE_FULL_Single}
if (FWriteToLog) then
aaWriteToLog('Write - OK: waitLevel = '+IntToStr(waitLevel)+#13#10+'FMaxWaitReadLevel = '+IntToStr(FMaxWaitReadLevel)+#13#10+'FMaxWaitWriteLevel = '+IntToStr(FMaxWaitWriteLevel)+#13#10+'FActive = '+IntToStr(FActive)+#13#10+'FActiveThreadID = '+IntToStr(FActiveThreadID)+#13#10+'FOwnerName = '+FOwnerName);
{$ENDIF}
        Break;
       end;
      if (waitLevel > FMaxWaitWriteLevel) then
       FMaxWaitWriteLevel := waitLevel;
{$IFDEF DEBUG_TRACE_FULL_Single}
if (FWriteToLog) then
aaWriteToLog('Write - Sleep: waitLevel = '+IntToStr(waitLevel)+#13#10+'FMaxWaitReadLevel = '+IntToStr(FMaxWaitReadLevel)+#13#10+'FMaxWaitWriteLevel = '+IntToStr(FMaxWaitWriteLevel)+#13#10+'FActive = '+IntToStr(FActive)+#13#10+'FActiveThreadID = '+IntToStr(FActiveThreadID)+#13#10+'FOwnerName = '+FOwnerName);
{$ENDIF}
    finally
      LeaveCriticalSection(FSect);
    end;
    // wait for other threads
    if (aaGetTickCount > t) then
     begin
{$IFDEF DEBUG_TRACE_FULL_Single}
if (FWriteToLog) then
aaWriteToLog('Write - Before Sleep. TACRReadWriteThreadSyncByCriticalSections.InternalWaitAndLockForWriteSingle, Diff =  '+IntToStr(ACRGetTickCountDiff(t,st))+', waitLevel = '+IntToStr(ACRGetWaitLevel(st,ACR_MAX_WAIT_FOR_CRITICAL_SECTION_LOCK))+',  ACR_MAX_WAIT_FOR_CRITICAL_SECTION_LOCK = '+IntToStr( ACR_MAX_WAIT_FOR_CRITICAL_SECTION_LOCK));
{$ENDIF}
      Sleep(1);
      t := aaGetTickCount;
{$IFDEF DEBUG_TRACE_FULL_Single}
if (FWriteToLog) then
aaWriteToLog('Write - After Sleep. TACRReadWriteThreadSyncByCriticalSections.InternalWaitAndLockForWriteSingle, Diff =  '+IntToStr(ACRGetTickCountDiff(t,st))+', waitLevel = '+IntToStr(ACRGetWaitLevel(st,ACR_MAX_WAIT_FOR_CRITICAL_SECTION_LOCK))+',  ACR_MAX_WAIT_FOR_CRITICAL_SECTION_LOCK = '+IntToStr( ACR_MAX_WAIT_FOR_CRITICAL_SECTION_LOCK));
{$ENDIF}
      if (ACRGetTickCountDiff(t,st) > ACR_MAX_WAIT_FOR_CRITICAL_SECTION_LOCK) then
       begin
{$IFDEF DEBUG_TRACE_InternalWaitAndLockForWriteSingle_FULL}
aaWriteToLog('2. TACRReadWriteThreadSyncByCriticalSections.InternalWaitAndLockForWriteSingle - Error');
WriteActiveThreads;
{$ENDIF}
{$IFDEF DEBUG_TRACE_FULL_Single}
aaWriteToLog('2. TACRReadWriteThreadSyncByCriticalSections.InternalWaitAndLockForWriteSingle - Error');
WriteActiveThreads;
{$ENDIF}
        raise EACRException.Create(12363,ErrorLCriticalSectionTimeOutExceeded,[ACRGetTickCountDiff(t,st),ACR_MAX_WAIT_FOR_CRITICAL_SECTION_LOCK]);
       end;
     end;
   end; // wait for lock
{$IFDEF DEBUG_TRACE_InternalWaitAndLockForWriteSingle}
aaWriteToLog('< TACRReadWriteThreadSyncByCriticalSections.InternalWaitAndLockForWriteSingle, OwnerName = '+FOwnerName);
except
 on e: Exception do
  begin
WriteActiveThreads;
aaWriteToLog('Error in  TACRReadWriteThreadSyncByCriticalSections.InternalWaitAndLockForWriteSingle, OwnerName = '+FOwnerName+#13#10+e.Message);
raise;
  end;
end;
{$ENDIF}
end; // InternalWaitAndLockForWriteSingle


//------------------------------------------------------------------------------
// unlock nested mode
//------------------------------------------------------------------------------
procedure TACRReadWriteThreadSyncByCriticalSections.InternalUnlockNested;
var
    bCurThreadActive: Boolean;
    curThread,index:  Integer;
begin
{$IFDEF DEBUG_TRACE_InternalUnlockNested}
aaWriteToLog('> TACRReadWriteThreadSyncByCriticalSections.InternalUnlockNested, OwnerName = '+FOwnerName);
try
{$ENDIF}
{$IFDEF DEBUG_TRACE_InternalUnlockNested_FULL}
if (FWriteToLog) then
begin
if (index >= FActiveThreads.ItemCount) then
 aaWriteToLog('1. TACRReadWriteThreadSyncByCriticalSections.Unlock - Error searching thread. Index = '+IntTostr(index))
else
if (index < 0) then
 aaWriteToLog('1. TACRReadWriteThreadSyncByCriticalSections.Unlock error - Thread is not in active threads list. Index = '+IntTostr(index))
else
 begin
   aaWriteToLog('1. TACRReadWriteThreadSyncByCriticalSections.Unlock - Thread locks = '+IntToStr(FActiveThreadsNumLocks.Items[index]))
 end;
aaWriteToLog('1. UNLOCK '+FOwnerName+' '+IntToHex(Integer(FOwner),8)+' :'
+#13#10+'curThread = '+IntToStr(curThread)
+#13#10+'count = '+IntToStr(FActiveThreads.ItemCount)
+#13#10+'FActive = '+IntToStr(FActive)
+#13#10+'NumWriters = '+IntToStr(FNumWantToWrite)
+#13#10+'NumReaders = '+IntToStr(FNumWantToRead)
);
end;
{$ENDIF}
 EnterCriticalSection(FSect);
 try
   curThread := Integer(GetCurrentThreadID);
   index := FActiveThreads.IndexOf(curThread);
   if (index < 0) then
    raise EACRException.Create(11638,ErrorLInvalidItemNumber,[curThread,FActiveThreads.ItemCount]);
   Dec(FActiveThreadsNumLocks.Items[index]);
   // if current thread remove all its locks, change FActive
   if (FActiveThreadsNumLocks.Items[index] <= 0) then
    begin
     // this thread is not active anymore
     FActiveThreads.Delete(index);
     FActiveThreadsNumLocks.Delete(index);
     if (FActive > 0) then
      begin
       // resource is used by reader - delete one of them
       Dec(FActive);
      end
     else
      begin
       // resource is used by writer - delete it
       //Inc(FActive);
       FActive := 0;
      end;
{$IFDEF DEBUG_TRACE_InternalUnlockNested_FULL}
index := FActiveThreads.IndexOf(curThread);
if (FWriteToLog) then
begin
if (index >= FActiveThreads.ItemCount) then
 aaWriteToLog('2. TACRReadWriteThreadSyncByCriticalSections.Unlock - Error searching thread. Index = '+IntTostr(index))
else
if (index < 0) then
 aaWriteToLog('2. TACRReadWriteThreadSyncByCriticalSections.Unlock OK - Thread is not in active threads list. Index = '+IntTostr(index))
else
 begin
   aaWriteToLog('2. TACRReadWriteThreadSyncByCriticalSections.Unlock error - Thread locks = '+IntToStr(FActiveThreadsNumLocks.Items[index]))
 end;
aaWriteToLog('< 2. UNLOCK '+FOwnerName+' '+IntToHex(Integer(FOwner),8)+' :'
+#13#10+'curThread = '+IntToStr(curThread)
+#13#10+'count = '+IntToStr(FActiveThreads.ItemCount)
+#13#10+'FActive = '+IntToStr(FActive)
+#13#10+'NumWriters = '+IntToStr(FNumWantToWrite)
+#13#10+'NumReaders = '+IntToStr(FNumWantToRead)
+#13#10+'--------------------------------------------------------------------------------'+#13#10
);
end;
{$ENDIF}
    end
   else
    begin
{$IFDEF DEBUG_TRACE_InternalUnlockNested_FULL}
index := FActiveThreads.IndexOf(curThread);
if (FWriteToLog) then
begin
if (index >= FActiveThreads.ItemCount) then
 aaWriteToLog('3. TACRReadWriteThreadSyncByCriticalSections.Unlock - Error searching thread. Index = '+IntTostr(index))
else
if (index < 0) then
 aaWriteToLog('3. TACRReadWriteThreadSyncByCriticalSections.Unlock OK - Thread is not in active threads list. Index = '+IntTostr(index))
else
 begin
   aaWriteToLog('3. TACRReadWriteThreadSyncByCriticalSections.Unlock error - Thread locks = '+IntToStr(FActiveThreadsNumLocks.Items[index]))
 end;
aaWriteToLog('< 3. UNLOCK '+FOwnerName+' '+IntToHex(Integer(FOwner),8)+' :'
+#13#10+'curThread = '+IntToStr(curThread)
+#13#10+'count = '+IntToStr(FActiveThreads.ItemCount)
+#13#10+'FActive = '+IntToStr(FActive)
+#13#10+'NumWriters = '+IntToStr(FNumWantToWrite)
+#13#10+'NumReaders = '+IntToStr(FNumWantToRead)
+#13#10+'--------------------------------------------------------------------------------'+#13#10
);
end;
{$ENDIF}
    end;
 finally
   LeaveCriticalSection(FSect);
 end;
{$IFDEF DEBUG_TRACE_InternalUnlockNested}
aaWriteToLog('< TACRReadWriteThreadSyncByCriticalSections.InternalUnlockNested, OwnerName = '+FOwnerName);
except
 on e: Exception do
  begin
WriteActiveThreads;
aaWriteToLog('Error in  TACRReadWriteThreadSyncByCriticalSections.InternalUnlockNested, OwnerName = '+FOwnerName+#13#10+e.Message);
raise;
  end;
end;
{$ENDIF}
end; // InternalUnlockNested


//------------------------------------------------------------------------------
// unlock single mode
//------------------------------------------------------------------------------
procedure TACRReadWriteThreadSyncByCriticalSections.InternalUnlockSingle;
begin
{$IFDEF DEBUG_TRACE_InternalUnlockSingle}
aaWriteToLog('> TACRReadWriteThreadSyncByCriticalSections.InternalUnlockSingle, OwnerName = '+FOwnerName);
try
{$ENDIF}
  EnterCriticalSection(FSect);
  try
    if (FActive < 0) then
     Inc(FActive)
    else
     Dec(FActive);
    if (FActive = 0) then
      FActiveThreadID := Integer(INVALID_HANDLE_VALUE);
{$IFDEF DEBUG_TRACE_FULL_Single}
aaWriteToLog('Unlock Single:'+#13#10+'FMaxWaitReadLevel = '+IntToStr(FMaxWaitReadLevel)+#13#10+'FMaxWaitWriteLevel = '+IntToStr(FMaxWaitWriteLevel)+#13#10+'FActive = '+IntToStr(FActive)+#13#10+'FActiveThreadID = '+IntToStr(FActiveThreadID)+#13#10+'FOwnerName = '+FOwnerName);
{$ENDIF}

{$IFDEF DEBUG_TRACE_InternalUnlockSingle_FULL}
if (FWriteToLog) then
begin
aaWriteToLog('TACRReadWriteThreadSyncByCriticalSections.InternalUnlockSingle - OK!');
WriteActiveThreads;
end;
{$ENDIF}
  finally
    LeaveCriticalSection(FSect);
  end;
{$IFDEF DEBUG_TRACE_InternalUnlockSingle}
aaWriteToLog('< TACRReadWriteThreadSyncByCriticalSections.InternalUnlockSingle, OwnerName = '+FOwnerName);
except
 on e: Exception do
  begin
WriteActiveThreads;
aaWriteToLog('Error in  TACRReadWriteThreadSyncByCriticalSections.InternalUnlockSingle, OwnerName = '+FOwnerName+#13#10+e.Message);
raise;
  end;
end;
{$ENDIF}
end; // InternalUnlockSingle


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TACRReadWriteThreadSyncByCriticalSections.Create(bAllowNestedLocks: Boolean; pOwner: TObject; OwnerDesc: AnsiString);
begin
{$IFDEF DEBUG_LOG}
  FWriteToLog := false;
{$IFDEF DEBUG_TRACE_THREAD_SYNC_STATS}
// stats
  FReadLockCount := 0;
  FWriteLockCount := 0;
  FUnlockCount := 0;
  FReadWaitCount := 0;
  FWriteWaitCount := 0;
  FReadWaitTime := 0;
  FWriteWaitTime := 0;
{$ENDIF}
{$ENDIF}
  FNumWantToRead := 0;
  FNumWantToWrite := 0;
  FMaxWaitReadLevel := 0;
  FMaxWaitWriteLevel := 0;
  FActive := 0;
  FActiveThreadID := Integer(INVALID_HANDLE_VALUE);
  FAllowNestedLocks := bAllowNestedLocks;
  SetOwner(pOwner,OwnerDesc);
{$IFDEF DEBUG_LOG}
  FWriteToLog := True;
//  FWriteToLog := (Pos('TACRCacheManagerThread',FOwnerName) > 0) or  (Pos('TACRDiskPageManager',FOwnerName) > 0) or (Pos('TACRDiskDatabaseData',FOwnerName) > 0);
{$ENDIF}

  InitializeCriticalSection(FSect);
  if (FAllowNestedLocks) then
   begin
    FActiveThreads := TACRIntegerArray.Create(0);
    FActiveThreadsNumLocks := TACRInt64Array.Create(0);
   end
  else
   begin
    FActiveThreads := nil;
    FActiveThreadsNumLocks := nil;
   end;
end; // Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TACRReadWriteThreadSyncByCriticalSections.Destroy;
begin
  DeleteCriticalSection(FSect);
  if (FAllowNestedLocks) then
   begin
    FActiveThreads.Free;
    FActiveThreadsNumLocks.Free;
   end;
{$IFDEF DEBUG_TRACE_THREAD_SYNC_STATS}
if (FUnLockCount > 0) then
if (FWriteToLog) then aaWriteToLog(#13#10+'DESTROY '+FOwnerName+' '+IntToHex(Integer(FOwner),8)+' :'
+#13#10+'ReadLockCount  = '+IntToStr(FReadLockCount)
+#13#10+'ReadWaitCount  = '+IntToStr(FReadWaitCount)
+#13#10+'ReadWaitTime   = '+IntToStr(FReadWaitTime)
+#13#10+'WriteLockCount = '+IntToStr(FWriteLockCount)
+#13#10+'WriteWaitCount = '+IntToStr(FWriteWaitCount)
+#13#10+'WriteWaitTime  = '+IntToStr(FWriteWaitTime)
+#13#10+'LockCount      = '+IntToStr(FReadLockCount + FWriteLockCount)
+#13#10+'UnlockCount    = '+IntToStr(FUnLockCount)
);
{$ENDIF}
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// lock for read
//------------------------------------------------------------------------------
procedure TACRReadWriteThreadSyncByCriticalSections.WaitAndLockForRead;
begin
 if (FAllowNestedLocks) then
  InternalWaitAndLockForReadNested
 else
  InternalWaitAndLockForReadSingle;
end; // WaitAndLockForRead


//------------------------------------------------------------------------------
// lock for write
//------------------------------------------------------------------------------
procedure TACRReadWriteThreadSyncByCriticalSections.WaitAndLockForWrite;
begin
 if (FAllowNestedLocks) then
  InternalWaitAndLockForWriteNested
 else
  InternalWaitAndLockForWriteSingle;
end; //WaitAndLockForWrite


//------------------------------------------------------------------------------
// unlock
//------------------------------------------------------------------------------
procedure TACRReadWriteThreadSyncByCriticalSections.Unlock;
begin
 if (FAllowNestedLocks) then
  InternalUnlockNested
 else
  InternalUnlockSingle;
end; // Unlock




////////////////////////////////////////////////////////////////////////////////
//
// TACRReadWriteThreadSyncBySingleCriticalSection
//
////////////////////////////////////////////////////////////////////////////////


constructor TACRReadWriteThreadSyncBySingleCriticalSection.Create;
begin
{$IFDEF DEBUG_LOG}
  FWriteToLog := false;
{$IFDEF DEBUG_TRACE_THREAD_SYNC_STATS}
// stats
  FReadLockCount := 0;
  FWriteLockCount := 0;
  FUnlockCount := 0;
  FReadWaitCount := 0;
  FWriteWaitCount := 0;
  FReadWaitTime := 0;
  FWriteWaitTime := 0;
{$ENDIF}
{$ENDIF}
  InitializeCriticalSection(FSect);
end;

destructor TACRReadWriteThreadSyncBySingleCriticalSection.Destroy;
begin
  DeleteCriticalSection(FSect);
  inherited;
end;

procedure TACRReadWriteThreadSyncBySingleCriticalSection.WaitAndLockForRead;
{$IFDEF DEBUG_TRACE_THREAD_SYNC_STATS}
var    t:                Cardinal;
{$ENDIF}
begin
{$IFDEF DEBUG_TRACE_WaitAndLockForRead}
aaWriteToLog('> TACRReadWriteThreadSyncBySingleCriticalSection.WaitAndLockForRead '+FOwnerName+' '+IntToHex(Integer(FOwner),8));
try
{$ENDIF}
{$IFDEF DEBUG_TRACE_THREAD_SYNC_STATS}
   t := GetTickCount;
{$ENDIF}
   EnterCriticalSection(FSect);
{$IFDEF DEBUG_TRACE_THREAD_SYNC_STATS}
   t := ACRGetTickCountDiff(GetTickCount,t);
   Inc(FReadLockCount);
   if (t > 0) then
    begin
     Inc(FReadWaitTime,t);
     Inc(FReadWaitCount);
    end;
{$ENDIF}
{$IFDEF DEBUG_TRACE_WaitAndLockForRead}
aaWriteToLog('< TACRReadWriteThreadSyncBySingleCriticalSection.WaitAndLockForRead '+FOwnerName+' '+IntToHex(Integer(FOwner),8));
except
 on e: Exception do
  begin
    aaWriteToLog('Error in TACRReadWriteThreadSyncBySingleCriticalSection.WaitAndLockForRead '+FOwnerName+' '+IntToHex(Integer(FOwner),8)+#13#10+e.Message);
  end;
end;
{$ENDIF}
end;

procedure TACRReadWriteThreadSyncBySingleCriticalSection.WaitAndLockForWrite;
{$IFDEF DEBUG_TRACE_THREAD_SYNC_STATS}
var    t:                Cardinal;
{$ENDIF}
begin
{$IFDEF DEBUG_TRACE_WaitAndLockForWrite}
aaWriteToLog('> TACRReadWriteThreadSyncBySingleCriticalSection.Write '+FOwnerName+' '+IntToHex(Integer(FOwner),8));
try
{$ENDIF}
{$IFDEF DEBUG_TRACE_THREAD_SYNC_STATS}
   t := GetTickCount;
{$ENDIF}
   EnterCriticalSection(FSect);
{$IFDEF DEBUG_TRACE_THREAD_SYNC_STATS}
   t := ACRGetTickCountDiff(GetTickCount,t);
   Inc(FWriteLockCount);
   if (t > 0) then
    begin
     Inc(FWriteWaitTime,t);
     Inc(FWriteWaitCount);
    end;
{$ENDIF}
{$IFDEF DEBUG_TRACE_WaitAndLockForWrite}
aaWriteToLog('< TACRReadWriteThreadSyncBySingleCriticalSection.WaitAndLockForWrite '+FOwnerName+' '+IntToHex(Integer(FOwner),8));
except
 on e: Exception do
  begin
    aaWriteToLog('Error in TACRReadWriteThreadSyncBySingleCriticalSection.WaitAndLockForWrite '+FOwnerName+' '+IntToHex(Integer(FOwner),8)+#13#10+e.Message);
raise;
  end;
end;
{$ENDIF}
end;

procedure TACRReadWriteThreadSyncBySingleCriticalSection.Unlock;
begin
{$IFDEF DEBUG_TRACE_Unlock}
aaWriteToLog('> TACRReadWriteThreadSyncBySingleCriticalSection.Unlock '+FOwnerName+' '+IntToHex(Integer(FOwner),8));
try
{$ENDIF}
   LeaveCriticalSection(FSect);
{$IFDEF DEBUG_TRACE_THREAD_SYNC}
if (FWriteToLog) then aaWriteToLog(#13#10+'< TACRReadWriteThreadSyncBySingleCriticalSection.Unlock '+FOwnerName+' '+IntToHex(Integer(FOwner),8));
{$ENDIF}
{$IFDEF DEBUG_TRACE_THREAD_SYNC_STATS}
   Inc(FUnLockCount);
{$ENDIF}
{$IFDEF DEBUG_TRACE_Unlock}
aaWriteToLog('< TACRReadWriteThreadSyncBySingleCriticalSection.Unlock '+FOwnerName+' '+IntToHex(Integer(FOwner),8));
except
 on e: Exception do
  begin
    aaWriteToLog('Error in TACRReadWriteThreadSyncBySingleCriticalSection.Unlock '+FOwnerName+' '+IntToHex(Integer(FOwner),8)+#13#10+e.Message);
raise;
  end;
end;
{$ENDIF}
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
  FThreadSync :=  TACRReadWriteThreadSyncByCriticalSections.Create(False,Self);
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
// Crtitical section objects
//
////////////////////////////////////////////////////////////////////////////////

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
 CSection:  PACRCriticalSection;
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

procedure EnterCSect(var CSect: TRTLCriticalSection; CheckEnter: Boolean = true);
var
 CSection: PACRCriticalSection;
 CurrentThread: TACRThread;
 CurrentThreadID: Cardinal;
begin
{$IFDEF LOG_CSECT}
//aaWriteToLog('>>> EnterCSect');
 CSection := FindCSect(CSect);
 if CSection = nil then
    aaWriteToLog('>>> EnterCSect ERROR: Critical Section '+IntToStr(Integer(@CSect))+' not found!')
 else
  if CSection.Log then
    aaWriteToLog('>>> Critical Section '+IntToStr(Integer(@CSect))
                  +' Owner = '+CSection.Owner+' Enter... Locked '
                  +IntToStr(CSect.LockCount)+' times in '
                  +IntToStr(CSect.RecursionCount)+' recursions by Thread '
                  +IntToStr(CSect.OwningThread));
{$ENDIF}
{$IFDEF LOG_CSECT}
if CSection.Log then
aaWriteToLog('    GetCurrentThreadID...');
{$ENDIF}
 CurrentThreadID := GetCurrentThreadID;
{$IFDEF LOG_CSECT}
if CSection.Log then
aaWriteToLog('    Thread ID='+IntToStr(CurrentThreadID));
{$ENDIF}
 CurrentThread := FindThread(CurrentThreadID);
{$IFDEF LOG_CSECT}
if CSection.Log then
aaWriteToLog('    CurrentThread = '+IntToStr(Integer(CurrentThread)));
if CSection.Log then
if CurrentThread <> nil then // check thread to be registered
aaWriteToLog('    Thread ID='+IntToStr(CurrentThread.ThreadID));
{$ENDIF}
 if CheckEnter then
 if CurrentThread <> nil then // check thread to be registered
 repeat
  if CSect.OwningThread = CurrentThread.ThreadID then
   begin
{$IFDEF LOG_CSECT}
if CSection.Log then
aaWriteToLog('    CSect blocked by this thread, enter one more time...');
{$ENDIF}
    break;
   end
  else
   begin
{$IFDEF LOG_CSECT}
if CSection.Log then
if (CSect.LockCount > -1) then
begin
if CurrentThread <> nil then // check thread to be registered
aaWriteToLog('    Current thread ID='+IntToStr(CurrentThread.ThreadID)+'; CSect '+IntToStr(Integer(@CSect))+' blocked by other thread ID='+IntToStr(CSect.OwningThread))
end
else
begin
if CurrentThread <> nil then // check thread to be registered
if CurrentThread.Terminated then
aaWriteToLog('    Thread terminated!');
end;
{$ENDIF}
    if CurrentThreadID = MainThreadID then
     begin
{$IFDEF LOG_CSECT}
if CSection.Log then
aaWriteToLog('    Main Thread');
{$ENDIF}
      break;
     end;
    if CurrentThread.Terminated then
     begin
{$IFDEF LOG_CSECT}
if CSection.Log then
aaWriteToLog('    Free Thread...');
{$ENDIF}
      LeaveAllCSect(CurrentThreadID);
      CurrentThread.Free;
//      Exit;
{$IFDEF LOG_CSECT}
if CSection.Log then
aaWriteToLog('    OK');
{$ENDIF}
    end;
   end;
  sleep(0);
 until ((CSect.LockCount <= -1) and (CSect.RecursionCount <= 0));
{$IFDEF LOG_CSECT}
if CSection.Log then
aaWriteToLog('    EnterCriticalSection...');
{$ENDIF}
 EnterCriticalSection(CSect);
{$IFDEF LOG_CSECT}
if CSection.Log then
aaWriteToLog('    Entered!');
{$ENDIF}
{$IFDEF LOG_CSECT}
 if CSection <> nil then
  if CSection.Log then
    aaWriteToLog('### Critical Section '+IntToStr(Integer(@CSect))
                  +' Owner = '+CSection.Owner+' Entered! Locked '
                  +IntToStr(CSect.LockCount)+' times in '
                  +IntToStr(CSect.RecursionCount)+' recursions by Thread '
                  +IntToStr(CSect.OwningThread));
// aaWriteToLog('### EnterCSect');
{$ENDIF}
end;

procedure LeaveCSect(var CSect: TRTLCriticalSection);
var
 CSection: PACRCriticalSection;
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
  CSection: PACRCriticalSection;
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
 CSection: PACRCriticalSection;
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
 if (CSection <> nil) then
  if CriticalSections <> nil then
   CriticalSections.Remove(CSection);
 if (CSection <> nil) then
  Dispose(CSection);
{$IFDEF LOG_CSECT}
aaWriteToLog('### DeleteCSect');
{$ENDIF}
end;

function FindCSect(var CSect: TRTLCriticalSection): PACRCriticalSection;
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
     CSection := PACRCriticalSection(CSections.Items[i]).CSect;
     if CSection = @CSect then
      begin
       Result := CSections.Items[i];
{$IFDEF LOG_CSECT}
       if Result.Log then
aaWriteToLog(' -> Found, i  = '+IntToStr(i)+', Owner = '+PACRCriticalSection(CSections.Items[i]).Owner);
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
aaWriteToLog(#13#10+FOwnerName+' '+IntToHex(Integer(FOwner),8)+' :'+#13#10+'ACRCriticalSection> try to initialize...');
{$ENDIF}

 CriticalSections := TThreadList.Create;

{$IFDEF DEBUG_LOG_INIT}
// aaWriteToLog(#13#10+FOwnerName+' '+IntToHex(Integer(FOwner),8)+' :'+#13#10+'ACRCriticalSection> initialized');
{$ENDIF}

finalization

{$IFDEF LOG_CSECT}
 if CriticalSections <> nil then
  begin
   CSections := CriticalSections.LockList;
   try
aaWriteToLog('ACRCriticalSection> Rest Count = '+IntToStr(CSections.Count));
   finally
    CriticalSections.UnlockList;
   end;
  end;
{$ENDIF}

 CriticalSections.free;
 CriticalSections := nil;



end.
