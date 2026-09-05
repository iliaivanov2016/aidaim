unit ACRMemEngine;

{$I ACRVer.inc}

interface

uses SysUtils, Classes, Math,
{$IFDEF MSWINDOWS}
     Windows,
{$ENDIF}
{$IFDEF LINUX}
     Types,
     Libc,
{$ENDIF}

// Accuracer units

     {$IFDEF DEBUG_LOG}
     ACRDebug,
     {$ENDIF}

{$IFNDEF D6H}
     ACRD4Routines,
{$ENDIF}
     ACRCriticalSection,
     ACRExcept,
     ACRBase,
     ACRBaseEngine,
     ACRBTree,
     ACRPage,
     ACRCompression,
     ACRTypes,
     ACRExpressions,
     ACRConverts,
     ACRVariant,
     ACRConst;

type

////////////////////////////////////////////////////////////////////////////////
//
// TACRMemoryDatabaseData
//
////////////////////////////////////////////////////////////////////////////////


  TACRMemoryDatabaseData = class (TACRDatabaseData)
   private
    FLastSessionID: TACRSessionID;
    FViewDefs:      TACRViewDefs;
   protected
		procedure InternalGetTablesList(Session: TACRBaseSession;	List: TACRWideStringList); override;
   public
		function TableExists(Session: TACRBaseSession;	TableName: WideString): Boolean; override;
		function GetTablesInfo(SortByTableName: Boolean = True): TACRTableInfoArray; override;
    // create
    constructor Create;
    destructor Destroy; override;
    // create table data
    function CreateTableData(Cursor: TACRCursor): TACRTableData; override;
    procedure ConnectSession(Session: TACRBaseSession); override;
    // load local memory database
    procedure LoadDatabaseFromStream(
                        Session: TACRBaseSession;
                        Stream:  TStream
                       ); override;
    // save local memory database
    procedure SaveDatabaseToStream(
                    Session:              TACRBaseSession;
                    Stream:               TStream;
                    CompressionAlgorithm: TACRCompressionAlgorithm = acaNone;
                    CompressionMode:      Byte = 0;
                    BlockSize:            Integer = ACRDefaultSaveBlockSize
                  ); override;
    // return table comment if table exists, otherwise empty string
    function GetTableComment(TableName: WideString): WideString; override;
    // set table comment
    procedure SetTableComment(TableName, Comment: WideString); override;
    //------------------------- VIEWS - added in v.6.00 ------------------------
    // create view
    procedure CreateView(
                         Session:           TACRBaseSession;
                         ViewName:          WideString;
                         ViewDef:           TACRViewDef
                        ); override;
    // drop view
    procedure DropView(
                         Session:           TACRBaseSession;
                         ViewName:          WideString;
                         bCascade:          Boolean = True
                      ); override;
    // return nil if not found, otherwise return view definition
    function FindView(
                         Session:           TACRBaseSession;
                         ViewName:          WideString
                     ): TACRViewDef; override;
    // return true if view deleted
    function CheckDeleteTableOrView(Name: WideString; Cascade: Boolean): Boolean;
    //--------------------- END OF VIEWS - added in v.6.00 ---------------------
  end; // TACRMemoryDatabaseData


////////////////////////////////////////////////////////////////////////////////
//
// TACRMemoryRecordManager
//
////////////////////////////////////////////////////////////////////////////////

  TACRLoadingRecordsInfo = record
    pFlag:    PByte;    // pointer to last byte in FDeletedFlagBuffer
    BitNo:    Integer;  // (0 - 7) number of last bit found in pFlag
    ByteNo:   Integer;  // (0 - n) number of byte in PFlag relative to the beginning of FDeletedFlagBuffer
  end;

  TACRMemoryRecordManager = class (TACRBaseRecordManager)
   private
    LTableData:             TACRTableData;
    // record buffers
    FRecordBuffer:          PAnsiChar;
    // sequence of bits: 1 - for deleted record, 0 - for existing record
    FDeleteFlagBuffer:      PAnsiChar;
    FAllocatedRecordCount:  Integer;
    FAllocRecordsBy:        Integer;
    FFirstRecordID:         Integer;
    FLastRecordID:          Integer;
    FBitsTable:             array [0..255] of byte;
    FNoRecordsDeleted:      ByteBool;
    FLoadingRecordInfo:     TACRLoadingRecordsInfo;

   protected
    function GetBitmapSize: TACRRecordNo;
   private
    // find record id by record position
    function FindRecord(RecordNo: TACRRecordNo): TACRRecordNo;
    // returns position of the record specified by record id,
    // or INVALID_ID8 if the record with this id does not exists
    function GetTablePositionByRecordID(
              RecordNo:           TACRRecordNo
                                        ): TACRRecordNo;
    // return result for attempt of getting record relatively to first position
    // and set RecordID to new record ID
    function GetRecordFromFirstPosition(
            GetRecordMode: TACRGetRecordMode;
            var RecordID: Integer
                                       ): TACRGetRecordResult;
    // return result for attempt of getting record relatively to last position
    // and set RecordID to new record ID
    function GetRecordFromLastPosition(
            GetRecordMode: TACRGetRecordMode;
            var RecordID: Integer
                                      ): TACRGetRecordResult;
    // return result for attempt of getting record relatively any position
    // and set RecordID to new record ID
    function GetRecordFromAnyPosition(
            GetRecordMode: TACRGetRecordMode;
            var RecordID: Integer
                                      ): TACRGetRecordResult;
   protected
    procedure SetRecordCount(NewRecordCount: Integer);
   public
    constructor Create(
                        aTableData:           TACRTableData;
                        RecordBufferSize:     Integer;
                        AllocRecordsBy:       Integer
                      );
    destructor Destroy; override;

    procedure Empty(SessionID: TACRSessionID = INVALID_SESSION_ID); override;

    procedure RewriteBLOBValues(SourceRecordBuffer, DestRecordBuffer: TACRRecordBuffer);

    // add record and return its number
    function AddRecord(
                       RecordBuffer:  TACRRecordBuffer;
                       var RecordID:  TACRRecordID;
                       SessionID:     TACRSessionID = INVALID_SESSION_ID
                      ): Boolean; override;
    // update record, return true if record was updated, false if record was deleted
    function UpdateRecord(
                          RecordBuffer: TACRRecordBuffer;
                          RecordID:     TACRRecordID;
                          SessionID:    TACRSessionID = INVALID_SESSION_ID
                         ): Boolean; override;
    // delete record, return true if record was deleted, false if record was deleted earlier
    function DeleteRecord(
                          var RecordID: TACRRecordID;
                          SessionID:    TACRSessionID = INVALID_SESSION_ID
                         ): Boolean; override;
    // return true if record exists
    function IsRecordExists(var RecordID: TACRRecordID; SessionID: TACRSessionID = INVALID_SESSION_ID): Boolean; override;
    procedure GetRecordBuffer(var NavigationInfo: TACRNavigationInfo); override;
    // return record no
    function GetApproximateRecNo(RecordID: TACRRecordID; SessionID: TACRSessionID): TACRRecordNo; override;
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
    // add loaded record
    procedure AddLoadedRecord(RecordBuffer: TACRRecordBuffer; var RecordPos: Integer); override;
  end; // TACRMemoryRecordManager


////////////////////////////////////////////////////////////////////////////////
//
// TACRMemoryTableData
//
////////////////////////////////////////////////////////////////////////////////


  TACRMemoryTableData = class (TACRAdvancedTableData)
   private
    FLoadedRecordCount: Integer;
    FAllocRecordsBy:    Integer;
    FPageManager:       TACRPageManager;

   protected
    function GetPageManager: TACRPageManager; override;
    procedure CreateRecordManager; override;
    procedure CreateIndexManager(IndexDefs: TACRIndexDefs); override;
    procedure LoadTableHeader(
              Stream:             TStream;
              var BLOBDescriptor: TACRBLOBDescriptor
                              );
    procedure SaveTableHeader(
              Stream:             TStream;
              var BLOBDescriptor: TACRBLOBDescriptor
                              );
    procedure LoadBLOBDataFromStream(
            RecordBuffer: TACRRecordBuffer;
            FieldNo:      Integer;
            Stream:       TStream
                                 );
    procedure LoadRecordFromStream(
            RecordBuffer: TACRRecordBuffer;
            Stream:       TStream
                                 );
    procedure PrepareRecordBufferForSave(
            RecordBuffer:             TACRRecordBuffer;
            BLOBDescriptorList:       TList;
            BLOBDataList:             TList;
            BLOBPosition:             Int64
                                                );
    procedure SaveRecordToStream(
            RecordBuffer: TACRRecordBuffer;
            Stream:       TStream
                                 );
    procedure LoadRecordManager(Stream: TStream);
    procedure SaveRecordManager(Stream: TStream);
//    function GetBitmapSize(SessionID: TACRSessionID): TACRRecordNo; override;
    // return filter bitmap rec no by record id
    function GetBitmapRecNoByRecordID(RecordID: TACRRecordID): TACRRecordNo; override;
    // return filter bitmap rec no by record id
    function GetRecordIDByBitmapRecNo(RecordNo: TACRRecordNo): TACRRecordID; override;
    procedure InternalEmptyTable(SessionID: TACRSessionID); override;
   public
    constructor Create(
                        aDatabaseData: TACRDatabaseData;
                        AllocRecordsBy: Integer
                      );
    destructor Destroy; override;

    procedure CreateTable(
                          Cursor: TACRCursor;
                          FieldDefs: TACRFieldDefs;
                          IndexDefs: TACRIndexDefs;
                          ConstraintDefs: TACRConstraintDefs
                         ); override;
    procedure DeleteTable(Session: TACRBaseSession; Cascade: Boolean; DesignMode: Boolean = False); override;
    procedure DeleteConstraint(Cursor: TACRCursor; Name: WideString; Cascade: Boolean; FKPartialDelete: Boolean); override;
    procedure EmptyTable(Cursor: TACRCursor; SkipFKCheck: Boolean = False); override;
    procedure RenameTable(Cursor: TACRCursor; NewTableName: WideString); override;
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
    procedure OpenTable(Cursor: TACRCursor); override;
    procedure CloseTable(Cursor: TACRCursor); override;
    procedure AddIndex(IndexDef: TACRIndexDef; Cursor: TACRCursor); override;
    procedure DeleteIndex(IndexID: TACRObjectID; Cursor: TACRCursor); override;
    procedure EmptyIndex(IndexID: TACRObjectID; SessionID: TACRSessionID); override;
    procedure DeleteAllIndexes(Cursor: TACRCursor); override;
    procedure EmptyAllIndexes(SessionID: TACRSessionID); override;

    // return 0 if id1 = id2, 1 if id1>id2, -1 if id1<id2
    function CompareRecordID(const RecordID1: TACRRecordID; const RecordID2: TACRRecordID): Integer; override;
    // move cursor to specified position and set current record id in cursor
    procedure InternalSetRecNo(Cursor: TACRCursor; RecNo: TACRRecordNo); override;
    // get current record position from cursor
    function InternalGetRecNo(Cursor: TACRCursor): TACRRecordNo; override;

   public
    property SequenceManager: TACRBaseSequenceManager read FSequenceManager write FSequenceManager;
  end; // TACRMemoryTableData

  // return TableName loaded from stream
  function ACRGetSavedTableNameFromStream(Stream: TStream): WideString;

