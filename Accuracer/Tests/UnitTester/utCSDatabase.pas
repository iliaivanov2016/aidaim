unit utCSDatabase;

interface

{$I UTConfig.inc}
{$I ACRVer.inc}

{$DEFINE EXTERNAL_SERVER}

{$DEFINE TEST_DATABASE}
{$DEFINE TEST_TABLE}
{$DEFINE TEST_QUERY}

uses Windows, SysUtils, Messages, Classes, Math, DB,
     uTestList,
     ACRConst,
     ACRTypes,
     ACRClient,
     ACRServer,
     ACRMemory,
     ACRCompression,
     ACRMain,
{$IFDEF ACR5H}
     ACRComMain,
{$ENDIF}
{$IFDEF DEBUG_LOG}
ACRDebug,
{$ENDIF}
     ACRLexer,
     ACRVariant,
     ACRConnection;

const MinBufferSize = 100*1024;
{$IFDEF EXTERNAL_SERVER}
const DS_DESTROY = (WM_USER+3);
var ServerExeName: AnsiString = 'ACRServer\AccuracerDatabaseServer.exe';
    ServerName: AnsiString = 'Accuracerdatabaseserver';
    ServerHWND: HWND;
{$ENDIF}

type
  TUnitTestCSDatabase = class(TUnitTest)
   private
    server:       TACRServer;
    db:           TACRDatabase;
    remoteDB:     TACRDatabase;
    RemoteDBName: String;
    table:        TACRTable;
    query:        TACRQuery;
    dbTotalPageCount,
    dbUsedPageCount,
    dbFreePageCount: Integer;
    dbDensity,
    dbFormatVersion: Double;
    FTestExceptions: Boolean;

    TestCaption:            String;
    client_msg_string:      String;
    client_msg_buffer:      PChar;
    client_msg_size:        Integer;
    client_msg_stream:      TACRMemoryStream;
    server_msg_string:      String;
    server_msg_buffer:      PChar;
    server_msg_size:        Integer;
    server_msg_stream:      TACRMemoryStream;
    server_msg_clientInfo:  TACRClientInfo;
    FClientMessageReceived: Boolean;
    FServerMessageReceived: Boolean;
   private
    procedure TestDatabase;
    procedure TestTable;
    procedure TestQuery;
    procedure TestVCL;
    procedure DoOnSQL1(
                          Sender:     TComponent;
                          ClientInfo: TACRClientInfo;
                          Params:     TACRSQLParams;
{$IFDEF ACR5H}
                          var SQL:    WideString;
{$ELSE}
                          var SQL:    AnsiString;
{$ENDIF}
                          var Abort:  Boolean
                                   );
    procedure DoOnSQL2(
                          Sender:     TComponent;
                          ClientInfo: TACRClientInfo;
                          Params:     TACRSQLParams;
{$IFDEF ACR5H}
                          var SQL:    WideString;
{$ELSE}
                          var SQL:    AnsiString;
{$ENDIF}
                          var Abort:  Boolean
                                   );
    procedure DoOnSQL3(
                          Sender:     TComponent;
                          ClientInfo: TACRClientInfo;
                          Params:     TACRSQLParams;
{$IFDEF ACR5H}
                          var SQL:    WideString;
{$ELSE}
                          var SQL:    AnsiString;
{$ENDIF}
                          var Abort:  Boolean
                                   );
    procedure TestOnSQL;
    procedure TestEncryption;
    // tests for messages....
    function AllocateAndGenerateRandomBuffer(Size: Integer): PChar;
    procedure CompareBuffers(Buffer1, Buffer2: PChar; bStream: Boolean = false);
    procedure CompareStreams(Stream1, Stream2: TStream);
    procedure ClientReceiveTextMessage(const Text: String);
    procedure ClientReceiveTextBinary(Buffer: PChar; Size: Integer);
    procedure ClientReceiveTextStream(Stream: TStream);
    procedure ServerReceiveTextMessage(const Client: TACRClientInfo; const Text: String);
    procedure ServerReceiveTextBinary(const Client: TACRClientInfo; Buffer: PChar; Size: Integer);
    procedure ServerReceiveTextStream(const Client: TACRClientInfo; Stream: TStream);
    procedure TestMessagesSimple;
    procedure TestMessagesMultiThread;
    procedure TestMessages;
   public
    procedure TestShort; override;
    procedure TestExceptions; override;
  end;

var
  UnitTestCSDatabase: TUnitTestCSDatabase;

{$IFDEF EXTERNAL_SERVER}
procedure RunExe(ExeName: AnsiString; Parameters: AnsiString = '');
function IsServerStarted: Boolean;
procedure ShutdownServer;
{$ENDIF}

implementation

Function ShellExecute(hWnd:HWND;lpOperation:PAnsiChar;lpFile:PAnsiChar;lpParameter:PAnsiChar;
                      lpDirectory:PAnsiChar;nShowCmd:Integer):Thandle; Stdcall;
External 'Shell32.Dll' name 'ShellExecuteA';


{$IFDEF EXTERNAL_SERVER}
procedure RunExe(ExeName: AnsiString; Parameters: AnsiString);
const MaxTime = 10000; // 10 sec
var bOK:  Boolean;
    t:    Cardinal;
    s:    AnsiString;
begin
  if (not ACRFileExists(ExeName)) then
    raise Exception.Create('RunExe failed, file does not exist: '+ExeName);
  s := ExtractFilePath(ExeName);
  bOK := false;
  t := aaGetTickCount;
  while ((ACRGetTickCountDiff(aaGetTickCount,t) < MaxTime) and (not bOK)) do
   begin
    ShellExecute(0,'Open',pAnsiChar(ExeName),PAnsiChar(Parameters),
                        pAnsiChar(s), SW_SHOWNORMAL);
    bOK := IsServerStarted;
    Sleep(100);
   end;
 if (not bOK) then
  raise Exception.Create('RunExe failed: '+ExeName)
 else
  begin
   ServerHWND := FindWindowEx(0,0,nil,PAnsiChar(ServerName));
   if (ServerHWND = 0) then
    raise Exception.Create('Server Window not found: '+ServerName);
  end;
end; // RunExe


function IsServerStarted: Boolean;
const
   ACR_SERVER_GUID = '{7E102F1D-C7AF-4CBB-A401-317DDBCFD197}';
var
  Mutex:         THandle;
  MutexName:     array [0..MAX_PATH] of Char;
begin
  StrPCopy(@MutexName, ACR_SERVER_GUID);
  Mutex := OpenMutex(MUTEX_ALL_ACCESS, True, @MutexName);
  Result := (Mutex <> 0);
  if (Result) then
   CloseHandle(Mutex);
end; // IsServerStarted

procedure ShutdownServer;
const MaxTime = 10000; // 10 sec
var bOK:  Boolean;
    t:    Cardinal;
begin
  bOK := false;
  SendMessageA(ServerHWND,DS_DESTROY,1,2);
  t := aaGetTickCount;
  while ((ACRGetTickCountDiff(aaGetTickCount,t) < MaxTime) and (not bOK)) do
   begin
    PostMessageA(ServerHWND,DS_DESTROY,1,2);
    bOK := (not IsServerStarted);
    Sleep(100);
   end;
end;
{$ENDIF}

{ TUnitTestCSDatabase }

procedure TUnitTestCSDatabase.TestDatabase;
var
    Caption:      String;
begin
{$IFDEF TEST_DATABASE}
{$IFNDEF EXTERNAL_SERVER}
  WriteToProcessLog(Caption + 'Start...');
  WriteToProcessLog(Caption + 'Set local database crypto parameters...');
   db.CryptoParams.CryptoAlgorithm := craBlowfish;
   db.CryptoParams.CryptoMode := acmCBC;
   db.CryptoParams.Password := 'The Password';
  WriteToProcessLog(Caption + 'Delete local database...');
   db.DeleteDatabase;
