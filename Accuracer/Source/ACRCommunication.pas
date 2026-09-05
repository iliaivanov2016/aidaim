//------------------------------------------------------------------------------
//
// Client classes
//
//------------------------------------------------------------------------------

unit ACRCommunication;

interface

{$I ACRVer.inc}

uses SysUtils, Classes,

// Accuracer units

{$IFDEF DEBUG_LOG}
     ACRDebug,
{$ENDIF}
{$IFNDEF D5H}
     ACRD4Routines,
{$ENDIF}
     ACRCompression,
     ACRBase,
     ACRExcept,
     ACRTypes,
     ACRConst,
     ACRMemory  // last
     ;


type

//------------------------------------------------------------------------------
//
//  Communication Command Format:
//
//  CommandHeader | [CommandData]
//
//------------------------------------------------------------------------------

  TACRCommunicationCommandType = (acctRequest,acctReply);

  TACRCommunicationRequest = (
//0
     accrqNULL // not a request

    // Session requests to the RemoteDatabase
// 1
    ,accrqConnectDatabase
    ,accrqDisconnectDatabase   // not used since v 4.02
    ,accrqIsDatabaseExists
    ,accrqGetTablesList
    ,accrqIsTableExists
// 6
    ,accrqGetFormatVersion
    ,accrqGetTotalPageCount
    ,accrqGetFreePageCount
    ,accrqIsDatabaseEncrypted
    ,accrqIsDatabaseEncryptedByPassword
    ,accrqIsCryptoParamsValid
// 12    
    ,accrqIsInTransaction
    ,accrqStartTransaction
    ,accrqCommit
// 15
    ,accrqRollback


    // Cursor requests
// 16
    ,accrqCreateTable
    ,accrqDeleteTable
    ,accrqEmptyTable
    ,accrqRenameTable
    ,accrqRenameField
// 21
    ,accrqOpenTable
    ,accrqCloseTable

//
//    ,accrqApplyDefaultValues

    ,accrqAddIndex
    ,accrqDeleteIndex
    ,accrqDeleteAllIndexes
    ,accrqGetRecordCount
// 27
    ,accrqGetRecordBuffer
// 28
    ,accrqSetRecNo
// 29    
    ,accrqGetRecNo
// 30    
    ,accrqInternalEdit
    ,accrqInternalCancel
// 32
    ,accrqInternalPost
    ,accrqInternalDelete
    ,accrqActivateFilters
// 35    
    ,accrqDeactivateFilters
    ,accrqLocate
    ,accrqFindKey
// 38    
    ,accrqResetRange
    ,accrqApplyRange
// 40
    ,accrqReadBLOBValue

// 41
    // SQLProcessor requests
    ,accrqExecSQL
    ,accrqSQLUnprepareParams
// 43
    ,accrqIsRecordExists
// 44
    ,accrqExportTableToSQL
// 45 - v.5
    ,accrqGetTablesInfo
// 46
    ,accrqGetTableState
// 47    
    ,accrqGetTableStateCursor
    ,accrqGetTableComment
    ,accrqSetTableComment
// 50
    ,accrqExportDatabaseToSQL
// 51
    ,accrqCreateStoredFunction
    ,accrqDropStoredFunction
    ,accrqAlterStoredFunction
    ,accrqAlterStoredFunctionRename
    ,accrqFindStoredFunction
// 56
    ,accrqGetStoredFunctions
// 57    
    ,accrqExportStoredFunctionsToSQL
// 58
    ,accrqClearCache
// 59
    ,accrqFlushFileBuffers
// 60
    ,accrqLoadRecords
    ,accrqSetCaseInsensitive
    ,accrqCreateView
// 63    
    ,accrqDropView
  );
  TACRCommunicationReply = (
     accrplNULL // not a reply
    ,accrplYes  // 1
    ,accrplNo   // 2
// 3
    ,accrplOperationSucceed
// 4
    ,accrplOperationFailed
  );

  TACRCommunicationCommandHeader = packed record
    Request:          TACRCommunicationRequest;
    Reply:            TACRCommunicationReply;
  end; // 2 bytes
  PACRCommunicationCommandHeader = ^TACRCommunicationCommandHeader;


