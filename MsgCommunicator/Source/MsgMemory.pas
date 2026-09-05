unit MsgMemory;

{$I MsgVer.inc}

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
     MsgDebug,
{$ENDIF}
     MsgExcept, MsgConst;


type

 TMsgMemorySize = Cardinal;

////////////////////////////////////////////////////////////////////////////////
//
// TMsgMemoryManager
//
////////////////////////////////////////////////////////////////////////////////

 TMsgMemoryManager = class (TObject)
  private
   FMaxMemorySize:        TMsgMemorySize;  // Max Memory Limit
   FTotalMemAllocated:    TMsgMemorySize;  // Total allocated memory
   FMaxMemAllocated:      TMsgMemorySize;

   FFreeSystemMemorySize: TMsgMemorySize;  // Free Memory size in system

   FAllocMemCallCount:    Int64;  // count of allocmem calls
   FGetMemCallCount:      Int64;  // count of getmem calls
   FFreeMemCallCount:     Int64;  // count of freemem calls
   FReallocMemCallCount:  Int64;  // count of reallocmem calls

   MMLock: TRTLCriticalSection;
  public
   // Constructor
   constructor Create; overload;
   // Constructor
   constructor Create(MaxMemorySize: TMsgMemorySize); overload;
   // Destructor
   destructor Destroy; override;
   // GetMem analog
   function GetMem(BufferSize: TMsgMemorySize): Pointer;
   // AllocMem analog
   function AllocMem(BufferSize: TMsgMemorySize): Pointer;
   // ReAllocMem analog
   procedure ReallocMem(var Buffer; BufferSize: TMsgMemorySize; ClearTail: Boolean = False);
   // ReAllocMem and clear Tail of Buffer
   procedure ReallocMemAndClearTail(var Buffer; BufferSize: TMsgMemorySize);
   // FreeMem and set pointer to nil
   procedure FreeAndNilMem(var Buffer);
   // Return buffer size
   function GetMemoryBufferSize(Buffer: Pointer): TMsgMemorySize;
   // Get min from free system memory size and (FMaxMemorySize - FTotalMemAllocated)
   function GetFreeMemorySize:  TMsgMemorySize;
  public
   property MaxMemorySize:        TMsgMemorySize read FMaxMemorySize;
   property TotalMemAllocated:    TMsgMemorySize read FTotalMemAllocated;
   property MaxMemAllocated:    TMsgMemorySize read FMaxMemAllocated;
   // statistics usage
   property AllocMemCallCount:    Int64 read FAllocMemCallCount;
   property GetMemCallCount:      Int64 read FGetMemCallCount;
   property FreeMemCallCount:     Int64 read FFreeMemCallCount;
   property ReallocMemCallCount:  Int64 read FReallocMemCallCount;
 end; // TMsgMemoryManager

// Memory Manager variable
var MemoryManager: TMsgMemoryManager = nil;

// move memory block
procedure MsgMove(const Source; var Dest; count : Integer );

// form refreshing
procedure MsgRefresh;
var
  MsgRefreshTime,
  MsgRefreshInterval:              DWORD;


implementation

uses Math;

type
  TGetMemType = (gmtGetMem, gmtVirtualAlloc, gmtGlobalAlloc);

  // Memory Block Header
  PMsgMemoryBlockHeader = ^TMsgMemoryBlockHeader;
  TMsgMemoryBlockHeader = packed record
    Size:       Cardinal;
    GetMemType: TGetMemType;
    Signature:  Cardinal;  // Last 4 byte
  end;

  // Memory Block Footer
  PMsgMemoryBlockFooter = ^TMsgMemoryBlockFooter;
  TMsgMemoryBlockFooter = packed record
    Signature: Cardinal;  // = MsgMemoryEndSignature
  end;


const  MsgMemorySignature:    Cardinal = $ACCACCAC;
       MsgMemoryEndSignature: Cardinal = $ACCEACCE;

type
   TGetMemFunction = packed record
     Size:       Cardinal;
     GetMemType: TGetMemType;
   end;

const

// If Enable MemChecker then use only GetMem function
{$IFDEF DEBUG_MEMCHECK}
   GetMemTypes: array[1..1] of TGetMemFunction =
      (
        (Size: High(TMsgMemorySize);  GetMemType: gmtGetMem)
      );
{$ELSE}
 {$IFDEF LINUX}
   GetMemTypes: array[1..1] of TGetMemFunction =
      (
        (Size: High(TMsgMemorySize);  GetMemType: gmtGetMem)
      );
 {$ENDIF}
 {$IFDEF MSWINDOWS}
   GetMemTypes: array[1..4] of TGetMemFunction =
      (
        (Size: 726;   GetMemType: gmtGetMem),          // 0     - 1024  ==> GetMem
        (Size: 64500;  GetMemType: gmtGlobalAlloc),    // 1025  - 64500 ==> GlobalAlloc
        (Size: 1048576;  GetMemType: gmtGetMem),       // 64500 - 1 MB ...  ==> GetMem
        (Size: High(TMsgMemorySize);  GetMemType: gmtGlobalAlloc)    // 1 MB -  ...  ==> GlobalAlloc
      );
 {$ENDIF}
{$ENDIF}

