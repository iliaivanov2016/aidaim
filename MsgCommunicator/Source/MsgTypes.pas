unit MsgTypes;

interface

{$I MsgVer.inc}

uses
     SysUtils, Classes,
{$IFDEF MSWINDOWS}
     Controls,
     Windows,
{$ENDIF}

{$IFDEF D12H}
     Msg_d12h,
{$ENDIF}
// MsgCommunicator units
{$IFDEF LINUX}
     MsgLinux,
{$ENDIF}
     {$IFDEF DEBUG_LOG}
     MsgDebug,
     {$ENDIF}
     MsgMemory,
     MsgConst,
     MsgCriticalSection,
     MsgExcept;

type

 TMsgUserIDs = array of Cardinal;
 TMsgContactNameSource = (mcnsUserName,mcnsFirstName,mcnsLastName,mcnsFullName,
                          mcnsCustom);
 TMsgMessageType = (
// Message Types
 aamtText, aamtBinary, aamtStream,
// Types for large objects with progress support
 aamtsFile,
// Command Types
 MsgUserOnLine, MsgUserOffLine,
 MsgInitLargeObject, MsgAbortLargeObject, // Types for large objects with progress support
 MsgCustomCommand,
 // added in 3.40
 aamtUnicodeText,
// Types for large objects with progress support
 aamtsStream,
 aamtNone
                    );

const MsgLowestType = MsgUserOnLine;
const MsgHighestType = MsgCustomCommand;

type
 TMsgDefaultNetworkSettings = (msgLocal, msgLAN, msgWAN, msgModem);

 TMsgCommandID = Int64;
 TMsgCommandHeader = packed record
  // RandomData MUST BE THE FIRST field in record !!! otherwise it will have no effect
  // CTS or CBC modes recommended. ECB not recommended - will produce same ends.
  RandomData:       array [0..3] of Integer; // 128 bit of random data
  CommandCode:      Integer; // code of the command (like in ConnectionManager.SendBuffer)
  CommandResult:    Integer; // error code or MSG_COMMAND_OK
  NativeError:      Integer; // native error code: EMsgException.NativeError
 end; // TMsgCommandHeader
 PMsgCommandHeader = ^TMsgCommandHeader;

 TMsgStringComparison = (mscmpExact,mscmpStarts,mscmpContains);
 TMsgComparisonOperator = (mcmpopNone,mcmpopEqual,mcmpopGreater,mcmpopLower,mcmpopNotEqual,
                           mcmpopGreaterEqual,mcmpopLowerEqual);
 TMsgTextComparison = packed record
  Comparison:       TMsgStringComparison;
  CaseInsensitive:  Boolean;
 end;
 TMsgDateComparison = packed record
  Comparison1:       TMsgComparisonOperator;
  DateTime1:         TDateTime;
  Comparison2:       TMsgComparisonOperator;
  DateTime2:         TDateTime;
 end;
 TMsgIntegerComparison = packed record
  Comparison1:       TMsgComparisonOperator;
  Value1:            Integer;
  Comparison2:       TMsgComparisonOperator;
  Value2:            Integer;
 end;

type

//------------------------------------------------------------------------------
// Encryption types
//------------------------------------------------------------------------------

  TMsgCryptoKey = packed record
   Key:             array [0..Msg_MAX_KEY] of Byte;
   KeySize:         Word; // 0 by default
  end;

  TMsgCryptoInfo = packed record
   KeyInfo:         TMsgCryptoKey;
   InitVector:      array [0..Msg_MAX_VECTOR] of Byte;
   Password:        AnsiString; // MsgDefaultPassword by default
   CryptoAlgorithm: Byte;  // msg_Cipher_None by Default
   CryptoMode:      Byte;  // msg_CTS by Default
   UseInitVector:   Boolean; // False by default
  end;

  TMsgCryptoControlBlock = packed record
   Data:            array [0..Msg_MAX_CONTROL_BLOCK] of Byte;
  end; // 256

  TMsgCryptoHeader = packed record
   ControlBlock:      TMsgCryptoControlBlock;
   ControlBlockCRC:   Cardinal;
   CryptoAlgorithm:   Byte;
   CryptoMode:        Byte;
   CryptoAskPassword: Byte; // ask password (1) or key (0)
   Reserverd:         array[0..4] of Byte;
  end; // 268

 TMsgCryptoParams = TMsgCryptoInfo;

