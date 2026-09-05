unit SQLMemTempEngine;

{$I SQLMemVer.inc}

interface

uses SysUtils, Classes,

// SQLMemTable units

     {$IFDEF DEBUG_LOG}
     SQLMemDebug,
     {$ENDIF}
     SQLMemCriticalSection,
     SQLMemExcept,
     SQLMemBase,
     SQLMemPage,
     SQLMemBaseEngine,
     SQLMemCompression,
     SQLMemTypes,
     SQLMemConverts,
     SQLMemConst;

type
   TSQLMemTemporaryTableData = class;


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemTemporaryRecordManager
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemTemporaryRecordManager = class (TSQLMemBaseRecordManager)
   private
    FRecordsPerPage:        Integer;
    FPageSize:              Integer;
    FCachedRecordCount:     Integer;
    FAllocatedRecordCount:  Integer;
    FTempPageRecordCount:   Integer;
    FTempPageFile:          TSQLMemFileStream;
    FAllocRecordsBy:        Integer;

    FBufferList:            TList; // list of buffer's pointers (FAllocRecordsBy records each buffer);

    function ReadRecord(
                        var RecordBuffer: TSQLMemRecordBuffer;
                        RecordID: TSQLMemRecordNo
                       ): Boolean;
    // return result for attempt of getting record relatively to first position
    // and set RecordID to new record ID
    function GetRecordFromFirstPosition(
            GetRecordMode: TSQLMemGetRecordMode;
            var RecordID:  TSQLMemRecordNo
                                       ): TSQLMemGetRecordResult;
    // return result for attempt of getting record relatively to last position
    // and set RecordID to new record ID
    function GetRecordFromLastPosition(
            GetRecordMode: TSQLMemGetRecordMode;
            var RecordID:  TSQLMemRecordNo
                                      ): TSQLMemGetRecordResult;
    // return result for attempt of getting record relatively any position
    // and set RecordID to new record ID
    function GetRecordFromAnyPosition(
            GetRecordMode: TSQLMemGetRecordMode;
            var RecordID:  TSQLMemRecordNo
                                      ): TSQLMemGetRecordResult;
   public
    constructor Create(
                        RecordBufferSize:     Integer;
                        RecordsPerPage:       Integer;
                        AllocRecordsBy:       Integer
                      );
    destructor Destroy; override;

    procedure Empty(SessionID: TSQLMemSessionID = INVALID_SESSION_ID); override;

    // return true if record exists
    function IsRecordExists(var RecordID: TSQLMemRecordID; SessionID: TSQLMemSessionID = INVALID_SESSION_ID): Boolean; override;
    // add record and return its number
    function AddRecord(
                       RecordBuffer:   TSQLMemRecordBuffer;
                        var RecordID:  TSQLMemRecordID;
                        SessionID:     TSQLMemSessionID = INVALID_SESSION_ID
                       ): Boolean; override;
    procedure GetRecordBuffer(var NavigationInfo: TSQLMemNavigationInfo); override;
    // return record no
    function GetApproximateRecNo(RecordID: TSQLMemRecordID; SessionID: TSQLMemSessionID): TSQLMemRecordNo; override;
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
  end; // TSQLMemTemporaryRecordManager


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemTemporaryDatabaseData
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemTemporaryDatabaseData = class (TSQLMemDatabaseData)
   public
    constructor Create;
    destructor Destroy; override;
    // create table data
    function CreateTableData(Cursor: TSQLMemCursor): TSQLMemTableData; override;
    procedure ConnectSession(Session: TSQLMemBaseSession); override;
  end; // TSQLMemTemporaryDatabaseData


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemTemporaryTableData
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemTemporaryTableData = class (TSQLMemTableData)
   private
// changed in v.4.80 - to fix the problem 20 October 2008
//    FBLOBFile:          TSQLMemFileStream;
    FBLOBFile:          TSQLMemTemporaryStream;
    FRecordsPerPage:    Integer;
    FAllocRecordsBy:    Integer;
    FPageManager:       TSQLMemPageManager;

   protected
    function GetPageManager: TSQLMemPageManager; override;
    procedure CreateRecordManager; override;
    procedure CreateBLOBFile;
    procedure DeleteBLOBFile;
    // return filter bitmap rec no by record id
    function GetBitmapRecNoByRecordID(RecordID: TSQLMemRecordID): TSQLMemRecordNo; override;
    // return filter bitmap rec no by record id
    function GetRecordIDByBitmapRecNo(RecordNo: TSQLMemRecordNo): TSQLMemRecordID; override;
    // lock
    procedure Lock(WriteMode: Boolean); override;
    // unlock
    procedure Unlock; override;
   public
    constructor Create(
                        aDatabaseData:  TSQLMemDatabaseData;
                        RecordsPerPage: Integer = 10;
                        AllocRecordsBy: Integer = 1000
                      );
    destructor Destroy; override;

    procedure CreateTable(
                          Cursor: TSQLMemCursor;
                          FieldDefs: TSQLMemFieldDefs;
                          IndexDefs: TSQLMemIndexDefs;
                          ConstraintDefs: TSQLMemConstraintDefs
                         ); override;
    procedure DeleteTable(Session: TSQLMemBaseSession; Cascade: Boolean; DesignMode: Boolean = False); override;
    procedure EmptyTable(Cursor: TSQLMemCursor; SkipFKCheck: Boolean = False); override;
    procedure OpenTable(Cursor: TSQLMemCursor); override;
    procedure CloseTable(Cursor: TSQLMemCursor); override;
    procedure AddIndex(IndexDef: TSQLMemIndexDef; Cursor: TSQLMemCursor); override;

    // return 0 if id1 = id2, 1 if id1>id2, -1 if id1<id2
    function CompareRecordID(const RecordID1: TSQLMemRecordID; const RecordID2: TSQLMemRecordID): Integer; override;

    function InsertRecord(var Cursor: TSQLMemCursor): Boolean; override;
    function DeleteRecord(Cursor: TSQLMemCursor): Boolean; override;
    function UpdateRecord(Cursor: TSQLMemCursor): Boolean; override;
    procedure DeleteVisibleRecords(Cursor: TSQLMemCursor); override;

    // move cursor to specified position and set current record id in cursor
    procedure InternalSetRecNo(Cursor: TSQLMemCursor; RecNo: TSQLMemRecordNo); override;
    // get current record position from cursor
    function InternalGetRecNo(Cursor: TSQLMemCursor): TSQLMemRecordNo; override;

    //---------------------------------------------------------------------------
    // BLOB methods
    //---------------------------------------------------------------------------
    function InternalCreateBlobStream(
              Cursor:   TSQLMemCursor;
              ToInsert: Boolean;
              FieldNo:  Integer;
              OpenMode: TSQLMemBLOBOpenMode
              ): TSQLMemStream; override;

    procedure WriteBLOBFieldToRecordBuffer(
              Cursor:     TSQLMemCursor;
              FieldNo:    Integer;
              BLOBStream: TSQLMemStream
              ); override;

    procedure ClearBLOBFieldInRecordBuffer(
              var RecordBuffer: TSQLMemRecordBuffer;
              FieldNo:    Integer
              ); override;

    procedure LoadTableFromStream(
                        Cursor:               TSQLMemCursor;
                        Stream:               TStream
                       ); override;
    procedure SaveTableToStream(
                        Stream:                 TStream;
                        CompressionAlgorithm:   TSQLMemCompressionAlgorithm = acaNone;
                        CompressionMode:        Byte = 0;
                        BlockSize:              Integer = 0;
                        SkipCheckIsTableOpened: Boolean = false
                      ); override;
  end; // TSQLMemTemporaryTableData