implementation

uses

// Accuracer units

  ACRLocalEngine,
  ACRStoredFunctions,
  ACRMemory       // last

  ;

////////////////////////////////////////////////////////////////////////////////
//
// TACRMemoryDatabaseData
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// get tables list
//------------------------------------------------------------------------------
procedure TACRMemoryDatabaseData.InternalGetTablesList(Session: TACRBaseSession;	List: TACRWideStringList);
var i: Integer;
begin
  inherited InternalGetTablesList(Session,List);
  for i := 0 to FViewDefs.Count - 1 do
    List.Add(FViewDefs[i].Name);
end; // InternalGetTablesList


//------------------------------------------------------------------------------
// return true if table exists
//------------------------------------------------------------------------------
function TACRMemoryDatabaseData.TableExists(Session: TACRBaseSession;	TableName: WideString): Boolean;
begin
  Result := inherited TableExists(Session,TableName);
  if (not Result) then
   Result := (FViewDefs.GetDefNumberByName(TableName) >= 0);
end; // TableExists


//------------------------------------------------------------------------------
// get all tables info - name, state, etc.
//------------------------------------------------------------------------------
function TACRMemoryDatabaseData.GetTablesInfo(SortByTableName: Boolean): TACRTableInfoArray;
var
      i,n:          Integer;
      TableData:  TACRTableData;
      ViewDef:    TACRViewDef;
begin
  Lock(False);
  try
    n := FTableDataList.Count;
    SetLength(Result, n + FViewDefs.Count);
    for i := 0 to n - 1 do
    begin
      TableData := FTableDataList.Items[i];
      Result[i].TableName := TableData.TableName;
      Result[i].Comment := TableData.Comment;
      Result[i].CreationDate := TableData.CreationDate;
      Result[i].TableState := TableData.TableState;
    end;
    for i := 0 to FViewDefs.Count - 1 do
    begin
      ViewDef := TACRViewDef(FViewDefs.Items[i]);
      Result[i+n].TableName := ViewDef.Name;
      Result[i+n].Comment := ViewDef.Comment;
      Result[i+n].CreationDate := ViewDef.CreationDate;
      Result[i+n].TableState.TableState := 0;
      Result[i+n].TableState.TableMetaDataState := 0;
      Result[i+n].TableState.TableFailureFlags := 0;
      Result[i+n].TableState.LastTableOperation := ltoCreateView;
      Result[i+n].TableState.LastModificationDate := ViewDef.CreationDate;
    end;
    if ((Length(Result)>0) and SortByTableName) then
    begin
      ACRSortTableInfo(Result, 0, High(Result));
    end;
  finally
    Unlock;
  end;
end; // GetTablesInfo


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TACRMemoryDatabaseData.Create;
begin
  inherited Create;
  FTemporary := False;
  FInMemory := True;
  FPageManager := nil;
  FLastSessionID := INVALID_SESSION_ID;
  FLockParams.Delay := ACRMemoryDelay;
  FLockParams.RetryCount := ACRMemoryRetryCount;
  // added in v.5.10
  FStoredFunctionsManager := TACRStoredFunctionManager.Create(Self);
  // added in v.6.00
  FViewDefs := TACRViewDefs.Create;
end;// Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TACRMemoryDatabaseData.Destroy;
begin
  inherited Destroy;
  FViewDefs.Free;
end; // Destroy