//------------------------------------------------------------------------------
// general types
//------------------------------------------------------------------------------

 TMsgIntegerArray = class;

 TMsgLockParams = packed record
  RetryCount:   Integer;
  Delay:        Integer;
 end;

//------------------------------------------------------------------------------
// network types
//------------------------------------------------------------------------------


TMsgConnectParams = packed record
    ConnectionParamsTunning:          Boolean;
    PingClients:                      Boolean;
    CompressionAlgorithm:             Byte;
    CompressionMode:                  Byte;
    CryptoInfo:                       TMsgCryptoInfo;
    RemoteHost:                       AnsiString;
    RemotePort:                       Integer;
    LocalHost:                        AnsiString;
    LocalPort:                        Integer;
    ServerID:                         Integer;
    PacketSize:                       Integer;
    MaxThreadCount:                   Integer;
    TestPacketCount:                  Integer;
    ConnectRetryCount:                Integer;
    ConnectDelay:                     Integer;
    StartReceiveTimeOut:              Integer;
    ReceiveTimeOut:                   Integer;
    ReceiveSleep:                     Integer;
    ServerReceiveTimeOut:             Integer;
    ServerReceiveSleep:               Integer;
    MinSendTimeOut:                   Integer;
    SendTimeOut:                      Integer;
    MinServerSendTimeOut:             Integer;
    ServerSendTimeOut:                Integer;
    WaitForSendSleep:                 Integer;
    ServerWaitForSendSleep:           Integer;
    ResendDelay:                      Integer;
    RequestDelay:                     Integer;
    ServerResendDelay:                Integer;
    ServerRequestDelay:               Integer;
    DisconnectRetryCount:             Integer;
    DisconnectDelay:                  Integer;
    WaitForTimeOut:                   Integer;
    WaitForMessagesSend:              Integer;
    WaitForServerSessionThreadTimeOut:Integer;
    ThreadsTerminateDelay:            Integer;
    ServerThreadsTerminateDelay:      Integer;
    ServerSessionTerminatorSleep:     Integer;
    PingCount:                        Integer;
    WaitForPingAnswer:                Integer;
    ServerPingSleep:                  Integer;
    KeepConnection:                   Boolean;
    UseServerSettings:                Boolean;
 end;
 PMsgConnectParams = ^TMsgConnectParams;
 TMsgSessionID = Integer;

 // MsgDatabaseFile Mode Types
 TMsgShareMode = (smExclusive, smShared);
 TMsgAccessMode = (amReadOnly, amReadWrite);

 TMsgTimeoutParams = record
  RetryCount:   Word;
  Timeout:      Integer;
 end;

////////////////////////////////////////////////////////////////////////////////
//
// TMsgIntegerArray
//
////////////////////////////////////////////////////////////////////////////////

TMsgIntegerArray = class(TObject)
   public
     Items:          array of Integer;
     ItemCount:      Integer;
     AllocBy:        Integer;
     deAllocBy:      Integer;
     MaxAllocBy:     Integer;
     AllocItemCount: Integer;

     constructor Create(
      size: Integer = 0;
      DefaultAllocBy: Integer = 10;
      MaximumAllocBy: Integer = 100
     );
     destructor Destroy; override;
     procedure SetSize(newSize: Integer);
     procedure Assign(v: TMsgIntegerArray);
     procedure Append(value: Integer);
     procedure Add(value: Integer);
     procedure Remove(value: Integer);
     procedure Insert(ItemNo: Integer; value: Integer);
     procedure Delete(ItemNo: Integer);
     procedure MoveTo(itemNo, newItemNo: Integer);
     procedure CopyTo(
                      var ar: array of Integer;
                      itemNo, iCount: Integer
                      );
     function IsValueExists(value: Integer): Boolean;
 end; // TMsgIntegerArray