implementation


uses

// SQLMemTable units

  SQLMemLocalEngine,
  SQLMemMemEngine,
  SQLMemMemory
  ;


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemTemporaryRecordManager
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// read record
//------------------------------------------------------------------------------
function TSQLMemTemporaryRecordManager.ReadRecord(
                        var RecordBuffer: TSQLMemRecordBuffer;
                        RecordID: TSQLMemRecordNo
                       ): Boolean;
var ReadBytes:          Integer;
    OldPos,NewPos:      Int64;
    Buffer:             PAnsiChar;
    BufNo:              Integer;
begin
 Result := True;
 try
 {
aaWriteToLog('ReadRecord: RecordID = '+IntToStr(RecordID)
+#13#10+'FCachedRecordCount = '+IntToStr(FCachedRecordCount)
+#13#10+'FAllocatedRecordCount = '+IntToStr(FAllocatedRecordCount)
+#13#10+'FMaxCachedRecordCount = '+IntToStr(FMaxCachedRecordCount)
+#13#10+'FAllocRecordsBy = '+IntToStr(FAllocRecordsBy)
+#13#10+'FRecordBufferSize = '+IntToStr(FRecordBufferSize)
);
}
   if (RecordID < FCachedRecordCount) then
    begin
       BufNo := RecordID div FAllocRecordsBy;
       Buffer := FBufferList.Items[BufNo];
//aaWriteToLog('ReadRecord: Offset = '+IntToStr((RecordID mod FAllocRecordsBy) * FRecordBufferSize));
       Move((Buffer + (RecordID mod FAllocRecordsBy) * FRecordBufferSize)^,RecordBuffer^,
        FRecordBufferSize);
//aaWriteToLog('ReadRecord: OK!');
    end
   else
    begin
//aaWriteToLog('ReadRecord: read from file...');
     if (FTempPageFile = nil) then
      raise ESQLMemException.Create(12365,ErrorLNilPointer);
     OldPos := FTempPageFile.Position;
     NewPos := Int64(RecordID - FCachedRecordCount) *
               Int64(FRecordBufferSize);
     FTempPageFile.Position := NewPos;
{
aaWriteToLog('OldPos = '+IntToStr(OldPos));
aaWriteToLog('NewPos = '+IntToStr(NewPos));
aaWriteToLog('FTempPageFile.Position = '+IntToStr(FTempPageFile.Position));
aaWriteToLog('FTempPageFile.Size = '+IntToStr(FTempPageFile.Size));
}
     if (FTempPageFile.Position <> NewPos) then
      raise ESQLMemException.Create(10129,ErrorLCannotSetPosition,
        [NewPos,OldPos,FTempPageFile.Size]);
     OldPos := FTempPageFile.Position;
//aaWriteToLog('Before read');
     ReadBytes := FTempPageFile.Read(RecordBuffer^,FRecordBufferSize);
//aaWriteToLog('After read, ReadBytes = '+IntToStr(ReadBytes));
     if (ReadBytes <> FRecordBufferSize) then
      raise ESQLMemException.Create(10130,ErrorLCannotReadFromStream,
        [OldPos,FTempPageFile.Size,FRecordBufferSize,ReadBytes]);
    end;
 except
   Result := False;
 end;
//aaWriteToLog('< ReadRecord, Result = '+BoolToStr(Result,True));
end; // ReadRecord


//------------------------------------------------------------------------------
// return result for attempt of getting record relatively to first position
// and set RecordID to new record ID
//------------------------------------------------------------------------------
function TSQLMemTemporaryRecordManager.GetRecordFromFirstPosition(
        GetRecordMode: TSQLMemGetRecordMode;
        var RecordID:  TSQLMemRecordNo
                                   ): TSQLMemGetRecordResult;
begin
 Result := grrError;
 case GetRecordMode of
  grmPrior:
   begin
    Result := grrBOF;
   end;
  grmCurrent:
   begin
    Result := grrError;
   end;
  grmNext:
   begin
    RecordID := 0;
    Result := grrOK;
   end;
 end; // GetRecordMode
end; // GetRecordFromFirstPosition


//------------------------------------------------------------------------------
// return result for attempt of getting record relatively to last position
// and set RecordID to new record ID
//------------------------------------------------------------------------------
function TSQLMemTemporaryRecordManager.GetRecordFromLastPosition(
        GetRecordMode: TSQLMemGetRecordMode;
        var RecordID:  TSQLMemRecordNo
                                  ): TSQLMemGetRecordResult;
begin
 Result := grrError;
 case GetRecordMode of
  grmPrior:
   begin
    RecordID := FRecordCount-1;
    Result := grrOK;
   end;
  grmCurrent:
   begin
    Result := grrError;
   end;
  grmNext:
   begin
    Result := grrEOF;
   end;
 end; // GetRecordMode
end; // GetRecordFromLastPosition


//------------------------------------------------------------------------------
// return result for attempt of getting record relatively any position
// and set RecordID to new record ID
//------------------------------------------------------------------------------
function TSQLMemTemporaryRecordManager.GetRecordFromAnyPosition(
        GetRecordMode: TSQLMemGetRecordMode;
        var RecordID:  TSQLMemRecordNo
                                  ): TSQLMemGetRecordResult;
begin
 Result := grrError;
 case GetRecordMode of
  grmPrior:
   begin
    Result := grrBOF;
    if (RecordID > 0) then
     begin
      Dec(RecordID);
      Result := grrOK;
     end; // RecordID > 0
   end;
  grmCurrent:
   begin
    if ((RecordID >= FRecordCount) or (RecordID < 0)) then
     // current record does not exist
     Result := grrError
    else
     Result := grrOK;
   end;
  grmNext:
   begin
    Result := grrEOF;
    if (RecordID < FRecordCount-1) then
     begin
      Inc(RecordID);
      Result := grrOK;
     end;
   end;
 end; // GetRecordMode
end; // GetRecordFromAnyPosition


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TSQLMemTemporaryRecordManager.Create(
                        RecordBufferSize:     Integer;
                        RecordsPerPage:       Integer;
                        AllocRecordsBy:       Integer
                      );
