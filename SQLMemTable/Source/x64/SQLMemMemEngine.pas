unit SQLMemMemEngine;

{$I SQLMemVer.inc}

interface

uses SysUtils, Classes, Math,
{$IFDEF MSWINDOWS}
     Windows,
{$ENDIF}
{$IFDEF LINUX}
     Types,
     Libc,
{$ENDIF}

// SQLMemTable units

     {$IFDEF DEBUG_LOG}
     SQLMemDebug,
     {$ENDIF}

{$IFNDEF D6H}
     SQLMemD4Routines,
{$ENDIF}
     SQLMemCriticalSection,
     SQLMemExcept,
     SQLMemBase,
     SQLMemBaseEngine,
     SQLMemBTree,
     SQLMemPage,
     SQLMemCompression,
     SQLMemTypes,
     SQLMemExpressions,
     SQLMemConverts,
     SQLMemVariant,
     SQLMemConst;

type

////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemMemoryDatabaseData
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemMemoryDatabaseData = class (TSQLMemDatabaseData)
   private
    FLastSessionID: TSQLMemSessionID;
    FViewDefs:      TSQLMemViewDefs;
   protected
		procedure InternalGetTablesList(Session: TSQLMemBaseSession;	List: TSQLMemWideStringList); override;
   public
		function TableExists(Session: TSQLMemBaseSession;	TableName: WideString): Boolean; override;
		function GetTablesInfo(SortByTableName: Boolean = True): TSQLMemTableInfoArray; override;
    // create
    constructor Create;
    destructor Destroy; override;
    // create table data
    function CreateTableData(Cursor: TSQLMemCursor): TSQLMemTableData; override;
    procedure ConnectSession(Session: TSQLMemBaseSession); override;
    // load local memory database
    procedure LoadDatabaseFromStream(
                        Session: TSQLMemBaseSession;
                        Stream:  TStream
                       ); override;
    // save local memory database
    procedure SaveDatabaseToStream(
                    Session:              TSQLMemBaseSession;
                    Stream:               TStream;
                    CompressionAlgorithm: TSQLMemCompressionAlgorithm = acaNone;
                    CompressionMode:      Byte = 0;
                    BlockSize:            Integer = SQLMemDefaultSaveBlockSize
                  ); override;
    // return table comment if table exists, otherwise empty string
    function GetTableComment(TableName: WideString): WideString; override;
    // set table comment
    procedure SetTableComment(TableName, Comment: WideString); override;
    //------------------------- VIEWS - added in v.6.00 ------------------------
    // create view
    procedure CreateView(
                         Session:           TSQLMemBaseSession;
                         ViewName:          WideString;
                         ViewDef:           TSQLMemViewDef
                        ); override;
    // drop view
    procedure DropView(
                         Session:           TSQLMemBaseSession;
                         ViewName:          WideString;
                         bCascade:          Boolean = True
                      ); override;
    // return nil if not found, otherwise return view definition
    function FindView(
                         Session:           TSQLMemBaseSession;
                         ViewName:          WideString
                     ): TSQLMemViewDef; override;
    // return true if view deleted
    function CheckDeleteTableOrView(Name: WideString; Cascade: Boolean): Boolean;
    //--------------------- END OF VIEWS - added in v.6.00 ---------------------
  end; // TSQLMemMemoryDatabaseData


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemMemoryRecordManager
//
////////////////////////////////////////////////////////////////////////////////

  TSQLMemLoadingRecordsInfo = record
    pFlag:    PByte;    // pointer to last byte in FDeletedFlagBuffer
    BitNo:    Integer;  // (0 - 7) number of last bit found in pFlag
    ByteNo:   Integer;  // (0 - n) number of byte in PFlag relative to the beginning of FDeletedFlagBuffer
  end;

  TSQLMemMemoryRecordManager = class (TSQLMemBaseRecordManager)
   private
    LTableData:             TSQLMemTableData;
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
    FLoadingRecordInfo:     TSQLMemLoadingRecordsInfo;

   protected
    function GetBitmapSize: TSQLMemRecordNo;
   private
    // find record id by record position
    function FindRecord(RecordNo: TSQLMemRecordNo): TSQLMemRecordNo;
    // returns position of the record specified by record id,
    // or INVALID_ID8 if the record with this id does not exists
    function GetTablePositionByRecordID(
              RecordNo:           TSQLMemRecordNo
                                        ): TSQLMemRecordNo;
    // return result for attempt of getting record relatively to first position
    // and set RecordID to new record ID
    function GetRecordFromFirstPosition(
            GetRecordMode: TSQLMemGetRecordMode;
            var RecordID: Integer
                                       ): TSQLMemGetRecordResult;
    // return result for attempt of getting record relatively to last position
    // and set RecordID to new record ID
    function GetRecordFromLastPosition(
            GetRecordMode: TSQLMemGetRecordMode;
            var RecordID: Integer
                                      ): TSQLMemGetRecordResult;
    // return result for attempt of getting record relatively any position
    // and set RecordID to new record ID
    function GetRecordFromAnyPosition(
            GetRecordMode: TSQLMemGetRecordMode;
            var RecordID: Integer
                                      ): TSQLMemGetRecordResult;
   protected
    procedure SetRecordCount(NewRecordCount: Integer);
   public
    constructor Create(
                        aTableData:           TSQLMemTableData;
                        RecordBufferSize:     Integer;
                        AllocRecordsBy:       Integer
                      );
    destructor Destroy; override;

    procedure Empty(SessionID: TSQLMemSessionID = INVALID_SESSION_ID); override;

    procedure RewriteBLOBValues(SourceRecordBuffer, DestRecordBuffer: TSQLMemRecordBuffer);

    // add record and return its number
    function AddRecord(
                       RecordBuffer:  TSQLMemRecordBuffer;
                       var RecordID:  TSQLMemRecordID;
                       SessionID:     TSQLMemSessionID = INVALID_SESSION_ID
                      ): Boolean; override;
    // update record, return true if record was updated, false if record was deleted
    function UpdateRecord(
                          RecordBuffer: TSQLMemRecordBuffer;
                          RecordID:     TSQLMemRecordID;
                          SessionID:    TSQLMemSessionID = INVALID_SESSION_ID
                         ): Boolean; override;
    // delete record, return true if record was deleted, false if record was deleted earlier
    function DeleteRecord(
                          var RecordID: TSQLMemRecordID;
                          SessionID:    TSQLMemSessionID = INVALID_SESSION_ID
                         ): Boolean; override;
    // return true if record exists
    function IsRecordExists(var RecordID: TSQLMemRecordID; SessionID: TSQLMemSessionID = INVALID_SESSION_ID): Boolean; override;
    procedure GetRecordBuffer(var NavigationInfo: TSQLMemNavigationInfo); override;
    // return record no
    function GetApproximateRecNo(RecordID: TSQLMemRecordID; SessionID: TSQLMemSessionID): TSQLMemRecordNo; override;
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
    // add loaded record
    procedure AddLoadedRecord(RecordBuffer: TSQLMemRecordBuffer; var RecordPos: Integer); override;
  end; // TSQLMemMemoryRecordManager


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemMemoryTableData
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemMemoryTableData = class (TSQLMemAdvancedTableData)
   private
    FLoadedRecordCount: Integer;
    FAllocRecordsBy:    Integer;
    FPageManager:       TSQLMemPageManager;

   protected
    function GetPageManager: TSQLMemPageManager; override;
    procedure CreateRecordManager; override;
    procedure CreateIndexManager(IndexDefs: TSQLMemIndexDefs); override;
    procedure LoadTableHeader(
              Stream:             TStream;
              var BLOBDescriptor: TSQLMemBLOBDescriptor
                              );
    procedure SaveTableHeader(
              Stream:             TStream;
              var BLOBDescriptor: TSQLMemBLOBDescriptor
                              );
    procedure LoadBLOBDataFromStream(
            RecordBuffer: TSQLMemRecordBuffer;
            FieldNo:      Integer;
            Stream:       TStream
                                 );
    procedure LoadRecordFromStream(
            RecordBuffer: TSQLMemRecordBuffer;
            Stream:       TStream
                                 );
    procedure PrepareRecordBufferForSave(
            RecordBuffer:             TSQLMemRecordBuffer;
            BLOBDescriptorList:       TList;
            BLOBDataList:             TList;
            BLOBPosition:             Int64
                                                );
    procedure SaveRecordToStream(
            RecordBuffer: TSQLMemRecordBuffer;
            Stream:       TStream
                                 );
    procedure LoadRecordManager(Stream: TStream);
    procedure SaveRecordManager(Stream: TStream);