sleep(500); { TODO -oLeo : remove this delay }
  WriteToProcessLog(Caption + 'Create local database...');
   db.CreateDatabase;
  WriteToProcessLog(Caption + 'Open local database...');
   db.Open;
  WriteToProcessLog(Caption + 'Set local database parameters...');
   dbTotalPageCount := db.TotalPageCount;
   dbUsedPageCount := db.UsedPageCount;
   dbFreePageCount := db.FreePageCount;
   dbDensity := db.Density;
   dbFormatVersion := db.FormatVersion;
  WriteToProcessLog(Caption + 'Close local database...');
   db.Close;
  WriteToProcessLog(Caption + 'Local database closed.');

  Caption := 'TUnitTestCSDatabase.TestDatabase - ';
  WriteToProcessLog(Caption + 'Set remote database parameters...');
  remoteDB.CryptoParams.Password := ACRDefaultPassword;

  remoteDB.ConnectionParams.DatabaseName := RemoteDBName;
  if (not remoteDB.Exists) then
   WriteToErrorLog(Caption+'remote database does not exists');

  remoteDB.ConnectionParams.DatabaseName := RemoteDBName+'aaa';
  if (remoteDB.Exists) then
   WriteToErrorLog(Caption+'wrong remote database exists');

  remoteDB.ConnectionParams.DatabaseName := RemoteDBName;
  if (not remoteDB.Exists) then
   WriteToErrorLog(Caption+'remote database does not exists');

  if (not remotedb.IsDatabaseEncrypted) then
   WriteToErrorLog(Caption+'remote database is not encrypted');

  if (not remotedb.IsDatabaseEncryptedByPassword) then
   WriteToErrorLog(Caption+'remote database is not encrypted by password');

  if (remotedb.IsCryptoParamsValid) then
   WriteToErrorLog(Caption+'remote database can be opened with default password');
  remoteDB.ConnectionParams.DatabaseName := RemoteDBName;

  remoteDB.CryptoParams.Assign(db.CryptoParams);

  if (not remotedb.IsCryptoParamsValid) then
   WriteToErrorLog(Caption+'remote database cannot be opened with correct password');


   WriteToProcessLog(Caption + 'Opening...');

 remoteDB.Open;
 try
  WriteToProcessLog(Caption + 'Opened!');

  if (remoteDB.CryptoParams.Password <> db.CryptoParams.Password) then
   WriteToErrorLog(Caption+'remote database has invalid password');

  if (remoteDB.CryptoParams.CryptoAlgorithm <> db.CryptoParams.CryptoAlgorithm) then
   WriteToErrorLog(Caption+'remote database has invalid CryptoAlgorithm');

  if (remoteDB.CryptoParams.CryptoMode <> db.CryptoParams.CryptoMode) then
   WriteToErrorLog(Caption+'remote database has invalid CryptoMode');

  if (remoteDB.TotalPageCount <> dbTotalPageCount) then
   WriteToErrorLog(Caption+'remote database has invalid total page count');

  if (remoteDB.FreePageCount <> dbFreePageCount) then
   WriteToErrorLog(Caption+'remote database has invalid free page count');

  if (remoteDB.UsedPageCount <> dbUsedPageCount) then
   WriteToErrorLog(Caption+'remote database has invalid used page count');

  if (remoteDB.Density <> dbDensity) then
   WriteToErrorLog(Caption+'remote database has invalid density');

  if (remoteDB.FormatVersion <> dbFormatVersion) then
   WriteToErrorLog(Caption+'remote database has invalid format version');

  if (remoteDB.ReadOnly) then
   WriteToErrorLog(Caption+'remote database is read only');

  if (not remoteDB.Exclusive) then
   WriteToErrorLog(Caption+'remote database is not in exclusive');

  if (remoteDB.InTransaction) then
   WriteToErrorLog(Caption+'remote database is in transaction #0');

  remoteDB.StartTransaction;

  if (not remoteDB.InTransaction) then
   WriteToErrorLog(Caption+'remote database is not in transaction #1');

  remoteDB.Commit(False);

  if (remoteDB.InTransaction) then
   WriteToErrorLog(Caption+'remote database is in transaction #1');

  remoteDB.StartTransaction;

  if (not remoteDB.InTransaction) then
   WriteToErrorLog(Caption+'remote database is not in transaction #2');

  remoteDB.Rollback;

  if (remoteDB.InTransaction) then
   WriteToErrorLog(Caption+'remote database is in transaction #2');

  remoteDB.FlushFileBuffers;

  WriteToProcessLog(Caption + 'Finished');
 finally
  remoteDB.Close;
  if (db.Connected) then
     WriteToErrorLog(Caption+'local database is not closed in the end of test');
 end;
{$ENDIF}
{$ENDIF}
end;


procedure TUnitTestCSDatabase.TestTable;
var
    Caption,sql:  String;
    AdvFieldDef:  TACRAdvFieldDef;
    x:            Int64;
    sl:           TStringList;
    bs:           TStream;
    Buf:          array [0..250000] of byte;
    Buf1:         array [0..250000] of byte;
    BufSize,i:    Integer;
    bm:           TBookmark;
{$IFDEF ACR5H}
    state:        TACRTableState;
    tableInfo:    TACRTableInfoArray;
{$ENDIF}
begin
{$IFDEF TEST_TABLE}
  Caption := 'TUnitTestCSDatabase.TestTable - ';
  WriteToProcessLog(Caption + 'Start...');


{$IFNDEF EXTERNAL_SERVER}
  remoteDB.ConnectionParams.DatabaseName := RemoteDBName;
  remoteDB.CryptoParams.Assign(db.CryptoParams);
{$ENDIF}

  remoteDB.Open;
  try
    table.DatabaseName := remoteDB.DatabaseName;
    table.Exclusive := True;
    table.TableName := 'test';

    if (table.Exists) then
     WriteToErrorLog(Caption+'remote table exists');

    table.AdvFieldDefs.Clear;
    table.FieldDefs.Clear;
    table.IndexDefs.Clear;

    AdvFieldDef := table.AdvFieldDefs.AddFieldDef;
    AdvFieldDef.Name := 'id';
    AdvFieldDef.DataType := aftAutoInc;
    AdvFieldDef.AutoincMinValue := 3;
    AdvFieldDef.AutoincMaxValue := 1000;
    AdvFieldDef.AutoincIncrement := 2;
    AdvFieldDef.AutoincInitialValue := 4;
    AdvFieldDef.AutoincCycled := True;

    AdvFieldDef := table.AdvFieldDefs.AddFieldDef;
    AdvFieldDef.Name := 'str';
    AdvFieldDef.DataType := aftString;
    AdvFieldDef.Size := 50;
    AdvFieldDef.DefaultValue.AsString := 'bbb';
    AdvFieldDef.MinValue.AsString := 'aaa';
    AdvFieldDef.MaxValue.AsString := 'ddd';

    AdvFieldDef := table.AdvFieldDefs.AddFieldDef;
    AdvFieldDef.Name := 'blob';
    AdvFieldDef.DataType := aftBlob;
    AdvFieldDef.Size := 0;

    AdvFieldDef := table.AdvFieldDefs.AddFieldDef;
    AdvFieldDef.Name := 'memo';
    AdvFieldDef.DataType := aftMemo;
    AdvFieldDef.Size := 0;

    table.IndexDefs.Add('idx_str','str',[ixCaseInsensitive,ixDescending]);

    table.CreateTable;
{$IFDEF ACR5H}
    tableInfo := remoteDB.GetTablesInfo;
    if (Length(tableInfo) <> 1) then
     WriteToErrorLog(Caption+'invalid tables info #1');
    tableInfo := nil; 
{$ENDIF}

    WriteToProcessLog(Caption + 'table created');

      if (not table.Exists) then
       WriteToErrorLog(Caption+'remote table does not exists');
    WriteToProcessLog(Caption + 'table exists');

      sl := TStringList.Create;
      try
        remoteDB.GetTablesList(sl);
        if (sl.Count <> 1) then
         WriteToErrorLog(Caption+'remote table table list is invalid');
        if (sl.Strings[0] <> table.TableName) then
         WriteToErrorLog(Caption+'remote table table list is invalid #2');
      finally
        sl.free;
      end;

      table.RenameTable('table_aaa');
      if (table.TableName <> 'table_aaa') then
       WriteToErrorLog(Caption+'remote table was not renamed');
      if (not table.Exists) then
       WriteToErrorLog(Caption+'remote table was not renamed #2');

      table.DeleteTable;
      if (table.Exists) then
       WriteToErrorLog(Caption+'remote table was not deleted');

      table.TableName := 'test';
      table.CreateTable;
      if (not table.Exists) then
       WriteToErrorLog(Caption+'remote table was not created again');

      table.TableName := 'aaa';

      if (table.Exists) then
       WriteToErrorLog(Caption+'remote table exists #2');


      table.TableName := 'test';
      table.Open;

    WriteToProcessLog(Caption + 'table opened');

      if (not table.Exists) then
       WriteToErrorLog(Caption+'remote table does not exists #2');

      x := table.RecordCount;
{$IFDEF DEBUG_LOG}
aaWriteToLog('RecordCount #1 = '+IntToStr(x));
{$ENDIF}
      if (x <> 0) then
       WriteToErrorLog(Caption+'remote table has invalid record count = '+IntToStr(x));

      table.Insert;
      table.Post;

      x := table.RecordCount;
{$IFDEF DEBUG_LOG}
aaWriteToLog('RecordCount #2 = '+IntToStr(x));
{$ENDIF}
      if (x <> 1) then
       WriteToErrorLog(Caption+'remote table has invalid record count #2 = '+IntToStr(x));