////////////////////////////////////////////////////////////////////////////////
//
// TACRNetworkSession
//
////////////////////////////////////////////////////////////////////////////////


 TACRNetworkSession = class(TACRBaseSession)
  protected
   FSentCommandHeader:          TACRCommunicationCommandHeader;
   FSentCommandDataStream:      TACRMemoryStream;
   FReceivedCommandHeader:      TACRCommunicationCommandHeader;
   FReceivedCommandDataStream:  TACRMemoryStream;
   FCommandReceived:            Boolean;
   FMinCacheSize:                Int64;
   FMaxCacheSize:                Int64;
  public
   FConnected:                  Boolean; // public -- for UnitTester
   constructor Create;
   destructor Destroy; override;
   procedure DoCloseSessionOnNetworkError; virtual;
   // receive data from network and move it to ReceivedCommandHeader and ReceivedCommandDataStream
   procedure ReceiveData(Buffer: PAnsiChar; BufferSize: Integer); override;
   // send command specified by SentCommandHeader [ optionally SentCommandDataStream ]
   function SendCommand: Boolean; virtual;
   // send buffer via established connection using connection manager
   procedure SendBuffer(var Buffer: PAnsiChar; BufferSize: Integer); virtual;
   // send custom message
   procedure SendMessage(Buffer: PAnsiChar; BufferSize: Integer); virtual;
   procedure ReceiveMessage(Buffer: PAnsiChar; BufferSize: Integer); virtual;
  public
   property SentCommandHeader: TACRCommunicationCommandHeader
              read FSentCommandHeader write FSentCommandHeader;
   property SentCommandDataStream: TACRMemoryStream
              read FSentCommandDataStream;
   property ReceivedCommandHeader: TACRCommunicationCommandHeader
              read FReceivedCommandHeader;
   property ReceivedCommandDataStream: TACRMemoryStream
              read FReceivedCommandDataStream;
   property MinCacheSize: Int64 read FMinCacheSize write FMinCacheSize;
   property MaxCacheSize: Int64 read FMaxCacheSize write FMaxCacheSize;
 end; // TACRNetworkSession




////////////////////////////////////////////////////////////////////////////////
//
// TACRBaseRecordCache - used in client-server
// both on server side and on client side (with record buffers - TACRClientRecordCache)
//
////////////////////////////////////////////////////////////////////////////////


 TACRBaseRecordCache = class(TObject)
  protected
   LCursor:           TACRCursor; // main parent cursor: TACRClientCursor or TACRLocalCursor
   FRecords:          TACRRecordIDArray; // stores RecordID in order from BOF to EOF
   FRecordNumbers:    TACRInt64Array; // stores RecNo for each record in FRecords
   FBuffer:           TACRRecordBuffer; // stores record buffers
   FNumRecords:       Integer; // real number of records stored in the cache (from 0 index)
   FMinRecords:       Integer; // minimum number of records (minimum size of the cache)
   FMaxRecords:       Integer; // maximum number of records (maximum size of the cache)
   FState:            TACRTableState; // last table state when the records were loaded last time
   FLoaded:           Boolean;
   FRecordCount:      TACRRecordNo; // number of visible records in the table (with all filters applied)
   FFirstRecordID:    TACRRecordID; // id of first visible record in the table (immediately after BOF)
   FLastRecordID:     TACRRecordID; // id of last visible record in the table (immediately before EOF)
   FLastLoadedTime:   Cardinal; // aaGetTickCount value when was last time loaded
  protected
   procedure ResizeCache(NewRecordCount: Integer); virtual;
  public
   constructor Create(aMinRecords, aMaxRecords: Integer; aCursor: TACRCursor);
   destructor Destroy; override;
   procedure LoadFromStream(Stream: TACRMemoryStream); virtual;
   procedure SaveToStream(Stream: TACRMemoryStream);
   procedure SetState(const NewState: TACRTableState);
  public
   property MinRecords: Integer read FMinRecords;
   property MaxRecords: Integer read FMaxRecords;
   property NumRecords: Integer read FNumRecords write FNumRecords;
   property State: TACRTableState read FState;
   property Loaded: Boolean read FLoaded write FLoaded default False;
 end; // TACRBaseRecordCache