function GetMemFunctionType(MemSize: TMsgMemorySize): TGetMemType;
var i: Integer;
begin
  // Set GetMem Function for Maximum Size
  Result := GetMemTypes[High(GetMemTypes)].GetMemType;
  // Find lower diapason
  for i:= High(GetMemTypes) downto Low(GetMemTypes)  do
    if (MemSize <= GetMemTypes[i].Size) then
     begin
      Result := GetMemTypes[i].GetMemType;
      Break;
     end;
end;

////////////////////////////////////////////////////////////////////////////////
//
// TMsgMemoryManager
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TMsgMemoryManager.Create; 
begin 
 FMaxMemorySize := 0;
 FMaxMemAllocated := 0; 
 FTotalMemAllocated := 0; 
 InitializeCriticalSection(MMLock); 
end;//Create 
 
//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------ 
constructor TMsgMemoryManager.Create(MaxMemorySize: TMsgMemorySize);
begin 
 Create; 
 FMaxMemorySize := MaxMemorySize; 
end;//Create
	
 
//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TMsgMemoryManager.Destroy; 
begin 
 DeleteCriticalSection(MMLock);
 {$IFNDEF RELEASE_BUILD}
 if (FTotalMemAllocated > 0) then 
  raise EMsgException.Create(10044,ErrorLMemoryLeakFound,[FTotalMemAllocated]);
 {$ENDIF} 
 inherited;
end;//Destructor 
	
	
//------------------------------------------------------------------------------
// GetMemoryBufferSize 
//------------------------------------------------------------------------------
function TMsgMemoryManager.GetMemoryBufferSize(Buffer: Pointer): TMsgMemorySize;
var
  Block: PMsgMemoryBlockHeader; 
begin 
  if Buffer = nil then
    Result := 0 
  else 
    begin 
  Block := PMsgMemoryBlockHeader(PAnsiChar(Buffer) - SizeOf(TMsgMemoryBlockHeader));
  if (Block.Signature = MsgMemorySignature) then
    Result := Block.Size
  else
    raise EMsgException.Create(10017, ErrorLInvalidPointer); 
    end; 
end;//GetMemoryBufferSize
 
	
//------------------------------------------------------------------------------ 
// GetMem 
//------------------------------------------------------------------------------
function TMsgMemoryManager.GetMem(BufferSize: TMsgMemorySize): Pointer;
var
  NewSize: TMsgMemorySize; 
  BlockHeader: PMsgMemoryBlockHeader; 
  BlockFooter: PMsgMemoryBlockFooter; 
  GetMemType: TGetMemType; 
begin 
  // Increment Counter 
  Inc(FGetMemCallCount); 
 
  // Allocate 0 bytes ? 
  if (BufferSize = 0) then 
    raise EMsgException.Create(10018, ErrorLCannotAllocateZeroBytes); 
	
  // Mem Limit ?
  if ((FMaxMemorySize <> 0) and
      (BufferSize + FTotalMemAllocated > FMaxMemorySize)) then 
    raise EMsgException.Create(10019, ErrorLMemoryLimitExceeded, [FMaxMemorySize]);
 
  try 
    // Calculate New Size of Buffer 
    NewSize := BufferSize + SizeOf(TMsgMemoryBlockHeader) + SizeOf(TMsgMemoryBlockFooter); 
 
    // GetMem 
    GetMemType := GetMemFunctionType(NewSize); 
    case GetMemType of 
      gmtGetMem: 
          System.GetMem(BlockHeader, NewSize) 
 {$IFDEF MSWINDOWS} 
      ;
      gmtVirtualAlloc: 
          BlockHeader := VirtualAlloc(nil, NewSize, MEM_COMMIT, PAGE_READWRITE);
      gmtGlobalAlloc: 
          BlockHeader := Pointer(GlobalAlloc(GMEM_FIXED, NewSize)) 
 {$ENDIF}
      else
          raise EMsgException.Create(10020, ErrorLUnknownGetMemType, [Integer(GetMemType)]);
    end; 
    // Fill Block Header
    BlockHeader.GetMemType := GetMemType;
    BlockHeader.Signature := MsgMemorySignature; 
    BlockHeader.Size := BufferSize; 
    // Fill Block Footer
    BlockFooter := Pointer(PAnsiChar(BlockHeader) + SizeOf(TMsgMemoryBlockHeader) + BufferSize);
    BlockFooter.Signature := MsgMemoryEndSignature; 
	
 
    Result := Pointer(Cardinal(BlockHeader) + SizeOf(TMsgMemoryBlockHeader)); 
    EnterCriticalSection(MMLock);
    Inc(FTotalMemAllocated, BufferSize); 
    if (FTotalMemAllocated > FMaxMemAllocated) then
     FMaxMemAllocated := FTotalMemAllocated;
    LeaveCriticalSection(MMLock); 
  except 
    on e: Exception do
      raise EMsgException.Create(10021, ErrorLGetMemError, [e.Message]); 
  end;