{$IFDEF ACR5H}
      state := table.GetTableState;
      if (state.LastTableOperation <> ltoInsert) then
       WriteToErrorLog(Caption+'invalid state after insert');
{$ENDIF}

      x := table.RecordCount;
{$IFDEF DEBUG_LOG}
aaWriteToLog('RecordCount #3 = '+IntToStr(x));
{$ENDIF}
      if (x <> 1) then
       WriteToErrorLog(Caption+'remote table has invalid record count #3 = '+IntToStr(x));

      if (table.FieldByName('id').AsInteger <> 6) then
       WriteToErrorLog(Caption+'remote table has invalid default value for "id" field');

      if (table.FieldByName('str').AsString <> 'bbb') then
       WriteToErrorLog(Caption+'remote table has invalid default value for "str" field');

      table.Edit;
      table.FieldByName('str').AsString := 'ccc';
      x := table.RecordCount;
{$IFDEF DEBUG_LOG}
aaWriteToLog('Before Cancel');
{$ENDIF}
      table.Cancel;
{$IFDEF DEBUG_LOG}
aaWriteToLog('After Cancel');
{$ENDIF}

      if (table.FieldByName('str').AsString <> 'bbb') then
       WriteToErrorLog(Caption+'remote table has invalid default value for "str" field #2');

{$IFDEF DEBUG_LOG}
aaWriteToLog('Before Edit');
{$ENDIF}
      table.Edit;
{$IFDEF DEBUG_LOG}
aaWriteToLog('After Edit');
{$ENDIF}
      table.FieldByName('str').AsString := 'ccc';
      table.Post;

      if (table.FieldByName('str').AsString <> 'ccc') then
       WriteToErrorLog(Caption+'remote table has invalid default value for "str" field #3');


      x := table.RecNo;
      if (x <> 1) then
       WriteToErrorLog(Caption+'remote table has invalid recno = '+IntToStr(x));

      table.Insert;
      table.Post;

      table.RecNo := 1;
      if (table.FieldByName('id').AsInteger <> 6) then
       WriteToErrorLog(Caption+'remote table has set wrong recno, RecNo = '+IntToStr(table.RecNo)+', Value = '+table.FieldByName('id').AsString);

      if (not table.Locate('str','bbb',[])) then
       WriteToErrorLog(Caption+'locate failed');

      table.First;
      if (table.FieldByName('id').AsInteger <> 6) then
       WriteToErrorLog(Caption+'remote table first failed');
      table.Next;
      if (table.FieldByName('id').AsInteger <> 8) then
       WriteToErrorLog(Caption+'remote table next failed');
      table.Next;
      if (not table.EOF) then
       WriteToErrorLog(Caption+'remote table EOF failed');


{$IFDEF DEBUG_LOG}
aaWriteToLog(Caption+'Before Set Filter');
{$ENDIF}
      table.Filtered := False;
      table.Filter := 'id = 6';
{$IFDEF DEBUG_LOG}
aaWriteToLog(Caption+'Before Set Filtered');
{$ENDIF}
      table.Filtered := True;
{$IFDEF DEBUG_LOG}
aaWriteToLog(Caption+'After Set Filtered');
{$ENDIF}

      x := table.RecordCount;
{$IFDEF DEBUG_LOG}
aaWriteToLog(Caption+'Filtered RecordCount = '+IntToStr(x));
{$ENDIF}
      if (x <> 1) then
       WriteToErrorLog(Caption+'remote table has invalid filtered record count #1 = '+IntToStr(x));

      table.Filtered := False;

      table.First;

      x := table.RecordCount;
      if (x <> 2) then
       WriteToErrorLog(Caption+'remote table has invalid record count #4 = '+IntToStr(x));

    WriteToProcessLog(Caption + 'testing bookmarks...');

      bm := table.GetBookmark;
      if (not table.BookmarkValid(bm)) then
       WriteToErrorLog(Caption+'remote table - invalid bookmark #1');
      table.Delete;
      if (table.BookmarkValid(bm)) then
       WriteToErrorLog(Caption+'remote table - invalid bookmark #2');
      table.FreeBookmark(bm);

    WriteToProcessLog(Caption + 'testing bookmarks... finished');

      table.IndexName := 'idx_str';
      if (not table.FindKey(['bbb'])) then
       WriteToErrorLog(Caption+'findkey failed');

      x := table.RecordCount;
      if (x <> 1) then
       WriteToErrorLog(Caption+'remote table has invalid record count #2 = '+IntToStr(x));

      table.Close;

      table.EmptyTable;

      table.Open;
      x := table.RecordCount;
      if (x <> 0) then
       WriteToErrorLog(Caption+'remote table has invalid record count #3 = '+IntToStr(x));


      // test blobs
      BufSize := High(Buf) - Low(Buf) + 1;
      for i := Low(Buf) to High(Buf) do
       begin
        Buf[i] := i mod 256;
        Buf1[i] := Buf[i];
       end;
      table.Open;
    WriteToProcessLog(Caption + 'testing blobs...');

      table.Insert;
      table.Post;

    WriteToProcessLog(Caption + 'testing blobs... insert ok ');

      bs := table.CreateBlobStream(table.FieldByName('blob'),bmRead);

    WriteToProcessLog(Caption + 'testing blobs... 0');

      if (bs.Size <> 0) then
         WriteToErrorLog(Caption+'error reading blob from table - size <> 0');
     bs.Free;

      if (not table.FieldByName('memo').IsNull) then
         WriteToErrorLog(Caption+'error - memo field is not null');


      table.Insert;

    WriteToProcessLog(Caption + 'testing blobs... 1');

      bs := table.CreateBlobStream(table.FieldByName('blob'),bmWrite);

    WriteToProcessLog(Caption + 'testing blobs... 2');

      bs.WriteBuffer(Buf[0],BufSize);

    WriteToProcessLog(Caption + 'testing blobs... 21');

      table.FieldByName('memo').AsString := '';
      table.FieldByName('memo').AsString := 'aaa';

      table.Post;

    WriteToProcessLog(Caption + 'testing blobs... 3');

      bs := table.CreateBlobStream(table.FieldByName('blob'),bmRead);
      if (bs.Size <> BufSize) then
         WriteToErrorLog(Caption+'error reading blob from table - invalid size');
      bs.ReadBuffer(Buf[0],BufSize);
      bs.Free;

    WriteToProcessLog(Caption + 'testing blobs... 4');

      for i := Low(Buf) to High(Buf) do
       if (Buf[i] <> Buf1[i]) then
        begin
         WriteToErrorLog(Caption+'error reading blob from table - invalid data');
         break;
        end;
    WriteToProcessLog(Caption + 'testing blobs... 45');

     if (table.FieldByName('memo').AsString <> 'aaa') then
      WriteToErrorLog(Caption+'error reading memo from table - invalid data after insert');

    WriteToProcessLog(Caption + 'testing blobs... 5');

     table.Edit;
     bs := table.CreateBlobStream(table.FieldByName('blob'),bmReadWrite);
     bs.Size := BufSize * 2;
     table.FieldByName('memo').AsString := '1234567890 !AbXdikes';
     table.Post;

    WriteToProcessLog(Caption + 'testing blobs... 6');

     if (table.FieldByName('memo').AsString <> '1234567890 !AbXdikes') then
      WriteToErrorLog(Caption+'error reading memo from table - invalid data after edit');

    WriteToProcessLog(Caption + 'testing blobs... 7');

     bs := table.CreateBlobStream(table.FieldByName('blob'),bmRead);
     if (bs.Size <> BufSize * 2) then
       WriteToErrorLog(Caption+'error reading blob from table - invalid size <> bufsize * 2');
     bs.Free;

    WriteToProcessLog(Caption + 'blobs... OK');

   sql := table.ExportTableToSQL(True,True,True,False,True,True,False);
   if (Pos('DROP TABLE test',sql) <> 1) then
    WriteToErrorLog(Caption+'ExportTableToSQL failed')
   else
    WriteToProcessLog(Caption+'ExportTableToSQL OK');

   table.Close;

  finally
   table.DeleteTable(True);
   remoteDB.Close;
  end;

  WriteToProcessLog(Caption + 'Finished');
{$ENDIF}  
end;

procedure TUnitTestCSDatabase.TestQuery;
var
    Caption:      String;
    Count:        Integer;
