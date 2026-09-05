unit CPSMemory;

{$I CPSVer.inc}

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
     CPSDebug,
     {$ENDIF}
     CPSCriticalSection,
     CPSExcept, CPSConst;

type

 TCPSMemorySize = Int64;

////////////////////////////////////////////////////////////////////////////////
//
// TCPSMemoryManager
//
////////////////////////////////////////////////////////////////////////////////

 TCPSMemoryManager = class (TObject)
  private
   FMaxMemorySize:        TCPSMemorySize;  // Max Memory Limit
   FTotalMemAllocated:    TCPSMemorySize;  // Total allocated memory
   FMaxMemAllocated:      TCPSMemorySize;
   FFreeSystemMemorySize: TCPSMemorySize;  // Free Memory size in system

   FAllocMemCallCount:    Int64;  // count of allocmem calls
   FGetMemCallCount:      Int64;  // count of getmem calls
   FFreeMemCallCount:     Int64;  // count of freemem calls
   FReallocMemCallCount:  Int64;  // count of reallocmem calls

   FThreadSync:           TRTLCriticalSection;
  protected
   procedure Lock(bExclusive: Boolean = True);
   procedure Unlock;
  public
   // Constructor
   constructor Create; overload;
   // Constructor
   constructor Create(MaxMemorySize: TCPSMemorySize); overload;
   // Destructor
   destructor Destroy; override;
   // GetMem analog
   function GetMem(BufferSize: TCPSMemorySize): Pointer;
   // AllocMem analog
   function AllocMem(BufferSize: TCPSMemorySize): Pointer;
   // ReAllocMem analog
   procedure ReallocMem(var Buffer; BufferSize: TCPSMemorySize; ClearTail: Boolean = False);
   // ReAllocMem and clear Tail of Buffer
   procedure ReallocMemAndClearTail(var Buffer; BufferSize: TCPSMemorySize);
   // FreeMem and set pointer to nil
   procedure FreeAndNilMem(var Buffer);
   // Return buffer size
   function GetMemoryBufferSize(Buffer: Pointer): TCPSMemorySize;
   // Get min from free system memory size and (FMaxMemorySize - FTotalMemAllocated)
   function GetFreeMemorySize:  TCPSMemorySize;
  public
   property MaxMemorySize:        TCPSMemorySize read FMaxMemorySize;
   property TotalMemAllocated:    TCPSMemorySize read FTotalMemAllocated;
   property MaxMemAllocated:    TCPSMemorySize read FMaxMemAllocated;
   // statistics usage
   property AllocMemCallCount:    Int64 read FAllocMemCallCount;
   property GetMemCallCount:      Int64 read FGetMemCallCount;
   property FreeMemCallCount:     Int64 read FFreeMemCallCount;
   property ReallocMemCallCount:  Int64 read FReallocMemCallCount;
 end; // TCPSMemoryManager

// Memory Manager variable
var MemoryManager:      TCPSMemoryManager = nil;
var CPSMemoryUseCount:  Cardinal = 0;

// move memory block
procedure CPSMove(const Source; var Dest; count : Integer );
// return number of bytes for pre-allocation of the buffer
// for optimization of continios data grow
function CPSGetReallocDelta(BufferSize: Int64): TCPSMemorySize;
// increase counter
procedure CPSMemoryIncUseCount;
// decrease counter
procedure CPSMemoryDecUseCount;

// form refreshing
procedure CPSRefresh;
var
  CPSRefreshTime,
  CPSRefreshInterval:              DWORD;


implementation

uses Math;

type
  TGetMemType = (gmtGetMem, gmtVirtualAlloc, gmtGlobalAlloc);

  // Memory Block Header
  PCPSMemoryBlockHeader = ^TCPSMemoryBlockHeader;
  TCPSMemoryBlockHeader = packed record
    Size:       Cardinal;
    GetMemType: TGetMemType;
    Signature: Cardinal;  // Last 4 byte
  end;

  // Memory Block Footer
  PCPSMemoryBlockFooter = ^TCPSMemoryBlockFooter;
  TCPSMemoryBlockFooter = packed record
    Signature: Cardinal;  // = CPSMemoryEndSignature
  end;