//    function GetBitmapSize(SessionID: TSQLMemSessionID): TSQLMemRecordNo; override;
    // return filter bitmap rec no by record id
    function GetBitmapRecNoByRecordID(RecordID: TSQLMemRecordID): TSQLMemRecordNo; override;
    // return filter bitmap rec no by record id
    function GetRecordIDByBitmapRecNo(RecordNo: TSQLMemRecordNo): TSQLMemRecordID; override;
    procedure InternalEmptyTable(SessionID: TSQLMemSessionID); override;
   public
    constructor Create(
                        aDatabaseData: TSQLMemDatabaseData;
                        AllocRecordsBy: Integer
                      );
    destructor Destroy; override;

    procedure CreateTable(
                          Cursor: TSQLMemCursor;
                          FieldDefs: TSQLMemFieldDefs;
                          IndexDefs: TSQLMemIndexDefs;
                          ConstraintDefs: TSQLMemConstraintDefs
                         ); override;
    procedure DeleteTable(Session: TSQLMemBaseSession; Cascade: Boolean; DesignMode: Boolean = False); override;
    procedure DeleteConstraint(Cursor: TSQLMemCursor; Name: WideString; Cascade: Boolean; FKPartialDelete: Boolean); override;
    procedure EmptyTable(Cursor: TSQLMemCursor; SkipFKCheck: Boolean = False); override;
    procedure RenameTable(Cursor: TSQLMemCursor; NewTableName: WideString); override;
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
    procedure OpenTable(Cursor: TSQLMemCursor); override;
    procedure CloseTable(Cursor: TSQLMemCursor); override;
    procedure AddIndex(IndexDef: TSQLMemIndexDef; Cursor: TSQLMemCursor); override;
    procedure DeleteIndex(IndexID: TSQLMemObjectID; Cursor: TSQLMemCursor); override;
    procedure EmptyIndex(IndexID: TSQLMemObjectID; SessionID: TSQLMemSessionID); override;
    procedure DeleteAllIndexes(Cursor: TSQLMemCursor); override;
    procedure EmptyAllIndexes(SessionID: TSQLMemSessionID); override;

    // return 0 if id1 = id2, 1 if id1>id2, -1 if id1<id2
    function CompareRecordID(const RecordID1: TSQLMemRecordID; const RecordID2: TSQLMemRecordID): Integer; override;
    // move cursor to specified position and set current record id in cursor
    procedure InternalSetRecNo(Cursor: TSQLMemCursor; RecNo: TSQLMemRecordNo); override;
    // get current record position from cursor
    function InternalGetRecNo(Cursor: TSQLMemCursor): TSQLMemRecordNo; override;

   public
    property SequenceManager: TSQLMemBaseSequenceManager read FSequenceManager write FSequenceManager;
  end; // TSQLMemMemoryTableData

  // return TableName loaded from stream
  function SQLMemGetSavedTableNameFromStream(Stream: TStream): WideString;

implementation

uses

// SQLMemTable units

  SQLMemLocalEngine,
  SQLMemStoredFunctions,
  SQLMemMemory       // last

  ;

////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemMemoryDatabaseData
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// get tables list
//------------------------------------------------------------------------------
procedure TSQLMemMemoryDatabaseData.InternalGetTablesList(Session: TSQLMemBaseSession;	List: TSQLMemWideStringList);
var i: Integer;
begin
  inherited InternalGetTablesList(Session,List);
  for i := 0 to FViewDefs.Count - 1 do
    List.Add(FViewDefs[i].Name);
end; // InternalGetTablesList


//------------------------------------------------------------------------------
// return true if table exists
//------------------------------------------------------------------------------
function TSQLMemMemoryDatabaseData.TableExists(Session: TSQLMemBaseSession;	TableName: WideString): Boolean;
begin
  Result := inherited TableExists(Session,TableName);
  if (not Result) then
   Result := (FViewDefs.GetDefNumberByName(TableName) >= 0);
end; // TableExists