begin
{$IFDEF TEST_QUERY}
  Caption := 'TUnitTestCSDatabase.TestQuery - ';
  WriteToProcessLog(Caption + 'Start...');
{$IFNDEF EXTERNAL_SERVER}
  remoteDB.ConnectionParams.DatabaseName := RemoteDBName;
  remoteDB.CryptoParams.Assign(db.CryptoParams);
{$ENDIF}  
  remoteDB.Open;
  try
    query.DatabaseName := remoteDB.DatabaseName;

    query.SQL.Text := 'DROP TABLE TestSQL; CREATE TABLE TestSQL(id AutoInc, str CHAR(50))';
    query.ExecSQL;

    if (not remoteDB.TableExists('TestSQL')) then
     WriteToErrorLog(Caption+'table was not created');


    query.SQL.Text := 'INSERT INTO TestSQL(str) VALUES ("aaa");INSERT INTO TestSQL(str) VALUES ("bbb");INSERT INTO TestSQL(str) VALUES (NULL);';
    query.ExecSQL;
    if (query.RowsAffected <> 3) then
     WriteToErrorLog(Caption+'insert failed');

 WriteToProcessLog(Caption + 'insert passed');

    // TOP option with INTO
    query.SQL.Text := 'SELECT TOP 1,2 str INTO TempTable FROM TestSQL Order BY str';
    query.Open;
    if (query.RecordCount <> 1) then
     WriteToErrorLog(Caption + 'SELECT TOP 1,2 str INTO TempTable FROM TestSQL Order BY str - failed, invalid record count = '+IntToStr(query.RecordCount));
    if (query.FieldCount <> 1) then
     WriteToErrorLog(Caption + 'SELECT TOP 1,2 str INTO TempTable FROM TestSQL Order BY str - failed, invalid field count = '+IntToStr(query.FieldCount));
    if (query.FieldByName('str').AsString <> 'aaa') then
     WriteToErrorLog(Caption + 'SELECT TOP 1,2 str INTO TempTable FROM TestSQL Order BY str - failed, invalid field value = '+query.FieldByName('str').AsString);

    query.Close;
    query.SQL.Text := 'SELECT * FROM TempTable';
    query.Open;
    if (query.RecordCount <> 1) then
     WriteToErrorLog(Caption + 'SELECT TOP 1,2 str INTO TempTable FROM TestSQL Order BY str - failed SELECT * FROM TempTable, invalid record count = '+IntToStr(query.RecordCount));
    if (query.FieldCount <> 1) then
     WriteToErrorLog(Caption + 'SELECT TOP 1,2 str INTO TempTable FROM TestSQL Order BY str - failed SELECT * FROM TempTable, invalid field count = '+IntToStr(query.FieldCount));
    if (query.FieldByName('str').AsString <> 'aaa') then
     WriteToErrorLog(Caption + 'SELECT TOP 1,2 str INTO TempTable FROM TestSQL Order BY str - failed SELECT * FROM TempTable, invalid field value = '+query.FieldByName('str').AsString);

     // ORDER BY option on hidden field with INTO
    query.Close;
    query.SQL.Text := 'SELECT str INTO TempTable FROM TestSQL ORDER BY id DESC';
    query.Open;
    if (query.FieldCount <> 1) then
     WriteToErrorLog(Caption + 'SELECT str INTO TempTable FROM TestSQL ORDER BY id DESC - failed, invalid field count = '+IntToStr(query.FieldCount));
    if (query.FieldByName('str').AsString <> '') then
     WriteToErrorLog(Caption + 'SELECT str INTO TempTable FROM TestSQL ORDER BY id DESC - failed, invalid field value = '+query.FieldByName('str').AsString);

    query.Close;
    query.SQL.Text := 'SELECT * FROM TempTable';
    query.Open;
    if (query.FieldCount <> 1) then
     WriteToErrorLog(Caption + 'SELECT str INTO TempTable FROM TestSQL ORDER BY id DESC - failed SELECT * FROM TempTable, invalid field count = '+IntToStr(query.FieldCount));
    if (query.FieldByName('str').AsString <> '') then
     WriteToErrorLog(Caption + 'SELECT str INTO TempTable FROM TestSQL ORDER BY id DESC - failed SELECT * FROM TempTable, invalid field value = '+query.FieldByName('str').AsString);
    query.Close;

    query.SQL.Text := 'DROP TABLE TempTable';
    query.ExecSQL;
    if (remoteDB.TableExists('TempTable')) then
      WriteToErrorLog(Caption + 'TempTable was not deleted');

    query.RequestLive := True;
    query.SQL.Text := 'SELECT str,id FROM TestSQL';
    query.Open;

    if (query.RecordCount <> 3) then
     WriteToErrorLog(Caption+'select failed');
    query.First;
    if (query.FieldByName('str').AsString <> 'aaa') then
     WriteToErrorLog(Caption+'select failed - first record');
    if (query.Fields[1].AsInteger <> 1) then
     WriteToErrorLog(Caption+'select failed - first record int field');
    query.Next;
    if (query.FieldByName('str').AsString <> 'bbb') then
     WriteToErrorLog(Caption+'select failed - second record');
    query.Next;
    if (not query.FieldByName('str').IsNull) then
     WriteToErrorLog(Caption+'select failed - third record');
    query.Next;
    if (not query.EOF) then
     WriteToErrorLog(Caption+'select failed - not EOF');

 WriteToProcessLog(Caption + 'live query without params closing ....');
    query.Close;

 WriteToProcessLog(Caption + 'live query without params passed ');

    query.SQL.Text := 'SELECT * FROM TestSQL WHERE str = :P_STR';
    query.ParamByName('P_STR').AsString := 'bbb';
    query.Open;
    if (query.RecordCount <> 1) then
     WriteToErrorLog(Caption+'select with params failed - invalid record count');
    if (query.FieldByName('str').AsString <> 'bbb') then
     WriteToErrorLog(Caption+'select with params failed - invalid record');

    query.Close;

 WriteToProcessLog(Caption + 'live query with params passed ');

    query.SQL.Text := 'DROP TABLE TestSQL2; CREATE TABLE TestSQL2(id AutoInc, str CHAR(50))';
    query.ExecSQL;

    if (not remoteDB.TableExists('TestSQL2')) then
     WriteToErrorLog(Caption+'table 2 was not created ');

    query.SQL.Text := 'INSERT INTO TestSQL2(str) VALUES ("aaa");INSERT INTO TestSQL2(str) VALUES ("bbb");INSERT INTO TestSQL2(str) VALUES (NULL);';
    query.ExecSQL;
    if (query.RowsAffected <> 3) then
     WriteToErrorLog(Caption+'insert failed');

 WriteToProcessLog(Caption + 'creating second table passed ');

    query.SQL.Text := 'SELECT * FROM TestSQL,TestSQL2 WHERE TestSQL.id = TestSQL2.id ORDER BY TestSQL.str';
//    query.SQL.Text := 'SELECT * FROM TestSQL,TestSQL2 WHERE TestSQL.id = TestSQL2.id';
    query.Open;

 WriteToProcessLog(Caption + 'join opened ');
    if (not query.ReadOnly) then
     WriteToErrorLog(Caption+'join returns live result');
    if (query.RecordCount <> 3) then
     WriteToErrorLog(Caption+'join returns invalid result');
    if (query.FieldCount <> 4) then
     WriteToErrorLog(Caption+'join returns invalid result #1');
    query.First;
    Count := 0;
    while Not query.Eof do
     begin
      Inc(Count);
      query.Next;
     end;
    if (Count <> 3) then
     WriteToErrorLog(Caption+'join returns invalid result #2');
    query.Close;
 WriteToProcessLog(Caption + 'JOIN passed ');

 WriteToProcessLog(Caption + 'JOIN passed ');
    query.RequestLive := False;
    query.SQL.Text := 'SELECT * FROM TestSQL2 WHERE str = :P_STR';
    query.ParamByName('P_STR').AsString := 'bbb';
    query.Open;
    if (not query.ReadOnly) then
     WriteToErrorLog(Caption+'live query returned instead of read only');
    if (query.RecordCount <> 1) then
     WriteToErrorLog(Caption+'select with params failed #1 - invalid record count');
    if (query.FieldByName('str').AsString <> 'bbb') then
     WriteToErrorLog(Caption+'select with params failed #1 - invalid record');
  WriteToProcessLog(Caption + 'Not live query on single table passed ');

   finally
    query.SQL.Text := 'DROP TABLE TestSQL; DROP TABLE TempTable; DROP TABLE TestSQL2; DROP TABLE TestSQL;';
    query.ExecSQL;
    remoteDB.Close;
  end;
 WriteToProcessLog(Caption + 'Finished');
{$ENDIF}
end;

procedure TUnitTestCSDatabase.TestVCL;
var
    Caption:      String;
    fh: Integer;
