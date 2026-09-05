unit ACRMemory;

{$I ACRVer.inc}

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
     ACRDebug,
     {$ENDIF}
     ACRCriticalSection,
     ACRExcept, ACRConst;

type

 TACRMemorySize = Int64;

////////////////////////////////////////////////////////////////////////////////
//
// TACRMemoryManager
//
////////////////////////////////////////////////////////////////////////////////

 TACRMemoryManager = class (TObject)
  private
   FMaxMemorySize:        TACRMemorySize;  // Max Memory Limit
   FTotalMemAllocated:    TACRMemorySize;  // Total allocated memory
   FMaxMemAllocated:      TACRMemorySize;
   FFreeSystemMemorySize: TACRMemorySize;  // Free Memory size in system

   FAllocMemCallCount:    Int64;  // count of allocmem calls
   FGetMemCallCount:      Int64;  // count of getmem calls
   FFreeMemCallCount:     Int64;  // count of freemem calls
   FReallocMemCallCount:  Int64;  // count of reallocmem calls

   FThreadSync:           TACRReadWriteThreadSyncBySingleCriticalSection;
  protected
   procedure Lock(bExclusive: Boolean = True);
   procedure Unlock;
  public
   // Constructor
   constructor Create; overload;
   // Constructor
   constructor Create(MaxMemorySize: TACRMemorySize); overload;
   // Destructor
   destructor Destroy; override;
   // GetMem analog
   function GetMem(BufferSize: TACRMemorySize): Pointer;
   // AllocMem analog
   function AllocMem(BufferSize: TACRMemorySize): Pointer;
   // ReAllocMem analog
   procedure ReallocMem(var Buffer; BufferSize: TACRMemorySize; ClearTail: Boolean = False);
   // ReAllocMem and clear Tail of Buffer
   procedure ReallocMemAndClearTail(var Buffer; BufferSize: TACRMemorySize);
   // FreeMem and set pointer to nil
   procedure FreeAndNilMem(var Buffer);
   // Return buffer size
   function GetMemoryBufferSize(Buffer: Pointer): TACRMemorySize;
   // Get min from free system memory size and (FMaxMemorySize - FTotalMemAllocated)
   function GetFreeMemorySize:  TACRMemorySize;
  public
   property MaxMemorySize:        TACRMemorySize read FMaxMemorySize;
   property TotalMemAllocated:    TACRMemorySize read FTotalMemAllocated;
   property MaxMemAllocated:    TACRMemorySize read FMaxMemAllocated;
   // statistics usage
   property AllocMemCallCount:    Int64 read FAllocMemCallCount;
   property GetMemCallCount:      Int64 read FGetMemCallCount;
   property FreeMemCallCount:     Int64 read FFreeMemCallCount;
   property ReallocMemCallCount:  Int64 read FReallocMemCallCount;
 end; // TACRMemoryManager

// Memory Manager variable
var MemoryManager:      TACRMemoryManager = nil;
var ACRMemoryUseCount:  Cardinal = 0;

// move memory block
procedure ACRMove(const Source; var Dest; count : Integer );
// return number of bytes for pre-allocation of the buffer
// for optimization of continios data grow
function ACRGetReallocDelta(BufferSize: Int64): TACRMemorySize;
// increase counter
procedure ACRMemoryIncUseCount;
// decrease counter
procedure ACRMemoryDecUseCount;

// form refreshing
procedure ACRRefresh;
var
  ACRRefreshTime,
  ACRRefreshInterval:              DWORD;


implementation

uses Math, ACRTypes;

type
  TGetMemType = (gmtGetMem, gmtVirtualAlloc, gmtGlobalAlloc);

  // Memory Block Header
  PACRMemoryBlockHeader = ^TACRMemoryBlockHeader;
  TACRMemoryBlockHeader = packed record
    Size:       Cardinal;
    GetMemType: TGetMemType;
    Signature: Cardinal;  // Last 4 byte
  end;

  // Memory Block Footer
  PACRMemoryBlockFooter = ^TACRMemoryBlockFooter;
  TACRMemoryBlockFooter = packed record
    Signature: Cardinal;  // = ACRMemoryEndSignature
  end;