begin
 if (RecordBufferSize = 0) then
  raise ESQLMemException.Create(10124,ErrorLInvalidRecordSize);
 FRecordCount := 0;
 FRecordBufferSize := RecordBufferSize;
 FRecordsPerPage := RecordsPerPage;
 if (FRecordsPerPage = 0) then
  FRecordsPerPage := 1;
 FPageSize := FRecordsPerPage * FRecordBufferSize;
 FTempPageRecordCount := 0;
 FCachedRecordCount := 0;
 FAllocRecordsBy := AllocRecordsBy;
 FTempPageFile := nil;
 FBufferList := TList.Create;
end; // Create;


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TSQLMemTemporaryRecordManager.Destroy;
begin
 Empty;
 FBufferList.Free;
 FBufferList := nil;
 inherited Destroy;
end; // Destroy


//------------------------------------------------------------------------------
// Empty
//------------------------------------------------------------------------------
procedure TSQLMemTemporaryRecordManager.Empty(SessionID: TSQLMemSessionID);
var
    FileName: AnsiString;
    i:        Integer;
    Buffer:   PAnsiChar;
begin
 FRecordCount := 0;
 FTempPageRecordCount := 0;
 FCachedRecordCount := 0;
 FAllocatedRecordCount := 0;
 for i := 0 to FBufferList.Count-1 do
  begin
    Buffer := FBufferList.Items[i];
    try
      if (SQLMem_ENCRYPTED_DB_USED) then
       FillChar(Buffer^,FAllocRecordsBy * FRecordBufferSize,$00);
    except
    end;
    try
      MemoryManager.FreeAndNilMem(Buffer);
    except
    end;
  end;
 FBufferList.Clear;
 if (FTempPageFile <> nil) then
  begin
   FileName := FTempPageFile.FileName;
   FTempPageFile.Free;
   FTempPageFile := nil;
   SysUtils.DeleteFile(FileName);
  end;
end; // Empty


//------------------------------------------------------------------------------
// return true if record exists
//------------------------------------------------------------------------------
function TSQLMemTemporaryRecordManager.IsRecordExists(var RecordID: TSQLMemRecordID; SessionID: TSQLMemSessionID): Boolean;
var RecordNo: TSQLMemRecordNo;
begin
 RecordNo := 0;
 Move(RecordID,RecordNo,sizeof(RecordID));
 // fixed in 4.96
 Result := ((FRecordCount > 0) and (RecordNo < FRecordCount) and (RecordNo >= 0));
end; // IsRecordExists


//------------------------------------------------------------------------------
// add record and return its number
//------------------------------------------------------------------------------
function TSQLMemTemporaryRecordManager.AddRecord(
                                              RecordBuffer: TSQLMemRecordBuffer;
                                              var RecordID:  TSQLMemRecordID;
                                              SessionID:     TSQLMemSessionID
                                              ): Boolean;
var SaveToTemp: Boolean;
    Buffer:     PAnsiChar;
begin
 try
   SaveToTemp := False;
   if (FCachedRecordCount >= FAllocatedRecordCount) then
    begin
     // need extending cache or writing to temporary file
{$IFDEF DEBUG_SQL_TIME}
aaIncCounter(counter14);
aaStartTime(time14);
{$ENDIF}
      try
        Buffer := MemoryManager.GetMem(FAllocRecordsBy * FRecordBufferSize);
      except
        Buffer := nil;
      end;
{$IFDEF DEBUG_SQL_TIME}
aaStopTime(time14);
{$ENDIF}
      if (Buffer <> nil) then
       begin
         Inc(FCachedRecordCount);
         FBufferList.Add(Buffer);
         Inc(FAllocatedRecordCount,FAllocRecordsBy);
{
       // create or extend cache
       if (FAllocatedRecordCount + FAllocRecordsBy <= FMaxCachedRecordCount) then
        Inc(FAllocatedRecordCount,FAllocRecordsBy)
       else
        FAllocatedRecordCount := FMaxCachedRecordCount;
aaIncCounter(counter14);
aaStartTime(time14);
       if (FCache = nil) then
        FCache := MemoryManager.GetMem(FAllocatedRecordCount * FRecordBufferSize)
       else
        MemoryManager.ReallocMem(FCache,(FAllocatedRecordCount * FRecordBufferSize));
aaStopTime(time14);
}
       end
      else
       begin
         SaveToTemp := True;
         // need writing to temporary file
         if (FTempPageFile = nil) then
          FTempPageFile := TSQLMemFileStream.Create(GetTempFileName,fmCreate);
         FTempPageFile.Position := FTempPageFile.Size;
         FTempPageFile.WriteBuffer(Recordbuffer^,FRecordBufferSize);
         Inc(FTempPageRecordCount);
       end; // save to file
    end
   else
    begin
     // no need in extending
     Inc(FCachedRecordCount);
     Buffer := FBufferList.Items[FBufferList.Count-1];
    end;
   if (not SaveToTemp) then
    Move(RecordBuffer^,(Buffer + (FRecordCount mod FAllocRecordsBy) * FRecordBufferSize)^,
         FRecordBufferSize);
   Move(FRecordCount,RecordID,sizeof(RecordID));
   Inc(FRecordCount);
   Result := True;
 except
   Result := False;
 end;
end; // AddRecord


//------------------------------------------------------------------------------
// get record
//------------------------------------------------------------------------------
procedure TSQLMemTemporaryRecordManager.GetRecordBuffer(var NavigationInfo: TSQLMemNavigationInfo);
var RecordNo: TSQLMemRecordNo;
begin
 RecordNo := 0;
 Move(NavigationInfo.RecordID,RecordNo,sizeof(NavigationInfo.RecordID));
{
aaWriteToLog('> RecordNo = '+IntToStr(RecordNo)
+#13#10+'RecordCount = '+IntToStr(FRecordCount)
+#13#10+'FirstPosition = '+BoolToStr(NavigationInfo.FirstPosition)
+#13#10+'LastPosition = '+BoolToStr(NavigationInfo.LastPosition)
+#13#10+'GetMode = '+IntToStr(Integer(NavigationInfo.GetRecordMode))
);
}
 if (FRecordCount = 0) then
  begin
   NavigationInfo.GetRecordResult := grrEOF;
   Exit;
  end;
 // get record relatively to the first position
 if (NavigationInfo.FirstPosition) then
  begin
   NavigationInfo.GetRecordResult := GetRecordFromFirstPosition(
                                        NavigationInfo.GetRecordMode,
                                        RecordNo
                                                               );
   if (NavigationInfo.GetRecordResult = grrOK) then
    NavigationInfo.FirstPosition := False;
  end
 else
 // get record relatively to the last position
 if (NavigationInfo.LastPosition) then
  begin
   NavigationInfo.GetRecordResult := GetRecordFromLastPosition(
                                        NavigationInfo.GetRecordMode,
                                        RecordNo
                                                               );
   if (NavigationInfo.GetRecordResult = grrOK) then
    NavigationInfo.LastPosition := False;
  end
 else
  NavigationInfo.GetRecordResult := GetRecordFromAnyPosition(
                                        NavigationInfo.GetRecordMode,
                                        RecordNo
                                                               );