//------------------------------------------------------------------------------
// create table data
//------------------------------------------------------------------------------
function TACRMemoryDatabaseData.CreateTableData(Cursor: TACRCursor): TACRTableData;
begin
{$IFDEF DEBUG_TRACE_TACRMemoryDatabaseData_CreateTableData}
aaWriteToLog('> TACRMemoryDatabaseData.CreateTableData'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'DatabaseName = '+FDatabaseName
+#13#10+'TableName = '+Cursor.TableName
+#13#10+'Length(TableName) = '+IntToStr(Length(Cursor.TableName))
);
{$ENDIF}
 Result := TACRMemoryTableData.Create(Self,Cursor.MemoryTableAllocBy);
 Result.TableName := Cursor.TableName;
 AddTableData(Result);
{$IFDEF DEBUG_TRACE_TACRMemoryDatabaseData_CreateTableData}
aaWriteToLog('< TACRMemoryDatabaseData.CreateTableData'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'Result = '+IntToHex(Integer(Result),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'DatabaseName = '+FDatabaseName
+#13#10+'TableName = '+Cursor.TableName
+#13#10+'Length(TableName) = '+IntToStr(Length(Cursor.TableName))
+#13#10+'TableNameCRC = '+IntToHex(Result.TableNameCRC,8)
+#13#10+'TableDataList.Count = '+IntToStr(FTableDataList.Count)
);
{$ENDIF}
end;


//------------------------------------------------------------------------------
// ConnectSession
//------------------------------------------------------------------------------
procedure TACRMemoryDatabaseData.ConnectSession(Session: TACRBaseSession);
begin
  inherited ConnectSession(Session);
  Session.SessionID := GetCurrentThreadId;
end;// ConnectSession


//------------------------------------------------------------------------------
// load local memory database
//------------------------------------------------------------------------------
procedure TACRMemoryDatabaseData.LoadDatabaseFromStream(
                    Session: TACRBaseSession;
                    Stream: TStream
                   );
var i, n:   Integer;
    Cursor: TACRLocalCursor;
begin
  Lock(true);
  try
   Cursor := TACRLocalCursor.Create;
   try
    Cursor.SkipTableExistsCheck := True;
    Cursor.Exclusive := False;
    Cursor.ReadOnly := True;
    Cursor.InMemory := True;
    Cursor.Temporary := False;
    Cursor.Session := Session;
    try
      // load number of tables
      LoadDataFromStream(n,SizeOf(n),Stream,11760);
      for i := 0 to n - 1 do
       begin
         Cursor.LoadTableFromStream(Stream);
       end;
    except on E: Exception do
     begin
      Cursor.Session := nil;
      raise;
     end;
    end;
    // added in v.5.10
    if (Stream.Position < Stream.Size) then
     begin
      TACRStoredFunctionManager(FStoredFunctionsManager).Load(Stream);
     end;
   finally
    Cursor.Free;
   end;
  finally
    Unlock;
  end;
end; // LoadDatabaseFromStream


//------------------------------------------------------------------------------
// save local memory database
//------------------------------------------------------------------------------
procedure TACRMemoryDatabaseData.SaveDatabaseToStream(
                Session:              TACRBaseSession;
                Stream:               TStream;
                CompressionAlgorithm: TACRCompressionAlgorithm;
                CompressionMode:      Byte;
                BlockSize:            Integer
              );
var Cursor:     TACRLocalCursor;
    tablesList: TACRWideStringList;
    i:          Integer;
begin
  Lock(true);
  try
   Cursor := TACRLocalCursor.Create;
   tablesList := TACRWideStringList.Create;
   try
    Cursor.SkipTableExistsCheck := True;
    Cursor.Exclusive := False;
    Cursor.ReadOnly := True;
    Cursor.InMemory := True;
    Cursor.Temporary := False;
    InternalGetTablesList(Cursor.Session,tablesList);
    i := tablesList.Count;
    SaveDataToStream(i,SizeOf(i),Stream,11759);
    for i := 0 to tablesList.Count - 1 do
     begin
       Cursor.Session := Session;
       Cursor.TableName := tablesList.Strings[i];
       Cursor.OpenTableByFieldDefs(nil,nil,nil);
       Cursor.LockTable(False);
       try
        Cursor.InternalInitFieldDefs;
        Cursor.SaveTableToStream(Stream,
          CompressionAlgorithm,CompressionMode,BlockSize,True,True);
       finally
        Cursor.UnlockTable(False);
        Cursor.CloseTable;
       end;
     end;
    // added in v.5.10
    TACRStoredFunctionManager(FStoredFunctionsManager).Save(Stream);
   finally
    tablesList.Free;
    Cursor.Free;
   end;
  finally
    Unlock;
  end;
end; // SaveDatabaseToStream


//------------------------------------------------------------------------------
// return table comment if table exists, otherwise empty string
//------------------------------------------------------------------------------
function TACRMemoryDatabaseData.GetTableComment(TableName: WideString): WideString;
var i:          Integer;
    tableData:  TACRTableData;
    crc:        Cardinal;
begin
  Result := '';
  Lock(False);
  try
    crc := GetTableNameCRC(TableName);
    for i := 0 to FTableDataList.Count-1 do
     begin
      tableData := FTableDataList.Items[i];
      if (tableData.TableNameCRC = crc) then
       if (WideUpperCase(tableData.TableName) = WideUpperCase(TableName)) then
        begin
         Result := tableData.Comment;
         break;
        end;
     end;
  finally
    Unlock;
  end;
end; // GetTableComment


//------------------------------------------------------------------------------
// set table comment
//------------------------------------------------------------------------------
procedure TACRMemoryDatabaseData.SetTableComment(TableName, Comment: WideString);
var i:          Integer;
    tableData:  TACRTableData;
    crc:        Cardinal;
begin
  Lock(False);
  try
    crc := GetTableNameCRC(TableName);
    for i := 0 to FTableDataList.Count-1 do
     begin
      tableData := FTableDataList.Items[i];
      if (tableData.TableNameCRC = crc) then
       if (WideUpperCase(tableData.TableName) = WideUpperCase(TableName)) then
        begin
         tableData.Comment := Comment;
         break;
        end;
     end;
  finally
    Unlock;
  end;
end; // SetTableComment

//--------------------------- VIEWS - added in v.6.00 --------------------------


//------------------------------------------------------------------------------
// create view
//------------------------------------------------------------------------------
procedure TACRMemoryDatabaseData.CreateView(
                         Session:           TACRBaseSession;
                         ViewName:          WideString;
                         ViewDef:           TACRViewDef
                                          );
begin
{$IFDEF DEBUG_TRACE_TACRMemoryDatabaseData_CreateView}
aaWriteToLog('> TACRMemoryDatabaseData.CreateView. SessionID = ' + IntToStr(Session.SessionID) + ', ViewName = ' + ViewName);
try
{$ENDIF}
  if (TableExists(Session,ViewName)) then
    raise EACRException.Create(12623,ErrorLTableExists,[ViewName]);
  Lock(True);
  try
   FViewDefs.Add(ViewDef);
  finally
   Unlock;
  end;
{$IFDEF DEBUG_TRACE_TACRMemoryDatabaseData_TableExists}
aaWriteToLog('< TACRMemoryDatabaseData.CreateView. SessionID = ' + IntToStr(Session.SessionID) + ', ViewName = ' + ViewName);
except
 on e: Exception
 begin
aaWriteToLog('Error in TACRMemoryDatabaseData.CreateView. SessionID = ' + IntToStr(Session.SessionID) + ', ViewName = ' + ViewName);
  raise;
 end;
end;
{$ENDIF}
end; // CreateView


//------------------------------------------------------------------------------
// drop view
//------------------------------------------------------------------------------
procedure TACRMemoryDatabaseData.DropView(
                     Session:           TACRBaseSession;
                     ViewName:          WideString;
                     bCascade:          Boolean
                  );
var idx: Integer;
begin
{$IFDEF DEBUG_TRACE_TACRMemoryDatabaseData_DropView}
aaWriteToLog('> TACRMemoryDatabaseData.DropView. SessionID = ' + IntToStr(Session.SessionID) + ', ViewName = ' + ViewName);
try
{$ENDIF}
  if (not TableExists(Session,ViewName)) then
    raise EACRException.Create(12624,ErrorLTableExists,[ViewName]);
  Lock(True);
  try
   if (bCascade) then
   begin
    FViewDefs.DeleteChildren(ViewName);
   end
   else
    if (FViewDefs.FindChildren(ViewName)) then
     raise EACRException.Create(12625,ErrorLCannotDeleteViewOtherViewsExists,[ViewName]);
   idx := FViewDefs.GetDefNumberByName(ViewName);
   if (idx >= 0) then
    FViewDefs.Delete(idx);
  finally
   Unlock;
  end;
{$IFDEF DEBUG_TRACE_TACRMemoryDatabaseData_TableExists}
aaWriteToLog('< TACRMemoryDatabaseData.DropView. SessionID = ' + IntToStr(Session.SessionID) + ', ViewName = ' + ViewName);
except
 on e: Exception
 begin
aaWriteToLog('Error in TACRMemoryDatabaseData.DropView. SessionID = ' + IntToStr(Session.SessionID) + ', ViewName = ' + ViewName);
  raise;
 end;
end;
{$ENDIF}
end; // DropView


//------------------------------------------------------------------------------
// return nil if not found, otherwise return view definition
//------------------------------------------------------------------------------
function TACRMemoryDatabaseData.FindView(
                     Session:           TACRBaseSession;
                     ViewName:          WideString
                                  ): TACRViewDef;
var idx: Integer;
begin
{$IFDEF DEBUG_TRACE_TACRMemoryDatabaseData_CreateView}
aaWriteToLog('> TACRMemoryDatabaseData.FindView. SessionID = ' + IntToStr(Session.SessionID) + ', ViewName = ' + ViewName);
try
{$ENDIF}
  Lock(False);
  try
   idx := FViewDefs.GetDefNumberByName(ViewName);
   if (idx >= 0) then
   begin
    Result := TACRViewDef.Create;
    Result.Assign(FViewDefs.Items[idx]);
   end
   else
    Result := nil;
  finally
   Unlock;
  end;
{$IFDEF DEBUG_TRACE_TACRMemoryDatabaseData_TableExists}
aaWriteToLog('< TACRMemoryDatabaseData.FindView. SessionID = ' + IntToStr(Session.SessionID) + ', ViewName = ' + ViewName+', Result = '+BoolToStr(Result,True));
except
 on e: Exception
 begin
aaWriteToLog('Error in TACRMemoryDatabaseData.CreateView. SessionID = ' + IntToStr(Session.SessionID) + ', ViewName = ' + ViewName);
  raise;
 end;
end;
{$ENDIF}
end; // FindView


//------------------------------------------------------------------------------
// return true if view deleted
//------------------------------------------------------------------------------
function TACRMemoryDatabaseData.CheckDeleteTableOrView(Name: WideString; Cascade: Boolean): Boolean;
var idx: Integer;
begin
  Lock(True);
  try
    if (Cascade) then
      FViewDefs.DeleteChildren(Name)
    else
     if (FViewDefs.FindChildren(Name)) then
      raise EACRException.Create(12626,ErrorLCannotDeleteViewOtherViewsExists,[Name]);
    idx := FViewDefs.GetDefNumberByName(Name);
    if (idx >= 0) then
    begin
     Result := True;
     FViewDefs.Delete(idx);
    end
    else
     Result := False;
  finally
    Unlock;
  end;
end; // CheckDeleteTableOrView


//------------------------ END OF VIEWS - added in v.6.00 ----------------------




////////////////////////////////////////////////////////////////////////////////
//
// TACRMemoryRecordManager
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// return bitmap size
//------------------------------------------------------------------------------
function TACRMemoryRecordManager.GetBitmapSize: TACRRecordNo;
begin
//  Result := FAllocatedRecordCount;
  Result := FLastRecordID + 1;
end; // GetBitmapSize


//------------------------------------------------------------------------------
// find record position in buffer by record number
//------------------------------------------------------------------------------
function TACRMemoryRecordManager.FindRecord(RecordNo: TACRRecordNo): TACRRecordNo;
var i,l:        Integer;
    b,k:        Byte;
    n:          TACRRecordNo;
begin
 Result := INVALID_ID8;
 if (RecordNo < 0) or (RecordNo > FRecordCount) then
  Exit;

 if (FNoRecordsDeleted) then
  begin
   Result := RecordNo;
   Exit;
  end;

 i := 0; // byte number
 n := 0; // bits count
 while (n <= RecordNo) do
  begin
   b := PByte(FDeleteFlagBuffer + i)^;
   if (n + FBitsTable[b] > RecordNo) then
    break;
   Inc(n,FBitsTable[b]);
   Inc(i);
  end;
 Result := i * 8;
 if (Result > FAllocatedRecordCount) then
  raise EACRException.Create(10457,ErrorLInvalidBitNo,[RecordNo,FAllocatedRecordCount]);
 b := PByte(FDeleteFlagBuffer + i)^;
 l := 7;
 if (i = (FAllocatedRecordCount div 8)) then
  l := (FAllocatedRecordCount mod 8)-1;
 for k := 0 to l do
  begin
   if ((b and (1 shl k)) = 0) then Inc(n);
   if (n > RecordNo) then Break;
   Inc(Result);
  end;
end;


//------------------------------------------------------------------------------
// returns position of the record specified by record id,
// or INVALID_ID8 if the record with this id does not exists
//------------------------------------------------------------------------------
function TACRMemoryRecordManager.GetTablePositionByRecordID(
              RecordNo:            TACRRecordNo
                ): TACRRecordNo;
var n,i,j:    Integer;
    b,k:      Byte;
begin
 Result := INVALID_ID8;
 if (RecordNo >= FAllocatedRecordCount) then
  Exit;
 if (FNoRecordsDeleted) then
  begin
   Result := RecordNo+1;
   Exit;
  end;
 // number of byte with flags
 i := RecordNo div 8;
 Result := 0; // bits count
 if (i > 0) then
   for j := 0 to i-1 do
     for k := 7 downto 0 do
      begin
       b := PByte(FDeleteFlagBuffer + j)^;
       if ((b and (1 shl k)) = 0) then Inc(Result);
      end;
 // scan last byte
 b := PByte(FDeleteFlagBuffer + i)^;
 n := RecordNo mod 8;
 for k := 0 to n do
   if ((b and (1 shl k)) = 0) then Inc(Result);
end;


//------------------------------------------------------------------------------
// return result for attempt of getting record relatively to first position
//------------------------------------------------------------------------------
function TACRMemoryRecordManager.GetRecordFromFirstPosition(
            GetRecordMode: TACRGetRecordMode;
            var RecordID: Integer
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
    RecordID := FFirstRecordID;
    Result := grrOK;
   end;
 end; // GetRecordMode
end; // GetRecordFromFirstPosition


//------------------------------------------------------------------------------
// return result for attempt of getting record relatively to last position
//------------------------------------------------------------------------------
function TACRMemoryRecordManager.GetRecordFromLastPosition(
            GetRecordMode: TACRGetRecordMode;
            var RecordID: Integer
                                                          ): TACRGetRecordResult;
begin
 Result := grrError;
 case GetRecordMode of
  grmPrior:
   begin
    RecordID := FLastRecordID;
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
function TACRMemoryRecordManager.GetRecordFromAnyPosition(
            GetRecordMode:  TACRGetRecordMode;
            var RecordID:   Integer
                                      ): TACRGetRecordResult;
var
{$I ACR_check_null_flag_var.inc}
begin
 Result := grrError;
 CHECK_NULL_FLAG_NullFlags := FDeleteFlagBuffer;
 case GetRecordMode of
  grmPrior:
   begin
    Result := grrBOF;
    if (RecordID > 0) then
     begin
      Dec(RecordID);
      while (RecordID >= FFirstRecordID) do
       begin
        // record found
        CHECK_NULL_FLAG_BitNo := RecordID;
        {$I ACR_check_null_flag.inc}
        if (not CHECK_NULL_FLAG_Result) then
         begin
          Result := grrOK;
          break;
         end;
        Dec(RecordID);
       end; // scan prior record
     end; // RecordID > 0
   end;
  grmCurrent:
   begin
    if ((RecordID > FLastRecordID) or (RecordID < FFirstRecordID)) then
     // current record does not exist
     Result := grrError
    else
    begin
      CHECK_NULL_FLAG_BitNo := RecordID;
      {$I ACR_check_null_flag.inc}
      if (CHECK_NULL_FLAG_Result) then
       // current record is deleted
       Result := grrError
      else
       Result := grrOK;
    end;
   end;
  grmNext:
   begin
    Result := grrEOF;
    if (RecordID < FAllocatedRecordCount-1) then
     begin
      Inc(RecordID);
      while ((RecordID <= FLastRecordID) and (RecordID < FAllocatedRecordCount)) do
       begin
        // record found
        CHECK_NULL_FLAG_BitNo := RecordID;
        {$I ACR_check_null_flag.inc}
        if (not CHECK_NULL_FLAG_Result) then
         begin
          Result := grrOK;
          break;
         end;
        Inc(RecordID);
       end; // scan prior record
     end;
   end;
 end; // GetRecordMode
end; // GetRecordFromAnyPosition


//------------------------------------------------------------------------------
// set record count
//------------------------------------------------------------------------------
procedure TACRMemoryRecordManager.SetRecordCount(NewRecordCount: Integer);
var i: Integer;
begin
 if (NewRecordCount = 0) then
  MemoryManager.FreeAndNilMem(FRecordBuffer)
 else
 if (FAllocatedRecordCount = 0) then
   FRecordBuffer := MemoryManager.GetMem(NewRecordCount * FRecordBufferSize)
 else
   MemoryManager.ReallocMem(FRecordBuffer,NewRecordCount * FRecordBufferSize,False);
 i := (NewRecordCount div 8) + Integer((NewRecordCount mod 8) > 0);
 if (i = 0) then
  MemoryManager.FreeAndNilMem(FDeleteFlagBuffer)
 else
 if (FAllocatedRecordCount = 0) then
  FDeleteFlagBuffer := MemoryManager.GetMem(i)
 else
  MemoryManager.ReallocMem(Pointer(FDeleteFlagBuffer),i);
 FAllocatedRecordCount := NewRecordCount;
end; // SetRecordCount


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TACRMemoryRecordManager.Create(
                        aTableData:           TACRTableData;
                        RecordBufferSize:     Integer;
                        AllocRecordsBy:       Integer
                      );
var
    i,c: Byte;
begin
 if (RecordBufferSize = 0) then
  raise EACRException.Create(10011,ErrorLInvalidRecordSize);
 LTableData := aTableData;
 FRecordBuffer := nil;
 FDeleteFlagBuffer := nil;
 FRecordCount := 0;
 FAllocatedRecordCount := 0;
 FFirstRecordID := 0;
 FLastRecordID := 0;
 FRecordBufferSize := RecordBufferSize;
 FAllocRecordsBy := AllocRecordsBy;
 FNoRecordsDeleted := True;
 for i := 0 to 255 do
  begin
   c := 0;
   if ((i and 1) = 0) then Inc(c);
   if ((i and 2) = 0) then Inc(c);
   if ((i and 4) = 0) then Inc(c);
   if ((i and 8) = 0) then Inc(c);
   if ((i and 16) = 0) then Inc(c);
   if ((i and 32) = 0) then Inc(c);
   if ((i and 64) = 0) then Inc(c);
   if ((i and 128) = 0) then Inc(c);
   FBitsTable[i] := c;
  end;
end; // Create;


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TACRMemoryRecordManager.Destroy;
begin
 Empty;
 inherited Destroy;
end; // Destroy


//------------------------------------------------------------------------------
// Empty
//------------------------------------------------------------------------------
procedure TACRMemoryRecordManager.Empty(SessionID: TACRSessionID);
begin
 FAllocatedRecordCount := 0;
 FRecordCount := 0;
 if (FRecordBuffer <> nil) then
   MemoryManager.FreeAndNilMem(FRecordBuffer);
 if (FDeleteFlagBuffer <> nil) then
   MemoryManager.FreeAndNilMem(FDeleteFlagBuffer);
 FFirstRecordID := 0;
 FLastRecordID := 0;
end; // Empty


//------------------------------------------------------------------------------
// rewrite BLOB values
//------------------------------------------------------------------------------
procedure TACRMemoryRecordManager.RewriteBLOBValues(
                            SourceRecordBuffer,
                            DestRecordBuffer:   TACRRecordBuffer);
var
{$I ACR_check_null_flag_var.inc}
begin
 if (LTableData.BLOBFieldsPresent) then
  for CHECK_NULL_FLAG_BitNo := 0 to LTableData.FieldManager.FieldDefs.Count - 1 do
   if (IsBLOBFieldType(LTableData.FieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo].BaseFieldType)) then
    begin
      CHECK_NULL_FLAG_NullFlags := DestRecordBuffer;
      {$I ACR_check_null_flag.inc}
      if (not CHECK_NULL_FLAG_Result) then
       begin
        CHECK_NULL_FLAG_NullFlags := SourceRecordBuffer;
        {$I ACR_check_null_flag.inc}
         if (LTableData.IsBLOBModified(SourceRecordBuffer,
             LTableData.FieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo]) or
             CHECK_NULL_FLAG_Result) then
          begin
           LTableData.ClearBLOBFieldInRecordBuffer(DestRecordBuffer,CHECK_NULL_FLAG_BitNo);
           LTableData.SetBLOBModified(False,SourceRecordBuffer,
            LTableData.FieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo]);
          end;
       end // old value is not null
      else
       begin
         LTableData.SetBLOBModified(False,SourceRecordBuffer,
          LTableData.FieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo]);
       end; // old value is null
    end;