implementation


////////////////////////////////////////////////////////////////////////////////
//
// TACRNetworkSession
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRNetworkSession.Create;
begin
  inherited;
  FCommandReceived := False;
  FSentCommandDataStream := TACRMemoryStream.Create;
  FReceivedCommandDataStream := TACRMemoryStream.Create;
  FConnected := False;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRNetworkSession.Destroy;
begin
  FSentCommandDataStream.Free;
  FReceivedCommandDataStream.Free;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// Close Session On Network Error
//------------------------------------------------------------------------------
procedure TACRNetworkSession.DoCloseSessionOnNetworkError;
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('==================================================================');
aaWriteToLog('Error in TACRNetworkSession.DoCloseSessionOnNetworkError - not overriden');
aaWriteToLog('ClassName = '+Self.ClassName);
aaWriteToLog('------------------------------------------------------------------');
aaWriteToLog('SessionID=' + IntToStr(Integer(Self.SessionID))
+'==================================================================');
{$ENDIF}
end; // DoCloseSessionOnNetworkError


//------------------------------------------------------------------------------
// receive data from network and move it to ReceivedCommandHeader and ReceivedCommandDataStream
//------------------------------------------------------------------------------
procedure TACRNetworkSession.ReceiveData(Buffer: PAnsiChar; BufferSize: Integer);
var Size: Integer;
begin
{$IFDEF DEBUG_LOG_COMMUNICATION}
aaWriteToLog('start TACRNetworkSession.ReceiveData, Buffer = '+IntToStr(Integer(Buffer))+
', length = '+
IntToStr(MemoryManager.GetMemoryBufferSize(Buffer))
+#13#10+
' local port = '+IntToStr(Self.ConnectParams.LocalPort)+'<<<'
);
{$ENDIF}
  // ignore invalid buffers
  if (BufferSize >= SizeOf(TACRCommunicationCommandHeader)) then
   begin
    FCommandReceived := True;
    Size := BufferSize - SizeOf(TACRCommunicationCommandHeader);
    FReceivedCommandDataStream.Size := Size;
    Move (Buffer^, FReceivedCommandHeader, SizeOf(TACRCommunicationCommandHeader));
    if (Size > 0) then
      Move(PAnsiChar(Buffer + SizeOf(TACRCommunicationCommandHeader))^,
           FReceivedCommandDataStream.Buffer^,Size);
    FReceivedCommandDataStream.Position := 0;
   end
  else
   raise EACRException.Create(11511,ErrorLInvalidCommandBufferReceived,[BufferSize,SizeOf(TACRCommunicationCommandHeader)]);
{$IFDEF DEBUG_LOG_COMMUNICATION}
aaWriteToLog('finish TACRNetworkSession.ReceiveData, Buffer = '+IntToStr(Integer(Buffer))+
', length = '+
IntToStr(MemoryManager.GetMemoryBufferSize(Buffer))
+#13#10+
'time = '+IntToStr(aaGetTickCount)
);
{$ENDIF}
end; // ReceiveData