//------------------------------------------------------------------------------
// get all tables info - name, state, etc.
//------------------------------------------------------------------------------
function TSQLMemMemoryDatabaseData.GetTablesInfo(SortByTableName: Boolean): TSQLMemTableInfoArray;
var
      i,n:          Integer;
      TableData:  TSQLMemTableData;
      ViewDef:    TSQLMemViewDef;
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
      ViewDef := TSQLMemViewDef(FViewDefs.Items[i]);
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
      SQLMemSortTableInfo(Result, 0, High(Result));
    end;
  finally
    Unlock;
  end;
end; // GetTablesInfo


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TSQLMemMemoryDatabaseData.Create;
begin
  inherited Create;
  FTemporary := False;
  FInMemory := True;
  FPageManager := nil;
  FLastSessionID := INVALID_SESSION_ID;
  FLockParams.Delay := SQLMemMemoryDelay;
  FLockParams.RetryCount := SQLMemMemoryRetryCount;
  // added in v.5.10
  FStoredFunctionsManager := TSQLMemStoredFunctionManager.Create(Self);
  // added in v.6.00
  FViewDefs := TSQLMemViewDefs.Create;
end;// Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TSQLMemMemoryDatabaseData.Destroy;
begin
  inherited Destroy;
  FViewDefs.Free;
end; // Destroy