end; // RewriteBLOBValues


//------------------------------------------------------------------------------
// add record and return its number
//------------------------------------------------------------------------------
function TACRMemoryRecordManager.AddRecord(
                       RecordBuffer:  TACRRecordBuffer;
                       var RecordID:  TACRRecordID;
                       SessionID:     TACRSessionID = INVALID_SESSION_ID
                      ): Boolean;
var delta, i, n: Int64;
    m:           Integer;
{$I ACR_set_null_flag_var.inc}
begin
 try
   // add to the end of buffer
//   RecordID.PageNo := FRecordCount;
   if (FRecordCount = 0) then
    RecordID.PageNo := 0
   else
    RecordID.PageNo := FLastRecordID+1;
   RecordID.PageItemNo := 0;
   if (FAllocatedRecordCount <= RecordID.PageNo) then
    begin
     // changed in v.4.95
     if (FAllocRecordsBy <= 0) then
      begin
       // no insert cache
       if (FAllocatedRecordCount <= 0) then
        begin
         FRecordBuffer := MemoryManager.GetMem(FRecordBufferSize);
         FDeleteFlagBuffer := MemoryManager.GetMem(1);
         FAllocatedRecordCount := 1;
        end
       else
        begin
         FAllocatedRecordCount := (RecordID.PageNo+1);
         MemoryManager.ReallocMem(Pointer(FRecordBuffer),
          FAllocatedRecordCount * FRecordBufferSize);
         i := FAllocatedRecordCount div 8;
         if (FAllocatedRecordCount mod 8 > 0) then
          Inc(i);
         MemoryManager.ReallocMem(Pointer(FDeleteFlagBuffer),i);
        end;
      end
     else
     if (FAllocatedRecordCount = 0) then
      begin
       FAllocatedRecordCount := FAllocRecordsBy;
       i := FAllocatedRecordCount * FRecordBufferSize;
       FRecordBuffer := MemoryManager.GetMem(i);
       i := FAllocatedRecordCount div 8;
       if (FAllocatedRecordCount mod 8 > 0) then
        Inc(i);
       FDeleteFlagBuffer := MemoryManager.GetMem(i);
      end
     else
      begin
       i := FAllocatedRecordCount * FRecordBufferSize;
       n := (RecordID.PageNo+1) * FRecordBufferSize;
       delta := ACRGetReallocDelta(n);
       n := (RecordID.PageNo+1-FAllocatedRecordCount) * FRecordBufferSize;
       if (delta < n) then
         delta := n;
       FAllocatedRecordCount := FAllocatedRecordCount + delta div FRecordBufferSize;
       MemoryManager.ReallocMem(Pointer(FRecordBuffer),FAllocatedRecordCount * FRecordBufferSize);
       i := FAllocatedRecordCount div 8;
       if (FAllocatedRecordCount mod 8 > 0) then
        Inc(i);
       MemoryManager.ReallocMem(Pointer(FDeleteFlagBuffer),i);
      end;
{
     // increase record buffer size
     Inc(FAllocatedRecordCount,FAllocRecordsBy);
     i := FAllocatedRecordCount * FRecordBufferSize;
     i := FAllocatedRecordCount div 8;
     if (FAllocatedRecordCount mod 8 > 0) then
      Inc(i);
     if (OldRecordCount = 0) then
      FDeleteFlagBuffer := MemoryManager.GetMem(i)
     else
      MemoryManager.ReallocMem(Pointer(FDeleteFlagBuffer),i);
}
    end; // increase record buffer size
    Move(RecordBuffer^,PAnsiChar(FRecordBuffer + RecordID.PageNo * FRecordBufferSize)^,
          FRecordBufferSize);
    SET_NULL_FLAG_ToSet := False;
    SET_NULL_FLAG_BitNo := Integer(RecordID.PageNo);
    SET_NULL_FLAG_NullFlags := FDeleteFlagBuffer;
    {$I ACR_set_null_flag.inc}
    Inc(FRecordCount);
    if (RecordID.PageNo < FFirstRecordID) then
     FFirstRecordID := RecordID.PageNo;
    if (RecordID.PageNo > FLastRecordID) then
     FLastRecordID := RecordID.PageNo;
    Result := True;
   except
  Result := False;
 end; // try
end; // AddRecord


//------------------------------------------------------------------------------
// update record, return true if record was updated, false if record was deleted
//------------------------------------------------------------------------------
function TACRMemoryRecordManager.UpdateRecord(
                          RecordBuffer: TACRRecordBuffer;
                          RecordID:     TACRRecordID;
                          SessionID:    TACRSessionID = INVALID_SESSION_ID
                         ): Boolean;
begin
 Result := False;
 if (not ((RecordID.PageNo < FFirstRecordID) or (RecordID.PageNo > FLastRecordID))) then
  try
   RewriteBLOBValues(RecordBuffer,PAnsiChar(FRecordBuffer + RecordID.PageNo * FRecordBufferSize));
   Move(RecordBuffer^,PAnsiChar(FRecordBuffer + RecordID.PageNo * FRecordBufferSize)^,
          FRecordBufferSize);
   Result := True;
  except
   Result := False;
  end;
end; // UpdateRecord


//------------------------------------------------------------------------------
// delete record, return true if record was deleted, false if record was deleted earlier
//------------------------------------------------------------------------------
function TACRMemoryRecordManager.DeleteRecord(
                          var RecordID: TACRRecordID;
                          SessionID:    TACRSessionID = INVALID_SESSION_ID
                         ): Boolean;
var
{$I ACR_check_null_flag_var.inc}
{$I ACR_set_null_flag_var.inc}
begin
 Result := False;
 RecordID.PageItemNo := 0;
 CHECK_NULL_FLAG_BitNo := Integer(RecordID.PageNo);
 CHECK_NULL_FLAG_NullFlags := FDeleteFlagBuffer;
 {$I ACR_check_null_flag.inc}
 if (FRecordCount > 0) and
    ((RecordID.PageNo >= FFirstRecordID) and (RecordID.PageNo <= FLastRecordID)) and
    (not CHECK_NULL_FLAG_Result) then
  try
   Dec(FRecordCount);
   if (FRecordCount = 0) then
    begin
     // no records
     Empty(SessionID);
    end
   else
    begin
     // set delete flag
     SET_NULL_FLAG_ToSet := True;
     SET_NULL_FLAG_BitNo := Integer(RecordID.PageNo);
     SET_NULL_FLAG_NullFlags := FDeleteFlagBuffer;
     {$I ACR_set_null_flag.inc}
     // update first and last records ID
     if (RecordID.PageNo = FFirstRecordID) then
      GetRecordFromAnyPosition(grmNext,FFirstRecordID);
     if (RecordID.PageNo = FLastRecordID) then
      begin
       GetRecordFromAnyPosition(grmPrior,FLastRecordID);
       RecordID.PageNo := FLastRecordID;
      end;
    end;
   FNoRecordsDeleted := False;
   Result := True;
 except
  Result := False;
 end;
end; // DeleteRecord


//------------------------------------------------------------------------------
// return true if record exists
//------------------------------------------------------------------------------
function TACRMemoryRecordManager.IsRecordExists(var RecordID: TACRRecordID; SessionID: TACRSessionID): Boolean;
var
{$I ACR_check_null_flag_var.inc}
begin
  if ((FRecordCount <= 0) or (RecordID.PageNo >= FAllocatedRecordCount)) then
   Result := False
  else
  begin
   CHECK_NULL_FLAG_BitNo := Integer(RecordID.PageNo);
   CHECK_NULL_FLAG_NullFlags := FDeleteFlagBuffer;
   Result := not CHECK_NULL_FLAG_Result;
  end;
end; // IsRecordExists


//------------------------------------------------------------------------------
// get record
//------------------------------------------------------------------------------
procedure TACRMemoryRecordManager.GetRecordBuffer(var NavigationInfo: TACRNavigationInfo);
begin
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
                                      NavigationInfo.RecordID.PageNo
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
                                      NavigationInfo.RecordID.PageNo
                                                               );
   if (NavigationInfo.GetRecordResult = grrOK) then
    NavigationInfo.LastPosition := False;
  end
 else
  NavigationInfo.GetRecordResult := GetRecordFromAnyPosition(
                                      NavigationInfo.GetRecordMode,
                                      NavigationInfo.RecordID.PageNo
                                                               );
 NavigationInfo.RecordID.PageItemNo := 0;
 if (NavigationInfo.GetRecordResult = grrOK) then
  begin
   try
     Move(
          PAnsiChar(FRecordBuffer + NavigationInfo.RecordID.PageNo * FRecordBufferSize)^,
          NavigationInfo.RecordBuffer^,
          FRecordBufferSize
         );
     NavigationInfo.GetRecordResult := grrOK;
   except
    raise EACRException.Create(10019,ErrorLRetreivingRecord);
   end;
  end; // record retrieved successfully