//------------------------------------------------------------------------------
// send command specified by SentCommandHeader [ optionally SentCommandDataStream ]
//------------------------------------------------------------------------------
function TACRNetworkSession.SendCommand: Boolean;
var Buffer:     PAnsiChar;
    BufferSize: Integer;
    Size:       Integer;

 procedure Finalize;
 begin
   if (Buffer <> nil) and (BufferSize > 0) then
    MemoryManager.FreeAndNilMem(Buffer);
   FSentCommandDataStream.Size := 0;
 end;

begin
{$IFDEF DEBUG_LOG_COMMUNICATION}
aaWriteToLog('TACRNetworkSession.SendCommand> start, local port = '+IntToStr(Self.ConnectParams.LocalPort)+'>>>');
{$ENDIF}
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
aaIncCounter(counter1);
if (FSentCommandHeader.Request = accrqLoadRecords) then
 aaIncCounter(counter2);
aaStartTime(time1);
{$ENDIF}
  Result := False;
  BufferSize := FSentCommandDataStream.Size + SizeOf(TACRCommunicationCommandHeader);
  Buffer := MemoryManager.GetMem(BufferSize);
  Move(FSentCommandHeader,Buffer^,SizeOf(TACRCommunicationCommandHeader));
  Size := FSentCommandDataStream.Size;
  if (Size > 0) then
    Move(FSentCommandDataStream.Buffer^,
         PAnsiChar(Buffer + SizeOf(TACRCommunicationCommandHeader))^,
         Size);
  FSentCommandDataStream.Position := 0;
  try
{$IFDEF DEBUG_LOG_COMMUNICATION}
aaWriteToLog('TACRNetworkSession.SendCommand> before SendBuffer, BufferSize = '+IntToStr(BufferSize));
{$ENDIF}
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
aaStartTime(time2);
{$ENDIF}
    SendBuffer(Buffer,BufferSize);
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
aaStopTime(time2);
{$ENDIF}
{$IFDEF DEBUG_LOG_COMMUNICATION}
aaWriteToLog('TACRNetworkSession.SendCommand> after SendBuffer, BufferSize = '+IntToStr(BufferSize));
{$ENDIF}
    Finalize;
    Result := True;
  except
    on e: EACRException do
     begin
      DoOnError(ACR_CS_ErrorSendCommandFailed,e.NativeError,
                 Format(ErrorL_CS_ErrorSendCommandFailed,
                       [Integer(FSentCommandHeader.Request),Integer(FSentCommandHeader.Reply),FSessionID,e.Message]));
      Finalize;
{ -- to enable client to resend a command (Acr 5.60)
      if (e.NativeError <> 40080) then
       SetConnected(False);
}
     end;
    on e: Exception do
     begin
      DoOnError(ACR_CS_ErrorSendCommandFailed,-1,
                 Format(ErrorL_CS_ErrorSendCommandFailed,
                       [Integer(FSentCommandHeader.Request),Integer(FSentCommandHeader.Reply),FSessionID,e.Message]));
      Finalize;
     end
    else
     begin
      DoOnError(ACR_CS_ErrorSendCommandFailed,-1,
                 Format(ErrorL_CS_ErrorSendCommandFailed,
                       [Integer(FSentCommandHeader.Request),Integer(FSentCommandHeader.Reply),FSessionID,'']));
      Finalize;
     end;
  end;
{$IFDEF DEBUG_LOG_COMMUNICATION_COUNT_TIMES}
aaStopTime(time1);
{$ENDIF}
{$IFDEF DEBUG_LOG_COMMUNICATION}
aaWriteToLog('finish TACRNetworkSession.SendCommand'
+#13#10+
'time = '+IntToStr(aaGetTickCount)
);
{$ENDIF}
end; // SendCommand


//------------------------------------------------------------------------------
// send buffer via established connection using connection manager
//------------------------------------------------------------------------------
procedure TACRNetworkSession.SendBuffer(var Buffer: PAnsiChar; BufferSize: Integer);
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('==================================================================');
aaWriteToLog('Error in TACRNetworkSession.SendBuffer - not overriden');
aaWriteToLog('ClassName = '+Self.ClassName);
aaWriteToLog(
'------------------------------------------------------------------');
aaWriteToLog('SessionID=' + IntToStr(Integer(Self.SessionID))
+'==================================================================');
{$ENDIF}
end;