//aaWriteToLog('1. RecordNo = '+IntToStr(RecordNo)+#13#10+'RecordCount = '+IntToStr(FRecordCount)+#13#10+'FirstPosition = '+BoolToStr(NavigationInfo.FirstPosition)+#13#10+'LastPosition = '+BoolToStr(NavigationInfo.LastPosition)+#13#10+'GetMode = '+IntToStr(Integer(NavigationInfo.GetRecordMode))+#13#10+'GetRecordResult = '+IntToStr(Integer(NavigationInfo.GetRecordResult)));
 if (NavigationInfo.GetRecordResult = grrOK) then
  begin
   NavigationInfo.GetRecordResult := grrError;
   if (ReadRecord(NavigationInfo.RecordBuffer,RecordNo)) then
    NavigationInfo.GetRecordResult := grrOK;
  end; // record retrieved successfully
 Move(RecordNo,NavigationInfo.RecordID,sizeof(NavigationInfo.RecordID));
{
aaWriteToLog('< RecordNo = '+IntToStr(RecordNo)
+#13#10+'RecordCount = '+IntToStr(FRecordCount)
+#13#10+'FirstPosition = '+BoolToStr(NavigationInfo.FirstPosition)
+#13#10+'LastPosition = '+BoolToStr(NavigationInfo.LastPosition)
+#13#10+'GetMode = '+IntToStr(Integer(NavigationInfo.GetRecordMode))
+#13#10+'GetRecordResult = '+IntToStr(Integer(NavigationInfo.GetRecordResult))
);
}
end; // GetRecordBuffer


//------------------------------------------------------------------------------
// return record no
//------------------------------------------------------------------------------
function TSQLMemTemporaryRecordManager.GetApproximateRecNo(RecordID: TSQLMemRecordID; SessionID: TSQLMemSessionID): TSQLMemRecordNo;
begin
 Result := 0;
 Move(RecordID,Result,Sizeof(RecordID));
 if (Result >= FRecordCount) then
  Result := -1
 else
  begin
   Inc(Result);
  end;
end; // GetApproximateRecNo


//------------------------------------------------------------------------------
// LoadFromStream
//------------------------------------------------------------------------------
procedure TSQLMemTemporaryRecordManager.LoadFromStream(Stream: TStream);
var Size:       Int64;
    ARCount,n:  Integer;
    Buffer:     PAnsiChar;
begin
  if (FAllocatedRecordCount > 0) then
   Empty;
  LoadDataFromStream(FRecordBufferSize,SizeOf(FRecordBufferSize),Stream,11217);
  LoadDataFromStream(FRecordCount,SizeOf(FRecordCount),Stream,11218);
  LoadDataFromStream(FRecordsPerPage,SizeOf(FRecordsPerPage),Stream,11219);
  LoadDataFromStream(FPageSize,SizeOf(FPageSize),Stream,11220);
  LoadDataFromStream(FAllocRecordsBy,SizeOf(FAllocRecordsBy),Stream,11224);

  ARCount := 0;
  while (ARCount < FRecordCount) do
   begin
    try
      Buffer := MemoryManager.GetMem(FAllocRecordsBy * FRecordBufferSize);
    except
      Buffer := nil;
    end;
    if (Buffer <> nil) then
     begin
      //
      FBufferList.Add(Buffer);
      Inc(FAllocatedRecordCount,FAllocRecordsBy);
      n := FRecordCount - ARCount;
      if (n <= FAllocRecordsBy) then
       begin
        // last records
        LoadDataFromStream(Buffer^, n * FRecordBufferSize, Stream, 11221);
        ArCount := FRecordCount;
       end
      else
       begin
        LoadDataFromStream(Buffer^, FAllocRecordsBy * FRecordBufferSize, Stream, 11222);
        Inc(ArCount,FAllocRecordsBy);
       end;
      FCachedRecordCount := ArCount; 
     end
    else
     begin
       // create temporary file
       FTempPageRecordCount := FRecordCount - ARCount;
       // need writing to temporary file
       if (FTempPageFile = nil) then
        FTempPageFile := TSQLMemFileStream.Create(GetTempFileName,fmCreate);
       FTempPageFile.LoadFromStreamWithPosition(Stream,Stream.Position,
        FTempPageRecordCount * FRecordBufferSize);
     end;
   end; // load records
end; // LoadFromStream


//------------------------------------------------------------------------------
// SaveToStream
//------------------------------------------------------------------------------
procedure TSQLMemTemporaryRecordManager.SaveToStream(Stream: TStream);
var Size:           Int64;
    i,n,ARCount:    Integer;
    Buffer:         PAnsiChar;
begin
  SaveDataToStream(FRecordBufferSize,SizeOf(FRecordBufferSize),Stream,11215);
  SaveDataToStream(FRecordCount,SizeOf(FRecordCount),Stream,11216);
  SaveDataToStream(FRecordsPerPage,SizeOf(FRecordsPerPage),Stream,11208);
  SaveDataToStream(FPageSize,SizeOf(FPageSize),Stream,11209);
  SaveDataToStream(FAllocRecordsBy,SizeOf(FAllocRecordsBy),Stream,11213);
  ARCount := 0;
  for i := 0 to FBufferList.Count - 1 do
   begin
    Buffer := FBufferList.Items[i];
    n := FRecordCount-ARCount;
    if (n <= FAllocRecordsBy) then
     begin
      SaveDataToStream(Buffer^,n * FRecordBufferSize,Stream,11210);
      ARCount := FRecordCount;
     end
    else
     begin
      SaveDataToStream(Buffer^,FAllocRecordsBy * FRecordBufferSize,Stream,11211);
      Inc(ARCount,FAllocRecordsBy);
     end;
   end;
  if (FTempPageRecordCount > 0) and (ARCount < FRecordCount) then
   begin
    FTempPageFile.Position := 0;
    FTempPageFile.SaveToStream(Stream);
   end;
end; // SaveToStream


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemTemporaryDatabaseData
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TSQLMemTemporaryDatabaseData.Create;
begin
  inherited Create;
  FTemporary := True;
  FInMemory := False;
  DatabaseName := SQLMemTemporaryDatabaseName;
end;// Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TSQLMemTemporaryDatabaseData.Destroy;
begin
{
 while (FTableDataList.Count > 0) do
  begin
    if (FTableDataList.Items[0] = nil) then
     raise ESQLMemException.Create(10379, ErrorLNilPointer);
    if (TSQLMemTableData(FTableDataList.Items[0]).CursorList.Count > 0) then
     TSQLMemTableData(FTableDataList.Items[0]).DeleteTable;
  end;
}
  inherited Destroy;