end; // GetRecordBuffer


//------------------------------------------------------------------------------
// return record no
//------------------------------------------------------------------------------
function TACRMemoryRecordManager.GetApproximateRecNo(RecordID: TACRRecordID; SessionID: TACRSessionID): TACRRecordNo;
begin
 if (FRecordCount = 0) or (RecordID.PageNo < FFirstRecordID) or (RecordID.PageNo > FLastRecordID) then
  Result := -1
 else
 if (FRecordCount = 1) then
  Result := 1
 else
  Result :=  Round((RecordID.PageNo - FFirstRecordID) / (FRecordCount) *
                   (FLastRecordID - FFirstRecordID)) + 1;
end; // GetApproximateRecNo


//------------------------------------------------------------------------------
// Load from stream
//------------------------------------------------------------------------------
procedure TACRMemoryRecordManager.LoadFromStream(Stream: TStream);
var i: Integer;
begin
 LoadDataFromStream(i,Sizeof(i),Stream,10449);
 SetRecordCount(i);
 i := (FAllocatedRecordCount div 8) + Integer((FAllocatedRecordCount mod 8) > 0);
 LoadDataFromStream(FNoRecordsDeleted,Sizeof(FNoRecordsDeleted),Stream,10450);
 LoadDataFromStream(FFirstRecordID,Sizeof(FFirstRecordID),Stream,10451);
 LoadDataFromStream(FLastRecordID,Sizeof(FLastRecordID),Stream,10452);
 if (FAllocatedRecordCount > 0) then
   LoadDataFromStream(FDeleteFlagBuffer^,i,Stream,10453);
end; // LoadFromStream


//------------------------------------------------------------------------------
// Save from stream
//------------------------------------------------------------------------------
procedure TACRMemoryRecordManager.SaveToStream(Stream: TStream);
var i: Integer;
begin
 i := (FAllocatedRecordCount div 8) + Integer((FAllocatedRecordCount mod 8) > 0);
 SaveDataToStream(FAllocatedRecordCount,Sizeof(FAllocatedRecordCount),Stream,10444);
 SaveDataToStream(FNoRecordsDeleted,Sizeof(FNoRecordsDeleted),Stream,10445);
 SaveDataToStream(FFirstRecordID,Sizeof(FFirstRecordID),Stream,10446);
 SaveDataToStream(FLastRecordID,Sizeof(FLastRecordID),Stream,10447);
 if (FAllocatedRecordCount > 0) then
  SaveDataToStream(FDeleteFlagBuffer^,i,Stream,10448);
end; // SaveToStream


//------------------------------------------------------------------------------
// add loaded record
//------------------------------------------------------------------------------
procedure TACRMemoryRecordManager.AddLoadedRecord(RecordBuffer: TACRRecordBuffer; var RecordPos: Integer);

 procedure GoToNextBit;
 begin
   Inc(RecordPos);
   if (not FNoRecordsDeleted) then
     if (FLoadingRecordInfo.BitNo < 7) then
      Inc(FLoadingRecordInfo.BitNo)
     else
      begin
       FLoadingRecordInfo.BitNo := 0;
       Inc(FLoadingRecordInfo.ByteNo);
       Inc(FLoadingRecordInfo.pFlag);
       if (FLoadingRecordInfo.ByteNo > (FAllocatedRecordCount div 8)) then
         raise EACRException.Create(10454,ErrorLInvalidRecordNo,[FLoadingRecordInfo.ByteNo]);
      end;
   if (RecordPos >= FAllocatedRecordCount) then
     raise EACRException.Create(10847,ErrorLInvalidRecordNo,[FAllocatedRecordCount]);
 end;

 procedure SearchForNextRecord;
 var bOK: Boolean;
 begin
  repeat
   bOK := (((FLoadingRecordInfo.pFlag^ shr FLoadingRecordInfo.BitNo) and $01) = 0);
   if (not bOK) then
    GoToNextBit;
  until (bOK);
 end; // SearchForNextRecord

begin
 Inc(FRecordCount);

 if (RecordPos = INVALID_ID4) then
  begin
    if (FNoRecordsDeleted) then
     RecordPos := 0
    else
     begin
        // init FLoadingRecordsInfo
        FLoadingRecordInfo.pFlag := PByte(FDeleteFlagBuffer);
        FLoadingRecordInfo.BitNo := 0;
        FLoadingRecordInfo.ByteNo := 0;
        RecordPos := 0;
     end;
  end
 else
  GoToNextBit;
 if (not FNoRecordsDeleted) then
   SearchForNextRecord;

 Move(RecordBuffer^,PAnsiChar(FRecordBuffer + RecordPos * FRecordBufferSize)^,FRecordBufferSize);
end; // AddLoadedRecord


////////////////////////////////////////////////////////////////////////////////
//
// TACRMemoryTableData
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// GetPageManager
//------------------------------------------------------------------------------
function TACRMemoryTableData.GetPageManager: TACRPageManager;
begin
  Result := FPageManager;
end;// GetPageManager


//------------------------------------------------------------------------------
// create RecordManager
//------------------------------------------------------------------------------
procedure TACRMemoryTableData.CreateRecordManager;
begin
 if (FRecordManager <> nil) then
  FRecordManager.Free;
 FRecordManager := TACRMemoryRecordManager.Create(
                      Self,
                      GetRecordBufferSize,
                      FAllocRecordsBy
                                                 );
end;// CreateRecordManager


//------------------------------------------------------------------------------
// create index manager
//------------------------------------------------------------------------------
procedure TACRMemoryTableData.CreateIndexManager(IndexDefs: TACRIndexDefs);
begin
 if (FIndexManager <> nil) then
  FIndexManager.Free;
 FillDefsByObjectId(IndexDefs);
 FIndexManager := TACRBaseIndexManager.Create(Self);
 FIndexManager.CreateIndexDefs(IndexDefs);
end;// CreateIndexManager


//------------------------------------------------------------------------------
// load table header
//------------------------------------------------------------------------------
procedure TACRMemoryTableData.LoadTableHeader(
              Stream:             TStream;
              var BLOBDescriptor: TACRBLOBDescriptor
                                             );
var FileHeader: TACRMemoryTableFileHeader;
    DatabaseID: TACRSequenceValue;
begin
  LoadDataFromStream(FileHeader,sizeof(FileHeader),Stream,10160);
  if (FileHeader.Signature <> ACRSignature) then
    raise EACRException.Create(10161,ErrorLInvalidSignature,
      [FileHeader.Signature,ACRSignature]);
  if (FileHeader.Version > ACRVersion + 0.0001) then
    raise EACRException.Create(10162,ErrorLInvalidVersion,
      [FileHeader.Version,ACRVersion]);
  if (FileHeader.Version < 1.0001) then
    raise EACRException.Create(10443,ErrorLInvalidVersion,
      [FileHeader.Version,ACRVersion]);
  if (FileHeader.Version < 1.010001) then
    raise EACRException.Create(10454,ErrorLInvalidVersion,
      [FileHeader.Version,ACRVersion]);
  if (FileHeader.Version < 1.020001) then
    raise EACRException.Create(10455,ErrorLInvalidVersion,
      [FileHeader.Version,ACRVersion]);
//SetLength(FTableName,FileHeader.NameLength);
//if (FileHeader.NameLength > 0) then
// LoadDataFromStream(PAnsiChar(@FTableName[1])^,FileHeader.NameLength,Stream,10163);
  LoadWideStringFromStream(FTableName,Stream,10163);
  if (FileHeader.Version >= 5) then
   begin
    LoadDataFromStream(FCreationDate,SizeOf(FCreationDate),Stream,11980);
    LoadDataFromStream(FTableState,SizeOf(FTableState),Stream,11981);
    LoadWideStringFromStream(FComment,Stream,11963);
   end
  else
    FComment := '';
  FTableNameCRC := GetTableNameCRC(FTableName);
  LoadDataFromStream(DatabaseID,sizeof(DatabaseID),Stream,10417);
  if (FDatabaseData.ObjectIdSequence.LastValue < DatabaseID) then
    FDatabaseData.ObjectIdSequence.LastValue := DatabaseID;
  BLOBDescriptor.StartPosition := Stream.Position;
  BLOBDescriptor.BlockSize := FileHeader.BlockSize;
  BLOBDescriptor.NumBlocks := FileHeader.NumBlocks;
  BLOBDescriptor.UncompressedSize := FileHeader.UncompressedSize;
  BLOBDescriptor.CompressionAlgorithm := FileHeader.CompressionAlgorithm;
  BLOBDescriptor.CompressionMode := FileHeader.CompressionMode;
  FLoadedRecordCount := FileHeader.RecordCount;
end; // LoadTableHeader


//------------------------------------------------------------------------------
// save table header
//------------------------------------------------------------------------------
procedure TACRMemoryTableData.SaveTableHeader(
              Stream:             TStream;
              var BLOBDescriptor: TACRBLOBDescriptor
              );
var FileHeader: TACRMemoryTableFileHeader;
    DatabaseID: TACRSequenceValue;
begin
  FileHeader.Signature := ACRSignature;
  FileHeader.Version := ACRVersion;
  FileHeader.RecordCount := FRecordManager.GetRecordCount;
  FileHeader.UncompressedSize := BLOBDescriptor.UncompressedSize;
  FileHeader.NumBlocks := BLOBDescriptor.NumBlocks;
  FileHeader.BlockSize := BLOBDescriptor.BlockSize;
  FileHeader.CompressionAlgorithm := BLOBDescriptor.CompressionAlgorithm;
  FileHeader.CompressionMode := BLOBDescriptor.CompressionMode;
//FileHeader.NameLength := Length(FTableName);
  SaveDataToStream(FileHeader,sizeof(FileHeader),Stream,10156);
//  SaveDataToStream(PAnsiChar(@FTableName[1])^,FileHeader.NameLength,Stream,10157);
  SaveWideStringToStream(FTableName,Stream,10157);
  SaveDataToStream(FCreationDate,SizeOf(FCreationDate),Stream,11982);
  SaveDataToStream(FTableState,SizeOf(FTableState),Stream,11983);
  SaveWideStringToStream(FComment,Stream,11962);
  DatabaseID := FDatabaseData.ObjectIdSequence.LastValue;
  SaveDataToStream(DatabaseID,sizeof(DatabaseID),Stream,10416);
end; // SaveTableHeader


//------------------------------------------------------------------------------
// load blob data
//------------------------------------------------------------------------------
procedure TACRMemoryTableData.LoadBLOBDataFromStream(
        RecordBuffer: TACRRecordBuffer;
        FieldNo:      Integer;
        Stream:       TStream
                             );
var Buffer:                 PAnsiChar;
    FBLOBPosition:          Int64;
    Offset,Offset2:         Integer;
    BLOBPartialDescriptor:  TACRPartialTemporaryBLOBDescriptor;