const  CPSMemorySignature:    Cardinal = $ACCACCAC;
       CPSMemoryEndSignature: Cardinal = $ACCEACCE;

type
   TGetMemFunction = packed record
     Size:       Cardinal;
     GetMemType: TGetMemType;
   end;

function GetMemFunctionType(MemSize: TCPSMemorySize): TGetMemType;
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
        (Size: CPSMaxMemorySize;  GetMemType: gmtGlobalAlloc)    // 1 MB -  ...  ==> GlobalAlloc
      );
}
 {$ENDIF}
{$ENDIF}
end;


////////////////////////////////////////////////////////////////////////////////
//
// TCPSMemoryManager
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// lock
//------------------------------------------------------------------------------
procedure TCPSMemoryManager.Lock(bExclusive: Boolean);
begin
  EnterCriticalSection(FThreadSync);
end;


//------------------------------------------------------------------------------
// unlock
//------------------------------------------------------------------------------
procedure TCPSMemoryManager.Unlock;
begin
  LeaveCriticalSection(FThreadSync);
end; // Unlock


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TCPSMemoryManager.Create;
begin
  InitializeCriticalSection(FThreadSync);
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
constructor TCPSMemoryManager.Create(MaxMemorySize: TCPSMemorySize);
begin
 Create;
 FMaxMemorySize := MaxMemorySize;
end;//Create


//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TCPSMemoryManager.Destroy;
begin
 DeleteCriticalSection(FThreadSync);
 inherited;
 {$IFNDEF RELEASE_BUILD}
 if (FTotalMemAllocated > 0) then
  raise ECPSException.Create(11990,ErrorLMemoryLeakFound,[FTotalMemAllocated]);
 {$ENDIF} 
end;//Destructor


//------------------------------------------------------------------------------
// GetMemoryBufferSize
//------------------------------------------------------------------------------
function TCPSMemoryManager.GetMemoryBufferSize(Buffer: Pointer): TCPSMemorySize;
var
  Block: PCPSMemoryBlockHeader;
begin
  if Buffer = nil then
    Result := 0
  else
    begin
      Block := PCPSMemoryBlockHeader(PAnsiChar(Buffer) - SizeOf(TCPSMemoryBlockHeader));
      if (Block.Signature = CPSMemorySignature) then
        Result := Block.Size
      else
        raise ECPSException.Create(30005, ErrorLInvalidPointer);
    end;
end;//GetMemoryBufferSize


//------------------------------------------------------------------------------
// GetMem
//------------------------------------------------------------------------------
function TCPSMemoryManager.GetMem(BufferSize: TCPSMemorySize): Pointer;
var
  NewSize: TCPSMemorySize;
  BlockHeader: PCPSMemoryBlockHeader;
  BlockFooter: PCPSMemoryBlockFooter;
  GetMemType: TGetMemType;
begin
  // Increment Counter
  Inc(FGetMemCallCount);

  // Allocate 0 bytes ?
  if (BufferSize = 0) then
    raise ECPSException.Create(30286, ErrorLCannotAllocateZeroBytes);

  // Mem Limit ?
  if ((FMaxMemorySize <> 0) and
      (BufferSize + FTotalMemAllocated > FMaxMemorySize)) then
    raise ECPSException.Create(30004, ErrorLMemoryLimitExceeded, [FMaxMemorySize]);

  try
    // Calculate New Size of Buffer
    NewSize := BufferSize + SizeOf(TCPSMemoryBlockHeader) + SizeOf(TCPSMemoryBlockFooter);

    // GetMem
    GetMemType := GetMemFunctionType(NewSize);