end;// Destroy


//------------------------------------------------------------------------------
// create table data
//------------------------------------------------------------------------------
function TSQLMemTemporaryDatabaseData.CreateTableData(Cursor: TSQLMemCursor): TSQLMemTableData;
var i,n:      Integer;
    bOK:      Boolean;
    nameCRC:  Cardinal;
begin
 Result := TSQLMemTemporaryTableData.Create(Self);
 Lock(True);
 try
  n := FTableDataList.Count;
  repeat
    // fixed in v.5.30
    bOK := True;
    Result.TableName := GetTemporaryName(SQLMemTemporaryTableName);
    nameCRC := GetTableNameCRC(Result.TableName,true);
    for i := 0 to n-1 do
     if (TSQLMemTemporaryTableData(FTableDataList.Items[i]).FTableNameCRC = nameCRC) then
      begin
       bOK := False;
       break;
      end;
  until (bOK);
  Cursor.TableName := Result.TableName;
  FTableDataList.Add(Result);
 finally
  Unlock;
 end;
end;// CreateTableData


//------------------------------------------------------------------------------
// ConnectSession
//------------------------------------------------------------------------------
procedure TSQLMemTemporaryDatabaseData.ConnectSession(Session: TSQLMemBaseSession);
begin
  inherited ConnectSession(Session);
  Session.SessionID := 0;
end;// ConnectSession


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemTemporaryTableData
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// GetPageManager
//------------------------------------------------------------------------------
function TSQLMemTemporaryTableData.GetPageManager: TSQLMemPageManager;
begin
  Result := FPageManager;
end;// GetPageManager


//------------------------------------------------------------------------------
// create record manager
//------------------------------------------------------------------------------
procedure TSQLMemTemporaryTableData.CreateRecordManager;
begin
 if (FRecordManager <> nil) then
  FRecordManager.Free;
 FRecordManager := TSQLMemTemporaryRecordManager.Create(GetRecordBufferSize,
  FRecordsPerPage,FAllocRecordsBy);
end; // CreateRecordManager


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
procedure TSQLMemTemporaryTableData.CreateBLOBFile;
begin
 if (FBLOBFieldsPresent) then
  begin
   DeleteBLOBFile;
// changed in v.4.80 - to fix the problem 20 October 2008
//   FBLOBFile := TSQLMemFileStream.Create(GetTempFileName,fmCreate);
   FBLOBFile := TSQLMemTemporaryStream.Create;
  end;
end;


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
procedure TSQLMemTemporaryTableData.DeleteBLOBFile;
// commented in v.4.80 - no need as it is a temporary stream now
//var FileName: AnsiString;
begin
 if (FBLOBFile <> nil) then
  begin
// commented in v.4.80 - no need as it is a temporary stream now
{
   FileName := FBLOBFile.FileName;
   if (SQLMem_ENCRYPTED_DB_USED) then
    FBLOBFile.ZeroFill;
}
   FBLOBFile.Free;
   FBLOBFile := nil;
// commented in v.4.80 - no need as it is a temporary stream now
//   SysUtils.DeleteFile(FileName);
  end;
end;


//------------------------------------------------------------------------------
// return filter bitmap rec no by record id
//------------------------------------------------------------------------------
function TSQLMemTemporaryTableData.GetBitmapRecNoByRecordID(RecordID: TSQLMemRecordID): TSQLMemRecordNo;
begin
  Result := 0;
  Move(RecordID,Result,sizeof(RecordID));
end; // GetBitmapRecNoByRecordID


//------------------------------------------------------------------------------
// return filter bitmap rec no by record id
//------------------------------------------------------------------------------
function TSQLMemTemporaryTableData.GetRecordIDByBitmapRecNo(RecordNo: TSQLMemRecordNo): TSQLMemRecordID;
begin
  Move(RecordNo,Result,sizeof(Result));
end; // GetRecordIDByBitmapRecNo


//------------------------------------------------------------------------------
// lock
//------------------------------------------------------------------------------
procedure TSQLMemTemporaryTableData.Lock(WriteMode: Boolean);
begin
// do nothing as never will ne used in multi-thread mode
end; // Lock


//------------------------------------------------------------------------------
// unlock
//------------------------------------------------------------------------------
procedure TSQLMemTemporaryTableData.Unlock;
begin
// do nothing as never will ne used in multi-thread mode
end; // Unlock


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TSQLMemTemporaryTableData.Create(
                    aDatabaseData:  TSQLMemDatabaseData;
                    RecordsPerPage: Integer;
                    AllocRecordsBy: Integer
                  );
begin
 inherited Create(aDatabaseData);
 FPageManager := TSQLMemTemporaryPageManager.Create;
 FCache := TSQLMemTableCache.Create(FPageManager,nil);
 FRecordsPerPage := RecordsPerPage;
 FAllocRecordsBy := AllocRecordsBy;
 FBLOBFile := nil;
 FInMemory := False;
 FTemporary := True;
end; // Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TSQLMemTemporaryTableData.Destroy;
//var ses: TSQLMemLocalSession;
begin
{
  ses := TSQLMemLocalSession.Create;
  try
    ses.Temporary := True;
    ses.DatabaseName := FDatabaseData.DatabaseName;
    ses.Connected := True;
    try
     DeleteTable(ses,True,False);
    except
    end;
  finally
    try
     ses.Connected := False;
    except
    end;
    ses.Free;
  end;
}
// v.5 - not needed as close table already deletes table and destroys table data
//  EmptyTable(nil);
//  DeleteAllIndexes(nil);
  FCache.ClearSharedCache;
  inherited Destroy;
  FPageManager.Free;
end; // Destroy


//------------------------------------------------------------------------------
// create table
//------------------------------------------------------------------------------
procedure TSQLMemTemporaryTableData.CreateTable(
                          Cursor: TSQLMemCursor;
                          FieldDefs: TSQLMemFieldDefs;
                          IndexDefs: TSQLMemIndexDefs;
                          ConstraintDefs: TSQLMemConstraintDefs
                                         );