begin
  Caption := 'TUnitTestCSDatabase.TestVCL - ';
  WriteToProcessLog(Caption + 'starting ...');
  RemoteDBName := 'RemoteDB';
{$IFNDEF EXTERNAL_SERVER}
  server := TACRServer.Create(nil);
{$ENDIF}
  db := TACRDatabase.Create(nil);
  remoteDB := TACRDatabase.Create(nil);
  table := TACRTable.Create(nil);
  query := TACRQuery.Create(nil);
  try

{$IFDEF EXTERNAL_SERVER}
// external server
   RunExe(ServerExeName);
   remoteDB.ConnectionParams.ServerID := 0;
   remoteDB.ConnectionParams.DatabaseName := 'TestDB';
{$ELSE}
// built-in server
   // create local db
   db.DatabaseFileName := TempDir+'serverdb.adb';
   db.DatabaseName := 'LocalDB';
   db.CryptoParams.CryptoAlgorithm := craBlowfish;
   db.CryptoParams.CryptoMode := acmCBC;
   db.CryptoParams.Password := 'The Password';
   db.CreateDatabase;


{$IFDEF D6H}
   sleep(100);
{$ENDIF}
   WriteToProcessLog(Caption + 'db created...');
   server.LoadDefaultSettings;
   server.ServerID := 111;
   server.DatabaseNames.Clear;
   server.DatabaseNames.Add(RemoteDBName);
   server.DatabaseFileNames.Clear;
   server.DatabaseFileNames.Add(db.DatabaseFileName);
   server.SaveSettingsToConfigFile;
   server.Active := True;
   WriteToProcessLog(Caption + 'server active');

// fast local settings
   remoteDB.ConnectionParams.ServerID := 111;
{$ENDIF}
   remoteDB.LocalDatabase := False;
   remoteDB.ConnectionParams.NetworkSettings.RestoreDefaultSettings := acrLocal;
   remoteDB.ConnectionParams.NetworkSettings.ConnectDelay := 100;
   remoteDB.ConnectionParams.NetworkSettings.ConnectRetryCount := 3;
   remoteDB.ConnectionParams.NetworkSettings.StartReceiveTimeOut := 3000;
   remoteDB.ConnectionParams.NetworkSettings.UseServerSettings := False;

   // test uncompressed and unencrypted network traffic
   WriteToProcessLog(Caption + 'testing without compression and without encryption...');
   remoteDB.ConnectionParams.CompressionAlgorithm := caNone;
   remoteDB.ConnectionParams.CryptoParams.CryptoAlgorithm := craNone;
   TestDatabase;
   TestTable;
   TestQuery;
   WriteToProcessLog(Caption + 'testing without compression and without encryption... OK');

{$IFNDEF EXTERNAL_SERVER}
   //test compressed and unencrypted network traffic
   WriteToProcessLog(Caption + 'testing with compression and without encryption...');
   remoteDB.Close;
   remoteDB.ConnectionParams.CompressionAlgorithm := caZLIB;
   remoteDB.ConnectionParams.CompressionMode := 5;
   remoteDB.ConnectionParams.CryptoParams.CryptoAlgorithm := craNone;
   TestDatabase;
   TestTable;
   TestQuery;
   WriteToProcessLog(Caption + 'testing with compression and without encryption... OK');

   //test uncompressed and encrypted network traffic
   WriteToProcessLog(Caption + 'testing without compression and with encryption...');
   remoteDB.Close;
   remoteDB.ConnectionParams.CompressionAlgorithm := caNone;
   remoteDB.ConnectionParams.CryptoParams.CryptoAlgorithm := craRijndael_256;
   server.Active := False;
   server.CryptoParams.CryptoAlgorithm := craRijndael_256;
   server.SaveSettingsToConfigFile;
   server.Active := True;
   TestDatabase;
   TestTable;
   TestQuery;
   WriteToProcessLog(Caption + 'testing without compression and with encryption...OK');

   //test compressed and encrypted network traffic
   WriteToProcessLog(Caption + 'testing with compression and with encryption...');
   remoteDB.Close;
   remoteDB.ConnectionParams.CompressionAlgorithm := caBZIP;
   remoteDB.ConnectionParams.CompressionMode := 5;
   remoteDB.ConnectionParams.CryptoParams.CryptoAlgorithm := craRijndael_256;
   remoteDB.ConnectionParams.CryptoParams.MakeRandomKey(20);
   server.Active := False;
   server.CryptoParams.Assign(remoteDB.ConnectionParams.CryptoParams);
   server.SaveSettingsToConfigFile;
   server.Active := True;
   TestDatabase;
   TestTable;
   TestQuery;
   WriteToProcessLog(Caption + 'testing with compression and with encryption...OK');
{$ENDIF}

  finally
   query.Free;
   table.Free;
   remoteDB.Free;
{$IFDEF EXTERNAL_SERVER}
   ShutdownServer;
{$ELSE}
   server.Free;
   WriteToProcessLog(Caption + 'deleting db...');
   if (db.Connected) then
    raise Exception.Create('Shit!');
   sleep(500);
{
   repeat
    fh := SysUtils.FileOpen(db.DatabaseFileName,fmOpenReadWrite or fmShareExclusive);
    sleep(50);
   until (fh>=0);
   SysUtils.FileClose(fh);
}
   WriteToProcessLog(Caption + 'deleting database...');
   db.DeleteDatabase;
   WriteToProcessLog(Caption + 'deleting database...OK');
{$IFDEF D6H}
//   sleep(100);
{$ENDIF}
   if (db.Exists) then
    WriteToErrorLog(Caption + '> Local db is not deleted')
   else
    WriteToProcessLog(Caption + 'deleted ok...');
   db.Free;
   WriteToProcessLog(Caption + 'db destroyed');
{$ENDIF}
  end;

WriteToProcessLog('TUnitTestCSDatabase.TestVCL - finished!!!');
end;


procedure TUnitTestCSDatabase.DoOnSQL1(
                      Sender:     TComponent;
                      ClientInfo: TACRClientInfo;
                      Params:     TACRSQLParams;
{$IFDEF ACR5H}
                      var SQL:    WideString;
{$ELSE}
                      var SQL:    AnsiString;
{$ENDIF}
                      var Abort:  Boolean
                               );
begin

 if (ClientInfo.Application = '') then
  WriteToErrorLog('TUnitTestCSDatabase.TestOnSQL - OnSQL event has invlid application');
 if (ClientInfo.Host = '') then
  WriteToErrorLog('TUnitTestCSDatabase.TestOnSQL - OnSQL event has invlid host');
 if (ClientInfo.DatabaseName = '') then
  WriteToErrorLog('TUnitTestCSDatabase.TestOnSQL - OnSQL event has invlid database name');
 if (ClientInfo.DatabaseFileName = '') then
  WriteToErrorLog('TUnitTestCSDatabase.TestOnSQL - OnSQL event has invlid database file name');

 if (Pos('table1',LowerCase(SQL)) > 0) then
  SQL := StringReplace(SQL,'table1','table2',[rfReplaceAll,rfIgnoreCase]);
end; // DoOnSQL1


procedure TUnitTestCSDatabase.DoOnSQL2(
                      Sender:     TComponent;
                      ClientInfo: TACRClientInfo;
                      Params:     TACRSQLParams;
{$IFDEF ACR5H}
                      var SQL:    WideString;
{$ELSE}
                      var SQL:    AnsiString;
{$ENDIF}
                      var Abort:  Boolean
                               );
begin
 Abort := True;
end; // DoOnSQL2

procedure TUnitTestCSDatabase.DoOnSQL3(
                      Sender:     TComponent;
                      ClientInfo: TACRClientInfo;
                      Params:     TACRSQLParams;
{$IFDEF ACR5H}
                      var SQL:    WideString;
{$ELSE}
                      var SQL:    AnsiString;
{$ENDIF}
                      var Abort:  Boolean
                               );
begin
 if (Pos('f_str',LowerCase(SQL)) > 0) then
  SQL := StringReplace(SQL,'f_str','str',[rfReplaceAll,rfIgnoreCase]);
 Params.GetParamByName('p_str').AsString := 'aaa';
end; // DoOnSQL1



procedure TUnitTestCSDatabase.TestOnSQL;
var
    Caption:      String;