const  ACRMemorySignature:    Cardinal = $ACCACCAC;
       ACRMemoryEndSignature: Cardinal = $ACCEACCE;

type
   TGetMemFunction = packed record
     Size:       Cardinal;
     GetMemType: TGetMemType;
   end;

function GetMemFunctionType(MemSize: TACRMemorySize): TGetMemType;
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
        (Size: ACRMaxMemorySize;  GetMemType: gmtGlobalAlloc)    // 1 MB -  ...  ==> GlobalAlloc
      );
}
 {$ENDIF}
{$ENDIF}
end;


////////////////////////////////////////////////////////////////////////////////
//
// TACRMemoryManager
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// lock
//------------------------------------------------------------------------------
procedure TACRMemoryManager.Lock(bExclusive: Boolean);
begin
  FThreadSync.Lock(bExclusive);
end;


//------------------------------------------------------------------------------
// unlock
//------------------------------------------------------------------------------
procedure TACRMemoryManager.Unlock;
begin
  FThreadSync.Unlock;
end; // Unlock


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TACRMemoryManager.Create;
begin
  FThreadSync := TACRReadWriteThreadSyncBySingleCriticalSection.Create;
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
constructor TACRMemoryManager.Create(MaxMemorySize: TACRMemorySize);
begin
 Create;
 FMaxMemorySize := MaxMemorySize;
end;//Create


//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TACRMemoryManager.Destroy;
begin
 FThreadSync.Free;
 inherited;
 {$IFNDEF RELEASE_BUILD}
 if (FTotalMemAllocated > 0) then
  raise EACRException.Create(11990,ErrorLMemoryLeakFound,[FTotalMemAllocated]);
 {$ENDIF} 
end;//Destructor


//------------------------------------------------------------------------------
// GetMemoryBufferSize
//------------------------------------------------------------------------------
function TACRMemoryManager.GetMemoryBufferSize(Buffer: Pointer): TACRMemorySize;
var
  Block: PACRMemoryBlockHeader;
begin
  if Buffer = nil then
    Result := 0
  else
    begin
      Block := PACRMemoryBlockHeader(PAnsiChar(Buffer) - SizeOf(TACRMemoryBlockHeader));
      if (Block.Signature = ACRMemorySignature) then
        Result := Block.Size
      else
        raise EACRException.Create(30005, ErrorGInvalidPointer);
    end;
end;//GetMemoryBufferSize


//------------------------------------------------------------------------------
// GetMem
//------------------------------------------------------------------------------
function TACRMemoryManager.GetMem(BufferSize: TACRMemorySize): Pointer;
var
  NewSize: TACRMemorySize;
  BlockHeader: PACRMemoryBlockHeader;
  BlockFooter: PACRMemoryBlockFooter;
  GetMemType: TGetMemType;
begin
  // Increment Counter
  Inc(FGetMemCallCount);

  // Allocate 0 bytes ?
  if (BufferSize = 0) then
    raise EACRException.Create(30286, ErrorGCannotAllocateZeroBytes);

  // Mem Limit ?
  if ((FMaxMemorySize <> 0) and
      (BufferSize + FTotalMemAllocated > FMaxMemorySize)) then
    raise EACRException.Create(30004, ErrorGMemoryLimitExceeded, [FMaxMemorySize]);

  try
    // Calculate New Size of Buffer
    NewSize := BufferSize + SizeOf(TACRMemoryBlockHeader) + SizeOf(TACRMemoryBlockFooter);

    // GetMem
    GetMemType := GetMemFunctionType(NewSize);