begin
{$IFDEF DEBUG_TRACE_TEMPTABLE_CREATETABLE}
aaWriteToLog('> TSQLMemTemporaryTableData.CreateTable');
{$ENDIF}
 if (FieldDefs.Count <= 0) then
  raise ESQLMemException.Create(10132,ErrorLNoFields);
 TableName := Cursor.TableName;
{$IFDEF DEBUG_TRACE_TEMPTABLE_CREATETABLE}
aaWriteToLog('1 TSQLMemTemporaryTableData.CreateTable, TableName = '+TableName);
{$ENDIF}
 CheckFieldDefinitions(FieldDefs);
{$IFDEF DEBUG_TRACE_TEMPTABLE_CREATETABLE}
aaWriteToLog('2 TSQLMemTemporaryTableData.CreateTable, TableName = '+TableName);
{$ENDIF}
 CheckIndexDefinitions(IndexDefs);
{$IFDEF DEBUG_TRACE_TEMPTABLE_CREATETABLE}
aaWriteToLog('3 TSQLMemTemporaryTableData.CreateTable, TableName = '+TableName);
{$ENDIF}
 CheckConstraintDefinitions(ConstraintDefs);
{$IFDEF DEBUG_TRACE_TEMPTABLE_CREATETABLE}
aaWriteToLog('4 TSQLMemTemporaryTableData.CreateTable, TableName = '+TableName);
{$ENDIF}
 CreateFieldManager(FieldDefs);
{$IFDEF DEBUG_TRACE_TEMPTABLE_CREATETABLE}
aaWriteToLog('5 TSQLMemTemporaryTableData.CreateTable, TableName = '+TableName);
{$ENDIF}
 CreateIndexManager(IndexDefs);
{$IFDEF DEBUG_TRACE_TEMPTABLE_CREATETABLE}
aaWriteToLog('6 TSQLMemTemporaryTableData.CreateTable, TableName = '+TableName);
{$ENDIF}
 CreateConstraintManager(ConstraintDefs);
{$IFDEF DEBUG_TRACE_TEMPTABLE_CREATETABLE}
aaWriteToLog('7 TSQLMemTemporaryTableData.CreateTable, TableName = '+TableName);
{$ENDIF}
 if (FConstraintManager.ConstraintDefs.ForeignKeysExists) then
  raise ESQLMemException.Create(11426,ErrorLForeignKeysAreNotSupportedInTempTable);
{$IFDEF DEBUG_TRACE_TEMPTABLE_CREATETABLE}
aaWriteToLog('8 TSQLMemTemporaryTableData.CreateTable, TableName = '+TableName);
{$ENDIF}
 CreateRecordManager;
{$IFDEF DEBUG_TRACE_TEMPTABLE_CREATETABLE}
aaWriteToLog('9 TSQLMemTemporaryTableData.CreateTable, TableName = '+TableName);
{$ENDIF}
 InitCursor(Cursor);
{$IFDEF DEBUG_TRACE_TEMPTABLE_CREATETABLE}
aaWriteToLog('10 TSQLMemTemporaryTableData.CreateTable, TableName = '+TableName);
{$ENDIF}
 CreateBLOBFile;
 FCreationDate := Now;
{$IFDEF DEBUG_TRACE_TEMPTABLE_CREATETABLE}
aaWriteToLog('< TSQLMemTemporaryTableData.CreateTable, TableName = '+TableName);
{$ENDIF}
end;// CreateTable


//------------------------------------------------------------------------------
// delete table
//------------------------------------------------------------------------------
procedure TSQLMemTemporaryTableData.DeleteTable(Session: TSQLMemBaseSession; Cascade: Boolean; DesignMode: Boolean);
var FSessionID: TSQLMemSessionID;
begin
 try
   inherited DeleteTable(Session,Cascade,DesignMode);
   if (FIndexManager.IndexDefs.Count > 0) then
    begin
     if (Session <> nil) then
      FSessionID := Session.SessionID
     else
      raise ESQLMemException.Create(11886,ErrorLNilPointer);
//      FSessionID := SYSTEM_SESSION_ID;
     FIndexManager.DropAllIndexes(FSessionID);
    end;
   FRecordManager.Empty(FSessionID);
   DeleteBLOBFile;
   FCache.ApplyChanges(FTableState.TableState);
 except
   FCache.CancelChanges;
   raise;
 end;
 if ((not DesignMode) or (FCursorList.Count = 0)) then
   Free;
end; // DeleteTable


//------------------------------------------------------------------------------
// empty table
//------------------------------------------------------------------------------
procedure TSQLMemTemporaryTableData.EmptyTable(Cursor: TSQLMemCursor; SkipFKCheck: Boolean);
begin
 try
   DeleteBLOBFile;
   inherited EmptyTable(Cursor,SkipFKCheck);
   if (FRecordManager <> nil) then
     FRecordManager.Empty;
   FCache.ApplyChanges(FTableState.TableState);
 except
   FCache.CancelChanges;
   raise;
 end;
end; // EmptyTable


//------------------------------------------------------------------------------
// open table
//------------------------------------------------------------------------------
procedure TSQLMemTemporaryTableData.OpenTable(Cursor: TSQLMemCursor);
begin
 TableName := Cursor.TableName;
 inherited OpenTable(Cursor);
end;// OpenTable


//------------------------------------------------------------------------------
// close table
//------------------------------------------------------------------------------
procedure TSQLMemTemporaryTableData.CloseTable(Cursor: TSQLMemCursor);
begin
 inherited CloseTable(Cursor);
 if ((FCursorList.Count <= 0) and (not Cursor.CreateTableStarted)) then
  begin
   DeleteTable(Cursor.Session,True);
  end;
end;// CloseTable


//------------------------------------------------------------------------------
// add index
//------------------------------------------------------------------------------
procedure TSQLMemTemporaryTableData.AddIndex(IndexDef: TSQLMemIndexDef; Cursor: TSQLMemCursor);
begin
 Lock(true);
 try
   inherited AddIndex(IndexDef,Cursor);
   FCache.ApplyChanges(FTableState.TableState);
 finally
  Unlock;
 end;
end; // AddIndex


//------------------------------------------------------------------------------
// return 0 if id1 = id2, 1 if id1>id2, -1 if id1<id2
//------------------------------------------------------------------------------
function TSQLMemTemporaryTableData.CompareRecordID(const RecordID1: TSQLMemRecordID; const RecordID2: TSQLMemRecordID): Integer;
var id1,id2: TSQLMemRecordNo;
begin
 id1 := 0;
 id2 := 0;
 Move(RecordID1,id1,sizeof(RecordID1));
 Move(RecordID2,id2,sizeof(RecordID2));
 if (id1 = id2) then
  Result := 0
 else
 if (id1 > id2) then
  Result := 1
 else
  Result := -1;
end; // CompareRecordID


//------------------------------------------------------------------------------
// insert record
//------------------------------------------------------------------------------
function TSQLMemTemporaryTableData.InsertRecord(var Cursor: TSQLMemCursor): Boolean;
var
    RecordID:       TSQLMemRecordID;
    Pos:            Pointer;