//------------------------------------------------------------------------------
// create table data
//------------------------------------------------------------------------------
function TSQLMemMemoryDatabaseData.CreateTableData(Cursor: TSQLMemCursor): TSQLMemTableData;
begin
{$IFDEF DEBUG_TRACE_TSQLMemMemoryDatabaseData_CreateTableData}
aaWriteToLog('> TSQLMemMemoryDatabaseData.CreateTableData'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'DatabaseName = '+FDatabaseName
+#13#10+'TableName = '+Cursor.TableName
+#13#10+'Length(TableName) = '+IntToStr(Length(Cursor.TableName))
);
{$ENDIF}
 Result := TSQLMemMemoryTableData.Create(Self,Cursor.MemoryTableAllocBy);
 Result.TableName := Cursor.TableName;
 AddTableData(Result);
{$IFDEF DEBUG_TRACE_TSQLMemMemoryDatabaseData_CreateTableData}
aaWriteToLog('< TSQLMemMemoryDatabaseData.CreateTableData'
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
procedure TSQLMemMemoryDatabaseData.ConnectSession(Session: TSQLMemBaseSession);
begin
  inherited ConnectSession(Session);
  Session.SessionID := GetCurrentThreadId;
end;// ConnectSession


//------------------------------------------------------------------------------
// load local memory database
//------------------------------------------------------------------------------
procedure TSQLMemMemoryDatabaseData.LoadDatabaseFromStream(
                    Session: TSQLMemBaseSession;
                    Stream: TStream
                   );
var i, n:   Integer;
    Cursor: TSQLMemLocalCursor;
begin
  Lock(true);
  try
   Cursor := TSQLMemLocalCursor.Create;
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
      TSQLMemStoredFunctionManager(FStoredFunctionsManager).Load(Stream);
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
procedure TSQLMemMemoryDatabaseData.SaveDatabaseToStream(
                Session:              TSQLMemBaseSession;
                Stream:               TStream;
                CompressionAlgorithm: TSQLMemCompressionAlgorithm;
                CompressionMode:      Byte;
                BlockSize:            Integer
              );
var Cursor:     TSQLMemLocalCursor;
    tablesList: TSQLMemWideStringList;
    i:          Integer;
begin
  Lock(true);
  try
   Cursor := TSQLMemLocalCursor.Create;
   tablesList := TSQLMemWideStringList.Create;
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
    TSQLMemStoredFunctionManager(FStoredFunctionsManager).Save(Stream);
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
function TSQLMemMemoryDatabaseData.GetTableComment(TableName: WideString): WideString;
var i:          Integer;
    tableData:  TSQLMemTableData;
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
procedure TSQLMemMemoryDatabaseData.SetTableComment(TableName, Comment: WideString);
var i:          Integer;
    tableData:  TSQLMemTableData;
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
procedure TSQLMemMemoryDatabaseData.CreateView(
                         Session:           TSQLMemBaseSession;
                         ViewName:          WideString;
                         ViewDef:           TSQLMemViewDef
                                          );
begin
{$IFDEF DEBUG_TRACE_TSQLMemMemoryDatabaseData_CreateView}
aaWriteToLog('> TSQLMemMemoryDatabaseData.CreateView. SessionID = ' + IntToStr(Session.SessionID) + ', ViewName = ' + ViewName);
try
{$ENDIF}
  if (TableExists(Session,ViewName)) then
    raise ESQLMemException.Create(12623,ErrorLTableExists,[ViewName]);
  Lock(True);
  try
   FViewDefs.Add(ViewDef);
  finally
   Unlock;
  end;
{$IFDEF DEBUG_TRACE_TSQLMemMemoryDatabaseData_TableExists}
aaWriteToLog('< TSQLMemMemoryDatabaseData.CreateView. SessionID = ' + IntToStr(Session.SessionID) + ', ViewName = ' + ViewName);
except
 on e: Exception
 begin
aaWriteToLog('Error in TSQLMemMemoryDatabaseData.CreateView. SessionID = ' + IntToStr(Session.SessionID) + ', ViewName = ' + ViewName);
  raise;
 end;
end;
{$ENDIF}
end; // CreateView


//------------------------------------------------------------------------------
// drop view
//------------------------------------------------------------------------------
procedure TSQLMemMemoryDatabaseData.DropView(
                     Session:           TSQLMemBaseSession;
                     ViewName:          WideString;
                     bCascade:          Boolean
                  );
var idx: Integer;
begin
{$IFDEF DEBUG_TRACE_TSQLMemMemoryDatabaseData_DropView}
aaWriteToLog('> TSQLMemMemoryDatabaseData.DropView. SessionID = ' + IntToStr(Session.SessionID) + ', ViewName = ' + ViewName);
try
{$ENDIF}
  if (not TableExists(Session,ViewName)) then
    raise ESQLMemException.Create(12624,ErrorLTableExists,[ViewName]);
  Lock(True);
  try
   if (bCascade) then
   begin
    FViewDefs.DeleteChildren(ViewName);
   end
   else
    if (FViewDefs.FindChildren(ViewName)) then
     raise ESQLMemException.Create(12625,ErrorLCannotDeleteViewOtherViewsExists,[ViewName]);
   idx := FViewDefs.GetDefNumberByName(ViewName);
   if (idx >= 0) then
    FViewDefs.Delete(idx);
  finally
   Unlock;
  end;
{$IFDEF DEBUG_TRACE_TSQLMemMemoryDatabaseData_TableExists}
aaWriteToLog('< TSQLMemMemoryDatabaseData.DropView. SessionID = ' + IntToStr(Session.SessionID) + ', ViewName = ' + ViewName);
except
 on e: Exception
 begin
aaWriteToLog('Error in TSQLMemMemoryDatabaseData.DropView. SessionID = ' + IntToStr(Session.SessionID) + ', ViewName = ' + ViewName);
  raise;
 end;
end;
{$ENDIF}
end; // DropView


//------------------------------------------------------------------------------
// return nil if not found, otherwise return view definition
//------------------------------------------------------------------------------
function TSQLMemMemoryDatabaseData.FindView(
                     Session:           TSQLMemBaseSession;
                     ViewName:          WideString
                                  ): TSQLMemViewDef;
var idx: Integer;
begin
{$IFDEF DEBUG_TRACE_TSQLMemMemoryDatabaseData_CreateView}
aaWriteToLog('> TSQLMemMemoryDatabaseData.FindView. SessionID = ' + IntToStr(Session.SessionID) + ', ViewName = ' + ViewName);
try
{$ENDIF}
  Lock(False);
  try
   idx := FViewDefs.GetDefNumberByName(ViewName);
   if (idx >= 0) then
   begin
    Result := TSQLMemViewDef.Create;
    Result.Assign(FViewDefs.Items[idx]);
   end
   else
    Result := nil;
  finally
   Unlock;
  end;
{$IFDEF DEBUG_TRACE_TSQLMemMemoryDatabaseData_TableExists}
aaWriteToLog('< TSQLMemMemoryDatabaseData.FindView. SessionID = ' + IntToStr(Session.SessionID) + ', ViewName = ' + ViewName+', Result = '+BoolToStr(Result,True));
except
 on e: Exception
 begin
aaWriteToLog('Error in TSQLMemMemoryDatabaseData.CreateView. SessionID = ' + IntToStr(Session.SessionID) + ', ViewName = ' + ViewName);
  raise;
 end;
end;
{$ENDIF}
end; // FindView


//------------------------------------------------------------------------------
// return true if view deleted
//------------------------------------------------------------------------------
function TSQLMemMemoryDatabaseData.CheckDeleteTableOrView(Name: WideString; Cascade: Boolean): Boolean;
var idx: Integer;
begin
  Lock(True);
  try
    if (Cascade) then
      FViewDefs.DeleteChildren(Name)
    else
     if (FViewDefs.FindChildren(Name)) then
      raise ESQLMemException.Create(12626,ErrorLCannotDeleteViewOtherViewsExists,[Name]);
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
// TSQLMemMemoryRecordManager
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// return bitmap size
//------------------------------------------------------------------------------
function TSQLMemMemoryRecordManager.GetBitmapSize: TSQLMemRecordNo;
begin
//  Result := FAllocatedRecordCount;
  Result := FLastRecordID + 1;
end; // GetBitmapSize


//------------------------------------------------------------------------------
// find record position in buffer by record number
//------------------------------------------------------------------------------
function TSQLMemMemoryRecordManager.FindRecord(RecordNo: TSQLMemRecordNo): TSQLMemRecordNo;
var i,l:        Integer;
    b,k:        Byte;
    n:          TSQLMemRecordNo;
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
  raise ESQLMemException.Create(10457,ErrorLInvalidBitNo,[RecordNo,FAllocatedRecordCount]);
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
function TSQLMemMemoryRecordManager.GetTablePositionByRecordID(
              RecordNo:            TSQLMemRecordNo
                ): TSQLMemRecordNo;
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
function TSQLMemMemoryRecordManager.GetRecordFromFirstPosition(
            GetRecordMode: TSQLMemGetRecordMode;
            var RecordID: Integer
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
    RecordID := FFirstRecordID;
    Result := grrOK;
   end;
 end; // GetRecordMode
end; // GetRecordFromFirstPosition


//------------------------------------------------------------------------------
// return result for attempt of getting record relatively to last position
//------------------------------------------------------------------------------
function TSQLMemMemoryRecordManager.GetRecordFromLastPosition(
            GetRecordMode: TSQLMemGetRecordMode;
            var RecordID: Integer
                                                          ): TSQLMemGetRecordResult;
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
function TSQLMemMemoryRecordManager.GetRecordFromAnyPosition(
            GetRecordMode:  TSQLMemGetRecordMode;
            var RecordID:   Integer
                                      ): TSQLMemGetRecordResult;
var
{$I SQLMem_check_null_flag_var.inc}
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
        {$I SQLMem_check_null_flag.inc}
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
      {$I SQLMem_check_null_flag.inc}
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
        {$I SQLMem_check_null_flag.inc}
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
procedure TSQLMemMemoryRecordManager.SetRecordCount(NewRecordCount: Integer);
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
constructor TSQLMemMemoryRecordManager.Create(
                        aTableData:           TSQLMemTableData;
                        RecordBufferSize:     Integer;
                        AllocRecordsBy:       Integer
                      );
var
    i,c: Byte;
begin
 if (RecordBufferSize = 0) then
  raise ESQLMemException.Create(10011,ErrorLInvalidRecordSize);
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
destructor TSQLMemMemoryRecordManager.Destroy;
begin
 Empty;
 inherited Destroy;
end; // Destroy


//------------------------------------------------------------------------------
// Empty
//------------------------------------------------------------------------------
procedure TSQLMemMemoryRecordManager.Empty(SessionID: TSQLMemSessionID);
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
procedure TSQLMemMemoryRecordManager.RewriteBLOBValues(
                            SourceRecordBuffer,
                            DestRecordBuffer:   TSQLMemRecordBuffer);
var
{$I SQLMem_check_null_flag_var.inc}
begin
 if (LTableData.BLOBFieldsPresent) then
  for CHECK_NULL_FLAG_BitNo := 0 to LTableData.FieldManager.FieldDefs.Count - 1 do
   if (IsBLOBFieldType(LTableData.FieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo].BaseFieldType)) then
    begin
      CHECK_NULL_FLAG_NullFlags := DestRecordBuffer;
      {$I SQLMem_check_null_flag.inc}
      if (not CHECK_NULL_FLAG_Result) then
       begin
        CHECK_NULL_FLAG_NullFlags := SourceRecordBuffer;
        {$I SQLMem_check_null_flag.inc}
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
function TSQLMemMemoryRecordManager.AddRecord(
                       RecordBuffer:  TSQLMemRecordBuffer;
                       var RecordID:  TSQLMemRecordID;
                       SessionID:     TSQLMemSessionID = INVALID_SESSION_ID
                      ): Boolean;
var delta, i, n: Int64;
    m:           Integer;
{$I SQLMem_set_null_flag_var.inc}
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
       delta := SQLMemGetReallocDelta(n);
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
    {$I SQLMem_set_null_flag.inc}
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
function TSQLMemMemoryRecordManager.UpdateRecord(
                          RecordBuffer: TSQLMemRecordBuffer;
                          RecordID:     TSQLMemRecordID;
                          SessionID:    TSQLMemSessionID = INVALID_SESSION_ID
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
function TSQLMemMemoryRecordManager.DeleteRecord(
                          var RecordID: TSQLMemRecordID;
                          SessionID:    TSQLMemSessionID = INVALID_SESSION_ID
                         ): Boolean;
var
{$I SQLMem_check_null_flag_var.inc}
{$I SQLMem_set_null_flag_var.inc}
begin
 Result := False;
 RecordID.PageItemNo := 0;
 CHECK_NULL_FLAG_BitNo := Integer(RecordID.PageNo);
 CHECK_NULL_FLAG_NullFlags := FDeleteFlagBuffer;
 {$I SQLMem_check_null_flag.inc}
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
     {$I SQLMem_set_null_flag.inc}
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
function TSQLMemMemoryRecordManager.IsRecordExists(var RecordID: TSQLMemRecordID; SessionID: TSQLMemSessionID): Boolean;
var
{$I SQLMem_check_null_flag_var.inc}
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
procedure TSQLMemMemoryRecordManager.GetRecordBuffer(var NavigationInfo: TSQLMemNavigationInfo);
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
    raise ESQLMemException.Create(10019,ErrorLRetreivingRecord);
   end;
  end; // record retrieved successfully
end; // GetRecordBuffer


//------------------------------------------------------------------------------
// return record no
//------------------------------------------------------------------------------
function TSQLMemMemoryRecordManager.GetApproximateRecNo(RecordID: TSQLMemRecordID; SessionID: TSQLMemSessionID): TSQLMemRecordNo;
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
procedure TSQLMemMemoryRecordManager.LoadFromStream(Stream: TStream);
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
procedure TSQLMemMemoryRecordManager.SaveToStream(Stream: TStream);
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
procedure TSQLMemMemoryRecordManager.AddLoadedRecord(RecordBuffer: TSQLMemRecordBuffer; var RecordPos: Integer);

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
         raise ESQLMemException.Create(10454,ErrorLInvalidRecordNo,[FLoadingRecordInfo.ByteNo]);
      end;
   if (RecordPos >= FAllocatedRecordCount) then
     raise ESQLMemException.Create(10847,ErrorLInvalidRecordNo,[FAllocatedRecordCount]);
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
// TSQLMemMemoryTableData
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// GetPageManager
//------------------------------------------------------------------------------
function TSQLMemMemoryTableData.GetPageManager: TSQLMemPageManager;
begin
  Result := FPageManager;
end;// GetPageManager


//------------------------------------------------------------------------------
// create RecordManager
//------------------------------------------------------------------------------
procedure TSQLMemMemoryTableData.CreateRecordManager;
begin
 if (FRecordManager <> nil) then
  FRecordManager.Free;
 FRecordManager := TSQLMemMemoryRecordManager.Create(
                      Self,
                      GetRecordBufferSize,
                      FAllocRecordsBy
                                                 );
end;// CreateRecordManager


//------------------------------------------------------------------------------
// create index manager
//------------------------------------------------------------------------------
procedure TSQLMemMemoryTableData.CreateIndexManager(IndexDefs: TSQLMemIndexDefs);
begin
 if (FIndexManager <> nil) then
  FIndexManager.Free;
 FillDefsByObjectId(IndexDefs);
 FIndexManager := TSQLMemBaseIndexManager.Create(Self);
 FIndexManager.CreateIndexDefs(IndexDefs);
end;// CreateIndexManager


//------------------------------------------------------------------------------
// load table header
//------------------------------------------------------------------------------
procedure TSQLMemMemoryTableData.LoadTableHeader(
              Stream:             TStream;
              var BLOBDescriptor: TSQLMemBLOBDescriptor
                                             );
var FileHeader: TSQLMemMemoryTableFileHeader;
    DatabaseID: TSQLMemSequenceValue;
begin
  LoadDataFromStream(FileHeader,sizeof(FileHeader),Stream,10160);
  if (FileHeader.Signature <> SQLMemSignature) then
    raise ESQLMemException.Create(10161,ErrorLInvalidSignature,
      [FileHeader.Signature,SQLMemSignature]);
  if (FileHeader.Version > SQLMemVersion + 0.0001) then
    raise ESQLMemException.Create(10162,ErrorLInvalidVersion,
      [FileHeader.Version,SQLMemVersion]);
  if (FileHeader.Version < 1.0001) then
    raise ESQLMemException.Create(10443,ErrorLInvalidVersion,
      [FileHeader.Version,SQLMemVersion]);
  if (FileHeader.Version < 1.010001) then
    raise ESQLMemException.Create(10454,ErrorLInvalidVersion,
      [FileHeader.Version,SQLMemVersion]);
  if (FileHeader.Version < 1.020001) then
    raise ESQLMemException.Create(10455,ErrorLInvalidVersion,
      [FileHeader.Version,SQLMemVersion]);
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
procedure TSQLMemMemoryTableData.SaveTableHeader(
              Stream:             TStream;
              var BLOBDescriptor: TSQLMemBLOBDescriptor
              );
var FileHeader: TSQLMemMemoryTableFileHeader;
    DatabaseID: TSQLMemSequenceValue;
begin
  FileHeader.Signature := SQLMemSignature;
  FileHeader.Version := SQLMemVersion;
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
procedure TSQLMemMemoryTableData.LoadBLOBDataFromStream(
        RecordBuffer: TSQLMemRecordBuffer;
        FieldNo:      Integer;
        Stream:       TStream
                             );
var Buffer:                 PAnsiChar;
    FBLOBPosition:          Int64;
    Offset,Offset2:         Integer;
    BLOBPartialDescriptor:  TSQLMemPartialTemporaryBLOBDescriptor;
begin
  Offset := FFieldManager.FieldDefs[FieldNo].MemoryOffset;
  Move(PAnsiChar(RecordBuffer + Offset)^,FBLOBPosition,sizeof(FBLOBPosition));
  // load disk blob descriptor
  SetStreamPosition(Stream,FBLOBPosition,10202);
  LoadDataFromStream(BLOBPartialDescriptor,sizeof(BLOBPartialDescriptor),
    Stream,10203);
  Offset2 := sizeof(TSQLMemPartialBLOBDescriptor);
  Buffer := MemoryManager.GetMem(BLOBPartialDescriptor.CompressedSize + Offset2);
  PSQLMemPartialBLOBDescriptor(Buffer)^.NumBlocks :=
    BLOBPartialDescriptor.NumBlocks;
  PSQLMemPartialBLOBDescriptor(Buffer)^.UncompressedSize :=
    BLOBPartialDescriptor.UncompressedSize;
  // load compresse blob data
  LoadDataFromStream(PAnsiChar(Buffer + Offset2)^,
    BLOBPartialDescriptor.CompressedSize,Stream,10204);
  Move(Buffer,PAnsiChar(RecordBuffer + Offset)^,sizeof(Buffer));
end; // LoadBLOBDataFromStream


//------------------------------------------------------------------------------
// load record
//------------------------------------------------------------------------------
procedure TSQLMemMemoryTableData.LoadRecordFromStream(
            RecordBuffer: TSQLMemRecordBuffer;
            Stream:       TStream
                                                  );
var
{$I SQLMem_check_null_flag_var.inc}
begin
  LoadDataFromStream(RecordBuffer^,GetRecordBufferSize,Stream,10201);
  if (FBLOBFieldsPresent) then
   begin
     CHECK_NULL_FLAG_NullFlags := RecordBuffer;
     for CHECK_NULL_FLAG_BitNo := 0 to FFieldManager.FieldDefs.Count - 1 do
      if (IsBLOBFieldType(FFieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo].BaseFieldType)) then
      begin
        {$I SQLMem_check_null_flag.inc}
        if (not CHECK_NULL_FLAG_Result) then
          // load blob
          LoadBLOBDataFromStream(RecordBuffer,CHECK_NULL_FLAG_BitNo,Stream);
      end;
   end;
end; // LoadRecord


//------------------------------------------------------------------------------
// prepare record buffer for save
//------------------------------------------------------------------------------
procedure TSQLMemMemoryTableData.PrepareRecordBufferForSave(
            RecordBuffer:             TSQLMemRecordBuffer;
            BLOBDescriptorList:       TList;
            BLOBDataList:             TList;
            BLOBPosition:             Int64
                                                );
var FBLOBPosition:            Int64;
    BLOBDataSize:             Integer;
    Offset:                   Integer;
    Buffer:                   PAnsiChar;
    PBLOBPartialDescriptor:   PSQLMemPartialTemporaryBLOBDescriptor;
{$I SQLMem_check_null_flag_var.inc}
begin
 FBLOBPosition := BLOBPosition;
 CHECK_NULL_FLAG_NullFlags := RecordBuffer;
 for CHECK_NULL_FLAG_BitNo := 0 to FFieldManager.FieldDefs.Count - 1 do
  if (IsBLOBFieldType(FFieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo].BaseFieldType)) then
  begin
    {$I SQLMem_check_null_flag.inc}
    if (not CHECK_NULL_FLAG_Result) then
     begin
      // save blob field data
      Offset := FFieldManager.FieldDefs[CHECK_NULL_FLAG_BitNo].MemoryOffset;
      Move(PAnsiChar(RecordBuffer + Offset)^,Buffer,Sizeof(Buffer));
      if (Buffer = nil) then
        raise ESQLMemException.Create(10196,ErrorLNilPointer);
      // calculate size of blob data
      BLOBDataSize := MemoryManager.GetMemoryBufferSize(Buffer) -
        sizeof(TSQLMemPartialBLOBDescriptor) +
        sizeof(TSQLMemPartialTemporaryBLOBDescriptor);
      PBLOBPartialDescriptor :=
        MemoryManager.GetMem(sizeof(TSQLMemPartialTemporaryBLOBDescriptor));
      PBLOBPartialDescriptor^.NumBlocks :=
        PSQLMemPartialBLOBDescriptor(Buffer)^.NumBlocks;
      PBLOBPartialDescriptor^.UncompressedSize :=
        PSQLMemPartialBLOBDescriptor(Buffer)^.UncompressedSize;
      PBLOBPartialDescriptor^.CompressedSize := BLOBDataSize -
        sizeof(TSQLMemPartialTemporaryBLOBDescriptor);
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
procedure TSQLMemMemoryTableData.SaveRecordToStream(
            RecordBuffer: TSQLMemRecordBuffer;
            Stream:       TStream
                                                );