////////////////////////////////////////////////////////////////////////////////
//
// TMsgThreadIntArray
//
////////////////////////////////////////////////////////////////////////////////

 TMsgThreadIntArray = class(TMsgIntegerArray)
   private
    FCSect:         TRTLCriticalSection;
   public
    constructor Create(
      Owner: AnsiString = '';
      Log: Boolean = False;
      size: Integer = 0;
      DefaultAllocBy: Integer = 10;
      MaximumAllocBy: Integer = 100
                        );
    destructor Destroy; override;
    procedure Lock;
    procedure Unlock;
 end; // TMsgThreadIntArray


////////////////////////////////////////////////////////////////////////////////
//
// TMsgList
//
////////////////////////////////////////////////////////////////////////////////

 TMsgList = class
 private
  FItems:       array of Pointer;
  FCount:       Integer;
  FCapacity:    Integer;
  FDeAllocBy:   Integer;
  FAllocBy:     Integer;
  FMaxAllocBy:  Integer;
 protected
    function GetItem(Index: Integer): Pointer;
    procedure SetItem(Index: Integer; Item: Pointer);
    procedure SetCount(value: Integer); virtual;
    procedure SetCapacity(value: Integer); virtual;
 public
    constructor Create(
      size: Integer = 0;
      DefaultAllocBy: Integer = 10;
      MaximumAllocBy: Integer = 100
                       );
    destructor Destroy; override;
    procedure Clear; virtual;
    function IndexOf(Item: Pointer): Integer; virtual;
    procedure Add(Item: Pointer); virtual;
    procedure Remove(Item: Pointer); virtual;
    procedure Delete(Index: Integer); virtual;
    property Capacity: Integer read FCapacity write SetCapacity;
    property Count: Integer read FCount write SetCount;
    property Items[Index: Integer]: Pointer read GetItem write SetItem; default;
 end; // TMsgList


////////////////////////////////////////////////////////////////////////////////
//
// TMsgThreadList
//
////////////////////////////////////////////////////////////////////////////////

 TMsgThreadList = class(TMsgList)
  private
    FLock: TRTLCriticalSection;
  public
    constructor Create(
      Owner: AnsiString = '';
      Log: Boolean = False;
      size: Integer = 0;
      DefaultAllocBy: Integer = 10;
      MaximumAllocBy: Integer = 100
                       );
    destructor Destroy; override;
    procedure Clear;
    function  LockList: TMsgList;
    procedure Add(Item: Pointer);
    procedure Remove(Item: Pointer);
    procedure Delete(Index: Integer); override;
    procedure UnlockList;
 end; // TMsgThreadList


////////////////////////////////////////////////////////////////////////////////
//
// TMsgThread
//
////////////////////////////////////////////////////////////////////////////////

  TMsgThread = class(TThread)
  public
    FFinished: Boolean;
    FRecreate: Boolean;
  public
    constructor Create(Suspended: Boolean);
    destructor Destroy; override;
    function IsTerminated: Boolean;
  end;// TMsgThread

  PTMsgThread = ^TMsgThread;

////////////////////////////////////////////////////////////////////////////////
//
// Other functions
//
////////////////////////////////////////////////////////////////////////////////


  // returns temporary name
  function GetTemporaryName(Prefix: AnsiString): AnsiString;
  function GetStrLength(Buffer: PAnsiChar; Unicode: Boolean): Integer;

implementation

uses
//  MsgExpressions,
MsgCompression, Math;



////////////////////////////////////////////////////////////////////////////////
//
// TMsgIntegerArray
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Construct array of specified size
//------------------------------------------------------------------------------
constructor TMsgIntegerArray.Create(
  size: Integer;
  DefaultAllocBy: Integer;
  MaximumAllocBy: Integer
  );
begin
 AllocBy := DefaultAllocBy; // default alloc
 deAllocBy := DefaultAllocBy; // default dealloc
 MaxAllocBy := MaximumAllocBy; // max alloc
 AllocItemCount := 0;
 SetSize(size);
end;//TMsgIntegerArray.Create


