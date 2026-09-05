unit SQLMemMemory;

{$I SQLMemVer.inc}

interface

uses SysUtils, Classes,
{$IFDEF MSWINDOWS}
     Windows,
     Forms,
{$ENDIF}
{$IFDEF LINUX}
     Libc,
     QForms,
{$ENDIF}
     {$IFDEF DEBUG_LOG}
     SQLMemDebug,
     {$ENDIF}
     SQLMemCriticalSection,
     SQLMemExcept, SQLMemConst;

type

 TSQLMemMemorySize = Int64;

////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemMemoryManager
//
////////////////////////////////////////////////////////////////////////////////

 TSQLMemMemoryManager = class (TObject)
  private
   FMaxMemorySize:        TSQLMemMemorySize;  // Max Memory Limit
   FTotalMemAllocated:    TSQLMemMemorySize;  // Total allocated memory
   FMaxMemAllocated:      TSQLMemMemorySize;
   FFreeSystemMemorySize: TSQLMemMemorySize;  // Free Memory size in system

   FAllocMemCallCount:    Int64;  // count of allocmem calls
   FGetMemCallCount:      Int64;  // count of getmem calls
   FFreeMemCallCount:     Int64;  // count of freemem calls
   FReallocMemCallCount:  Int64;  // count of reallocmem calls

   FThreadSync:           TSQLMemReadWriteThreadSyncBySingleCriticalSection;
  protected
   procedure Lock(bExclusive: Boolean = True);
   procedure Unlock;
  public
   // Constructor
   constructor Create; overload;
   // Constructor
   constructor Create(MaxMemorySize: TSQLMemMemorySize); overload;
   // Destructor
   destructor Destroy; override;
   // GetMem analog
   function GetMem(BufferSize: TSQLMemMemorySize): Pointer;
   // AllocMem analog
   function AllocMem(BufferSize: TSQLMemMemorySize): Pointer;
   // ReAllocMem analog
   procedure ReallocMem(var Buffer; BufferSize: TSQLMemMemorySize; ClearTail: Boolean = False);
   // ReAllocMem and clear Tail of Buffer
   procedure ReallocMemAndClearTail(var Buffer; BufferSize: TSQLMemMemorySize);
   // FreeMem and set pointer to nil
   procedure FreeAndNilMem(var Buffer);
   // Return buffer size
   function GetMemoryBufferSize(Buffer: Pointer): TSQLMemMemorySize;
   // Get min from free system memory size and (FMaxMemorySize - FTotalMemAllocated)
   function GetFreeMemorySize:  TSQLMemMemorySize;
  public
   property MaxMemorySize:        TSQLMemMemorySize read FMaxMemorySize;
   property TotalMemAllocated:    TSQLMemMemorySize read FTotalMemAllocated;
   property MaxMemAllocated:    TSQLMemMemorySize read FMaxMemAllocated;
   // statistics usage
   property AllocMemCallCount:    Int64 read FAllocMemCallCount;
   property GetMemCallCount:      Int64 read FGetMemCallCount;
   property FreeMemCallCount:     Int64 read FFreeMemCallCount;
   property ReallocMemCallCount:  Int64 read FReallocMemCallCount;
 end; // TSQLMemMemoryManager

// Memory Manager variable
var MemoryManager:      TSQLMemMemoryManager = nil;
var SQLMemMemoryUseCount:  Cardinal = 0;

// move memory block
procedure SQLMemMove(const Source; var Dest; count : Integer );
// return number of bytes for pre-allocation of the buffer
// for optimization of continios data grow
function SQLMemGetReallocDelta(BufferSize: Int64): TSQLMemMemorySize;
// increase counter
procedure SQLMemMemoryIncUseCount;
// decrease counter
procedure SQLMemMemoryDecUseCount;

// form refreshing
procedure SQLMemRefresh;
var
  SQLMemRefreshTime,
  SQLMemRefreshInterval:              DWORD;


implementation

uses Math, SQLMemTypes;