end;//GetMem 
 
	
//------------------------------------------------------------------------------
// AllocMem
//------------------------------------------------------------------------------
function TMsgMemoryManager.AllocMem(BufferSize: TMsgMemorySize):Pointer;
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
procedure TMsgMemoryManager.FreeAndNilMem(var Buffer);
var
  BlockHeader: PMsgMemoryBlockHeader;
  BlockFooter: PMsgMemoryBlockFooter;
  FooterIncorrect: Boolean;
begin
  // Increment Counter
  Inc(FFreeMemCallCount);
  try
    // Check Header Signature
    BlockHeader := PMsgMemoryBlockHeader(PAnsiChar(Buffer) - SizeOf(TMsgMemoryBlockHeader));
    if (BlockHeader.Signature <> MsgMemorySignature) then
      raise EMsgException.Create(10022, ErrorLInvalidPointer);

    // Check Footer Signature
    BlockFooter := Pointer(PAnsiChar(Buffer) + BlockHeader.Size);
    FooterIncorrect := (BlockFooter.Signature <> MsgMemoryEndSignature);

    // Calculate TotalMemAllocated
    EnterCriticalSection(MMLock);
    Dec(FTotalMemAllocated, BlockHeader.Size);
    LeaveCriticalSection(MMLock);

    // FreeMem
    case BlockHeader.GetMemType of
      gmtGetMem:
          System.FreeMem(BlockHeader);
 {$IFDEF MSWINDOWS}
      gmtVirtualAlloc:
          VirtualFree(BlockHeader, 0, MEM_RELEASE);
      gmtGlobalAlloc:
          GlobalFree(Cardinal(Pointer(BlockHeader)));
 {$ENDIF}
    end;

    // Clear Buffer Pointer
    Pointer(Buffer) := nil;

    // if Footer Signature incorrect then raise
    if (FooterIncorrect) then
      raise EMsgException.Create(10023, ErrorLMemoryOverrunDetected);

  except
    on EMsgException do raise;
    on e: Exception do
      raise EMsgException.Create(10024, ErrorLFreeMemError, [e.Message]);
  end;
end;//FreeAndNilMem


//------------------------------------------------------------------------------
// ReallocMem
//------------------------------------------------------------------------------
procedure TMsgMemoryManager.ReallocMem(var Buffer; BufferSize: TMsgMemorySize; ClearTail: Boolean);
var
  BlockHeader: PMsgMemoryBlockHeader;
  NewBuffer: Pointer;
begin
  // Increment Counter
  Inc(FReallocMemCallCount);
  try
    // Check Header Signature
    BlockHeader := PMsgMemoryBlockHeader(PAnsiChar(Buffer) - SizeOf(TMsgMemoryBlockHeader));
    if (BlockHeader.Signature <> MsgMemorySignature) then
      raise EMsgException.Create(10025, ErrorLInvalidPointer);

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
      raise EMsgException.Create(10026, ErrorLReallocMemError, [e.Message]);
  end;
end;//ReallocMem


//------------------------------------------------------------------------------
// ReAllocMem and clear Tail of Buffer
//------------------------------------------------------------------------------
procedure TMsgMemoryManager.ReallocMemAndClearTail(var Buffer; BufferSize: TMsgMemorySize);
begin
  ReallocMem(Buffer, BufferSize, True);
end;//ReallocMemAndClearTail

//------------------------------------------------------------------------------
// GetFreeMemorySize
//------------------------------------------------------------------------------
function TMsgMemoryManager.GetFreeMemorySize: TMsgMemorySize;
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
procedure MsgMove(const Source; var Dest; Count: Integer);
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
end;


//------------------------------------------------------------------------------
// Refresh
//------------------------------------------------------------------------------
procedure MsgRefresh;
begin
// MUST CALL IN NOT CSECT!!!
 try
  if MsgRefreshInterval = 0 then
    Exit;
  if MainThreadID <> GetCurrentThreadId then
    Exit;
{$IFDEF LOG_REFRESH}
aaWriteToLog('ACRRefreshTime = '+IntToStr(ACRRefreshTime));
aaWriteToLog('aaGetTickCount = '+IntToStr(aaGetTickCount));
{$ENDIF}
  if (GetTickCount >= (MsgRefreshInterval + MsgRefreshTime)) then
   begin
{$IFDEF LOG_REFRESH}
aaWriteToLog('ACRRefresh> ProcessMessages');
{$ENDIF}
    Application.ProcessMessages;
    MsgRefreshTime := GetTickCount;
{$IFDEF LOG_REFRESH}
aaWriteToLog('ACRRefresh> finished');
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

 MemoryManager := TMsgMemoryManager.Create;
 MsgRefreshInterval := MsgAntifreezeTimeOut;
 MsgRefreshTime := GetTickCount;

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgMemory> initialized');
{$ENDIF}

finalization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgMemory> finalizing...');
{$ENDIF}
 MemoryManager.Free;
 MemoryManager := nil;
{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgMemory> finalized');
{$ENDIF}

end.