//------------------------------------------------------------------------------
// Destruct array (free mem)
//------------------------------------------------------------------------------
destructor TMsgIntegerArray.Destroy;
begin
 Items := nil;
 inherited Destroy;
end;//TMsgIntegerArray.Destroy;


//------------------------------------------------------------------------------
// Set length of array to specified size
//------------------------------------------------------------------------------
procedure TMsgIntegerArray.SetSize(newSize: Integer);
begin
 if (newSize = 0) then
  begin
//aaDecCounter(counter5,allocItemCount);
   ItemCount := 0;
   allocItemCount := 0;
   Items := nil;
   Exit;
  end;

 if (newSize > allocItemCount) then
  begin
     AllocBy := AllocBy * 2;
     if (AllocBy > MaxAllocBy) then
      AllocBy := MaxAllocBy;
     if (allocItemCount + AllocBy > newSize) then
      begin
       allocItemCount := allocItemCount + AllocBy;
//aaIncCounter(counter5,AllocBy);
      end
     else
      begin
//aaIncCounter(counter5,(newSize-allocItemCount));
       allocItemCount := newSize;
      end;
     SetLength(Items,allocItemCount);
  end
 else
  if (newSize < ItemCount) then
   if (allocItemCount-newSize > deAllocBy) then
    begin
     deAllocBy := deAllocBy * 2;
     if (deAllocBy > MaxAllocBy) then
      deAllocBy := MaxAllocBy;
     SetLength(Items,newSize);
//aaDecCounter(counter5,(allocItemCount-newSize));
     allocItemCount := newSize;
    end;
 ItemCount := newSize;
end;//TMsgIntegerArray.SetSize


//------------------------------------------------------------------------------
// Set length of array to specified size
//------------------------------------------------------------------------------
procedure TMsgIntegerArray.Assign(v: TMsgIntegerArray); 
var 
  i: Integer;
begin 
  SetSize(v.ItemCount); 
  for i := 0 to ItemCount-1 do 
    items[i] := v.items[i]; 
end;// Assign 
	
	
//------------------------------------------------------------------------------ 
// inserts an element to the end of items array
//------------------------------------------------------------------------------ 
procedure TMsgIntegerArray.Append(value: Integer); 
begin 
 Inc(ItemCount);
 SetSize(itemCount);
 Items[itemCount-1] := value;
end;//TMsgIntegerArray.Append
	
	
//------------------------------------------------------------------------------ 
// add new item if it is not exist
//------------------------------------------------------------------------------
procedure TMsgIntegerArray.Add(value: Integer); 
begin
 if not IsValueExists(value) then
   Append(value); 
end;//TMsgIntegerArray.Add
	
	
//------------------------------------------------------------------------------ 
// Remove first item = value
//------------------------------------------------------------------------------
procedure TMsgIntegerArray.Remove(value: Integer);
var 
  i, j: Integer; 
begin
 j := -1; 
 for i := 0 to ItemCount-1 do 
  if Items[i] = value then 
   begin
    j := i;
    break;
   end;
 if j > -1 then 
   Delete(j); 
end;//TMsgIntegerArray.Remove

	
//------------------------------------------------------------------------------ 
// Insert an element into specified position 
//------------------------------------------------------------------------------
procedure TMsgIntegerArray.Insert(itemNo: Integer; value: Integer);
begin
 inc(ItemCount); 
 SetSize(ItemCount); 
 if (itemCount <= 1) then 
  items[0] := value 
 else 
 if (itemNo >= itemCount-1) 
  then 
   items[itemCount-1] := value 
  else 
   begin 
    Move(items[itemNo],items[itemNo+1], 
        (itemCount - itemNo-1) * sizeOf(Integer));
    items[itemNo] := value;
   end;
end;//TMsgIntegerArray.Insert 
	
 
//------------------------------------------------------------------------------ 
// Delete an element at specified position 
//------------------------------------------------------------------------------
procedure TMsgIntegerArray.Delete(itemNo: Integer); 
begin 
 if (itemNo < itemCount-1) then 
  Move(items[itemNo+1],items[itemNo], 
      (itemCount - itemNo-1) * sizeOf(Integer));
 dec(ItemCount); 
 SetSize(ItemCount); 