type
  TGetMemType = (gmtGetMem, gmtVirtualAlloc, gmtGlobalAlloc);

  // Memory Block Header
  PSQLMemMemoryBlockHeader = ^TSQLMemMemoryBlockHeader;
  TSQLMemMemoryBlockHeader = packed record
    Size:       Cardinal;
    GetMemType: TGetMemType;
    Signature: Cardinal;  // Last 4 byte
  end;

  // Memory Block Footer
  PSQLMemMemoryBlockFooter = ^TSQLMemMemoryBlockFooter;
  TSQLMemMemoryBlockFooter = packed record
    Signature: Cardinal;  // = SQLMemMemoryEndSignature
  end;


const  SQLMemMemorySignature:    Cardinal = $ACCACCAC;
       SQLMemMemoryEndSignature: Cardinal = $ACCEACCE;

type
   TGetMemFunction = packed record
     Size:       Cardinal;
     GetMemType: TGetMemType;
   end;

function GetMemFunctionType(MemSize: TSQLMemMemorySize): TGetMemType;
begin
{$IFDEF DEBUG_MEMCHECK}
// If Enable MemChecker then use only GetMem function
   Result :=  gmtGetMem;
{$ELSE}
 {$IFDEF LINUX}
   Result :=  gmtGetMem;
 {$ENDIF}
 {$IFDEF MSWINDOWS}
//    Result :=  gmtGlobalAlloc;
//  Result := gmtGetMem;
   {$IFDEF X64_ON}
   Result := gmtGetMem;
   {$ELSE}
   if (MemSize <= 726) or ((MemSize > 64500) and (MemSize <= 1048576)) then
    Result :=  gmtGetMem
   else
    Result :=  gmtGlobalAlloc;
   {$ENDIF}
{    
   GetMemTypes: array[1..4] of TGetMemFunction =
      (
        (Size: 726;   GetMemType: gmtGetMem),          // 0     - 1024  ==> GetMem
        (Size: 64500;  GetMemType: gmtGlobalAlloc),    // 1025  - 64500 ==> GlobalAlloc
        (Size: 1048576;  GetMemType: gmtGetMem),       // 64500 - 1 MB ...  ==> GetMem
        (Size: SQLMemMaxMemorySize;  GetMemType: gmtGlobalAlloc)    // 1 MB -  ...  ==> GlobalAlloc
      );
}
 {$ENDIF}
{$ENDIF}
end;


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemMemoryManager
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// lock
//------------------------------------------------------------------------------
procedure TSQLMemMemoryManager.Lock(bExclusive: Boolean);
begin
  FThreadSync.Lock(bExclusive);
end;


//------------------------------------------------------------------------------
// unlock
//------------------------------------------------------------------------------
procedure TSQLMemMemoryManager.Unlock;
begin
  FThreadSync.Unlock;
end; // Unlock


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemMemoryManager.Create;
begin
  FThreadSync := TSQLMemReadWriteThreadSyncBySingleCriticalSection.Create;
  FMaxMemorySize := 0;
  FTotalMemAllocated := 0;
  FMaxMemAllocated := 0;
  FFreeSystemMemorySize := 0;
  FAllocMemCallCount := 0;
  FGetMemCallCount := 0;
  FFreeMemCallCount := 0;
  FReallocMemCallCount := 0;
end;//Create

//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSQLMemMemoryManager.Create(MaxMemorySize: TSQLMemMemorySize);
begin
 Create;
 FMaxMemorySize := MaxMemorySize;
end;//Create


//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TSQLMemMemoryManager.Destroy;
begin
 FThreadSync.Free;
 inherited;
 {$IFNDEF RELEASE_BUILD}
 if (FTotalMemAllocated > 0) then
  raise ESQLMemException.Create(11990,ErrorLMemoryLeakFound,[FTotalMemAllocated]);
 {$ENDIF} 
end;//Destructor


//------------------------------------------------------------------------------
// GetMemoryBufferSize
//------------------------------------------------------------------------------
function TSQLMemMemoryManager.GetMemoryBufferSize(Buffer: Pointer): TSQLMemMemorySize;
var
  Block: PSQLMemMemoryBlockHeader;