begin
  Caption := 'TUnitTestCSDatabase.TestOnSQL - ';
  WriteToProcessLog(Caption + 'starting...');
  RemoteDBName := 'RemoteDB';
  server := TACRServer.Create(nil);
  db := TACRDatabase.Create(nil);
  remoteDB := TACRDatabase.Create(nil);
  query := TACRQuery.Create(nil);
  try
  WriteToProcessLog(Caption + 'starting... components created');
   // create local db
   db.DatabaseFileName := TempDir+'serverdb1.adb';
   db.DatabaseName := 'LocalDB';
   db.CreateDatabase;

   WriteToProcessLog(Caption + 'db created...');

   server.LoadDefaultSettings;
   server.ServerID := 111;
   server.DatabaseNames.Clear;
   server.DatabaseNames.Add(RemoteDBName);
   server.DatabaseFileNames.Clear;
   server.DatabaseFileNames.Add(db.DatabaseFileName);
   server.SaveSettingsToConfigFile;
   server.Active := True;

   remoteDB.LocalDatabase := False;
   remoteDB.ConnectionParams.ServerID := 111;
   remoteDB.ConnectionParams.DatabaseName := RemoteDBName;

   remoteDB.Open;
   query.DatabaseName := remoteDB.DatabaseName;
   query.SQL.Text := 'DROP TABLE Table1; DROP TABLE Table2; CREATE TABLE Table1 (id AutoInc, str char(100));CREATE TABLE Table2 (id AutoInc);INSERT INTO Table1(str) values ("aaa");';
   query.ExecSQL;

   query.SQL.Text := 'SELECT COUNT(*) FROM Table1';
   query.Open;
   if (query.Fields[0].AsInteger <> 1) then
     WriteToErrorLog(Caption + 'select without event failed');
   query.Close;

   server.OnSQL := DoOnSQL1;
   query.Open;
   if (query.Fields[0].AsInteger <> 0) then
     WriteToErrorLog(Caption + 'select with event 1 failed');
   query.Close;

   query.SQL.Text := 'SELECT COUNT(*) FROM Table1 WHERE f_str = :P_STR';
   query.ParamByName('P_STR').AsString := 'abbbdd';
   server.OnSQL := DoOnSQL3;
   query.Open;
   if (query.Fields[0].AsInteger <> 1) then
     WriteToErrorLog(Caption + 'select with event 1 and params failed');
   query.Close;

   query.SQL.Text := 'SELECT COUNT(*) FROM Table1 WHERE f_str <> :P_STR';
   query.ParamByName('P_STR').AsString := 'aaa';
   server.OnSQL := DoOnSQL3;
   query.Open;
   if (query.Fields[0].AsInteger <> 0) then
     WriteToErrorLog(Caption + 'select with event 1 and params failed #2');
   query.Close;

   if (FTestExceptions) then
    begin
     WriteToProcessLog(Caption + 'testing exceptions .... ');
     query.Close;
     server.OnSQL := DoOnSQL2;
     try
       query.Open;
       WriteToErrorLog(Caption + 'select with event 2 failed - abort was not called');
     except
       WriteToProcessLog(Caption + 'select with event 2 failed - abort was called ok');
     end;
     WriteToProcessLog(Caption + 'testing exceptions .... ok');
    end;

  finally
   query.Free;
   remoteDB.Free;
   server.Free;
   WriteToProcessLog(Caption + 'deleting db...');
   sleep(100);
   db.DeleteDatabase;
   if (db.Exists) then
    WriteToErrorLog(Caption + '> Local db is not deleted')
   else
    WriteToProcessLog(Caption + 'deleted ok...');
   db.Free;
   WriteToProcessLog(Caption + 'db destroyed');
  end;
end; // TestOnSQL1


procedure TUnitTestCSDatabase.TestEncryption;
var
    Caption:      String;
begin
  Caption := 'TUnitTestCSDatabase.TestEncryption - ';
  RemoteDBName := 'RemoteDB';
  server := TACRServer.Create(nil);
  db := TACRDatabase.Create(nil);
  remoteDB := TACRDatabase.Create(nil);
  try
   // create local db
   db.DatabaseFileName := TempDir+'serverdb1.adb';
   db.DatabaseName := 'LocalDB';
   db.CreateDatabase;

   WriteToProcessLog(Caption + 'db created...');

   server.LoadDefaultSettings;
   server.ServerID := 111;
   server.DatabaseNames.Clear;
   server.DatabaseNames.Add(RemoteDBName);
   server.DatabaseFileNames.Clear;
   server.DatabaseFileNames.Add(db.DatabaseFileName);
   server.CryptoParams.CryptoAlgorithm := craRijndael_256;
   server.CryptoParams.Password := 'test';
   server.SaveSettingsToConfigFile;
   server.Active := True;

   remoteDB.LocalDatabase := False;
// fast local settings
   remoteDB.ConnectionParams.NetworkSettings.RestoreDefaultSettings := acrLocal;
{
   remoteDB.ConnectionParams.NetworkSettings.ConnectDelay := 10;
   remoteDB.ConnectionParams.NetworkSettings.ConnectRetryCount := 2;
}
   remoteDB.ConnectionParams.NetworkSettings.StartReceiveTimeOut := 3000;
   remoteDB.ConnectionParams.NetworkSettings.UseServerSettings := False;

   remoteDB.ConnectionParams.ServerID := 111;
   remoteDB.ConnectionParams.DatabaseName := RemoteDBName;
   remoteDB.ConnectionParams.RemoteHost := ACRDefaultHost; //server.LocalHost;
   remoteDB.ConnectionParams.RemotePort := server.LocalPort;

   remoteDB.ConnectionParams.CryptoParams.CryptoAlgorithm := craRijndael_256;
   remoteDB.ConnectionParams.CryptoParams.Password := 'test';
   try
    remoteDB.Open;
    remoteDB.Close;
    sleep(100);
    WriteToProcessLog(Caption+' connect with craRijndael_256 and correct password - ok!');
   except
    WriteToErrorLog(Caption+' connect with craRijndael_256 and correct password failed!');
   end;
   remoteDB.ConnectionParams.CryptoParams.CryptoAlgorithm := craNone;
   remoteDB.ConnectionParams.CryptoParams.Password := ACRDefaultPassword;
   try
    remoteDB.Open;
    WriteToErrorLog(Caption+' can connect with craNone and invalid password');
    remoteDB.Close;
   except
    WriteToProcessLog(Caption+' connect with craNone failed - ok!');
   end;

{
   remoteDB.ConnectionParams.CryptoParams.Password := 'test';
   try
    remoteDB.Open;
    WriteToErrorLog(Caption+' can connect with craNone and correct password');
    remoteDB.Close;
   except
    WriteToProcessLog(Caption+' connect with craNone and correct password failed - ok!');
   end;

   remoteDB.ConnectionParams.CryptoParams.CryptoAlgorithm := craRijndael_256;
   remoteDB.ConnectionParams.CryptoParams.Password := 'Test';
   try
    remoteDB.Open;
    WriteToErrorLog(Caption+' can connect with craRijndael_256 and invalid password');
    remoteDB.Close;
   except
    WriteToProcessLog(Caption+' connect with craRijndael_256 and invalid password failed - ok!');
   end;
}
  finally
   remoteDB.Free;
   server.Free;
   WriteToProcessLog(Caption + 'deleting db...');
   sleep(100);
   db.DeleteDatabase;
   if (db.Exists) then
    WriteToErrorLog(Caption + '> Local db is not deleted')
   else
    WriteToProcessLog(Caption + 'deleted ok...');
   db.Free;
   WriteToProcessLog(Caption + 'db destroyed - test complete');
  end;
end; // TestEncryption


function TUnitTestCSDatabase.AllocateAndGenerateRandomBuffer(Size: Integer): PChar;
var i: Integer;
begin
  if (Size <= 0) then
   Result := nil
  else
   begin
     Result := MemoryManager.GetMem(Size);
     for i := 0 to Size - 1 do
      PChar(Result+i)^ := Chr(Random(MaxInt) mod 256);
   end;
end;


procedure TUnitTestCSDatabase.CompareBuffers(Buffer1, Buffer2: PChar; bStream: Boolean = false);
var i,size1,size2: Integer;
    s: string;
begin
  if (bStream) then
   s := ' stream test ';
  if (Buffer1 = nil) then
   size1 := 0
  else
   size1 := MemoryManager.GetMemoryBufferSize(Buffer1);
  if (Buffer2 = nil) then
   size2 := 0
  else
   size2 := MemoryManager.GetMemoryBufferSize(Buffer2);
  if (size1 <> size2) then
   WriteToErrorLog(TestCaption+' buffers have not equal sizes'+s)
  else
   if (size1 > 0) then
    for i := 0 to size1-1 do
     if (PChar(Buffer1+i)^ <> PChar(Buffer2+i)^) then
      begin
       WriteToErrorLog(TestCaption+' buffers have not equal content'+s);
       break;
      end;
end;