end;//TMsgIntegerArray.Delete
 
	
//------------------------------------------------------------------------------ 
// moves element to new position 
//------------------------------------------------------------------------------
procedure TMsgIntegerArray.MoveTo(itemNo, newItemNo: Integer);
var value : Integer;
begin 
 if (itemNo = newItemNo) then
  Exit;
 if (itemNo - newItemNo = 1) or (newItemNo-itemNo = 1) then 
  begin 
   value := items[itemNo];
   items[itemNo] := items[newItemNo];
   items[newItemNo] := value; 
   Exit;
  end; 
 if (itemNo > newItemNo) then
  begin
   value := items[itemNo]; 
   Move(PAnsiChar(items[newItemNo])^,PAnsiChar(items[newItemNo+1])^,
        (itemNo-newItemNo) * sizeof(Integer));
   items[newItemNo] := value; 
  end 
 else
  begin 
     value := items[ItemNo];
     Move(PAnsiChar(items[ItemNo+1])^,PAnsiChar(items[ItemNo])^,
        (newItemNo-ItemNo-1) * sizeof(Integer)); 
     items[newItemNo-1] := value;
  end;
end;// MoveTo(itemNo, newItemNo : Integer);
	
	
//------------------------------------------------------------------------------
// copies itemCount elements to ar from ItmeNo
//------------------------------------------------------------------------------ 
procedure TMsgIntegerArray.CopyTo(
                      var ar: array of Integer; 
                      itemNo, iCount: Integer
                             );
begin
 if (itemCount > 0) then 
  Move (PAnsiChar(items[itemNo])^,PAnsiChar(ar[0])^,sizeOf(Integer)*iCount);
end;// CopyTo(ar : array of Integer; itemNo,itemCount : Integer); 


//------------------------------------------------------------------------------
// returns true if value exists in Items array
//------------------------------------------------------------------------------
function TMsgIntegerArray.IsValueExists(value: Integer): Boolean;
var i: Integer;
begin
 Result := false;
 for i := 0 to ItemCount-1 do
  if Items[i] = value then
   begin
    Result := true;
    break;
   end;
end; // IsValueExists



////////////////////////////////////////////////////////////////////////////////
//
// TMsgThreadIntArray
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Construct array of specified size
//------------------------------------------------------------------------------
constructor TMsgThreadIntArray.Create(
                                Owner: AnsiString;
                                Log: Boolean;
                                size: Integer;
                                DefaultAllocBy: Integer;
                                MaximumAllocBy: Integer
                                    );
begin
  InitCSect(FCSect,Owner,Log);
  inherited Create(size, DefaultAllocBy, MaximumAllocBy);
end;//TMsgThreadIntArray.Create


//------------------------------------------------------------------------------
// Destruct array (free mem)
//------------------------------------------------------------------------------
destructor TMsgThreadIntArray.Destroy;
begin
  inherited Destroy;
  DeleteCSect(FCSect);
end;//TMsgThreadIntArray.Destroy;


//------------------------------------------------------------------------------
// Lock
//------------------------------------------------------------------------------
procedure TMsgThreadIntArray.Lock;
begin
  EnterCSect(FCSect);
end;//TMsgThreadIntArray.Lock;


//------------------------------------------------------------------------------
// Unlock
//------------------------------------------------------------------------------
procedure TMsgThreadIntArray.Unlock;
begin
  LeaveCSect(FCSect);
end;//TMsgThreadIntArray.Unlock;



////////////////////////////////////////////////////////////////////////////////
//
// TMsgList
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// get item
//------------------------------------------------------------------------------
function TMsgList.GetItem(Index: Integer): Pointer;
begin
  if ((Index < FCount) and (Index >= 0)) then
    Result := FItems[Index]
  else
   begin
    raise EMsgException.Create(11611,ErrorLInvalidIndex,[Index,FCount]);
   end;
end; // GetItem


//------------------------------------------------------------------------------
// set item
//------------------------------------------------------------------------------
procedure TMsgList.SetItem(Index: Integer; Item: Pointer);
begin
  if ((Index < FCount) and (Index >= 0)) then
    FItems[Index] := Item
  else
   begin