begin
  if Buffer = nil then
    Result := 0
  else
    begin
      Block := PSQLMemMemoryBlockHeader(PAnsiChar(Buffer) - SizeOf(TSQLMemMemoryBlockHeader));
      if (Block.Signature = SQLMemMemorySignature) then
        Result := Block.Size
      else
        raise ESQLMemException.Create(30005, ErrorGInvalidPointer);
    end;
end;//GetMemoryBufferSize


//------------------------------------------------------------------------------
// GetMem
//------------------------------------------------------------------------------
function TSQLMemMemoryManager.GetMem(BufferSize: TSQLMemMemorySize): Pointer;
var
  NewSize: TSQLMemMemorySize;
  BlockHeader: PSQLMemMemoryBlockHeader;
  BlockFooter: PSQLMemMemoryBlockFooter;
  GetMemType: TGetMemType;
begin
  // Increment Counter
  Inc(FGetMemCallCount);

  // Allocate 0 bytes ?
  if (BufferSize = 0) then
    raise ESQLMemException.Create(30286, ErrorGCannotAllocateZeroBytes);

  // Mem Limit ?
  if ((FMaxMemorySize <> 0) and
      (BufferSize + FTotalMemAllocated > FMaxMemorySize)) then
    raise ESQLMemException.Create(30004, ErrorGMemoryLimitExceeded, [FMaxMemorySize]);

  try
    // Calculate New Size of Buffer
    NewSize := BufferSize + SizeOf(TSQLMemMemoryBlockHeader) + SizeOf(TSQLMemMemoryBlockFooter);

    // GetMem
    GetMemType := GetMemFunctionType(NewSize);