//GetMemType := gmtGetMem;
{$IFDEF DEBUG_TRACE_TCPSMemoryManager_GetMem}
if (Byte(GetMemType) = 2) then
 aaWriteToLog(IntToStr(NewSize)+#9+IntToStr(Byte(GetMemType)));
{$ENDIF}
{$IFDEF DEBUG_TCPSMemoryManager_GetMem}
aaIncCounter(counter1);
if (Byte(GetMemType) = 0) then aaIncCounter(counter2);
if (Byte(GetMemType) = 1) then aaIncCounter(counter3);
if (Byte(GetMemType) = 2) then aaIncCounter(counter4);
{$ENDIF}
    case GetMemType of
      gmtGetMem:
          System.GetMem(BlockHeader, NewSize)
{$IFNDEF CPS_MEMORY_SYSTEM_ONLY}
{$IFDEF MSWINDOWS}
      ;
      gmtVirtualAlloc:
          BlockHeader := VirtualAlloc(nil, NewSize, MEM_COMMIT, PAGE_READWRITE);
      gmtGlobalAlloc:
          BlockHeader := Pointer(GlobalAlloc(GMEM_FIXED, NewSize))
 {$ENDIF}
 {$ENDIF}
      else
          raise ECPSException.Create(30340, ErrorLUnknownGetMemType, [Integer(GetMemType)]);
    end;
    // Fill Block Header
    BlockHeader.GetMemType := GetMemType;
    BlockHeader.Signature := CPSMemorySignature;
    BlockHeader.Size := BufferSize;
    // Fill Block Footer
    BlockFooter := Pointer(PAnsiChar(BlockHeader) + SizeOf(TCPSMemoryBlockHeader) + BufferSize);
    BlockFooter.Signature := CPSMemoryEndSignature;


    Result := Pointer(PAnsiChar(BlockHeader) + SizeOf(TCPSMemoryBlockHeader));
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
      raise ECPSException.Create(30015, ErrorLGetMemError, [e.Message]);
  end;
end;//GetMem


//------------------------------------------------------------------------------
// AllocMem
//------------------------------------------------------------------------------
function TCPSMemoryManager.AllocMem(BufferSize: TCPSMemorySize):Pointer;
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
procedure TCPSMemoryManager.FreeAndNilMem(var Buffer);
var
  BlockHeader: PCPSMemoryBlockHeader;
  BlockFooter: PCPSMemoryBlockFooter;
  FooterIncorrect: Boolean;
begin
  // Increment Counter
  Inc(FFreeMemCallCount);
  try
    // Check Header Signature
    BlockHeader := PCPSMemoryBlockHeader(PAnsiChar(Buffer) - SizeOf(TCPSMemoryBlockHeader));
    if (BlockHeader.Signature <> CPSMemorySignature) then
      raise ECPSException.Create(30001, ErrorLInvalidPointer);
{
if (CPS_ENCRYPTED_DB_USED) then
 if (BlockHeader.Size > 0) then
  FillChar(PAnsiChar(Buffer)^,BlockHeader.Size,$00);
}
(*
    if (BlockHeader.Signature <> CPSMemorySignature) then
     begin
aaWriteToLog('FreeMem invalid signature : Buffer = '+IntToHex(Integer(PAnsiChar(Buffer)),8));
      raise ECPSException.Create(30001, ErrorLInvalidPointer);
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
    FooterIncorrect := (BlockFooter.Signature <> CPSMemoryEndSignature);

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
//aaWriteToLog('6 TCPSMemoryManager.FreeAndNilMem, type = '+IntToStr(Integer(BlockHeader.GetMemType)));

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
      raise ECPSException.Create(30137, ErrorLMemoryOverrunDetected);

  except
    on ECPSException do raise;
    on e: Exception do
      raise ECPSException.Create(30138, ErrorLFreeMemError, [e.Message]);
  end;
end;//FreeAndNilMem


//------------------------------------------------------------------------------
// ReallocMem
//------------------------------------------------------------------------------
procedure TCPSMemoryManager.ReallocMem(var Buffer; BufferSize: TCPSMemorySize; ClearTail: Boolean);
var
  BlockHeader: PCPSMemoryBlockHeader;
  NewBuffer: Pointer;
begin
{$IFDEF DEBUG_TCPSMemoryManager_REALLOCMEM}
aaStartTime(time1);
aaIncCounter;
try
{$ENDIF}

  // Increment Counter
  Inc(FReallocMemCallCount);
  try
    // Check Header Signature
    BlockHeader := PCPSMemoryBlockHeader(PAnsiChar(Buffer) - SizeOf(TCPSMemoryBlockHeader));
    if (BlockHeader.Signature <> CPSMemorySignature) then
      raise ECPSException.Create(30002, ErrorLInvalidPointer);

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
      raise ECPSException.Create(30014, ErrorLReallocMemError, [e.Message]);
  end;
{$IFDEF DEBUG_TCPSMemoryManager_REALLOCMEM}
finally
aaStopTime(time1);
end;
{$ENDIF}
end;//ReallocMem


//------------------------------------------------------------------------------
// ReAllocMem and clear Tail of Buffer
//------------------------------------------------------------------------------
procedure TCPSMemoryManager.ReallocMemAndClearTail(var Buffer; BufferSize: TCPSMemorySize);
begin
  ReallocMem(Buffer, BufferSize, True);
end;//ReallocMemAndClearTail

//------------------------------------------------------------------------------
// GetFreeMemorySize
//------------------------------------------------------------------------------
function TCPSMemoryManager.GetFreeMemorySize: TCPSMemorySize;
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
procedure CPSMove(const Source; var Dest; Count : Integer );
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
end; // CPSMove


//------------------------------------------------------------------------------
// return number of bytes for pre-allocation of the buffer
// for optimization of continios data grow
//------------------------------------------------------------------------------
function CPSGetReallocDelta(BufferSize: Int64): Int64;
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
end; // CPSGetReallocDelta


//------------------------------------------------------------------------------
// increase counter
//------------------------------------------------------------------------------
procedure CPSMemoryIncUseCount;
begin
  if (CPSMemoryUseCount = 0) then
   begin
     MemoryManager := TCPSMemoryManager.Create;
   end;
  Inc(CPSMemoryUseCount);
end; // CPSMemoryIncUseCount


//------------------------------------------------------------------------------
// decrease counter
//------------------------------------------------------------------------------
procedure CPSMemoryDecUseCount;
begin
 if (CPSMemoryUseCount > 1) then
  Dec(CPSMemoryUseCount)
 else
  CPSMemoryUseCount := 0;
 if (CPSMemoryUseCount = 0) then
  if (MemoryManager <> nil) then
   begin
    MemoryManager.Free;
    MemoryManager := nil;
   end;
end; // CPSMemoryDecUseCount


//------------------------------------------------------------------------------
// Refresh
//------------------------------------------------------------------------------
procedure CPSRefresh;
begin
// MUST CALL IN NOT CSECT!!!
 try
  if CPSRefreshInterval = 0 then
    Exit;
  if MainThreadID <> GetCurrentThreadId then
    Exit;
{$IFDEF LOG_REFRESH}
aaWriteToLog('CPSRefreshTime = '+IntToStr(CPSRefreshTime));
{$ENDIF}
  if (GetTickCount >= (CPSRefreshInterval + CPSRefreshTime)) then
   begin
{$IFDEF LOG_REFRESH}
aaWriteToLog('CPSRefresh> Before Sleep');
{$ENDIF}
    Sleep(250);
{$IFDEF LOG_REFRESH}
aaWriteToLog('CPSRefresh> ProcessMessages');
{$ENDIF}
    Application.ProcessMessages;
    CPSRefreshTime := GetTickCount;
{$IFDEF LOG_REFRESH}
aaWriteToLog('CPSRefresh> finished, NEW CPSRefreshTime = '+IntToStr(CPSRefreshTime));
{$ENDIF}
   end;
 except
  on E: Exception do
   begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('ERROR in CPSRefresh: '+E.Message);
{$ENDIF}
   end;
 end;
end; // Refresh


initialization

 CPSMemoryIncUseCount;
{$IFDEF LOG_REFRESH}
aaWriteToLog('CPSRefreshInterval = '+IntToStr(CPSRefreshInterval));
aaWriteToLog('CPSRefreshTime = '+IntToStr(CPSRefreshTime));
{$ENDIF}

finalization

  // changed in 5.02 #4 to avoid problem with unloading run-time package
  // compiled by C++ Builder - CPSMemory finalization is not last there
  CPSMemoryDecUseCount;
// MemoryManager.Free;
// MemoryManager := nil;

end.