//    FCount := FCount;
    raise EMsgException.Create(11610,ErrorLInvalidIndex,[Index,FCount]);
   end;
end; // SetItem


//------------------------------------------------------------------------------
// set count
//------------------------------------------------------------------------------
procedure TMsgList.SetCount(value: Integer);
begin
 if (value = 0) then
  SetCapacity(0)
 else
  begin
   if (value > FCapacity) then
    SetCapacity(value);
   FCount := value;
  end;
end; // SetCount


//------------------------------------------------------------------------------
// set capacity
//------------------------------------------------------------------------------
procedure TMsgList.SetCapacity(value: Integer);
begin
 if (value < 0) then
  raise EMsgException.Create(11613,ErrorLInvalidCapacity,[value]);
 if (value = 0) then
  begin
   FCount := 0;
   FCapacity := 0;
   FItems := nil;
  end
 else
  begin
   if (value > FCapacity) then
    begin
     FAllocBy := FAllocBy * 2;
     if (FAllocBy > FMaxAllocBy) then
      FAllocBy := FMaxAllocBy;
     FCapacity := FCapacity + FAllocBy;
     if (FCapacity < value) then
      FCapacity := value;
    end // value > FCapacity
   else
    begin
     if ((FCapacity-value) > FDeAllocBy) then
      begin
       FCapacity := FCapacity - FDeAllocBy;
       FDeAllocBy := FDeAllocBy * 2;
       if (FDeAllocBy > FMaxAllocBy) then
        FDeAllocBy := FMaxAllocBy;
      end;
    end; // value < FCapacity
   SetLength(FItems,FCapacity);
  end;
end; // SetCapacity


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgList.Create(
      size: Integer = 0;
      DefaultAllocBy: Integer = 10;
      MaximumAllocBy: Integer = 100
                       );
begin
  FAllocBy := DefaultAllocBy;
  FDeAllocBy := FAllocBy;
  FMaxAllocBy := MaximumAllocBy;
  SetCount(0);
  SetCapacity(size);
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TMsgList.Destroy;
begin
  SetCapacity(0);
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// Clear
//------------------------------------------------------------------------------
procedure TMsgList.Clear;
begin
  SetCapacity(0);
end; // Clear


//------------------------------------------------------------------------------
// IndexOf
//------------------------------------------------------------------------------
function TMsgList.IndexOf(Item: Pointer): Integer;
var i: Integer;
begin
  Result := -1;
  for i := 0 to FCount-1 do
   if (FItems[i] = Item) then
    begin
     Result := i;
     break;
    end;
end; // IndexOf


//------------------------------------------------------------------------------
// add
//------------------------------------------------------------------------------
procedure TMsgList.Add(Item: Pointer);
begin
 if (FCount <= FCapacity) then
  SetCapacity(FCount+1);
 FItems[FCount] := Item;
 Inc(FCount);
end; // Add


//------------------------------------------------------------------------------
// remove
//------------------------------------------------------------------------------
procedure TMsgList.Remove(Item: Pointer);
var Index: Integer;
begin
  Index := IndexOf(Item);
  if (Index >= 0) then
    Delete(Index);
end; // Remove


//------------------------------------------------------------------------------
// delete
//------------------------------------------------------------------------------
procedure TMsgList.Delete(Index: Integer);
begin
  if ((Index < 0) or (Index >= FCount)) then
   begin
    raise EMsgException.Create(11612,ErrorLInvalidIndex,[Index,FCount]);
   end;
  if (FCount = 1) then
   SetCapacity(0)
  else
   begin
    if (Index < (FCount-1)) then
     Move(FItems[Index+1],FItems[Index],(FCount-Index)*SizeOf(Pointer));
    Dec(FCount);
    SetCapacity(FCount);
   end;
end; // Delete



////////////////////////////////////////////////////////////////////////////////
//
// TMsgThreadList
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// TMsgThreadList.Create
//------------------------------------------------------------------------------
constructor TMsgThreadList.Create(
      Owner: AnsiString = '';
      Log: Boolean = False;
      size: Integer = 0;
      DefaultAllocBy: Integer = 10;
      MaximumAllocBy: Integer = 100
                       );
