unit ACRTempEngine;

{$I ACRVer.inc}

interface

uses SysUtils, Classes,

// Accuracer units

     {$IFDEF DEBUG_LOG}
     ACRDebug,
     {$ENDIF}
     ACRCriticalSection,
     ACRExcept,
     ACRBase,
     ACRPage,
     ACRBaseEngine,
     ACRCompression,
     ACRTypes,
     ACRConverts,
     ACRConst;

type
   TACRTemporaryTableData = class;


////////////////////////////////////////////////////////////////////////////////
//
// TACRTemporaryRecordManager
//
////////////////////////////////////////////////////////////////////////////////


  TACRTemporaryRecordManager = class (TACRBaseRecordManager)
   private
    FRecordsPerPage:        Integer;
    FPageSize:              Integer;
    FCachedRecordCount:     Integer;
    FAllocatedRecordCount:  Integer;
    FTempPageRecordCount:   Integer;
    FTempPageFile:          TACRFileStream;
    FAllocRecordsBy:        Integer;

    FBufferList:            TList; // list of buffer's pointers (FAllocRecordsBy records each buffer);

    function ReadRecord(
                        var RecordBuffer: TACRRecordBuffer;
                        RecordID: TACRRecordNo
                       ): Boolean;
    // return result for attempt of getting record relatively to first position
    // and set RecordID to new record ID
    function GetRecordFromFirstPosition(
            GetRecordMode: TACRGetRecordMode;
            var RecordID:  TACRRecordNo
                                       ): TACRGetRecordResult;
    // return result for attempt of getting record relatively to last position
    // and set RecordID to new record ID
    function GetRecordFromLastPosition(
            GetRecordMode: TACRGetRecordMode;
            var RecordID:  TACRRecordNo
                                      ): TACRGetRecordResult;
    // return result for attempt of getting record relatively any position
    // and set RecordID to new record ID
    function GetRecordFromAnyPosition(
            GetRecordMode: TACRGetRecordMode;
            var RecordID:  TACRRecordNo
                                      ): TACRGetRecordResult;
   public
    constructor Create(
                        RecordBufferSize:     Integer;
                        RecordsPerPage:       Integer;
                        AllocRecordsBy:       Integer
                      );
    destructor Destroy; override;

    procedure Empty(SessionID: TACRSessionID = INVALID_SESSION_ID); override;

    // return true if record exists
    function IsRecordExists(var RecordID: TACRRecordID; SessionID: TACRSessionID = INVALID_SESSION_ID): Boolean; override;
    // add record and return its number
    function AddRecord(
                       RecordBuffer:   TACRRecordBuffer;
                        var RecordID:  TACRRecordID;
                        SessionID:     TACRSessionID = INVALID_SESSION_ID
                       ): Boolean; override;
    procedure GetRecordBuffer(var NavigationInfo: TACRNavigationInfo); override;
    // return record no
    function GetApproximateRecNo(RecordID: TACRRecordID; SessionID: TACRSessionID): TACRRecordNo; override;
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
  end; // TACRTemporaryRecordManager


////////////////////////////////////////////////////////////////////////////////
//
// TACRTemporaryDatabaseData
//
////////////////////////////////////////////////////////////////////////////////


  TACRTemporaryDatabaseData = class (TACRDatabaseData)
   public
    constructor Create;
    destructor Destroy; override;
    // create table data
    function CreateTableData(Cursor: TACRCursor): TACRTableData; override;
    procedure ConnectSession(Session: TACRBaseSession); override;
  end; // TACRTemporaryDatabaseData


////////////////////////////////////////////////////////////////////////////////
//
// TACRTemporaryTableData
//
////////////////////////////////////////////////////////////////////////////////


  TACRTemporaryTableData = class (TACRTableData)
   private