begin
  Offset := FFieldManager.FieldDefs[FieldNo].MemoryOffset;
  Move(PAnsiChar(RecordBuffer + Offset)^,FBLOBPosition,sizeof(FBLOBPosition));
  // load disk blob descriptor
  SetStreamPosition(Stream,FBLOBPosition,10202);
  LoadDataFromStream(BLOBPartialDescriptor,sizeof(BLOBPartialDescriptor),
    Stream,10203);
  Offset2 := sizeof(TACRPartialBLOBDescriptor);
  Buffer := MemoryManager.GetMem(BLOBPartialDescriptor.CompressedSize + Offset2);
  PACRPartialBLOBDescriptor(Buffer)^.NumBlocks :=
    BLOBPartialDescriptor.NumBlocks;
  PACRPartialBLOBDescriptor(Buffer)^.UncompressedSize :=
    BLOBPartialDescriptor.UncompressedSize;
  // load compresse blob data
  LoadDataFromStream(PAnsiChar(Buffer + Offset2)^,
    BLOBPartialDescriptor.CompressedSize,Stream,10204);
  Move(Buffer,PAnsiChar(RecordBuffer + Offset)^,sizeof(Buffer));
end; // LoadBLOBDataFromStream


//------------------------------------------------------------------------------
// load record
//------------------------------------------------------------------------------
procedure TACRMemoryTableData.LoadRecordFromStream(
            RecordBuffer: TACRRecordBuffer;
            Stream:       TStream
                                                  );
var
{$I ACR_check_null_flag_var.inc}
begin
  LoadDataFromStream(RecordBuffer^,GetRecordBufferSize,Stream,10201);
  if (FBLOBFieldsPresent) then
   begin
     CHECK_NULL_FLAG_NullFlags := RecordBuffer;
     for CHECK_NULL_FLAG_BitNo := 0 to FFieldManager.FieldDefs.Count - 1 do
      if (IsBLOBFieldType(FFieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo].BaseFieldType)) then
      begin
        {$I ACR_check_null_flag.inc}
        if (not CHECK_NULL_FLAG_Result) then
          // load blob
          LoadBLOBDataFromStream(RecordBuffer,CHECK_NULL_FLAG_BitNo,Stream);
      end;
   end;
end; // LoadRecord


//------------------------------------------------------------------------------
// prepare record buffer for save
//------------------------------------------------------------------------------
procedure TACRMemoryTableData.PrepareRecordBufferForSave(
            RecordBuffer:             TACRRecordBuffer;
            BLOBDescriptorList:       TList;
            BLOBDataList:             TList;
            BLOBPosition:             Int64
                                                );
var FBLOBPosition:            Int64;
    BLOBDataSize:             Integer;
    Offset:                   Integer;
    Buffer:                   PAnsiChar;
    PBLOBPartialDescriptor:   PACRPartialTemporaryBLOBDescriptor;
{$I ACR_check_null_flag_var.inc}
begin
 FBLOBPosition := BLOBPosition;
 CHECK_NULL_FLAG_NullFlags := RecordBuffer;
 for CHECK_NULL_FLAG_BitNo := 0 to FFieldManager.FieldDefs.Count - 1 do
  if (IsBLOBFieldType(FFieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo].BaseFieldType)) then
  begin
    {$I ACR_check_null_flag.inc}
    if (not CHECK_NULL_FLAG_Result) then
     begin
      // save blob field data
      Offset := FFieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo].MemoryOffset;
      Move(PAnsiChar(RecordBuffer + Offset)^,Buffer,Sizeof(Buffer));
      if (Buffer = nil) then
        raise EACRException.Create(10196,ErrorLNilPointer);
      // calculate size of blob data
      BLOBDataSize := MemoryManager.GetMemoryBufferSize(Buffer) -
        sizeof(TACRPartialBLOBDescriptor) +
        sizeof(TACRPartialTemporaryBLOBDescriptor);
      PBLOBPartialDescriptor :=
        MemoryManager.GetMem(sizeof(TACRPartialTemporaryBLOBDescriptor));
      PBLOBPartialDescriptor^.NumBlocks :=
        PACRPartialBLOBDescriptor(Buffer)^.NumBlocks;
      PBLOBPartialDescriptor^.UncompressedSize :=
        PACRPartialBLOBDescriptor(Buffer)^.UncompressedSize;
      PBLOBPartialDescriptor^.CompressedSize := BLOBDataSize -
        sizeof(TACRPartialTemporaryBLOBDescriptor);
      BLOBDataList.Add(Buffer);
      BLOBDescriptorList.Add(PBLOBPartialDescriptor);
      // store offset to blob data instead of pointer to memory buffer
      Move(FBLOBPosition,PAnsiChar(RecordBuffer + Offset)^,Sizeof(FBLOBPosition));
      Inc(FBLOBPosition,BLOBDataSize);
     end; // not null blob field
  end;
end; // PrepareRecordBufferForSave


//------------------------------------------------------------------------------
// save record
//------------------------------------------------------------------------------
procedure TACRMemoryTableData.SaveRecordToStream(
            RecordBuffer: TACRRecordBuffer;
            Stream:       TStream
                                                );
var i:                        Integer;
    BLOBDataSize:             Integer;
    Buffer:                   PAnsiChar;
    PBLOBPartialDescriptor:   PACRPartialTemporaryBLOBDescriptor;
    BLOBDescriptorList:       TList;
    BLOBDataList:             TList;
begin
 if (FBLOBFieldsPresent) then
  begin
   BLOBDescriptorList := TList.Create;
   BLOBDataList := TList.Create;
   try
     PrepareRecordBufferForSave(RecordBuffer,BLOBDescriptorList,
        BLOBDataList,Int64(Stream.Position + Int64(GetRecordBufferSize)));
     SaveDataToStream(RecordBuffer^,GetRecordBufferSize,Stream,10197);
     // save blob fields
     for i := 0 to BLOBDataList.Count - 1 do
      begin
       PBLOBPartialDescriptor := BLOBDescriptorList.Items[i];
       SaveDataToStream(PBLOBPartialDescriptor^,
        sizeof(TACRPartialTemporaryBLOBDescriptor),Stream,10198);
       Buffer := BLOBDataList.Items[i];
       BLOBDataSize := PBLOBPartialDescriptor^.CompressedSize;
       SaveDataToStream(PAnsiChar(Buffer + sizeof(TACRPartialBLOBDescriptor))^,BLOBDataSize,Stream,10199);
       MemoryManager.FreeAndNilMem(PBLOBPartialDescriptor);
      end; // not null blob field
   finally
    BLOBDescriptorList.Free;
    BLOBDataList.Free;
   end;
  end // blob fields
 else
  // no blob fields
  SaveDataToStream(RecordBuffer^,GetRecordBufferSize,Stream,10200);
end; // SaveRecord


//------------------------------------------------------------------------------
// load all records
//------------------------------------------------------------------------------
procedure TACRMemoryTableData.LoadRecordManager(Stream: TStream);
var RecordBuffer:     TACRRecordBuffer;
    i,RecPos:         Integer;
begin
  if (FLoadedRecordCount > 0) then
   begin
    FRecordManager.LoadFromStream(Stream);
    RecordBuffer := MemoryManager.GetMem(FRecordManager.RecordBufferSize);
    try
      RecPos := INVALID_ID4;
      for i := 0 to FLoadedRecordCount - 1 do
       begin
        LoadRecordFromStream(RecordBuffer,Stream);
        FRecordManager.AddLoadedRecord(RecordBuffer,RecPos);
       end;
    finally
      MemoryManager.FreeAndNilMem(RecordBuffer);
    end;
   end;
end; // LoadRecordManager


//------------------------------------------------------------------------------
// save all records
//------------------------------------------------------------------------------
procedure TACRMemoryTableData.SaveRecordManager(Stream: TStream);
var RecordBuffer:     TACRRecordBuffer;
    NavigationInfo:   TACRNavigationInfo;
begin
  if (FRecordManager.GetRecordCount > 0) then
   begin
     FRecordManager.SaveToStream(Stream);
     RecordBuffer := MemoryManager.GetMem(FRecordManager.RecordBufferSize);
     NavigationInfo.LastPosition := False;
     NavigationInfo.FirstPosition := True;
     NavigationInfo.RecordBuffer := RecordBuffer;
     NavigationInfo.GetRecordMode := grmNext;
     try
       FRecordManager.GetRecordBuffer(NavigationInfo);
       if (NavigationInfo.GetRecordResult = grrOK) then
        begin
         NavigationInfo.FirstPosition := False;
         repeat
          // save record buffer and blob fields
          SaveRecordToStream(RecordBuffer,Stream);
          FRecordManager.GetRecordBuffer(NavigationInfo);
         until (NavigationInfo.GetRecordResult <> grrOK);
        end;
     finally
      MemoryManager.FreeAndNilMem(RecordBuffer);
     end;
   end;
end; // SaveRecordManager

(*
//------------------------------------------------------------------------------
// Return bitmap size
//------------------------------------------------------------------------------
function TACRMemoryTableData.GetBitmapSize(SessionID: TACRSessionID): TACRRecordNo;
begin
  Result := TACRMemoryRecordManager(FRecordManager).GetBitmapSize;
end; // GetBitmapSize
*)

//------------------------------------------------------------------------------
// return filter bitmap rec no by record id
//------------------------------------------------------------------------------
function TACRMemoryTableData.GetBitmapRecNoByRecordID(RecordID: TACRRecordID): TACRRecordNo;
begin
  Result := RecordID.PageNo;
end; // GetBitmapRecNoByRecordID


//------------------------------------------------------------------------------
// return filter bitmap rec no by record id
//------------------------------------------------------------------------------
function TACRMemoryTableData.GetRecordIDByBitmapRecNo(RecordNo: TACRRecordNo): TACRRecordID;
begin
  Result.PageNo := RecordNo;
  Result.PageItemNo := 0;
end; // GetRecordIDByBitmapRecNo


//------------------------------------------------------------------------------
// empty table
//------------------------------------------------------------------------------
procedure TACRMemoryTableData.InternalEmptyTable(SessionID: TACRSessionID);
var
    NavigationInfo:   TACRNavigationInfo;
begin
 if (FRecordManager <> nil) then
   if (FBLOBFieldsPresent and (FRecordManager.GetRecordCount > 0)) then
    begin
     NavigationInfo.LastPosition := False;
     NavigationInfo.FirstPosition := True;
     NavigationInfo.RecordBuffer := MemoryManager.GetMem(FRecordManager.RecordBufferSize);
     NavigationInfo.GetRecordMode := grmNext;
     NavigationInfo.SessionID := SessionID;
     try
       FRecordManager.GetRecordBuffer(NavigationInfo);
       if (NavigationInfo.GetRecordResult = grrOk) then
        begin
         NavigationInfo.FirstPosition := False;
         repeat
          ClearBLOBFieldsInRecordBuffer(NavigationInfo.RecordBuffer);
          FRecordManager.GetRecordBuffer(NavigationInfo);
         until (NavigationInfo.GetRecordResult <> grrOK);
        end;
     finally
      MemoryManager.FreeAndNilMem(NavigationInfo.RecordBuffer);
     end;
    end;
 if (FRecordManager <> nil) then
  FRecordManager.Empty(SessionID);