begin
{$IFDEF DEBUG_SQL_TIME}
aaStartTime(time11);
{$ENDIF}
  if (FRecordManager = nil) then
   raise ESQLMemException.Create(10134,ErrorLNilPointer);
  if (Cursor.CurrentRecordBuffer = nil) then
   raise ESQLMemException.Create(10135,ErrorLNilPointer);
  // add record to first empty space
  Pos := Cursor.SavePosition;
  try
    try
      Result := FRecordManager.AddRecord(Cursor.CurrentRecordBuffer,RecordID);
      Move(RecordID,Cursor.CurrentRecordID,sizeof(Cursor.CurrentRecordID));
    except
      Result := False;
    end;
    if (Result) then
     begin
       if (FIndexManager.IndexDefs.Count > 0) then
        begin
         FIndexManager.InsertRecord(Cursor);
         ApplyChanges(FTableState.TableState);
        end;
       Cursor.FirstPosition := False;
       Cursor.LastPosition := False;
       if (TSQLMemRecordBitmap(Cursor.RecordBitmap).Active) then
        UpdateRecordBitmapAfterInsertRecord(Cursor,Pos);
     end;
  finally
    Cursor.FreePosition(Pos);
{$IFDEF DEBUG_SQL_TIME}
aaStopTime(time11);
{$ENDIF}
  end;
end; // InsertRecord;


//------------------------------------------------------------------------------
// delete record
//------------------------------------------------------------------------------
function TSQLMemTemporaryTableData.DeleteRecord(Cursor: TSQLMemCursor): Boolean;
begin
 Result := False;
end; // DeleteRecord


//------------------------------------------------------------------------------
// update record
//------------------------------------------------------------------------------
function TSQLMemTemporaryTableData.UpdateRecord(Cursor: TSQLMemCursor): Boolean;
begin
 Result := False;
end; // UpdateRecord


//------------------------------------------------------------------------------
// delete all visible records;
//------------------------------------------------------------------------------
procedure TSQLMemTemporaryTableData.DeleteVisibleRecords(Cursor: TSQLMemCursor);
begin
  raise ESQLMemException.Create(11301,ErrorLOperationIsNotSupported);
end; // DeleteVisibleRecords


//------------------------------------------------------------------------------
// move cursor to specified position and set current record id in cursor
//------------------------------------------------------------------------------
procedure TSQLMemTemporaryTableData.InternalSetRecNo(Cursor: TSQLMemCursor; RecNo: TSQLMemRecordNo);
var RecordID: TSQLMemRecordNo;
begin
  if (FRecordManager = nil) then
   raise ESQLMemException.Create(10136,ErrorLNilPointer);
  if (RecNo > 1) then
   RecordID := RecNo-1
  else
   RecordID := 0;
  Move(RecordID,Cursor.CurrentRecordID,sizeof(Cursor.CurrentRecordID));
end; // SetRecNo


//------------------------------------------------------------------------------
// get current record position from cursor
//------------------------------------------------------------------------------
function TSQLMemTemporaryTableData.InternalGetRecNo(Cursor: TSQLMemCursor): TSQLMemRecordNo;
begin
  if (FRecordManager = nil) then
   raise ESQLMemException.Create(10137,ErrorLNilPointer);
  Result := 0;
  Move(Cursor.CurrentRecordID,Result,sizeof(Cursor.CurrentRecordID));
  Inc(Result);
end; // GetRecNo


//---------------------------------------------------------------------------
// create BLOB stream
//---------------------------------------------------------------------------
function TSQLMemTemporaryTableData.InternalCreateBlobStream(
          Cursor:   TSQLMemCursor;
          ToInsert: Boolean;
          FieldNo:  Integer;
          OpenMode: TSQLMemBLOBOpenMode
          ): TSQLMemStream;
var TempStream:             TSQLMemTemporaryStream;
    CompressedStream:       TSQLMemCompressedBLOBStream;
    Offset:                 Integer;
    DiskOffset,OldPos:      Int64;
    ReadBytes,ReadSize:     Integer;
    BLOBDescriptor:         TSQLMemBLOBDescriptor;
    PartialBLOBDescriptor:  TSQLMemPartialTemporaryBLOBDescriptor;
{$I SQLMem_check_null_flag_var.inc}
begin
 if (FBLOBFile = nil) then
  raise ESQLMemException.Create(10140,ErrorLNilPointer);
 BLOBDescriptor.CompressionAlgorithm :=
     Byte(FieldManager.FieldDefs[FieldNo].BLOBCompressionAlgorithm);
 BLOBDescriptor.CompressionMode := FieldManager.FieldDefs[FieldNo].BLOBCompressionMode;
 BLOBDescriptor.BlockSize := FieldManager.FieldDefs[FieldNo].BLOBBlockSize;
 BLOBDescriptor.StartPosition := 0;
 TempStream := TSQLMemTemporaryStream.Create;
 // fixed in  v.5.70
 if (Cursor.CurrentRecordBuffer <> nil) then
 begin
   CHECK_NULL_FLAG_BitNo := FieldNo;
   CHECK_NULL_FLAG_NullFlags := Cursor.CurrentRecordBuffer;
   {$I SQLMem_check_null_flag.inc}
 end
 else
  CHECK_NULL_FLAG_Result := True;
 // create new compressed stream
 if ((ToInsert) or (OpenMode = bomWrite) or CHECK_NULL_FLAG_Result) then
  begin
   // empty stream
   BLOBDescriptor.NumBlocks := 0;
   BLOBDescriptor.UncompressedSize := 0;
   CompressedStream := TSQLMemCompressedBLOBStream.Create(TempStream,
    BLOBDescriptor,True);
   Result := TSQLMemLocalBLOBStream.Create(CompressedStream,Cursor,OpenMode,FieldNo);
  end // empty stream
 else
  begin
   // copy value from TableData
   Offset := FieldManager.FieldDefs[FieldNo].MemoryOffset;
   // offset to blob field data
   Move(PAnsiChar(Cursor.CurrentRecordBuffer + Offset)^,DiskOffset,Sizeof(DiskOffset));
   OldPos := FBLOBFile.Position;

   // set position in BLOB file
   FBLOBFile.Position := DiskOffset;
   if (FBLOBFile.Position <> DiskOffset) then
     raise ESQLMemException.Create(10141,ErrorLCannotSetPosition,
       [DiskOffset,OldPos,FBLOBFile.Size]);

   // read partial BLOB descriptor
   OldPos := FBLOBFile.Position;
   ReadSize := sizeof(TSQLMemPartialTemporaryBLOBDescriptor);
   ReadBytes := FBLOBFile.Read(PartialBLOBDescriptor,ReadSize);
   if (ReadBytes <> ReadSize) then
    raise ESQLMemException.Create(10142,ErrorLCannotReadFromStream,
      [OldPos,FBLOBFile.Size,ReadSize,ReadBytes]);

   // read compressed blob data
   TempStream.LoadFromStreamWithPosition(FBLOBFile,FBLOBFile.Position,
      PartialBLOBDescriptor.CompressedSize);

   // copy partial blob descriptor
   BLOBDescriptor.NumBlocks := PartialBLOBDescriptor.NumBlocks;
   BLOBDescriptor.UncompressedSize := PartialBLOBDescriptor.UncompressedSize;
   CompressedStream := TSQLMemCompressedBLOBStream.Create(TempStream,
    BLOBDescriptor,False);
   Result := TSQLMemLocalBLOBStream.Create(CompressedStream,Cursor,OpenMode,FieldNo);
  end; // copy value from TableData