procedure TUnitTestCSDatabase.CompareStreams(Stream1, Stream2: TStream);
var buf1,buf2: PChar;
begin
 if (Stream1.Size <> Stream2.Size) then
   WriteToErrorLog(TestCaption+' streams have not equal sizes')
  else
   if (Stream1.Size > 0) then
    begin
     buf1 := MemoryManager.GetMem(Stream1.Size);
     buf2 := MemoryManager.GetMem(Stream1.Size);
     try
       Stream1.Position := 0;
       Stream2.Position := 0;
       Stream1.ReadBuffer(buf1^,Stream1.Size);
       Stream2.ReadBuffer(buf2^,Stream1.Size);
       CompareBuffers(buf1,buf2,true);
     finally
       MemoryManager.FreeAndNilMem(buf1);
       MemoryManager.FreeAndNilMem(buf2);
     end;
    end;
end;


procedure TUnitTestCSDatabase.ClientReceiveTextMessage(const Text: String);
begin
 client_msg_string := Text;
 FClientMessageReceived := True;
end;


procedure TUnitTestCSDatabase.ClientReceiveTextBinary(Buffer: PChar; Size: Integer);
begin
 client_msg_size := Size;
 if Size <= 0 then
  client_msg_buffer := Buffer
 else
  begin
   client_msg_buffer := MemoryManager.GetMem(Size);
   Move(Buffer^,client_msg_buffer^,Size);
  end;
 FClientMessageReceived := True;
end;


procedure TUnitTestCSDatabase.ClientReceiveTextStream(Stream: TStream);
begin
  client_msg_stream.LoadFromStream(Stream);
  FClientMessageReceived := True;
end;


procedure TUnitTestCSDatabase.ServerReceiveTextMessage(const Client: TACRClientInfo; const Text: String);
begin
 server_msg_string := Text;
 server_msg_clientInfo := Client;
 FServerMessageReceived := True;
end;

procedure TUnitTestCSDatabase.ServerReceiveTextBinary(const Client: TACRClientInfo; Buffer: PChar; Size: Integer);
begin
 server_msg_size := Size;
 if Size <= 0 then
  server_msg_buffer := Buffer
 else
  begin
   server_msg_buffer := MemoryManager.GetMem(Size);
   Move(Buffer^,server_msg_buffer^,Size);
  end;
 server_msg_clientInfo := Client;
 FServerMessageReceived := True;
end;


procedure TUnitTestCSDatabase.ServerReceiveTextStream(const Client: TACRClientInfo; Stream: TStream);
begin
  server_msg_clientInfo := Client;
  server_msg_stream.LoadFromStream(Stream);
  FServerMessageReceived := True;
end;


procedure TUnitTestCSDatabase.TestMessagesSimple;
var Caption:    String;
    msg_et:     String;
    Clients:    TACRClientInfoArray;
    msg_clientinfo: TACRClientInfo;
    buffer_et:   PChar;
    buffer_size: Integer;
    stream_et:   TACRMemoryStream;

  procedure ResetClientInfo;
  begin
   server_msg_clientInfo.Host := '';
   server_msg_clientInfo.Port := -1;
   server_msg_clientInfo.SessionID := -1;
   server_msg_clientInfo.Application := '';
   server_msg_clientInfo.DatabaseName := '';
   server_msg_clientInfo.DatabaseFileName := '';
  end;

  function IsClientInfoInvalid: Boolean;
  begin
    Result := (UpperCase(server_msg_clientInfo.Host) <> UpperCase(msg_clientInfo.Host)) or
      (server_msg_clientInfo.Port <> msg_clientInfo.Port) or
      (server_msg_clientInfo.SessionID <> msg_clientInfo.SessionID) or
      (UpperCase(server_msg_clientInfo.Application) <> UpperCase(msg_clientInfo.Application)) or
      (UpperCase(server_msg_clientInfo.DatabaseName) <> UpperCase(msg_clientInfo.DatabaseName)) or
      (UpperCase(server_msg_clientInfo.DatabaseFileName) <> UpperCase(msg_clientInfo.DatabaseFileName));
  end;