var i:                        Integer;
    BLOBDataSize:             Integer;
    Buffer:                   PAnsiChar;
    PBLOBPartialDescriptor:   PSQLMemPartialTemporaryBLOBDescriptor;
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
        sizeof(TSQLMemPartialTemporaryBLOBDescriptor),Stream,10198);
       Buffer := BLOBDataList.Items[i];
       BLOBDataSize := PBLOBPartialDescriptor^.CompressedSize;
       SaveDataToStream(PAnsiChar(Buffer + sizeof(TSQLMemPartialBLOBDescriptor))^,BLOBDataSize,Stream,10199);
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
procedure TSQLMemMemoryTableData.LoadRecordManager(Stream: TStream);
var RecordBuffer:     TSQLMemRecordBuffer;
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
procedure TSQLMemMemoryTableData.SaveRecordManager(Stream: TStream);
var RecordBuffer:     TSQLMemRecordBuffer;
    NavigationInfo:   TSQLMemNavigationInfo;
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
function TSQLMemMemoryTableData.GetBitmapSize(SessionID: TSQLMemSessionID): TSQLMemRecordNo;
begin
  Result := TSQLMemMemoryRecordManager(FRecordManager).GetBitmapSize;
end; // GetBitmapSize
*)

//------------------------------------------------------------------------------
// return filter bitmap rec no by record id
//------------------------------------------------------------------------------
function TSQLMemMemoryTableData.GetBitmapRecNoByRecordID(RecordID: TSQLMemRecordID): TSQLMemRecordNo;
begin
  Result := RecordID.PageNo;