// changed in v.4.80 - to fix the problem 20 October 2008
//    FBLOBFile:          TACRFileStream;
    FBLOBFile:          TACRTemporaryStream;
    FRecordsPerPage:    Integer;
    FAllocRecordsBy:    Integer;
    FPageManager:       TACRPageManager;

   protected
    function GetPageManager: TACRPageManager; override;
    procedure CreateRecordManager; override;
    procedure CreateBLOBFile;
    procedure DeleteBLOBFile;
    // return filter bitmap rec no by record id
    function GetBitmapRecNoByRecordID(RecordID: TACRRecordID): TACRRecordNo; override;
    // return filter bitmap rec no by record id
    function GetRecordIDByBitmapRecNo(RecordNo: TACRRecordNo): TACRRecordID; override;
    // lock
    procedure Lock(WriteMode: Boolean); override;
    // unlock
    procedure Unlock; override;
   public
    constructor Create(
                        aDatabaseData:  TACRDatabaseData;
                        RecordsPerPage: Integer = 10;
                        AllocRecordsBy: Integer = 1000
                      );
    destructor Destroy; override;

    procedure CreateTable(
                          Cursor: TACRCursor;
                          FieldDefs: TACRFieldDefs;
                          IndexDefs: TACRIndexDefs;
                          ConstraintDefs: TACRConstraintDefs
                         ); override;
    procedure DeleteTable(Session: TACRBaseSession; Cascade: Boolean; DesignMode: Boolean = False); override;
    procedure EmptyTable(Cursor: TACRCursor; SkipFKCheck: Boolean = False); override;
    procedure OpenTable(Cursor: TACRCursor); override;
    procedure CloseTable(Cursor: TACRCursor); override;
    procedure AddIndex(IndexDef: TACRIndexDef; Cursor: TACRCursor); override;

    // return 0 if id1 = id2, 1 if id1>id2, -1 if id1<id2
    function CompareRecordID(const RecordID1: TACRRecordID; const RecordID2: TACRRecordID): Integer; override;

    function InsertRecord(var Cursor: TACRCursor): Boolean; override;
    function DeleteRecord(Cursor: TACRCursor): Boolean; override;
    function UpdateRecord(Cursor: TACRCursor): Boolean; override;
    procedure DeleteVisibleRecords(Cursor: TACRCursor); override;

    // move cursor to specified position and set current record id in cursor
    procedure InternalSetRecNo(Cursor: TACRCursor; RecNo: TACRRecordNo); override;
    // get current record position from cursor
    function InternalGetRecNo(Cursor: TACRCursor): TACRRecordNo; override;

    //---------------------------------------------------------------------------
    // BLOB methods
    //---------------------------------------------------------------------------
    function InternalCreateBlobStream(
              Cursor:   TACRCursor;
              ToInsert: Boolean;
              FieldNo:  Integer;
              OpenMode: TACRBLOBOpenMode
              ): TACRStream; override;

    procedure WriteBLOBFieldToRecordBuffer(
              Cursor:     TACRCursor;
              FieldNo:    Integer;
              BLOBStream: TACRStream
              ); override;

    procedure ClearBLOBFieldInRecordBuffer(
              var RecordBuffer: TACRRecordBuffer;
              FieldNo:    Integer
              ); override;

    procedure LoadTableFromStream(
                        Cursor:               TACRCursor;
                        Stream:               TStream
                       ); override;
    procedure SaveTableToStream(
                        Stream:                 TStream;
                        CompressionAlgorithm:   TACRCompressionAlgorithm = acaNone;
                        CompressionMode:        Byte = 0;
                        BlockSize:              Integer = 0;
                        SkipCheckIsTableOpened: Boolean = false
                      ); override;
  end; // TACRTemporaryTableData


implementation


uses

// Accuracer units

  ACRLocalEngine,
  ACRMemEngine,
  ACRMemory
  ;