begin
  Caption := 'UnitTestCSDatabase TestMessagesSimple - ';
  TestCaption := Caption;
  msg_et := Caption;

  WriteToProcessLog(Caption+'test started');
  RemoteDBName := 'RemoteDB';
  server := TACRServer.Create(nil);
  db := TACRDatabase.Create(nil);
  remoteDB := TACRDatabase.Create(nil);
  stream_et := TACRMemoryStream.Create();
  client_msg_stream := TACRMemoryStream.Create();
  server_msg_stream := TACRMemoryStream.Create();
  buffer_size := MinBufferSize;
  buffer_et := AllocateAndGenerateRandomBuffer(buffer_size);
  try
   // create local db
   db.DatabaseFileName := TempDir+'serverdb_msg.adb';
   db.DatabaseName := 'LocalDB';
   db.CreateDatabase;

   WriteToProcessLog(Caption + 'db created...');

   server.LoadDefaultSettings;
   server.ServerID := 11;
   server.DatabaseNames.Clear;
   server.DatabaseNames.Add(RemoteDBName);
   server.DatabaseFileNames.Clear;
   server.DatabaseFileNames.Add(db.DatabaseFileName);
   server.SaveSettingsToConfigFile;
   server.Active := True;

   remoteDB.LocalDatabase := False;
   remoteDB.ConnectionParams.ServerID := server.ServerID;
   remoteDB.ConnectionParams.DatabaseName := RemoteDBName;
   remoteDB.ConnectionParams.NetworkSettings.WaitForTimeOut := 300; // for quick free

   remoteDB.Open;

   remoteDB.OnReceiveTextMessage := ClientReceiveTextMessage;
   remoteDB.OnReceiveBinaryMessage := ClientReceiveTextBinary;
   remoteDB.OnReceiveStreamMessage := ClientReceiveTextStream;
   server.OnReceiveTextMessage := ServerReceiveTextMessage;
   server.OnReceiveBinaryMessage := ServerReceiveTextBinary;
   server.OnReceiveStreamMessage := ServerReceiveTextStream;

   // test server sending
   server.GetClients(Clients);
   if (Length(Clients) <> 1) then
    WriteToErrorLog(TestCaption+' invalid clients length #1');


   msg_clientInfo := Clients[0];
   client_msg_string := msg_et+'aaa';
   FClientMessageReceived := False;
   WriteToProcessLog(TestCaption+' sending message #1 ...');
   server.SendMessage(msg_clientInfo,msg_et);
   WriteToProcessLog(TestCaption+' receiving message #1 ...');
   while (not FClientMessageReceived) do
    sleep(100);
   if (client_msg_string = msg_et) then
     WriteToProcessLog(TestCaption+' sending message #1 ... ok. Message received is equal to message has beeen sent.')
   else
     WriteToErrorLog(TestCaption+' sending message #1 ... failed. Message received is not equal to message has beeen sent.');


   client_msg_string := msg_et+'aaa';
   FClientMessageReceived := False;
   WriteToProcessLog(TestCaption+' sending message #2 ...');
   server.SendMessage(msg_clientInfo,'');
   WriteToProcessLog(TestCaption+' receiving message #2 ...');
   while (not FClientMessageReceived) do
    sleep(100);
   if (client_msg_string = '') then
     WriteToProcessLog(TestCaption+' sending message #2 ... ok. Message received is equal to message has beeen sent.')
   else
     WriteToErrorLog(TestCaption+' sending message #2 ... failed. Message received is not equal to message has beeen sent.');

   ResetClientInfo;
   server_msg_string := msg_et+'aaa';
   FServerMessageReceived := False;
   WriteToProcessLog(TestCaption+' sending message #3 ...');
   remoteDB.SendMessage(msg_et);
   WriteToProcessLog(TestCaption+' receiving message #3 ...');
   while (not FServerMessageReceived) do
    sleep(100);
   if (server_msg_string = msg_et) then
     WriteToProcessLog(TestCaption+' sending message #3 ... ok. Message received is equal to message has beeen sent.')
   else
     WriteToErrorLog(TestCaption+' sending message #3 ... failed. Message received is not equal to message has beeen sent.');
   if IsClientInfoInvalid then
    WriteToErrorLog(TestCaption+' sending message #3 ... failed. Message received from other client.');

   ResetClientInfo;
   server_msg_string := msg_et+'aaa';
   FServerMessageReceived := False;
   WriteToProcessLog(TestCaption+' sending message #4 ...');
   remoteDB.SendMessage('');
   WriteToProcessLog(TestCaption+' receiving message #4 ...');
   while (not FServerMessageReceived) do
    sleep(100);
   if (server_msg_string = '') then
     WriteToProcessLog(TestCaption+' sending message #4 ... ok. Message received is equal to message has beeen sent.')
   else
     WriteToErrorLog(TestCaption+' sending message #4 ... failed. Message received is not equal to message has beeen sent.');
   if IsClientInfoInvalid then
    WriteToErrorLog(TestCaption+' sending message #4 ... failed. Message received from other client.');


   // send buffer
   msg_clientInfo := Clients[0];
   client_msg_buffer := nil;
   client_msg_size := 0;
   FClientMessageReceived := False;
   WriteToProcessLog(TestCaption+' sending message #5 ...');
   server.SendMessage(msg_clientInfo,buffer_et,buffer_size);
   WriteToProcessLog(TestCaption+' receiving message #5 ...');
   while (not FClientMessageReceived) do
    sleep(100);
   CompareBuffers(client_msg_buffer,buffer_et);
   MemoryManager.FreeAndNilMem(client_msg_buffer);
   WriteToProcessLog(TestCaption+' sending message #5 ... complete');

   msg_clientInfo := Clients[0];
   client_msg_buffer := PChar(Self);
   client_msg_size := -100;
   FClientMessageReceived := False;
   WriteToProcessLog(TestCaption+' sending message #6 ...');
   server.SendMessage(msg_clientInfo,nil,0);
   WriteToProcessLog(TestCaption+' receiving message #6 ...');
   while (not FClientMessageReceived) do
    sleep(100);
   CompareBuffers(client_msg_buffer,nil);
   WriteToProcessLog(TestCaption+' sending message #6 ... complete');

   ResetClientInfo;
   server_msg_buffer := nil;
   server_msg_size := 0;
   FServerMessageReceived := False;
   WriteToProcessLog(TestCaption+' sending message #7 ...');
   remoteDB.SendMessage(buffer_et,buffer_size);
   WriteToProcessLog(TestCaption+' receiving message #7 ...');
   while (not FServerMessageReceived) do
    sleep(100);
   CompareBuffers(server_msg_buffer,buffer_et);
   MemoryManager.FreeAndNilMem(server_msg_buffer);
   WriteToProcessLog(TestCaption+' sending message #7 ... complete');
   if IsClientInfoInvalid then
    WriteToErrorLog(TestCaption+' sending message #7 ... failed. Message received from other client.');

   ResetClientInfo;
   server_msg_buffer := PChar(Self);
   server_msg_size := -100;
   FServerMessageReceived := False;
   WriteToProcessLog(TestCaption+' sending message #8 ...');
   remoteDB.SendMessage(nil,0);
   WriteToProcessLog(TestCaption+' receiving message #8 ...');
   while (not FServerMessageReceived) do
    sleep(100);
   CompareBuffers(server_msg_buffer,nil);
   WriteToProcessLog(TestCaption+' sending message #8 ... complete');
   if IsClientInfoInvalid then
    WriteToErrorLog(TestCaption+' sending message #8 ... failed. Message received from other client.');

   // streams

   // stream with data
   stream_et.Size := 0;
   stream_et.Position := 0;
   stream_et.WriteBuffer(buffer_et^,Buffer_Size);
   msg_clientInfo := Clients[0];
   client_msg_stream.Size := 0;
   FClientMessageReceived := False;
   WriteToProcessLog(TestCaption+' sending message #9 ...');
   server.SendMessage(msg_clientInfo,stream_et);
   WriteToProcessLog(TestCaption+' receiving message #9 ...');
   while (not FClientMessageReceived) do
    sleep(100);
   CompareStreams(client_msg_stream,stream_et);
   WriteToProcessLog(TestCaption+' sending message #9 ... complete');

   // stream empty
   msg_clientInfo := Clients[0];
   client_msg_stream.Size := 10;
   stream_et.Size := 0;
   FClientMessageReceived := False;
   WriteToProcessLog(TestCaption+' sending message #10 ...');
   server.SendMessage(msg_clientInfo,stream_et);
   WriteToProcessLog(TestCaption+' receiving message #10 ...');
   while (not FClientMessageReceived) do
    sleep(100);
   CompareStreams(client_msg_stream,stream_et);
   WriteToProcessLog(TestCaption+' sending message #10 ... complete');

   // stream with data
   stream_et.Size := 0;
   stream_et.Position := 0;
   stream_et.WriteBuffer(buffer_et^,Buffer_Size);
   ResetClientInfo;
   server_msg_stream.size := 0;
   FServerMessageReceived := False;
   WriteToProcessLog(TestCaption+' sending message #11 ...');
   remoteDB.SendMessage(stream_et);
   WriteToProcessLog(TestCaption+' receiving message #11 ...');
   while (not FServerMessageReceived) do
    sleep(100);
   CompareStreams(server_msg_stream,stream_et);
   WriteToProcessLog(TestCaption+' sending message #11 ... complete');
   if IsClientInfoInvalid then
    WriteToErrorLog(TestCaption+' sending message #11 ... failed. Message received from other client.');

   ResetClientInfo;
   // stream empty
   server_msg_stream.Size := 10;
   stream_et.Size := 0;
   FServerMessageReceived := False;
   WriteToProcessLog(TestCaption+' sending message #12 ...');
   remoteDB.SendMessage(stream_et);
   WriteToProcessLog(TestCaption+' receiving message #12 ...');
   while (not FServerMessageReceived) do
    sleep(100);
   CompareStreams(server_msg_stream,stream_et);
   WriteToProcessLog(TestCaption+' sending message #12 ... complete');
   if IsClientInfoInvalid then
    WriteToErrorLog(TestCaption+' sending message #12 ... failed. Message received from other client.');

 WriteToProcessLog(TestCaption+'nil clients...');
   Clients := nil;
{
   if (FTestExceptions) then
    begin
     WriteToProcessLog(Caption + 'testing exceptions .... ');
     WriteToProcessLog(Caption + 'testing exceptions .... ok');
    end;
}
  finally
   WriteToProcessLog(Caption + ' free remoteDB...');
   remoteDB.Free;
   WriteToProcessLog(Caption + ' free server...');
   server.Free;
   WriteToProcessLog(Caption + 'deleting db...');
   sleep(100); { TODO -oLeo : Is this the same shit? It's your code... }
   db.DeleteDatabase;
   if (db.Exists) then
    WriteToErrorLog(Caption + '> Local db is not deleted')
   else
    WriteToProcessLog(Caption + 'deleted ok...');
   db.Free;
   WriteToProcessLog(Caption + 'db destroyed');
   stream_et.Free;
   client_msg_stream.Free;
   server_msg_stream.Free;
   MemoryManager.FreeAndNilMem(buffer_et);
   WriteToProcessLog(Caption + 'streams destroyed');
  end;
  WriteToProcessLog(Caption+'test finished');
end;


procedure TUnitTestCSDatabase.TestMessagesMultiThread;
var Caption: String;
begin
  Caption := 'UnitTestCSDatabase TestMessagesMultiThread - ';
  WriteToProcessLog(Caption+'test started');

  WriteToProcessLog(Caption+'test finished');
end;


procedure TUnitTestCSDatabase.TestMessages;
begin
  TestMessagesSimple;
  TestMessagesMultiThread;
end;


procedure TUnitTestCSDatabase.TestShort;
begin
  FTestExceptions := False;
  WriteToProcessLog('UnitTestCSDatabase - short test started');
  CheckAction(TestVCL, 'TUnitTestCSDatabase.TestVCL');
WriteToProcessLog('TUnitTestCSDatabase.TestVCL - complete!');
{$IFNDEF EXTERNAL_SERVER}
  CheckAction(TestOnSQL, 'TUnitTestCSDatabase.TestOnSQL event');
  CheckAction(TestMessages, 'TUnitTestCSDatabase.TestMessages');
{$ENDIF}
  WriteToProcessLog('UnitTestCSDatabase - short test finished');
end;


procedure TUnitTestCSDatabase.TestExceptions;
begin
{$IFNDEF EXTERNAL_SERVER}
  FTestExceptions := True;
  WriteToProcessLog('UnitTestCSDatabase - Exceptions test started');
  CheckAction(TestEncryption, 'TUnitTestCSDatabase.TestEncryption');
  CheckAction(TestOnSQL, 'TUnitTestCSDatabase.TestOnSQL event');
  WriteToProcessLog('UnitTestCSDatabase - Exceptions test finished');
{$ENDIF}  
end;

initialization
  UnitTestCSDatabase := TUnitTestCSDatabase.Create(UnitTestList);
{$IFDEF EXTERNAL_SERVER}
  ServerExeName := IncludeTrailingBackslash(ExtractFilePath(ParamStr(0)))+ServerExeName;
{$ENDIF}

finalization
  UnitTestCSDatabase.Free;


end.