end; // InternalCreateBlobStream


//---------------------------------------------------------------------------
// write BLOB field to record buffer
//---------------------------------------------------------------------------
procedure TSQLMemTemporaryTableData.WriteBLOBFieldToRecordBuffer(
          Cursor:     TSQLMemCursor;
          FieldNo:    Integer;
          BLOBStream: TSQLMemStream
          );
var
    WriteSize,WriteBytes:     Integer;
    PartialBLOBDescriptor:    TSQLMemPartialTemporaryBLOBDescriptor;
    DiskOffset:               Int64;
{$I SQLMem_set_null_flag_var.inc}
begin
 if (FBLOBFile = nil) then
  raise ESQLMemException.Create(10144,ErrorLNilPointer);
 if (BLOBStream.Modified) then
  begin
   if (BLOBStream.Size = 0) then
    begin
     // empty stream
     SET_NULL_FLAG_ToSet := True;
     SET_NULL_FLAG_BitNo := FieldNo;
     SET_NULL_FLAG_NullFlags := Cursor.CurrentRecordBuffer;
     {$I SQLMem_set_null_flag.inc}
    end
   else
    begin
     PartialBLOBDescriptor.NumBlocks := TSQLMemCompressedBLOBStream(
        TSQLMemLocalBLOBStream(BLOBStream).TemporaryStream).BLOBDescriptor.NumBlocks;
     PartialBLOBDescriptor.UncompressedSize := TSQLMemCompressedBLOBStream(
        TSQLMemLocalBLOBStream(BLOBStream).TemporaryStream).BLOBDescriptor.UncompressedSize;
     PartialBLOBDescriptor.CompressedSize := TSQLMemCompressedBLOBStream(
        TSQLMemLocalBLOBStream(BLOBStream).TemporaryStream).CompressedSize;
     SetStreamPosition(FBLOBFile,FBLOBFile.Size,10422);
     DiskOffset := FBLOBFile.Position;
     // save blob descriptor
     WriteSize := sizeof(PartialBLOBDescriptor);
     WriteBytes := FBLOBFile.Write(PartialBLOBDescriptor,WriteSize);
     if (WriteBytes <> WriteSize) then
      raise ESQLMemException.Create(10145,ErrorLCannotWriteToStream,
        [DiskOffset,FBLOBFile.Size,WriteSize,WriteBytes]);
     // save compressed data to blob file
     TSQLMemStream(TSQLMemCompressedBLOBStream(TSQLMemLocalBLOBStream(BLOBStream).TemporaryStream).
        CompressedStream).SaveToStream(FBLOBFile);
     // store offset of blob descriptor in blob file to record buffer
     Move(DiskOffset,PAnsiChar(Cursor.CurrentRecordBuffer +
      FieldManager.FieldDefs[FieldNo].MemoryOffset)^,sizeof(DiskOffset));
     SET_NULL_FLAG_ToSet := False;
     SET_NULL_FLAG_BitNo := FieldNo;
     SET_NULL_FLAG_NullFlags := Cursor.CurrentRecordBuffer;
     {$I SQLMem_set_null_flag.inc}
    end; // not empty stream
  end; // Modified
end; // WriteBLOBFieldToRecordBuffer

                             
//---------------------------------------------------------------------------
// clear BLOB field in record buffer
//---------------------------------------------------------------------------
procedure TSQLMemTemporaryTableData.ClearBLOBFieldInRecordBuffer(
          var RecordBuffer: TSQLMemRecordBuffer;
          FieldNo:    Integer
          );
begin
// do nothing by default
end; // ClearBLOBFieldInRecordBuffer


//---------------------------------------------------------------------------
// load from stream
//---------------------------------------------------------------------------
procedure TSQLMemTemporaryTableData.LoadTableFromStream(
            Cursor:               TSQLMemCursor;
            Stream:               TStream
            );
var Size: Int64;
    s:    WideString;
    i:    Integer;
begin
  repeat
   s := GetTemporaryName(SQLMemTemporaryTableName);
  until (not FDatabaseData.TableExists(Cursor.Session,s));
  FTableName := s;
  FTableNameCRC := GetTableNameCRC(FTableName);
  // load fields
  if (FFieldManager <> nil) then
   FFieldManager.Free;
  FFieldManager := TSQLMemBaseFieldManager.Create(Self,FSequenceManager);
  FFieldManager.LoadFromStream(Stream);
  FFieldManager.FieldDefs.RecalcFieldOffsets;
  FBLOBFieldsPresent := False;
  for i := 0 to FFieldManager.FieldDefs.Count - 1 do
   if (IsBLOBFieldType(FFieldManager.FieldDefs[i].BaseFieldType)) then
    begin
     FBLOBFieldsPresent := True;
     if (FFieldManager.FieldDefs[i].BLOBBlockSize = 0) then
      raise ESQLMemException.Create(11333,ErrorLZeroBlockSizeIsNotAllowedForField,[FFieldManager.FieldDefs[i].Name]);
    end;

  if (FConstraintManager <> nil) then
    FConstraintManager.Free;
  // Create ConstraintManager
  FConstraintManager := TSQLMemBaseConstraintManager.Create(Self);

  // load indexes
  if (FIndexManager <> nil) then
   FIndexManager.Free;
  FIndexManager := TSQLMemBaseIndexManager.Create(Self);
  FIndexManager.LoadFromStream(Stream);

  CreateRecordManager;
  FRecordManager.LoadFromStream(Stream);

  LoadDataFromStream(Size,SizeOf(Size),Stream,11195);
  CreateBLOBFile;
  if (Size > 0) then
   begin
    FBLOBFile.LoadFromStreamWithPosition(Stream,Stream.Position,Size);
    Stream.Position := Stream.Position + Size;
   end;
end; // LoadTableFromStream


//---------------------------------------------------------------------------
// save to stream
//---------------------------------------------------------------------------
procedure TSQLMemTemporaryTableData.SaveTableToStream(
                        Stream:                 TStream;
                        CompressionAlgorithm:   TSQLMemCompressionAlgorithm;
                        CompressionMode:        Byte;
                        BlockSize:              Integer;
                        SkipCheckIsTableOpened: Boolean
                      );
var Size: Int64;
begin
  FFieldManager.SaveToStream(Stream);
  FIndexManager.SaveToStream(Stream);
  FRecordManager.SaveToStream(Stream);
  if (FBLOBFile = nil) then
    Size := 0
  else
    Size := FBLOBFile.Size;
  SaveDataToStream(Size,SizeOf(Size),Stream,11194);
  if (Size > 0) then
    FBLOBFile.SaveToStream(Stream);
  Stream.Position := Stream.Size;  
end; // SaveTableToStream


initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('SQLMemTempEngine> initialization finished');
{$ENDIF}
  SQLMemMemoryIncUseCount;

finalization

  SQLMemMemoryDecUseCount;


end.