end; // GetBitmapRecNoByRecordID


//------------------------------------------------------------------------------
// return filter bitmap rec no by record id
//------------------------------------------------------------------------------
function TSQLMemMemoryTableData.GetRecordIDByBitmapRecNo(RecordNo: TSQLMemRecordNo): TSQLMemRecordID;
begin
  Result.PageNo := RecordNo;
  Result.PageItemNo := 0;
end; // GetRecordIDByBitmapRecNo


//------------------------------------------------------------------------------
// empty table
//------------------------------------------------------------------------------
procedure TSQLMemMemoryTableData.InternalEmptyTable(SessionID: TSQLMemSessionID);
var
    NavigationInfo:   TSQLMemNavigationInfo;
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
constructor TSQLMemMemoryTableData.Create(
                        aDatabaseData: TSQLMemDatabaseData;
                        AllocRecordsBy: Integer
                      );
begin
 inherited Create(aDatabaseData);
 FPageManager := TSQLMemMemoryPageManager.Create;
 FCache := TSQLMemTableCache.Create(FPageManager,nil);
 FAllocRecordsBy := AllocRecordsBy;
 FInMemory := True;
 FTemporary := False;
 FLockManager := TSQLMemTableLockManager.Create(Self,False);
end; // Create;


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TSQLMemMemoryTableData.Destroy;
var ses:      TSQLMemLocalSession;
    i:        Integer;
    cursor:   TSQLMemLocalCursor;