//GetMemType := gmtGetMem;
{$IFDEF DEBUG_TRACE_TSQLMemMemoryManager_GetMem}
if (Byte(GetMemType) = 2) then
 aaWriteToLog(IntToStr(NewSize)+#9+IntToStr(Byte(GetMemType)));
{$ENDIF}
{$IFDEF DEBUG_TSQLMemMemoryManager_GetMem}
aaIncCounter(counter1);
if (Byte(GetMemType) = 0) then aaIncCounter(counter2);
if (Byte(GetMemType) = 1) then aaIncCounter(counter3);
if (Byte(GetMemType) = 2) then aaIncCounter(counter4);
{$ENDIF}
    case GetMemType of
      gmtGetMem:
          System.GetMem(BlockHeader, NewSize)
{$IFNDEF SQLMem_MEMORY_SYSTEM_ONLY}
{$IFDEF MSWINDOWS}
      ;
      gmtVirtualAlloc:
          BlockHeader := VirtualAlloc(nil, NewSize, MEM_COMMIT, PAGE_READWRITE);
      gmtGlobalAlloc:
          BlockHeader := Pointer(GlobalAlloc(GMEM_FIXED, NewSize))
 {$ENDIF}
 {$ENDIF}
      else
          raise ESQLMemException.Create(30340, ErrorGUnknownGetMemType, [Integer(GetMemType)]);
    end;
    // Fill Block Header
    BlockHeader.GetMemType := GetMemType;
    BlockHeader.Signature := SQLMemMemorySignature;
    BlockHeader.Size := BufferSize;
    // Fill Block Footer
    BlockFooter := Pointer(PAnsiChar(BlockHeader) + SizeOf(TSQLMemMemoryBlockHeader) + BufferSize);
    BlockFooter.Signature := SQLMemMemoryEndSignature;


    Result := Pointer(PAnsiChar(BlockHeader) + SizeOf(TSQLMemMemoryBlockHeader));
// aaWriteToLog('GetMem: Result = '+IntToHex(Integer(Result),8)+', Size = '+IntToStr(BufferSize));
    Lock;
    try
      Inc(FTotalMemAllocated, BufferSize);
      if (FTotalMemAllocated > FMaxMemAllocated) then
       FMaxMemAllocated := FTotalMemAllocated;
    finally
      Unlock;
    end;
  except
    on e: Exception do
      raise ESQLMemException.Create(30015, ErrorGGetMemError, [e.Message]);
  end;
end;//GetMem


//------------------------------------------------------------------------------
// AllocMem
//------------------------------------------------------------------------------
function TSQLMemMemoryManager.AllocMem(BufferSize: TSQLMemMemorySize):Pointer;
begin
  Inc(FAllocMemCallCount);
  try
    Result := self.GetMem(BufferSize);
    FillChar(Result^, BufferSize, 0);
  finally
    Dec(FGetMemCallCount);
  end;
end;//AllocMem


//------------------------------------------------------------------------------
// FreeMem and set Pointer to nil
//------------------------------------------------------------------------------
procedure TSQLMemMemoryManager.FreeAndNilMem(var Buffer);
var
  BlockHeader: PSQLMemMemoryBlockHeader;
  BlockFooter: PSQLMemMemoryBlockFooter;
  FooterIncorrect: Boolean;
begin
  // Increment Counter
  Inc(FFreeMemCallCount);
  try
    // Check Header Signature
    BlockHeader := PSQLMemMemoryBlockHeader(PAnsiChar(Buffer) - SizeOf(TSQLMemMemoryBlockHeader));
    if (BlockHeader.Signature <> SQLMemMemorySignature) then
      raise ESQLMemException.Create(30001, ErrorGInvalidPointer);
{
if (SQLMem_ENCRYPTED_DB_USED) then
 if (BlockHeader.Size > 0) then
  FillChar(PAnsiChar(Buffer)^,BlockHeader.Size,$00);
}
(*
    if (BlockHeader.Signature <> SQLMemMemorySignature) then
     begin
aaWriteToLog('FreeMem invalid signature : Buffer = '+IntToHex(Integer(PAnsiChar(Buffer)),8));
      raise ESQLMemException.Create(30001, ErrorGInvalidPointer);
     end
    else
begin
if (BlockHeader.Size = 646) then
 aaWriteToLog('');

 aaWriteToLog('FreeMem valid signature : Buffer = '+IntToHex(Integer(PAnsiChar(Buffer)),8)
 +', Size = '+IntToStr(BlockHeader.Size));
end;
*)

    // Check Footer Signature
    BlockFooter := Pointer(PAnsiChar(Buffer) + BlockHeader.Size);
    FooterIncorrect := (BlockFooter.Signature <> SQLMemMemoryEndSignature);

    // Calculate TotalMemAllocated
    Lock;
    try
      if (FTotalMemAllocated > BlockHeader.Size) then
        Dec(FTotalMemAllocated, BlockHeader.Size)
      else
        FTotalMemAllocated := 0;  
    finally
      Unlock;
    end;
//if (DebugStarted) then
//aaWriteToLog('6 TSQLMemMemoryManager.FreeAndNilMem, type = '+IntToStr(Integer(BlockHeader.GetMemType)));

    // FreeMem
    case BlockHeader.GetMemType of
      gmtGetMem:
          System.FreeMem(BlockHeader);
{$IFDEF MSWINDOWS}
      gmtVirtualAlloc:
          VirtualFree(BlockHeader, 0, MEM_RELEASE);
      gmtGlobalAlloc:
 {$IFDEF X64_ON}
          GlobalFree(NativeUInt(Pointer(BlockHeader)));
 {$ELSE}
          GlobalFree(Cardinal(Pointer(BlockHeader)));
 {$ENDIF}
{$ENDIF}

    end;

    // Clear Buffer Pointer
    Pointer(Buffer) := nil;

    // if Footer Signature incorrect then raise
    if (FooterIncorrect) then
      raise ESQLMemException.Create(30137, ErrorGMemoryOverrunDetected);

  except
    on ESQLMemException do raise;
    on e: Exception do
      raise ESQLMemException.Create(30138, ErrorGFreeMemError, [e.Message]);
  end;
end;//FreeAndNilMem


//------------------------------------------------------------------------------
// ReallocMem
//------------------------------------------------------------------------------
procedure TSQLMemMemoryManager.ReallocMem(var Buffer; BufferSize: TSQLMemMemorySize; ClearTail: Boolean);
var
  BlockHeader: PSQLMemMemoryBlockHeader;
  NewBuffer: Pointer;
begin
{$IFDEF DEBUG_TSQLMemMemoryManager_REALLOCMEM}
aaStartTime(time1);
aaIncCounter;
try
{$ENDIF}

  // Increment Counter
  Inc(FReallocMemCallCount);
  try
    // Check Header Signature
    BlockHeader := PSQLMemMemoryBlockHeader(PAnsiChar(Buffer) - SizeOf(TSQLMemMemoryBlockHeader));
    if (BlockHeader.Signature <> SQLMemMemorySignature) then
      raise ESQLMemException.Create(30002, ErrorGInvalidPointer);

    // GetMem
    NewBuffer := Self.GetMem(BufferSize);
    // Copy OldBuffer to NewBuffer
    Move(PAnsiChar(Buffer)^, NewBuffer^,
       min(BufferSize, BlockHeader.Size));
    // Clear Tail
    if (ClearTail) then
      if (BufferSize > BlockHeader.Size) then
        FillChar(PAnsiChar(PAnsiChar(NewBuffer) + BlockHeader.Size)^, BufferSize-BlockHeader.Size, 0);

    // Free old buffer
    Self.FreeAndNilMem(PAnsiChar(Buffer));
    // Set Buffer to NewBuffer
    Pointer(Buffer) := NewBuffer;

    // Correct call counters
    Dec(FGetMemCallCount);
    Dec(FFreeMemCallCount);
  except
    on e: Exception do
      raise ESQLMemException.Create(30014, ErrorGReallocMemError, [e.Message]);
  end;
{$IFDEF DEBUG_TSQLMemMemoryManager_REALLOCMEM}
finally
aaStopTime(time1);
end;
{$ENDIF}
end;//ReallocMem


//------------------------------------------------------------------------------
// ReAllocMem and clear Tail of Buffer
//------------------------------------------------------------------------------
procedure TSQLMemMemoryManager.ReallocMemAndClearTail(var Buffer; BufferSize: TSQLMemMemorySize);
begin
  ReallocMem(Buffer, BufferSize, True);
end;//ReallocMemAndClearTail

//------------------------------------------------------------------------------
// GetFreeMemorySize
//------------------------------------------------------------------------------
function TSQLMemMemoryManager.GetFreeMemorySize: TSQLMemMemorySize;
{$IFDEF MSWINDOWS}
var
  Status: TMemoryStatus;
{$ENDIF}
begin
{$IFDEF MSWINDOWS}
  GlobalMemoryStatus(Status);
  FFreeSystemMemorySize := Status.dwAvailPhys;
  if (FMaxMemorySize = 0) then
    Result := FFreeSystemMemorySize
  else
    Result := Min(FFreeSystemMemorySize, FMaxMemorySize);
{$ENDIF}
{$IFDEF LINUX}
    Result := FMaxMemorySize;
{$ENDIF}
end;//GetFreeMemorySize


//------------------------------------------------------------------------------
// move memory block
//------------------------------------------------------------------------------
procedure SQLMemMove(const Source; var Dest; Count : Integer );
var
  S, D: PAnsiChar;
  I, Offset: Integer;
begin
  S := PAnsiChar(@Source);
  D := PAnsiChar(@Dest);
  Offset := D - S;
  if ((Offset > 0) and (Offset < 4)) then
    for i := Count-1 downto 0 do
      (D+i)^ := (S+i)^
  else
  if ((Offset > -4) and (Offset < 0)) then
    for i := 0 to Count-1 do
      (D+i)^ := (S+i)^
  else
    Move(Source, Dest, Count);
end; // SQLMemMove


//------------------------------------------------------------------------------
// return number of bytes for pre-allocation of the buffer
// for optimization of continios data grow
//------------------------------------------------------------------------------
function SQLMemGetReallocDelta(BufferSize: Int64): Int64;
begin
  if (BufferSize <= 10240) then
   Result := 1024
  else
  if (BufferSize <= 102400) then
   Result := 10240
  else
  if (BufferSize <= 1024*1024) then
   Result := 102400
  else
  if (BufferSize <= 10*1024*1024) then
   Result := 1024*1024
  else
  if (BufferSize <= 100*1024*1024) then
   Result := 2*1024*1024 // 2 MB
  else
  if (BufferSize <= 1024*1024*1024) then
   Result := 10*1024*1024 // 10 MB
  else
   Result := 100*1024*1024;// 100 MB
end; // SQLMemGetReallocDelta


//------------------------------------------------------------------------------
// increase counter
//------------------------------------------------------------------------------
procedure SQLMemMemoryIncUseCount;
begin
  if (SQLMemMemoryUseCount = 0) then
   begin
     MemoryManager := TSQLMemMemoryManager.Create;
     SQLMemTempPageManagerMaxMemoryPageCount :=
      ((MemoryManager.GetFreeMemorySize div 10) div SQLMemDefaultPageSize);
   end;
  Inc(SQLMemMemoryUseCount);
end; // SQLMemMemoryIncUseCount


//------------------------------------------------------------------------------
// decrease counter
//------------------------------------------------------------------------------
procedure SQLMemMemoryDecUseCount;
begin
 if (SQLMemMemoryUseCount > 1) then
  Dec(SQLMemMemoryUseCount)
 else
  SQLMemMemoryUseCount := 0;
 if (SQLMemMemoryUseCount = 0) then
  if (MemoryManager <> nil) then
   begin
    MemoryManager.Free;
    MemoryManager := nil;
   end;
end; // SQLMemMemoryDecUseCount


//------------------------------------------------------------------------------
// Refresh
//------------------------------------------------------------------------------
procedure SQLMemRefresh;
begin
// MUST CALL IN NOT CSECT!!!
 try
  if SQLMemRefreshInterval = 0 then
    Exit;
  if MainThreadID <> GetCurrentThreadId then
    Exit;
{$IFDEF LOG_REFRESH}
aaWriteToLog('SQLMemRefreshTime = '+IntToStr(SQLMemRefreshTime));
{$ENDIF}
  if (aaGetTickCount >= (SQLMemRefreshInterval + SQLMemRefreshTime)) then
   begin
{$IFDEF LOG_REFRESH}
aaWriteToLog('SQLMemRefresh> Before Sleep');
{$ENDIF}
    Sleep(250);
{$IFDEF LOG_REFRESH}
aaWriteToLog('SQLMemRefresh> ProcessMessages');
{$ENDIF}
    Application.ProcessMessages;
    SQLMemRefreshTime := aaGetTickCount;
{$IFDEF LOG_REFRESH}
aaWriteToLog('SQLMemRefresh> finished, NEW SQLMemRefreshTime = '+IntToStr(SQLMemRefreshTime));
{$ENDIF}
   end;
 except
  on E: Exception do
   begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('ERROR in SQLMemRefresh: '+E.Message);
{$ENDIF}
   end;
 end;
end; // Refresh


initialization

 SQLMemMemoryIncUseCount;
 SQLMemRefreshInterval := SQLMemAntifreezeTimeOut;
 SQLMemRefreshTime := aaGetTickCount;
{$IFDEF LOG_REFRESH}
aaWriteToLog('SQLMemRefreshInterval = '+IntToStr(SQLMemRefreshInterval));
aaWriteToLog('SQLMemRefreshTime = '+IntToStr(SQLMemRefreshTime));
{$ENDIF}

finalization

  // changed in 5.02 #4 to avoid problem with unloading run-time package
  // compiled by C++ Builder - SQLMemMemory finalization is not last there
  SQLMemMemoryDecUseCount;
// MemoryManager.Free;
// MemoryManager := nil;

end.