//------------------------------------------------------------------------------
// send custom message
//------------------------------------------------------------------------------
procedure TACRNetworkSession.SendMessage(Buffer: PAnsiChar; BufferSize: Integer);
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('==================================================================');
aaWriteToLog('Error in TACRNetworkSession.SendMessage - not overriden');
aaWriteToLog('ClassName = '+Self.ClassName);
aaWriteToLog(
'------------------------------------------------------------------');
aaWriteToLog('SessionID=' + IntToStr(Integer(Self.SessionID))
+'==================================================================');
{$ENDIF}
end;


//------------------------------------------------------------------------------
// receive message
//------------------------------------------------------------------------------
procedure TACRNetworkSession.ReceiveMessage(Buffer: PAnsiChar; BufferSize: Integer);
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('==================================================================');
aaWriteToLog('Error in TACRNetworkSession.ReceiveMessage - not overriden');
aaWriteToLog('ClassName = '+Self.ClassName);
aaWriteToLog(
'------------------------------------------------------------------');
aaWriteToLog('SessionID=' + IntToStr(Integer(Self.SessionID))
+'==================================================================');
{$ENDIF}
end;




////////////////////////////////////////////////////////////////////////////////
//
// TACRBaseRecordCache - used in client-server
// both on server side and on client side (with record buffers)
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// resize cache
//------------------------------------------------------------------------------
procedure TACRBaseRecordCache.ResizeCache(NewRecordCount: Integer);
begin
  FRecords.Realloc(FNumRecords,NewRecordCount);
  FRecordNumbers.Realloc(FNumRecords,NewRecordCount);
  if (NewRecordCount <= 0) then
   begin
    if (FBuffer <> nil) then
     MemoryManager.FreeAndNilMem(FBuffer);
   end
  else
   begin
    if (FBuffer = nil) then
     FBuffer := MemoryManager.GetMem(NewRecordCount*LCursor.RecordSize)
    else
     MemoryManager.ReallocMem(FBuffer,NewRecordCount*LCursor.RecordSize);
   end;
end; // ResizeCache


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TACRBaseRecordCache.Create(aMinRecords, aMaxRecords: Integer;  aCursor: TACRCursor);
begin
  if (aCursor = nil) then raise EACRException.Create(12314,ErrorLNilPointer);
  FBuffer := nil;
  FNumRecords := 0;
  FMinRecords := aMinRecords;
  FMaxRecords := aMaxRecords;
  FRecords := TACRRecordIDArray.Create(FMinRecords);
  FRecords.Sorted := False;
  FRecordNumbers := TACRInt64Array.Create(FMinRecords);
  FRecordCount := 0;
  FillChar(FFirstRecordID,SizeOf(FFirstRecordID),$FF);
  FillChar(FLastRecordID,SizeOf(FLastRecordID),$FF);
  FillChar(FState,SizeOf(FState),$00);
  LCursor := aCursor;
end; // Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TACRBaseRecordCache.Destroy;
begin
  try
   FRecords.Free;
  except
  end;
  try
   FRecordNumbers.Free;
  except
  end;
  if (FBuffer <> nil) then
   try
    MemoryManager.FreeAndNilMem(FBuffer);
   except
   end;
  inherited;
end; // Create