////////////////////////////////////////////////////////////////////////////////
//
// TACRTemporaryRecordManager
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// read record
//------------------------------------------------------------------------------
function TACRTemporaryRecordManager.ReadRecord(
                        var RecordBuffer: TACRRecordBuffer;
                        RecordID: TACRRecordNo
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
      raise EACRException.Create(12365,ErrorLNilPointer);
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
      raise EACRException.Create(10129,ErrorLCannotSetPosition,
        [NewPos,OldPos,FTempPageFile.Size]);
     OldPos := FTempPageFile.Position;
//aaWriteToLog('Before read');
     ReadBytes := FTempPageFile.Read(RecordBuffer^,FRecordBufferSize);
//aaWriteToLog('After read, ReadBytes = '+IntToStr(ReadBytes));
     if (ReadBytes <> FRecordBufferSize) then
      raise EACRException.Create(10130,ErrorLCannotReadFromStream,
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
function TACRTemporaryRecordManager.GetRecordFromFirstPosition(
        GetRecordMode: TACRGetRecordMode;
        var RecordID:  TACRRecordNo
                                   ): TACRGetRecordResult;
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
function TACRTemporaryRecordManager.GetRecordFromLastPosition(
        GetRecordMode: TACRGetRecordMode;
        var RecordID:  TACRRecordNo
                                  ): TACRGetRecordResult;
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
function TACRTemporaryRecordManager.GetRecordFromAnyPosition(
        GetRecordMode: TACRGetRecordMode;
        var RecordID:  TACRRecordNo
                                  ): TACRGetRecordResult;
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
constructor TACRTemporaryRecordManager.Create(
                        RecordBufferSize:     Integer;
                        RecordsPerPage:       Integer;
                        AllocRecordsBy:       Integer
                      );
begin
 if (RecordBufferSize = 0) then
  raise EACRException.Create(10124,ErrorLInvalidRecordSize);
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
destructor TACRTemporaryRecordManager.Destroy;
begin
 Empty;
 FBufferList.Free;
 FBufferList := nil;
 inherited Destroy;
end; // Destroy


//------------------------------------------------------------------------------
// Empty
//------------------------------------------------------------------------------
procedure TACRTemporaryRecordManager.Empty(SessionID: TACRSessionID);
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
      if (ACR_ENCRYPTED_DB_USED) then
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
function TACRTemporaryRecordManager.IsRecordExists(var RecordID: TACRRecordID; SessionID: TACRSessionID): Boolean;
var RecordNo: TACRRecordNo;
begin
 RecordNo := 0;
 Move(RecordID,RecordNo,sizeof(RecordID));
 // fixed in 4.96
 Result := ((FRecordCount > 0) and (RecordNo < FRecordCount) and (RecordNo >= 0));
end; // IsRecordExists


//------------------------------------------------------------------------------
// add record and return its number
//------------------------------------------------------------------------------
function TACRTemporaryRecordManager.AddRecord(
                                              RecordBuffer: TACRRecordBuffer;
                                              var RecordID:  TACRRecordID;
                                              SessionID:     TACRSessionID
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
          FTempPageFile := TACRFileStream.Create(GetTempFileName,fmCreate);
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
procedure TACRTemporaryRecordManager.GetRecordBuffer(var NavigationInfo: TACRNavigationInfo);
var RecordNo: TACRRecordNo;
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
function TACRTemporaryRecordManager.GetApproximateRecNo(RecordID: TACRRecordID; SessionID: TACRSessionID): TACRRecordNo;
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
procedure TACRTemporaryRecordManager.LoadFromStream(Stream: TStream);
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
        FTempPageFile := TACRFileStream.Create(GetTempFileName,fmCreate);
       FTempPageFile.LoadFromStreamWithPosition(Stream,Stream.Position,
        FTempPageRecordCount * FRecordBufferSize);
     end;
   end; // load records
end; // LoadFromStream


//------------------------------------------------------------------------------
// SaveToStream
//------------------------------------------------------------------------------
procedure TACRTemporaryRecordManager.SaveToStream(Stream: TStream);
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
// TACRTemporaryDatabaseData
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TACRTemporaryDatabaseData.Create;
begin
  inherited Create;
  FTemporary := True;
  FInMemory := False;
  DatabaseName := ACRTemporaryDatabaseName;
end;// Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TACRTemporaryDatabaseData.Destroy;
begin
{
 while (FTableDataList.Count > 0) do
  begin
    if (FTableDataList.Items[0] = nil) then
     raise EACRException.Create(10379, ErrorLNilPointer);
    if (TACRTableData(FTableDataList.Items[0]).CursorList.Count > 0) then
     TACRTableData(FTableDataList.Items[0]).DeleteTable;
  end;
}
  inherited Destroy;
end;// Destroy


//------------------------------------------------------------------------------
// create table data
//------------------------------------------------------------------------------
function TACRTemporaryDatabaseData.CreateTableData(Cursor: TACRCursor): TACRTableData;
var i,n:      Integer;
    bOK:      Boolean;
    nameCRC:  Cardinal;
begin
 Result := TACRTemporaryTableData.Create(Self);
 Lock(True);
 try
  n := FTableDataList.Count;
  repeat
    // fixed in v.5.30
    bOK := True;
    Result.TableName := GetTemporaryName(ACRTemporaryTableName);
    nameCRC := GetTableNameCRC(Result.TableName,true);
    for i := 0 to n-1 do
     if (TACRTemporaryTableData(FTableDataList.Items[i]).FTableNameCRC = nameCRC) then
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
procedure TACRTemporaryDatabaseData.ConnectSession(Session: TACRBaseSession);
begin
  inherited ConnectSession(Session);
  Session.SessionID := 0;
end;// ConnectSession


////////////////////////////////////////////////////////////////////////////////
//
// TACRTemporaryTableData
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// GetPageManager
//------------------------------------------------------------------------------
function TACRTemporaryTableData.GetPageManager: TACRPageManager;
begin
  Result := FPageManager;
end;// GetPageManager


//------------------------------------------------------------------------------
// create record manager
//------------------------------------------------------------------------------
procedure TACRTemporaryTableData.CreateRecordManager;
begin
 if (FRecordManager <> nil) then
  FRecordManager.Free;
 FRecordManager := TACRTemporaryRecordManager.Create(GetRecordBufferSize,
  FRecordsPerPage,FAllocRecordsBy);
end; // CreateRecordManager


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
procedure TACRTemporaryTableData.CreateBLOBFile;
begin
 if (FBLOBFieldsPresent) then
  begin
   DeleteBLOBFile;
// changed in v.4.80 - to fix the problem 20 October 2008
//   FBLOBFile := TACRFileStream.Create(GetTempFileName,fmCreate);
   FBLOBFile := TACRTemporaryStream.Create;
  end;
end;


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
procedure TACRTemporaryTableData.DeleteBLOBFile;
// commented in v.4.80 - no need as it is a temporary stream now
//var FileName: AnsiString;
begin
 if (FBLOBFile <> nil) then
  begin
// commented in v.4.80 - no need as it is a temporary stream now
{
   FileName := FBLOBFile.FileName;
   if (ACR_ENCRYPTED_DB_USED) then
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
function TACRTemporaryTableData.GetBitmapRecNoByRecordID(RecordID: TACRRecordID): TACRRecordNo;
begin
  Result := 0;
  Move(RecordID,Result,sizeof(RecordID));
end; // GetBitmapRecNoByRecordID


//------------------------------------------------------------------------------
// return filter bitmap rec no by record id
//------------------------------------------------------------------------------
function TACRTemporaryTableData.GetRecordIDByBitmapRecNo(RecordNo: TACRRecordNo): TACRRecordID;
begin
  Move(RecordNo,Result,sizeof(Result));
end; // GetRecordIDByBitmapRecNo


//------------------------------------------------------------------------------
// lock
//------------------------------------------------------------------------------
procedure TACRTemporaryTableData.Lock(WriteMode: Boolean);
begin
// do nothing as never will ne used in multi-thread mode
end; // Lock


//------------------------------------------------------------------------------
// unlock
//------------------------------------------------------------------------------
procedure TACRTemporaryTableData.Unlock;
begin
// do nothing as never will ne used in multi-thread mode
end; // Unlock


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TACRTemporaryTableData.Create(
                    aDatabaseData:  TACRDatabaseData;
                    RecordsPerPage: Integer;
                    AllocRecordsBy: Integer
                  );
begin
 inherited Create(aDatabaseData);
 FPageManager := TACRTemporaryPageManager.Create;
 FCache := TACRTableCache.Create(FPageManager,nil);
 FRecordsPerPage := RecordsPerPage;
 FAllocRecordsBy := AllocRecordsBy;
 FBLOBFile := nil;
 FInMemory := False;
 FTemporary := True;
end; // Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TACRTemporaryTableData.Destroy;
//var ses: TACRLocalSession;
begin
{
  ses := TACRLocalSession.Create;
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
procedure TACRTemporaryTableData.CreateTable(
                          Cursor: TACRCursor;
                          FieldDefs: TACRFieldDefs;
                          IndexDefs: TACRIndexDefs;
                          ConstraintDefs: TACRConstraintDefs
                                         );
begin
{$IFDEF DEBUG_TRACE_TEMPTABLE_CREATETABLE}
aaWriteToLog('> TACRTemporaryTableData.CreateTable');
{$ENDIF}
 if (FieldDefs.Count <= 0) then
  raise EACRException.Create(10132,ErrorLNoFields);
 TableName := Cursor.TableName;
{$IFDEF DEBUG_TRACE_TEMPTABLE_CREATETABLE}
aaWriteToLog('1 TACRTemporaryTableData.CreateTable, TableName = '+TableName);
{$ENDIF}
 CheckFieldDefinitions(FieldDefs);
{$IFDEF DEBUG_TRACE_TEMPTABLE_CREATETABLE}
aaWriteToLog('2 TACRTemporaryTableData.CreateTable, TableName = '+TableName);
{$ENDIF}
 CheckIndexDefinitions(IndexDefs);
{$IFDEF DEBUG_TRACE_TEMPTABLE_CREATETABLE}
aaWriteToLog('3 TACRTemporaryTableData.CreateTable, TableName = '+TableName);
{$ENDIF}
 CheckConstraintDefinitions(ConstraintDefs);
{$IFDEF DEBUG_TRACE_TEMPTABLE_CREATETABLE}
aaWriteToLog('4 TACRTemporaryTableData.CreateTable, TableName = '+TableName);
{$ENDIF}
 CreateFieldManager(FieldDefs);
{$IFDEF DEBUG_TRACE_TEMPTABLE_CREATETABLE}
aaWriteToLog('5 TACRTemporaryTableData.CreateTable, TableName = '+TableName);
{$ENDIF}
 CreateIndexManager(IndexDefs);
{$IFDEF DEBUG_TRACE_TEMPTABLE_CREATETABLE}
aaWriteToLog('6 TACRTemporaryTableData.CreateTable, TableName = '+TableName);
{$ENDIF}
 CreateConstraintManager(ConstraintDefs);
{$IFDEF DEBUG_TRACE_TEMPTABLE_CREATETABLE}
aaWriteToLog('7 TACRTemporaryTableData.CreateTable, TableName = '+TableName);
{$ENDIF}
 if (FConstraintManager.ConstraintDefs.ForeignKeysExists) then
  raise EACRException.Create(11426,ErrorLForeignKeysAreNotSupportedInTempTable);
{$IFDEF DEBUG_TRACE_TEMPTABLE_CREATETABLE}
aaWriteToLog('8 TACRTemporaryTableData.CreateTable, TableName = '+TableName);
{$ENDIF}
 CreateRecordManager;
{$IFDEF DEBUG_TRACE_TEMPTABLE_CREATETABLE}
aaWriteToLog('9 TACRTemporaryTableData.CreateTable, TableName = '+TableName);
{$ENDIF}
 InitCursor(Cursor);
{$IFDEF DEBUG_TRACE_TEMPTABLE_CREATETABLE}
aaWriteToLog('10 TACRTemporaryTableData.CreateTable, TableName = '+TableName);
{$ENDIF}
 CreateBLOBFile;
 FCreationDate := Now;
{$IFDEF DEBUG_TRACE_TEMPTABLE_CREATETABLE}
aaWriteToLog('< TACRTemporaryTableData.CreateTable, TableName = '+TableName);
{$ENDIF}
end;// CreateTable


//------------------------------------------------------------------------------
// delete table
//------------------------------------------------------------------------------
procedure TACRTemporaryTableData.DeleteTable(Session: TACRBaseSession; Cascade: Boolean; DesignMode: Boolean);
var FSessionID: TACRSessionID;
begin
 try
   inherited DeleteTable(Session,Cascade,DesignMode);
   if (FIndexManager.IndexDefs.Count > 0) then
    begin
     if (Session <> nil) then
      FSessionID := Session.SessionID
     else
      raise EACRException.Create(11886,ErrorLNilPointer);
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
procedure TACRTemporaryTableData.EmptyTable(Cursor: TACRCursor; SkipFKCheck: Boolean);
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
procedure TACRTemporaryTableData.OpenTable(Cursor: TACRCursor);
begin
 TableName := Cursor.TableName;
 inherited OpenTable(Cursor);
end;// OpenTable


//------------------------------------------------------------------------------
// close table
//------------------------------------------------------------------------------
procedure TACRTemporaryTableData.CloseTable(Cursor: TACRCursor);
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
procedure TACRTemporaryTableData.AddIndex(IndexDef: TACRIndexDef; Cursor: TACRCursor);
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
function TACRTemporaryTableData.CompareRecordID(const RecordID1: TACRRecordID; const RecordID2: TACRRecordID): Integer;
var id1,id2: TACRRecordNo;
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
function TACRTemporaryTableData.InsertRecord(var Cursor: TACRCursor): Boolean;
var
    RecordID:       TACRRecordID;
    Pos:            Pointer;
begin
{$IFDEF DEBUG_SQL_TIME}
aaStartTime(time11);
{$ENDIF}
  if (FRecordManager = nil) then
   raise EACRException.Create(10134,ErrorLNilPointer);
  if (Cursor.CurrentRecordBuffer = nil) then
   raise EACRException.Create(10135,ErrorLNilPointer);
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
       if (TACRRecordBitmap(Cursor.RecordBitmap).Active) then
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
function TACRTemporaryTableData.DeleteRecord(Cursor: TACRCursor): Boolean;
begin
 Result := False;
end; // DeleteRecord


//------------------------------------------------------------------------------
// update record
//------------------------------------------------------------------------------
function TACRTemporaryTableData.UpdateRecord(Cursor: TACRCursor): Boolean;
begin
 Result := False;
end; // UpdateRecord


//------------------------------------------------------------------------------
// delete all visible records;
//------------------------------------------------------------------------------
procedure TACRTemporaryTableData.DeleteVisibleRecords(Cursor: TACRCursor);
begin
  raise EACRException.Create(11301,ErrorLOperationIsNotSupported);
end; // DeleteVisibleRecords


//------------------------------------------------------------------------------
// move cursor to specified position and set current record id in cursor
//------------------------------------------------------------------------------
procedure TACRTemporaryTableData.InternalSetRecNo(Cursor: TACRCursor; RecNo: TACRRecordNo);
var RecordID: TACRRecordNo;
begin
  if (FRecordManager = nil) then
   raise EACRException.Create(10136,ErrorLNilPointer);
  if (RecNo > 1) then
   RecordID := RecNo-1
  else
   RecordID := 0;
  Move(RecordID,Cursor.CurrentRecordID,sizeof(Cursor.CurrentRecordID));
end; // SetRecNo


//------------------------------------------------------------------------------
// get current record position from cursor
//------------------------------------------------------------------------------
function TACRTemporaryTableData.InternalGetRecNo(Cursor: TACRCursor): TACRRecordNo;
begin
  if (FRecordManager = nil) then
   raise EACRException.Create(10137,ErrorLNilPointer);
  Result := 0;
  Move(Cursor.CurrentRecordID,Result,sizeof(Cursor.CurrentRecordID));
  Inc(Result);
end; // GetRecNo


//---------------------------------------------------------------------------
// create BLOB stream
//---------------------------------------------------------------------------
function TACRTemporaryTableData.InternalCreateBlobStream(
          Cursor:   TACRCursor;
          ToInsert: Boolean;
          FieldNo:  Integer;
          OpenMode: TACRBLOBOpenMode
          ): TACRStream;
var TempStream:             TACRTemporaryStream;
    CompressedStream:       TACRCompressedBLOBStream;
    Offset:                 Integer;
    DiskOffset,OldPos:      Int64;
    ReadBytes,ReadSize:     Integer;
    BLOBDescriptor:         TACRBLOBDescriptor;
    PartialBLOBDescriptor:  TACRPartialTemporaryBLOBDescriptor;
{$I ACR_check_null_flag_var.inc}
begin
 if (FBLOBFile = nil) then
  raise EACRException.Create(10140,ErrorLNilPointer);
 BLOBDescriptor.CompressionAlgorithm :=
     Byte(FieldManager.FieldDefs[FieldNo].BLOBCompressionAlgorithm);
 BLOBDescriptor.CompressionMode := FieldManager.FieldDefs[FieldNo].BLOBCompressionMode;
 BLOBDescriptor.BlockSize := FieldManager.FieldDefs[FieldNo].BLOBBlockSize;
 BLOBDescriptor.StartPosition := 0;
 TempStream := TACRTemporaryStream.Create;
 // fixed in  v.5.70
 if (Cursor.CurrentRecordBuffer <> nil) then
 begin
   CHECK_NULL_FLAG_BitNo := FieldNo;
   CHECK_NULL_FLAG_NullFlags := Cursor.CurrentRecordBuffer;
   {$I ACR_check_null_flag.inc}
 end
 else
  CHECK_NULL_FLAG_Result := True;
 // create new compressed stream
 if ((ToInsert) or (OpenMode = bomWrite) or CHECK_NULL_FLAG_Result) then
  begin
   // empty stream
   BLOBDescriptor.NumBlocks := 0;
   BLOBDescriptor.UncompressedSize := 0;
   CompressedStream := TACRCompressedBLOBStream.Create(TempStream,
    BLOBDescriptor,True);
   Result := TACRLocalBLOBStream.Create(CompressedStream,Cursor,OpenMode,FieldNo);
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
     raise EACRException.Create(10141,ErrorLCannotSetPosition,
       [DiskOffset,OldPos,FBLOBFile.Size]);

   // read partial BLOB descriptor
   OldPos := FBLOBFile.Position;
   ReadSize := sizeof(TACRPartialTemporaryBLOBDescriptor);
   ReadBytes := FBLOBFile.Read(PartialBLOBDescriptor,ReadSize);
   if (ReadBytes <> ReadSize) then
    raise EACRException.Create(10142,ErrorLCannotReadFromStream,
      [OldPos,FBLOBFile.Size,ReadSize,ReadBytes]);

   // read compressed blob data
   TempStream.LoadFromStreamWithPosition(FBLOBFile,FBLOBFile.Position,
      PartialBLOBDescriptor.CompressedSize);

   // copy partial blob descriptor
   BLOBDescriptor.NumBlocks := PartialBLOBDescriptor.NumBlocks;
   BLOBDescriptor.UncompressedSize := PartialBLOBDescriptor.UncompressedSize;
   CompressedStream := TACRCompressedBLOBStream.Create(TempStream,
    BLOBDescriptor,False);
   Result := TACRLocalBLOBStream.Create(CompressedStream,Cursor,OpenMode,FieldNo);
  end; // copy value from TableData
end; // InternalCreateBlobStream


//---------------------------------------------------------------------------
// write BLOB field to record buffer
//---------------------------------------------------------------------------
procedure TACRTemporaryTableData.WriteBLOBFieldToRecordBuffer(
          Cursor:     TACRCursor;
          FieldNo:    Integer;
          BLOBStream: TACRStream
          );
var
    WriteSize,WriteBytes:     Integer;
    PartialBLOBDescriptor:    TACRPartialTemporaryBLOBDescriptor;
    DiskOffset:               Int64;
{$I ACR_set_null_flag_var.inc}
begin
 if (FBLOBFile = nil) then
  raise EACRException.Create(10144,ErrorLNilPointer);
 if (BLOBStream.Modified) then
  begin
   if (BLOBStream.Size = 0) then
    begin
     // empty stream
     SET_NULL_FLAG_ToSet := True;
     SET_NULL_FLAG_BitNo := FieldNo;
     SET_NULL_FLAG_NullFlags := Cursor.CurrentRecordBuffer;
     {$I ACR_set_null_flag.inc}
    end
   else
    begin
     PartialBLOBDescriptor.NumBlocks := TACRCompressedBLOBStream(
        TACRLocalBLOBStream(BLOBStream).TemporaryStream).BLOBDescriptor.NumBlocks;
     PartialBLOBDescriptor.UncompressedSize := TACRCompressedBLOBStream(
        TACRLocalBLOBStream(BLOBStream).TemporaryStream).BLOBDescriptor.UncompressedSize;
     PartialBLOBDescriptor.CompressedSize := TACRCompressedBLOBStream(
        TACRLocalBLOBStream(BLOBStream).TemporaryStream).CompressedSize;
     SetStreamPosition(FBLOBFile,FBLOBFile.Size,10422);
     DiskOffset := FBLOBFile.Position;
     // save blob descriptor
     WriteSize := sizeof(PartialBLOBDescriptor);
     WriteBytes := FBLOBFile.Write(PartialBLOBDescriptor,WriteSize);
     if (WriteBytes <> WriteSize) then
      raise EACRException.Create(10145,ErrorLCannotWriteToStream,
        [DiskOffset,FBLOBFile.Size,WriteSize,WriteBytes]);
     // save compressed data to blob file
     TACRStream(TACRCompressedBLOBStream(TACRLocalBLOBStream(BLOBStream).TemporaryStream).
        CompressedStream).SaveToStream(FBLOBFile);
     // store offset of blob descriptor in blob file to record buffer
     Move(DiskOffset,PAnsiChar(Cursor.CurrentRecordBuffer +
      FieldManager.FieldDefs[FieldNo].MemoryOffset)^,sizeof(DiskOffset));
     SET_NULL_FLAG_ToSet := False;
     SET_NULL_FLAG_BitNo := FieldNo;
     SET_NULL_FLAG_NullFlags := Cursor.CurrentRecordBuffer;
     {$I ACR_set_null_flag.inc}
    end; // not empty stream
  end; // Modified
end; // WriteBLOBFieldToRecordBuffer

                             
//---------------------------------------------------------------------------
// clear BLOB field in record buffer
//---------------------------------------------------------------------------
procedure TACRTemporaryTableData.ClearBLOBFieldInRecordBuffer(
          var RecordBuffer: TACRRecordBuffer;
          FieldNo:    Integer
          );
begin
// do nothing by default
end; // ClearBLOBFieldInRecordBuffer


//---------------------------------------------------------------------------
// load from stream
//---------------------------------------------------------------------------
procedure TACRTemporaryTableData.LoadTableFromStream(
            Cursor:               TACRCursor;
            Stream:               TStream
            );
var Size: Int64;
    s:    WideString;
    i:    Integer;
begin
  repeat
   s := GetTemporaryName(ACRTemporaryTableName);
  until (not FDatabaseData.TableExists(Cursor.Session,s));
  FTableName := s;
  FTableNameCRC := GetTableNameCRC(FTableName);
  // load fields
  if (FFieldManager <> nil) then
   FFieldManager.Free;
  FFieldManager := TACRBaseFieldManager.Create(Self,FSequenceManager);
  FFieldManager.LoadFromStream(Stream);
  FFieldManager.FieldDefs.RecalcFieldOffsets;
  FBLOBFieldsPresent := False;
  for i := 0 to FFieldManager.FieldDefs.Count - 1 do
   if (IsBLOBFieldType(FFieldManager.FieldDefs[i].BaseFieldType)) then
    begin
     FBLOBFieldsPresent := True;
     if (FFieldManager.FieldDefs[i].BLOBBlockSize = 0) then
      raise EACRException.Create(11333,ErrorLZeroBlockSizeIsNotAllowedForField,[FFieldManager.FieldDefs[i].Name]);
    end;

  if (FConstraintManager <> nil) then
    FConstraintManager.Free;
  // Create ConstraintManager
  FConstraintManager := TACRBaseConstraintManager.Create(Self);

  // load indexes
  if (FIndexManager <> nil) then
   FIndexManager.Free;
  FIndexManager := TACRBaseIndexManager.Create(Self);
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
procedure TACRTemporaryTableData.SaveTableToStream(
                        Stream:                 TStream;
                        CompressionAlgorithm:   TACRCompressionAlgorithm;
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
aaWriteToLog('ACRTempEngine> initialization finished');
{$ENDIF}
  ACRMemoryIncUseCount;

finalization

  ACRMemoryDecUseCount;


end.