begin
  inherited Create(size,DefaultAllocBy,MaximumAllocBy);
  InitCSect(FLock,Owner,Log);
end; // TMsgThreadList


//------------------------------------------------------------------------------
// TMsgThreadList.Destroy
//------------------------------------------------------------------------------
destructor TMsgThreadList.Destroy;
begin
  LockList;    // Make sure nobody else is inside the list.
  try
    inherited Destroy;
  finally
    UnlockList;
    DeleteCSect(FLock);
  end;
end; // TMsgThreadList.Destroy


//------------------------------------------------------------------------------
// clear list
//------------------------------------------------------------------------------
procedure TMsgThreadList.Clear;
begin
  LockList;
  try
    inherited Clear;
  finally
    UnlockList;
  end;
end;


//------------------------------------------------------------------------------
// lock list and return it as TMsgList for compatibility with TThreadList
//------------------------------------------------------------------------------
function TMsgThreadList.LockList: TMsgList;
begin
  EnterCSect(FLock);
  Result := TMsgList(Self);
end; // LockList


//------------------------------------------------------------------------------
// add item
//------------------------------------------------------------------------------
procedure TMsgThreadList.Add(Item: Pointer);
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
procedure TMsgThreadList.Remove(Item: Pointer);
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
procedure TMsgThreadList.Delete(Index: Integer);
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
procedure TMsgThreadList.UnlockList;
begin
  LeaveCSect(FLock);
end; // UnlockList



////////////////////////////////////////////////////////////////////////////////
//
// TMsgThread
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TMsgThread.Create(Suspended: Boolean);
begin
{$IFDEF LOG_TMSGTHREAD}
aaWriteToLog(Self.ClassName+' - CREATING...   Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
 FFinished := False;
 FRecreate := False;
 inherited Create(Suspended);
 Priority := tpNormal;
 FreeOnTerminate := True;
{$IFDEF LOG_TMSGTHREAD}
aaWriteToLog(Self.ClassName+' - CREATED!      Self = '+IntToHex(Integer(Self),8)+#9+'ThreadID = '+IntToStr(ThreadID));
{$ENDIF}
end; // Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TMsgThread.Destroy;
begin
// LeaveAllCSect(ThreadID);
{$IFDEF LOG_TMSGTHREAD}
aaWriteToLog(Self.ClassName+' - DESTROYING... Self = '+IntToHex(Integer(Self),8)+#9+'ThreadID = '+IntToStr(ThreadID));
{$ENDIF}
 LeaveAllCSect(ThreadID);
 inherited Destroy;
 FFinished := True;
{$IFDEF LOG_TMSGTHREAD}
aaWriteToLog(Self.ClassName+' - DESTROYED!    Self = '+IntToHex(Integer(Self),8));
{$ENDIF}
end; // Destroy


//------------------------------------------------------------------------------
// IsTerminated
//------------------------------------------------------------------------------
function TMsgThread.IsTerminated: Boolean;
begin
 Result := Terminated;
end;



////////////////////////////////////////////////////////////////////////////////
//
// Functions
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// return AnsiString value length
//------------------------------------------------------------------------------
function GetStrLength(Buffer: PAnsiChar; Unicode: Boolean): Integer;
var i: Integer;
begin
 if (Unicode) then
  begin
    i := 0;
    Result := 0;
    while (Buffer <> nil) do
     begin
      if (PAnsiChar(Buffer+i)^ = #0) then
        if (PAnsiChar(Buffer+i+1)^ = #0) then
         begin
          Result := i;
          break;
         end;
      Inc(i);
      Inc(i);
     end;
  end
 else
  Result := {$IFDEF D12H}aaStrLen({$ELSE}StrLen({$ENDIF}Buffer);
end; // GetStrLength


function GetTemporaryName(Prefix: AnsiString): AnsiString;
var x: Integer;
begin
  x := Random(MAXINT);
  Result := Prefix + IntToStr(x);
end; // GetTemporaryName



initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgTypes> initialized');
{$ENDIF}

end.