end; // InternalEmptyTable


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TACRMemoryTableData.Create(
                        aDatabaseData: TACRDatabaseData;
                        AllocRecordsBy: Integer
                      );
begin
 inherited Create(aDatabaseData);
 FPageManager := TACRMemoryPageManager.Create;
 FCache := TACRTableCache.Create(FPageManager,nil);
 FAllocRecordsBy := AllocRecordsBy;
 FInMemory := True;
 FTemporary := False;
 FLockManager := TACRTableLockManager.Create(Self,False);
end; // Create;


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TACRMemoryTableData.Destroy;
var ses:      TACRLocalSession;
    i:        Integer;
    cursor:   TACRLocalCursor;
begin
 // called from DatabaseData.Destroy
 ses := TACRLocalSession.Create;
 try
   ses.InMemory := True;
   ses.DatabaseName := FDatabaseData.DatabaseName;
   ses.Connected := True;
   if (FIsTableOpened) then
    begin
     for i := 0 to FCursorList.Count-1 do
      begin
       try
         cursor := FCursorList.Items[i];
         cursor.CloseTable;
       except
       end;
      end;
    end;
//  if (FRecordManager <> nil) then
   begin
    try
      DeleteTable(ses,True,False);
    except
    end;
   end;
 finally
  try
   ses.Connected := False;
  except
  end;
  ses.Free;
 end;
{
 // fixed in 4.95
 if (FRecordManager <> nil) then
  EmptyTable(nil,True);
 if (FSequenceManager <> nil) then
  FSequenceManager.Free;
 FSequenceManager := nil;
 // fixed in 4.95
 if (FIndexManager <> nil) then
  DeleteAllIndexes(nil);
  }
 FPageManager.Free;
 inherited Destroy;
end; // Destroy


//------------------------------------------------------------------------------
// create table
//------------------------------------------------------------------------------
procedure TACRMemoryTableData.CreateTable(
                          Cursor:         TACRCursor;
                          FieldDefs:      TACRFieldDefs;
                          IndexDefs:      TACRIndexDefs;
                          ConstraintDefs: TACRConstraintDefs
                                         );
begin
{$IFDEF DEBUG_TRACE_TACRMemoryTableData_CreateTable}
aaWriteToLog('> TACRMemoryTableData.CreateTable'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'Cursor = '+IntToHex(Integer(Cursor),8)
+#13#10+'FieldDefs.Count = '+IntToStr(FieldDefs.Count)
+#13#10+'IndexDefs.Count = '+IntToStr(IndexDefs.Count)
+#13#10+'ConstraintDefs.Count = '+IntToStr(ConstraintDefs.Count)
);
{$ENDIF}
 if (FieldDefs = nil) then
  raise EACRException.Create(12401,ErrorLNilPointer);
 if (FieldDefs.Count <= 0) then
  raise EACRException.Create(11989,ErrorLNoFields);
 TableName := Cursor.TableName;
{$IFDEF DEBUG_TRACE_TACRMemoryTableData_CreateTable}
aaWriteToLog('1 TACRMemoryTableData.CreateTable'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'Cursor = '+IntToHex(Integer(Cursor),8)
+#13#10+'TableName = '+FTableName
+#13#10+'TableNameCRC = '+IntToHex(Integer(FTableNameCRC),8)
);
{$ENDIF}
 CheckFieldDefinitions(FieldDefs);
 CheckIndexDefinitions(IndexDefs);
 CheckConstraintDefinitions(ConstraintDefs);
 CreateSequenceManager;
 CreateFieldManager(FieldDefs);
 CreateIndexManager(IndexDefs);
 CreateConstraintManager(ConstraintDefs);
 BuildSequences;
 if (FConstraintManager.ConstraintDefs.ForeignKeysExists) then
  CheckForeignKeyDefinitionsAndCreateForeignKeyActions(Cursor);
{$IFDEF DEBUG_TRACE_TACRMemoryTableData_CreateTable}
aaWriteToLog('2 TACRMemoryTableData.CreateTable'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'Cursor = '+IntToHex(Integer(Cursor),8)
+#13#10+'TableName = '+FTableName
+#13#10+'TableNameCRC = '+IntToHex(Integer(FTableNameCRC),8)
);
{$ENDIF}
 CreateRecordManager;
 InitCursor(Cursor);
 FComment := Cursor.Comment;
 FCreationDate := Now;
{$IFDEF DEBUG_TRACE_TACRMemoryTableData_CreateTable}
aaWriteToLog('< TACRMemoryTableData.CreateTable finish'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
);
{$ENDIF}
end;// CreateTable


//------------------------------------------------------------------------------
// delete table
//------------------------------------------------------------------------------
procedure TACRMemoryTableData.DeleteTable(Session: TACRBaseSession; Cascade: Boolean; DesignMode: Boolean = False);
var FSessionID: TACRSessionID;
begin
{$IFDEF DEBUG_TRACE_TACRMemoryTableData_DeleteTable}
aaWriteToLog('TACRMemoryTableData.DeleteTable start, name = '+FTableName);
try
{$ENDIF}
  if (TACRMemoryDatabaseData(FDatabaseData).CheckDeleteTableOrView(FTableName,Cascade)) then
   Exit;
  if (Session <> nil) then
    FSessionID := Session.SessionID
  else
    raise EACRException.Create(11885,ErrorLNilPointer);
  if (not TryToLockTableX(FSessionID)) then
    raise EACRException.Create(11893,ErrorLTableIsNotOpenedExclusively,[FTableName]);
  try
   inherited DeleteTable(Session,Cascade,DesignMode);
{$IFDEF DEBUG_TRACE_TACRMemoryTableData_DeleteTable}
aaWriteToLog('TACRMemoryTableData.DeleteTable 1, name = '+FTableName);
{$ENDIF}
   if (FIndexManager.IndexDefs.Count > 0) then
     FIndexManager.DropAllIndexes(FSessionID);
   InternalEmptyTable(FSessionID);
   FCache.ApplyChanges(FTableState.TableState);
  except
    FCache.CancelChanges;
    raise;
  end;
  TryToUnlockTableX(FSessionID);
{$IFDEF DEBUG_TRACE_TACRMemoryTableData_DeleteTable}
aaWriteToLog('TACRMemoryTableData.DeleteTable 2, name = '+FTableName+ ' cursors count ='+IntToStr(FCursorList.Count));
{$ENDIF}
// must be done outside
(*
   if ((not DesignMode) or (FCursorList.Count = 0)) then
    begin
{$IFDEF DEBUG_TRACE_TACRMemoryTableData_DeleteTable}
aaWriteToLog('TACRMemoryTableData.DeleteTable 3');
{$ENDIF}
     Free;
{$IFDEF DEBUG_TRACE_TACRMemoryTableData_DeleteTable}
aaWriteToLog('TACRMemoryTableData.DeleteTable 4');
{$ENDIF}
    end;
*)
{$IFDEF DEBUG_TRACE_TACRMemoryTableData_DeleteTable}
finally
aaWriteToLog('TACRMemoryTableData.DeleteTable finish');
end;
{$ENDIF}
end; // DeleteTable


//------------------------------------------------------------------------------
// delete constraint (FK,FKAction or PK) and write changes to MetaData file
//------------------------------------------------------------------------------
procedure TACRMemoryTableData.DeleteConstraint(
                          Cursor:           TACRCursor;
                          Name:             WideString;
                          Cascade:          Boolean;
                          FKPartialDelete:  Boolean
                          );
begin
  Lock(true);
  try
    inherited DeleteConstraint(Cursor,Name,Cascade,FKPartialDelete);
    FPageManager.ApplyChanges(Cursor.Session.SessionID);
  finally
    Unlock;
  end;
end; // DeleteConstraint


//------------------------------------------------------------------------------
// empty table
//------------------------------------------------------------------------------
procedure TACRMemoryTableData.EmptyTable(Cursor: TACRCursor; SkipFKCheck: Boolean = False);
begin
 if (not SkipFKCheck) then
  if (FConstraintManager.ConstraintDefs.ForeignKeysActionsDeleteExists) then
   raise EACRException.Create(11494,ErrorLCannotEmptyTableWithForeignKeyActionsDelete,[FTableName]);
 try
   inherited EmptyTable(Cursor,SkipFKCheck);
   InternalEmptyTable(Cursor.Session.SessionID);
   UpdateTableState(ltoEmpty);
   FCache.ApplyChanges(FTableState.TableState);
 except
   FCache.CancelChanges;
   raise;
 end;
end; // EmptyTable


//------------------------------------------------------------------------------
// rename table
//------------------------------------------------------------------------------
procedure TACRMemoryTableData.RenameTable(Cursor: TACRCursor; NewTableName: WideString);
begin
 if (FDatabaseData.TableExists(Cursor.Session,NewTableName)) then
  raise EACRException.Create(11491,ErrorLCannotRenameTableAlreadyExists,[FTableName, NewTableName]);
 inherited RenameTable(Cursor,NewTableName);
end; // RenameTable


//------------------------------------------------------------------------------
// load table from stream
//------------------------------------------------------------------------------
procedure TACRMemoryTableData.LoadTableFromStream(
                        Cursor:               TACRCursor;
                        Stream:               TStream
                       );
var
    TempStream:       TStream;
    BLOBDescriptor:   TACRBLOBDescriptor;
    i:                Integer;
    Buffer,OutBuf:    PAnsiChar;
    OldTableName:     AnsiString;
begin
{ TODO -oLeo :
it is necessary to check if another TACRMemoryTableData exists 
with such table name after calling LoadTableHeader
If it exists, we must close all cursors that references it, destroy it and move 
all references from these cursors to current TACRMemoryTableData 
if load is successfully completed.
We must close all cursors referencing this table before calling
LoadTableFrom... / SaveTableTo in TACRTable
}
 Lock(true);