//GetMemType := gmtGetMem;
{$IFDEF DEBUG_TRACE_TACRMemoryManager_GetMem}
if (Byte(GetMemType) = 2) then
 aaWriteToLog(IntToStr(NewSize)+#9+IntToStr(Byte(GetMemType)));
{$ENDIF}
{$IFDEF DEBUG_TACRMemoryManager_GetMem}
aaIncCounter(counter1);
if (Byte(GetMemType) = 0) then aaIncCounter(counter2);
if (Byte(GetMemType) = 1) then aaIncCounter(counter3);
if (Byte(GetMemType) = 2) then aaIncCounter(counter4);
{$ENDIF}
    case GetMemType of
      gmtGetMem:
          System.GetMem(BlockHeader, NewSize)
{$IFNDEF ACR_MEMORY_SYSTEM_ONLY}
{$IFDEF MSWINDOWS}
      ;
      gmtVirtualAlloc:
          BlockHeader := VirtualAlloc(nil, NewSize, MEM_COMMIT, PAGE_READWRITE);
      gmtGlobalAlloc:
          BlockHeader := Pointer(GlobalAlloc(GMEM_FIXED, NewSize))
 {$ENDIF}
 {$ENDIF}
      else
          raise EACRException.Create(30340, ErrorGUnknownGetMemType, [Integer(GetMemType)]);
    end;
    // Fill Block Header
    BlockHeader.GetMemType := GetMemType;
    BlockHeader.Signature := ACRMemorySignature;
    BlockHeader.Size := BufferSize;
    // Fill Block Footer
    BlockFooter := Pointer(PAnsiChar(BlockHeader) + SizeOf(TACRMemoryBlockHeader) + BufferSize);
    BlockFooter.Signature := ACRMemoryEndSignature;


    Result := Pointer(PAnsiChar(BlockHeader) + SizeOf(TACRMemoryBlockHeader));
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
      raise EACRException.Create(30015, ErrorGGetMemError, [e.Message]);
  end;
end;//GetMem


//------------------------------------------------------------------------------
// AllocMem
//------------------------------------------------------------------------------
function TACRMemoryManager.AllocMem(BufferSize: TACRMemorySize):Pointer;
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
procedure TACRMemoryManager.FreeAndNilMem(var Buffer);
var
  BlockHeader: PACRMemoryBlockHeader;
  BlockFooter: PACRMemoryBlockFooter;
  FooterIncorrect: Boolean;
begin
  // Increment Counter
  Inc(FFreeMemCallCount);
  try
    // Check Header Signature
    BlockHeader := PACRMemoryBlockHeader(PAnsiChar(Buffer) - SizeOf(TACRMemoryBlockHeader));
    if (BlockHeader.Signature <> ACRMemorySignature) then
      raise EACRException.Create(30001, ErrorGInvalidPointer);
{
if (ACR_ENCRYPTED_DB_USED) then
 if (BlockHeader.Size > 0) then
  FillChar(PAnsiChar(Buffer)^,BlockHeader.Size,$00);
}
(*
    if (BlockHeader.Signature <> ACRMemorySignature) then
     begin
aaWriteToLog('FreeMem invalid signature : Buffer = '+IntToHex(Integer(PAnsiChar(Buffer)),8));
      raise EACRException.Create(30001, ErrorGInvalidPointer);
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
    FooterIncorrect := (BlockFooter.Signature <> ACRMemoryEndSignature);

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
//aaWriteToLog('6 TACRMemoryManager.FreeAndNilMem, type = '+IntToStr(Integer(BlockHeader.GetMemType)));

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
      raise EACRException.Create(30137, ErrorGMemoryOverrunDetected);

  except
    on EACRException do raise;
    on e: Exception do
      raise EACRException.Create(30138, ErrorGFreeMemError, [e.Message]);
  end;
end;//FreeAndNilMem


//------------------------------------------------------------------------------
// ReallocMem
//------------------------------------------------------------------------------
procedure TACRMemoryManager.ReallocMem(var Buffer; BufferSize: TACRMemorySize; ClearTail: Boolean);
var
  BlockHeader: PACRMemoryBlockHeader;
  NewBuffer: Pointer;
begin
{$IFDEF DEBUG_TACRMemoryManager_REALLOCMEM}
aaStartTime(time1);
aaIncCounter;
try
{$ENDIF}

  // Increment Counter
  Inc(FReallocMemCallCount);
  try
    // Check Header Signature
    BlockHeader := PACRMemoryBlockHeader(PAnsiChar(Buffer) - SizeOf(TACRMemoryBlockHeader));
    if (BlockHeader.Signature <> ACRMemorySignature) then
      raise EACRException.Create(30002, ErrorGInvalidPointer);

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
      raise EACRException.Create(30014, ErrorGReallocMemError, [e.Message]);
  end;
{$IFDEF DEBUG_TACRMemoryManager_REALLOCMEM}
finally
aaStopTime(time1);
end;
{$ENDIF}
end;//ReallocMem


//------------------------------------------------------------------------------
// ReAllocMem and clear Tail of Buffer
//------------------------------------------------------------------------------
procedure TACRMemoryManager.ReallocMemAndClearTail(var Buffer; BufferSize: TACRMemorySize);
begin
  ReallocMem(Buffer, BufferSize, True);
end;//ReallocMemAndClearTail

//------------------------------------------------------------------------------
// GetFreeMemorySize
//------------------------------------------------------------------------------
function TACRMemoryManager.GetFreeMemorySize: TACRMemorySize;
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
procedure ACRMove(const Source; var Dest; Count : Integer );
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
end; // ACRMove


//------------------------------------------------------------------------------
// return number of bytes for pre-allocation of the buffer
// for optimization of continios data grow
//------------------------------------------------------------------------------
function ACRGetReallocDelta(BufferSize: Int64): Int64;
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
end; // ACRGetReallocDelta


//------------------------------------------------------------------------------
// increase counter
//------------------------------------------------------------------------------
procedure ACRMemoryIncUseCount;
begin
  if (ACRMemoryUseCount = 0) then
   begin
     MemoryManager := TACRMemoryManager.Create;
     ACRTempPageManagerMaxMemoryPageCount :=
      ((MemoryManager.GetFreeMemorySize div 10) div ACRDefaultPageSize);
   end;
  Inc(ACRMemoryUseCount);
end; // ACRMemoryIncUseCount


//------------------------------------------------------------------------------
// decrease counter
//------------------------------------------------------------------------------
procedure ACRMemoryDecUseCount;
begin
 if (ACRMemoryUseCount > 1) then
  Dec(ACRMemoryUseCount)
 else
  ACRMemoryUseCount := 0;
 if (ACRMemoryUseCount = 0) then
  if (MemoryManager <> nil) then
   begin
    MemoryManager.Free;
    MemoryManager := nil;
   end;
end; // ACRMemoryDecUseCount


//------------------------------------------------------------------------------
// Refresh
//------------------------------------------------------------------------------
procedure ACRRefresh;
begin
// MUST CALL IN NOT CSECT!!!
 try
  if ACRRefreshInterval = 0 then
    Exit;
  if MainThreadID <> GetCurrentThreadId then
    Exit;
{$IFDEF LOG_REFRESH}
aaWriteToLog('ACRRefreshTime = '+IntToStr(ACRRefreshTime));
{$ENDIF}
  if (aaGetTickCount >= (ACRRefreshInterval + ACRRefreshTime)) then
   begin
{$IFDEF LOG_REFRESH}
aaWriteToLog('ACRRefresh> Before Sleep');
{$ENDIF}
    Sleep(250);
{$IFDEF LOG_REFRESH}
aaWriteToLog('ACRRefresh> ProcessMessages');
{$ENDIF}
    Application.ProcessMessages;
    ACRRefreshTime := aaGetTickCount;
{$IFDEF LOG_REFRESH}
aaWriteToLog('ACRRefresh> finished, NEW ACRRefreshTime = '+IntToStr(ACRRefreshTime));
{$ENDIF}
   end;
 except
  on E: Exception do
   begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('ERROR in ACRRefresh: '+E.Message);
{$ENDIF}
   end;
 end;
end; // Refresh


initialization

 ACRMemoryIncUseCount;
 ACRRefreshInterval := ACRAntifreezeTimeOut;
 ACRRefreshTime := aaGetTickCount;
{$IFDEF LOG_REFRESH}
aaWriteToLog('ACRRefreshInterval = '+IntToStr(ACRRefreshInterval));
aaWriteToLog('ACRRefreshTime = '+IntToStr(ACRRefreshTime));
{$ENDIF}

finalization

  // changed in 5.02 #4 to avoid problem with unloading run-time package
  // compiled by C++ Builder - ACRMemory finalization is not last there
  ACRMemoryDecUseCount;
// MemoryManager.Free;
// MemoryManager := nil;

end.