begin
 // called from DatabaseData.Destroy
 ses := TSQLMemLocalSession.Create;
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
procedure TSQLMemMemoryTableData.CreateTable(
                          Cursor:         TSQLMemCursor;
                          FieldDefs:      TSQLMemFieldDefs;
                          IndexDefs:      TSQLMemIndexDefs;
                          ConstraintDefs: TSQLMemConstraintDefs
                                         );
begin
{$IFDEF DEBUG_TRACE_TSQLMemMemoryTableData_CreateTable}
aaWriteToLog('> TSQLMemMemoryTableData.CreateTable'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
+#13#10+'Cursor = '+IntToHex(Integer(Cursor),8)
+#13#10+'FieldDefs.Count = '+IntToStr(FieldDefs.Count)
+#13#10+'IndexDefs.Count = '+IntToStr(IndexDefs.Count)
+#13#10+'ConstraintDefs.Count = '+IntToStr(ConstraintDefs.Count)
);
{$ENDIF}
 if (FieldDefs = nil) then
  raise ESQLMemException.Create(12401,ErrorLNilPointer);
 if (FieldDefs.Count <= 0) then
  raise ESQLMemException.Create(11989,ErrorLNoFields);
 TableName := Cursor.TableName;
{$IFDEF DEBUG_TRACE_TSQLMemMemoryTableData_CreateTable}
aaWriteToLog('1 TSQLMemMemoryTableData.CreateTable'
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
{$IFDEF DEBUG_TRACE_TSQLMemMemoryTableData_CreateTable}
aaWriteToLog('2 TSQLMemMemoryTableData.CreateTable'
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
{$IFDEF DEBUG_TRACE_TSQLMemMemoryTableData_CreateTable}
aaWriteToLog('< TSQLMemMemoryTableData.CreateTable finish'
+#13#10+'Self = '+IntToHex(Integer(Self),8)
+#13#10+'ClassName = '+Self.ClassName
);
{$ENDIF}
end;// CreateTable


//------------------------------------------------------------------------------
// delete table
//------------------------------------------------------------------------------
procedure TSQLMemMemoryTableData.DeleteTable(Session: TSQLMemBaseSession; Cascade: Boolean; DesignMode: Boolean = False);
var FSessionID: TSQLMemSessionID;
begin
{$IFDEF DEBUG_TRACE_TSQLMemMemoryTableData_DeleteTable}
aaWriteToLog('TSQLMemMemoryTableData.DeleteTable start, name = '+FTableName);
try
{$ENDIF}
  if (TSQLMemMemoryDatabaseData(FDatabaseData).CheckDeleteTableOrView(FTableName,Cascade)) then
   Exit;
  if (Session <> nil) then
    FSessionID := Session.SessionID
  else
    raise ESQLMemException.Create(11885,ErrorLNilPointer);
  if (not TryToLockTableX(FSessionID)) then
    raise ESQLMemException.Create(11893,ErrorLTableIsNotOpenedExclusively,[FTableName]);
  try
   inherited DeleteTable(Session,Cascade,DesignMode);
{$IFDEF DEBUG_TRACE_TSQLMemMemoryTableData_DeleteTable}
aaWriteToLog('TSQLMemMemoryTableData.DeleteTable 1, name = '+FTableName);
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
{$IFDEF DEBUG_TRACE_TSQLMemMemoryTableData_DeleteTable}
aaWriteToLog('TSQLMemMemoryTableData.DeleteTable 2, name = '+FTableName+ ' cursors count ='+IntToStr(FCursorList.Count));
{$ENDIF}
// must be done outside
(*
   if ((not DesignMode) or (FCursorList.Count = 0)) then
    begin
{$IFDEF DEBUG_TRACE_TSQLMemMemoryTableData_DeleteTable}
aaWriteToLog('TSQLMemMemoryTableData.DeleteTable 3');
{$ENDIF}
     Free;
{$IFDEF DEBUG_TRACE_TSQLMemMemoryTableData_DeleteTable}
aaWriteToLog('TSQLMemMemoryTableData.DeleteTable 4');
{$ENDIF}
    end;
*)
{$IFDEF DEBUG_TRACE_TSQLMemMemoryTableData_DeleteTable}
finally
aaWriteToLog('TSQLMemMemoryTableData.DeleteTable finish');
end;
{$ENDIF}
end; // DeleteTable


//------------------------------------------------------------------------------
// delete constraint (FK,FKAction or PK) and write changes to MetaData file
//------------------------------------------------------------------------------
procedure TSQLMemMemoryTableData.DeleteConstraint(
                          Cursor:           TSQLMemCursor;
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
procedure TSQLMemMemoryTableData.EmptyTable(Cursor: TSQLMemCursor; SkipFKCheck: Boolean = False);
begin
 if (not SkipFKCheck) then
  if (FConstraintManager.ConstraintDefs.ForeignKeysActionsDeleteExists) then
   raise ESQLMemException.Create(11494,ErrorLCannotEmptyTableWithForeignKeyActionsDelete,[FTableName]);
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
procedure TSQLMemMemoryTableData.RenameTable(Cursor: TSQLMemCursor; NewTableName: WideString);
begin
 if (FDatabaseData.TableExists(Cursor.Session,NewTableName)) then
  raise ESQLMemException.Create(11491,ErrorLCannotRenameTableAlreadyExists,[FTableName, NewTableName]);
 inherited RenameTable(Cursor,NewTableName);
end; // RenameTable


//------------------------------------------------------------------------------
// load table from stream
//------------------------------------------------------------------------------
procedure TSQLMemMemoryTableData.LoadTableFromStream(
                        Cursor:               TSQLMemCursor;
                        Stream:               TStream
                       );
var
    TempStream:       TStream;
    BLOBDescriptor:   TSQLMemBLOBDescriptor;
    i:                Integer;
    Buffer,OutBuf:    PAnsiChar;
    OldTableName:     AnsiString;
begin
{ TODO -oLeo :
it is necessary to check if another TSQLMemMemoryTableData exists 
with such table name after calling LoadTableHeader
If it exists, we must close all cursors that references it, destroy it and move 
all references from these cursors to current TSQLMemMemoryTableData 
if load is successfully completed.
We must close all cursors referencing this table before calling
LoadTableFrom... / SaveTableTo in TSQLMemTable
}
 Lock(true);
// EmptyTable(nil);
 try
  if (Cursor = nil) then
   raise ESQLMemException.Create(11607,ErrorLNilPointer);
  inherited;
  OldTableName := Cursor.TableName;
  TempStream := nil;
  CreateSequenceManager;
  if (FFieldManager <> nil) then
   FFieldManager.Free;
  FFieldManager := TSQLMemBaseFieldManager.Create(Self,FSequenceManager);
  if (FConstraintManager = nil) then
    FConstraintManager := TSQLMemBaseConstraintManager.Create(Self);
  if (FIndexManager <> nil) then
   FIndexManager.Free;
  FIndexManager := TSQLMemBaseIndexManager.Create(Self);
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
       SQLMemInternalDecompressBuffer(
            TSQLMemCompressionAlgorithm(BLOBDescriptor.CompressionAlgorithm),
            Buffer,BLOBDescriptor.BlockSize,OutBuf,i);
      finally
        MemoryManager.FreeAndNilMem(Buffer);
      end;
      TempStream := TSQLMemMemoryStream.Create;
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
procedure TSQLMemMemoryTableData.SaveTableToStream(
                        Stream:                 TStream;
                        CompressionAlgorithm:   TSQLMemCompressionAlgorithm;
                        CompressionMode:        Byte;
                        BlockSize:              Integer;
                        SkipCheckIsTableOpened: Boolean
                      );
var OldPos,StartPos:  Int64;
    TempStream:       TStream;
    BLOBDescriptor:   TSQLMemBLOBDescriptor;
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
   TempStream := TSQLMemMemoryStream.Create;
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
     SQLMemInternalCompressBuffer(CompressionAlgorithm,CompressionMode,
      TSQLMemMemoryStream(TempStream).Buffer,TempStream.Size,Buffer,OutSize);
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
      raise ESQLMemException.Create(10155,ErrorLCannotSetPosition,
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
procedure TSQLMemMemoryTableData.OpenTable(Cursor: TSQLMemCursor);
begin
 TableName := Cursor.TableName;
 if (Cursor.Exclusive) then
  begin
   if (not TryToLockTableX(Cursor.Session.SessionID)) then
    raise ESQLMemException.Create(11912,ErrorLCannotLockTable,['X',FTableName,Cursor.Session.SessionID]);
  end
 else
  begin
   if (not TryToLockTableIS(Cursor.Session.SessionID)) then
    raise ESQLMemException.Create(11913,ErrorLCannotLockTable,['IS',FTableName,Cursor.Session.SessionID]);
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
procedure TSQLMemMemoryTableData.CloseTable(Cursor: TSQLMemCursor);
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
procedure TSQLMemMemoryTableData.AddIndex(IndexDef: TSQLMemIndexDef; Cursor: TSQLMemCursor);
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
procedure TSQLMemMemoryTableData.DeleteIndex(IndexID: TSQLMemObjectID; Cursor: TSQLMemCursor);
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
procedure TSQLMemMemoryTableData.EmptyIndex(IndexID: TSQLMemObjectID; SessionID: TSQLMemSessionID);
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
procedure TSQLMemMemoryTableData.DeleteAllIndexes(Cursor: TSQLMemCursor);
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
procedure TSQLMemMemoryTableData.EmptyAllIndexes(SessionID: TSQLMemSessionID);
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
function TSQLMemMemoryTableData.CompareRecordID(const RecordID1: TSQLMemRecordID; const RecordID2: TSQLMemRecordID): Integer;
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
procedure TSQLMemMemoryTableData.InternalSetRecNo(Cursor: TSQLMemCursor; RecNo: TSQLMemRecordNo);
var RecordID: TSQLMemRecordNo;
begin
  if (FRecordManager = nil) then
   raise ESQLMemException.Create(10074,ErrorLNilPointer);
  RecordID := TSQLMemMemoryRecordManager(FRecordManager).FindRecord(RecNo-1);
  if (RecordID <> INVALID_ID8) then
   begin
    Cursor.CurrentRecordID.PageNo := RecordID;
    Cursor.CurrentRecordID.PageItemNo := 0;
   end;
end; // SetRecNo


//------------------------------------------------------------------------------
// get current record position from cursor
//------------------------------------------------------------------------------
function TSQLMemMemoryTableData.InternalGetRecNo(Cursor: TSQLMemCursor): TSQLMemRecordNo;
begin
 Result := -1;
  if (FRecordManager = nil) then
   raise ESQLMemException.Create(10033,ErrorLNilPointer);
  Result := TSQLMemMemoryRecordManager(FRecordManager).
                GetTablePositionByRecordID(Cursor.CurrentRecordID.PageNo);
  if (Result = INVALID_ID8) then
   Result := -1;
//  else
//   Inc(Result);
end; // GetRecNo


//------------------------------------------------------------------------------
// return TableName loaded from stream
//------------------------------------------------------------------------------
function SQLMemGetSavedTableNameFromStream(Stream: TStream): WideString;
var Offset,OldPos: Int64;
    FileHeader:    TSQLMemMemoryTableFileHeader;
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
end; // SQLMemGetSavedTableNameFromStream


initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('SQLMemMemEngine> initialized');
{$ENDIF}
  SQLMemMemoryIncUseCount;

finalization

  SQLMemMemoryDecUseCount;


end.