//------------------------------------------------------------------------------
// Load from stream
//------------------------------------------------------------------------------
procedure TACRBaseRecordCache.LoadFromStream(Stream: TACRMemoryStream);
begin
  LoadDataFromStream(FRecordCount,SizeOf(FRecordCount),Stream,12320);
  LoadDataFromStream(FFirstRecordID,SizeOf(TACRRecordID),Stream,12321);
  LoadDataFromStream(FLastRecordID,SizeOf(TACRRecordID),Stream,12322);
  LoadDataFromStream(FNumRecords,SizeOf(FNumRecords),Stream,12323);
  if (FNumRecords < 0) then
   FNumRecords := 0;
  FRecords.SetSize(FNumRecords);
  FRecordNumbers.SetSize(FNumRecords);
  if (FBuffer <> nil) then
   begin
    if (FNumRecords > 0) then
     MemoryManager.ReallocMem(FBuffer,FNumRecords *  LCursor.RecordSize)
    else
     MemoryManager.FreeAndNilMem(FBuffer);
   end
  else
   begin
    if (FNumRecords > 0) then
     FBuffer := MemoryManager.GetMem(FNumRecords *  LCursor.RecordSize);
   end;
  if (FNumRecords > 0) then
   begin
    LoadDataFromStream(FRecords.Items[0],FNumRecords * SizeOf(TACRRecordID),Stream,12324);
    LoadDataFromStream(FRecordNumbers.Items[0],FNumRecords*SizeOf(Int64),Stream,12325);
    if (FBuffer <> nil) then
     LoadDataFromStream(FBuffer^,FNumRecords * LCursor.RecordSize,Stream,12326);
   end;
  LoadDataFromStream(FState,SizeOf(FState),Stream,12367);
  FLoaded := True;
  FLastLoadedTime := aaGetTickCount;
end; // LoadFromStream


//------------------------------------------------------------------------------
// Save to stream
//------------------------------------------------------------------------------
procedure TACRBaseRecordCache.SaveToStream(Stream: TACRMemoryStream);
var pos,n: Int64;
begin
  if (FNumRecords <> FRecords.ItemCount) then
   raise EACRException.Create(12309,ErrorLInvalidCount,[FNumRecords,FRecords.ItemCount]);
  if (FNumRecords <> FRecordNumbers.ItemCount) then
   raise EACRException.Create(12310,ErrorLInvalidCount,[FNumRecords,FRecords.ItemCount]);
  if ((FNumRecords > 0) and (FBuffer = nil)) then
   raise EACRException.Create(12318,ErrorLNilPointer);
  pos := Stream.Position;
  n := SizeOf(FNumRecords)+ SizeOf(FRecordCount) +
                 SizeOf(TACRRecordID) * 2 +
                 FNumRecords * (SizeOf(Int64) + SizeOf(TACRRecordID) + LCursor.RecordSize);
  Stream.Size := Stream.Size + n;
  Stream.Position := pos;
  SaveDataToStream(FRecordCount,SizeOf(FRecordCount),Stream,12315);
  SaveDataToStream(FFirstRecordID,SizeOf(TACRRecordID),Stream,12316);
  SaveDataToStream(FLastRecordID,SizeOf(TACRRecordID),Stream,12317);
  SaveDataToStream(FNumRecords,SizeOf(FNumRecords),Stream,12311);
  if (FNumRecords > 0) then
   begin
    SaveDataToStream(FRecords.Items[0],FNumRecords * SizeOf(TACRRecordID),Stream,12312);
    SaveDataToStream(FRecordNumbers.Items[0],FNumRecords*SizeOf(Int64),Stream,12313);
    SaveDataToStream(FBuffer^,FNumRecords * LCursor.RecordSize,Stream,12319);
   end;
  SaveDataToStream(FState,SizeOf(FState),Stream,12360);
end; // SaveToStream


//------------------------------------------------------------------------------
// set new state
//------------------------------------------------------------------------------
procedure TACRBaseRecordCache.SetState(const NewState: TACRTableState);
begin
  Move(NewState,FState,SizeOf(FState));
end; // SetState


initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ACRCommunication> initialized');
{$ENDIF}
  ACRMemoryIncUseCount;

finalization

  ACRMemoryDecUseCount;


end.