// EmptyTable(nil);
 try
  if (Cursor = nil) then
   raise EACRException.Create(11607,ErrorLNilPointer);
  inherited;
  OldTableName := Cursor.TableName;
  TempStream := nil;
  CreateSequenceManager;
  if (FFieldManager <> nil) then
   FFieldManager.Free;
  FFieldManager := TACRBaseFieldManager.Create(Self,FSequenceManager);
  if (FConstraintManager = nil) then
    FConstraintManager := TACRBaseConstraintManager.Create(Self);
  if (FIndexManager <> nil) then
   FIndexManager.Free;
  FIndexManager := TACRBaseIndexManager.Create(Self);
  try
    LoadTableHeader(Stream,BLOBDescriptor);
    // create compressed stream
    if (BLOBDescriptor.CompressionAlgorithm = Byte(acaNone)) then
     TempStream := Stream
    else
     begin
      Buffer := MemoryManager.GetMem(BLOBDescriptor.BlockSize);
      try
       Stream.ReadBuffer(Buffer^,BLOBDescriptor.BlockSize);
       // fixed in 4.97
       i := BLOBDescriptor.UncompressedSize;
       ACRInternalDecompressBuffer(
            TACRCompressionAlgorithm(BLOBDescriptor.CompressionAlgorithm),
            Buffer,BLOBDescriptor.BlockSize,OutBuf,i);
      finally
        MemoryManager.FreeAndNilMem(Buffer);
      end;
      TempStream := TACRMemoryStream.Create;
      TempStream.WriteBuffer(OutBuf^,i);
      TempStream.Position := 0;
      FreeMem(OutBuf);
     end;
  except
    on e: Exception do
     begin
      if (TempStream <> nil) then
       if (BLOBDescriptor.CompressionAlgorithm <> Byte(acaNone)) then
        TempStream.Free;
      FTableName := OldTableName;
      FTableNameCRC := GetTableNameCRC(FTableName);
      raise;
     end;
  end;
  try
   LoadSequencesFromStream(TempStream);
   FFieldManager.LoadFromStream(TempStream);
   FFieldManager.FieldDefs.RecalcFieldOffsets;
   FConstraintManager.LoadFromStream(TempStream);
   FIndexManager.LoadFromStream(TempStream);
   FBLOBFieldsPresent := False;
   for i := 0 to FFieldManager.FieldDefs.Count - 1 do
    if (IsBLOBFieldType(FFieldManager.FieldDefs[i].BaseFieldType)) then
     begin
      FBLOBFieldsPresent := True;
      break;
     end;
   if (FRecordManager = nil) then
    CreateRecordManager;
   LoadRecordManager(TempStream);
   if (BLOBDescriptor.CompressionAlgorithm <> Byte(acaNone)) then
    TempStream.Free;
   Cursor.Comment := FComment; 
 except
  on e: Exception do
   begin
    if (BLOBDescriptor.CompressionAlgorithm <> Byte(acaNone)) then
     TempStream.Free;
    DeleteTable(Cursor.Session,True,False);
    raise;
   end;
 end;
 finally
  Unlock;
 end;
end; // LoadTable


//------------------------------------------------------------------------------
// save table to stream
//------------------------------------------------------------------------------
procedure TACRMemoryTableData.SaveTableToStream(
                        Stream:                 TStream;
                        CompressionAlgorithm:   TACRCompressionAlgorithm;
                        CompressionMode:        Byte;
                        BlockSize:              Integer;
                        SkipCheckIsTableOpened: Boolean
                      );
var OldPos,StartPos:  Int64;
    TempStream:       TStream;
    BLOBDescriptor:   TACRBLOBDescriptor;
    Buffer:           PAnsiChar;
    OutSize:          Integer;
begin
 Lock(true);
 try
  inherited SaveTableToStream(Stream,CompressionAlgorithm,CompressionMode,BlockSize,SkipCheckIsTableOpened);
  StartPos := Stream.Position;
  BLOBDescriptor.CompressionAlgorithm := Byte(CompressionAlgorithm);
  if (CompressionMode = 0) then
   CompressionMode := 1;
  BLOBDescriptor.CompressionMode := CompressionMode;
  BLOBDescriptor.BlockSize := BlockSize;
  // save table header
  // create compressed stream
  if (CompressionAlgorithm = acaNone) then
   TempStream := Stream
  else
   TempStream := TACRMemoryStream.Create;
  try
   SaveTableHeader(Stream,BLOBDescriptor);
   SaveSequencesToStream(TempStream);
   // save other objects
   FFieldManager.SaveToStream(TempStream);
   FConstraintManager.SaveToStream(TempStream);
   FIndexManager.SaveToStream(TempStream);
   SaveRecordManager(TempStream);
   if (CompressionAlgorithm <> acaNone) then
    begin
     ACRInternalCompressBuffer(CompressionAlgorithm,CompressionMode,
      TACRMemoryStream(TempStream).Buffer,TempStream.Size,Buffer,OutSize);
     BLOBDescriptor.BlockSize := OutSize;
     BLOBDescriptor.UncompressedSize := TempStream.Size;
     Stream.WriteBuffer(Buffer^,OutSize);
     FreeMem(Buffer);
    end;
  finally
    if (CompressionAlgorithm <> acaNone) then
     TempStream.Free;
    // save table header second time - store params of compressed blob stream
    OldPos := Stream.Position;
    Stream.Position := StartPos;
    if (Stream.Position <> StartPos) then
      raise EACRException.Create(10155,ErrorLCannotSetPosition,
        [StartPos,OldPos,Stream.Position]);
    SaveTableHeader(Stream,BLOBDescriptor);
    Stream.Position := OldPos;
  end;
 finally
  Unlock;
 end;
end; // SaveTable


//------------------------------------------------------------------------------
// open table
//------------------------------------------------------------------------------
procedure TACRMemoryTableData.OpenTable(Cursor: TACRCursor);
begin
 TableName := Cursor.TableName;
 if (Cursor.Exclusive) then
  begin
   if (not TryToLockTableX(Cursor.Session.SessionID)) then
    raise EACRException.Create(11912,ErrorLCannotLockTable,['X',FTableName,Cursor.Session.SessionID]);
  end
 else
  begin
   if (not TryToLockTableIS(Cursor.Session.SessionID)) then
    raise EACRException.Create(11913,ErrorLCannotLockTable,['IS',FTableName,Cursor.Session.SessionID]);
  end;
 LockCursorList;
 try
   inherited OpenTable(Cursor);
   FIsTableOpened := True;
 finally
   UnlockCursorList;
 end;
end;// OpenTable


//------------------------------------------------------------------------------
// close table
//------------------------------------------------------------------------------
procedure TACRMemoryTableData.CloseTable(Cursor: TACRCursor);
begin
 if (Cursor.Exclusive) then
  begin
   TryToUnlockTableX(Cursor.Session.SessionID);
  end
 else
  begin
   TryToUnlockTableIS(Cursor.Session.SessionID);
  end;
 LockCursorList;
 try
   inherited CloseTable(Cursor);
   if (FCursorList.Count = 0) then
    FIsTableOpened := False;
   FCache.ClearSharedCache;
 finally
   UnlockCursorList;
 end;
end;// CloseTable


//------------------------------------------------------------------------------
// add index
//------------------------------------------------------------------------------
procedure TACRMemoryTableData.AddIndex(IndexDef: TACRIndexDef; Cursor: TACRCursor);
begin
 Lock(true);
 try
   LockCursorList;
   try
    try
     inherited AddIndex(IndexDef,Cursor);
     FCache.ApplyChanges(FTableState.TableState);
    except
     FCache.CancelChanges;
     raise;
    end;
   finally
     UnlockCursorList;
   end;
 finally
  Unlock;
 end;
end; // AddIndex


//------------------------------------------------------------------------------
// delete index
//------------------------------------------------------------------------------
procedure TACRMemoryTableData.DeleteIndex(IndexID: TACRObjectID; Cursor: TACRCursor);
begin
 Lock(true);
 try
   LockCursorList;
   try
    try
     inherited DeleteIndex(IndexID,Cursor);
     FCache.ApplyChanges(FTableState.TableState);
    except
     FCache.CancelChanges;
     raise;
    end;
   finally
     UnlockCursorList;
   end;
 finally
  Unlock;
 end;
end; // DeleteIndex


//------------------------------------------------------------------------------
// empty index
//------------------------------------------------------------------------------
procedure TACRMemoryTableData.EmptyIndex(IndexID: TACRObjectID; SessionID: TACRSessionID);
begin
 Lock(true);
 try
  try
   inherited EmptyIndex(IndexID,SessionID);
   FCache.ApplyChanges(FTableState.TableState);
  except
   FCache.CancelChanges;
   raise;
  end;
 finally
  Unlock;
 end;
end; // EmptyIndex


//------------------------------------------------------------------------------
// delete all indexes
//------------------------------------------------------------------------------
procedure TACRMemoryTableData.DeleteAllIndexes(Cursor: TACRCursor);
begin
 Lock(true);
 try
  try
   inherited DeleteAllIndexes(Cursor);
   FCache.ApplyChanges(FTableState.TableState);
  except
   FCache.CancelChanges;
   raise;
  end;
 finally
  Unlock;
 end;
end; // DeleteAllIndexes


//------------------------------------------------------------------------------
// empty all indexes
//------------------------------------------------------------------------------
procedure TACRMemoryTableData.EmptyAllIndexes(SessionID: TACRSessionID);
begin
 Lock(true);
 try
  try
   inherited EmptyAllIndexes(SessionID);
   FCache.ApplyChanges(FTableState.TableState);
  except
   FCache.CancelChanges;
   raise;
  end;
 finally
  Unlock;
 end;
end; // EmptyAllIndexes


//------------------------------------------------------------------------------
// return 0 if id1 = id2, 1 if id1>id2, -1 if id1<id2
//------------------------------------------------------------------------------
function TACRMemoryTableData.CompareRecordID(const RecordID1: TACRRecordID; const RecordID2: TACRRecordID): Integer;
begin
 if (RecordID1.PageNo = RecordID2.PageNo) then
  Result := 0
 else
 if (RecordID1.PageNo > RecordID2.PageNo) then
  Result := 1
 else
  Result := -1;
end; // CompareRecordID


//------------------------------------------------------------------------------
// move cursor to specified position and set current record id in cursor
//------------------------------------------------------------------------------
procedure TACRMemoryTableData.InternalSetRecNo(Cursor: TACRCursor; RecNo: TACRRecordNo);
var RecordID: TACRRecordNo;
begin
  if (FRecordManager = nil) then
   raise EACRException.Create(10074,ErrorLNilPointer);
  RecordID := TACRMemoryRecordManager(FRecordManager).FindRecord(RecNo-1);
  if (RecordID <> INVALID_ID8) then
   begin
    Cursor.CurrentRecordID.PageNo := RecordID;
    Cursor.CurrentRecordID.PageItemNo := 0;
   end;
end; // SetRecNo


//------------------------------------------------------------------------------
// get current record position from cursor
//------------------------------------------------------------------------------
function TACRMemoryTableData.InternalGetRecNo(Cursor: TACRCursor): TACRRecordNo;
begin
 Result := -1;
  if (FRecordManager = nil) then
   raise EACRException.Create(10033,ErrorLNilPointer);
  Result := TACRMemoryRecordManager(FRecordManager).
                GetTablePositionByRecordID(Cursor.CurrentRecordID.PageNo);
  if (Result = INVALID_ID8) then
   Result := -1;
//  else
//   Inc(Result);
end; // GetRecNo


//------------------------------------------------------------------------------
// return TableName loaded from stream
//------------------------------------------------------------------------------
function ACRGetSavedTableNameFromStream(Stream: TStream): WideString;
var Offset,OldPos: Int64;
    FileHeader:    TACRMemoryTableFileHeader;
begin
  Result := '';
  OldPos := Stream.Position;
  try
   try
    LoadDataFromStream(FileHeader,sizeof(FileHeader),Stream,11723);
    LoadWideStringFromStream(Result,Stream,11724);
//    SetLength(Result,FileHeader.NameLength);
//    if (FileHeader.NameLength > 0) then
//     LoadDataFromStream(PAnsiChar(@Result[1])^,FileHeader.NameLength,Stream,11724);
   except
    Result := '';
   end;
  finally
    Stream.Position := OldPos;
  end;
end; // ACRGetSavedTableNameFromStream


initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ACRMemEngine> initialized');
{$ENDIF}
  ACRMemoryIncUseCount;

finalization

  ACRMemoryDecUseCount;


end.
