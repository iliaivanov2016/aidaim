unit utACRSQLPerformance;

interface

{$I UTConfig.Inc}
{$I ACRVer.Inc}

{$DEFINE TEST_LIVE}
{$DEFINE TEST_NOT_LIVE}
{$DEFINE TEST_DISK}
{$DEFINE TEST_MEMORY}

uses SysUtils, Classes, DB, Windows,
{$IFNDEF D6H}
      DBTables,
{$ELSE}
 {$IFDEF MSWINDOWS}
      DBTables,
 {$ENDIF}
{$ENDIF}
     DBClient,

     uTestList,
     ACRTypes,
     ACRConst,
{$IFDEF DEBUG_LOG}
     ACRDebug,
{$ENDIF}
     ACRSQLProcessor,
     ACRRelationalAlgebra,
     ACRVariant,
     ACRExpressions,
{$IFDEF ACR5H}
     ACRComMain,
{$ENDIF}
     ACRConverts,
     ACRMain;

const RecCount = 100000; // 100K
//const RecCount = 10000; // 10K

type
  TUnitTestACRSQLPerformance = class(TUnitTest)
   private
    FTime:     Cardinal;
    FRecCount: Integer;
    FDatabase: TACRDatabase;
    FTable:    TACRTable;
    FQuery:    TACRQuery;
    // in memory mode
    FMemQuery: TACRQuery;
    FMemTable: TACRTable;
   public
    procedure TestShort; override;
    procedure TestExceptions; override;
   protected
    procedure TestPerformance;
    procedure GenerateTestData;
    procedure Finalize;
    procedure CreateTableAndInsertRecord(Table: TACRTable);
    procedure TestSQL(
                SQLtext: string;
                Memory: Boolean;
                Live: Boolean
                );
    procedure RunTest(
                Memory: Boolean;
                Live: Boolean
                );
  end;

var UnitTestACRSQLPerformance: TUnitTestACRSQLPerformance;

implementation

procedure TUnitTestACRSQLPerformance.TestShort;
begin
  CheckAction(TestPerformance, 'Test SQL Performance');
end;


procedure TUnitTestACRSQLPerformance.TestExceptions;
begin
end;


procedure TUnitTestACRSQLPerformance.TestPerformance;
var t: Cardinal;
begin
 WriteToProcessLog('Starting SQL perfromance test ...');

 t := GetTickCount;
 GenerateTestData;
 t := GetTickCount - t;
 WriteToProcessLog('Generate data time = '+IntToStr(t));
 try

{$IFDEF TEST_MEMORY}
  {$IFDEF TEST_LIVE}
     RunTest(True,True);
  {$ENDIF}
  {$IFDEF TEST_NOT_LIVE}
     RunTest(True,False);
  {$ENDIF}
{$ENDIF}

{$IFDEF TEST_DISK}
  {$IFDEF TEST_LIVE}
   RunTest(False,True);
  {$ENDIF}
  {$IFDEF TEST_NOT_LIVE}
   RunTest(False,False);
  {$ENDIF}
{$ENDIF}
 finally
   Finalize;
 end;
 WriteToProcessLog('SQL perfromacne test complete');
end;

procedure TUnitTestACRSQLPerformance.GenerateTestData;
begin
 FDatabase := TACRDatabase.Create(nil);
 FQuery := TACRQuery.Create(nil);
 FTable := TACRTable.Create(nil);
 FMemQuery := TACRQuery.Create(nil);
 FMemTable := TACRTable.Create(nil);
 FDatabase.DatabaseName := 'TestSQLPerformance';
 FDatabase.DatabaseFileName := TempDir+'test_sql_performance.adb';
 FDatabase.CreateDatabase;
 FDatabase.Open;
 FQuery.DatabaseName := FDatabase.DatabaseName;
 FTable.DatabaseName := FDatabase.DatabaseName;
 FTable.TableName := 'test';
 FMemTable.InMemory := True;
 FMemTable.TableName := 'test';
 FMemQuery.InMemory := True;
{$IFDEF TEST_DISK}
 FTime := GetTickCount;
 CreateTableAndInsertRecord(FTable);
 FTime := GetTickCount - FTime;
 WriteToProcessLog(#13#10#13#10+'Insert record to DISK TABLE = '+IntToStr(FTime)+#13#10);
{$ENDIF}
{$IFDEF TEST_MEMORY}
 FTime := GetTickCount;
 CreateTableAndInsertRecord(FMemTable);
 FTime := GetTickCount - FTime;
 WriteToProcessLog(#13#10#13#10+'Insert record to MEMORY TABLE = '+IntToStr(FTime)+#13#10);
{$ENDIF}
end;

procedure TUnitTestACRSQLPerformance.Finalize;
begin
 FDatabase.Close;
 FDatabase.DeleteDatabase;
 FQuery.Free;
 FTable.Free;
 FMemQuery.SQL.Text := 'DROP TABLE test CASCADE';
 FMemQuery.ExecSQL;
 FMemQuery.Free;
 FMemTable.Free;
{$IFNDEF NODISK}
// FDatabase.DeleteDatabase;
{$ENDIF}
 FDatabase.Free;
end;

procedure TUnitTestACRSQLPerformance.CreateTableAndInsertRecord(
  Table: TACRTable);
var i: Integer;
begin
 Table.FieldDefs.Clear;
 Table.AdvFieldDefs.Clear;
 Table.IndexDefs.Clear;
 Table.AdvIndexDefs.Clear;
 Table.ForeignKeyDefs.Clear;
 Table.AdvFieldDefs.Add('id',aftAutoInc);
 Table.AdvFieldDefs.Add('str',aftChar,50);
 Table.AdvFieldDefs.Add('num',aftInteger,0);
 Table.IndexDefs.Add('PK','id',[ixUnique]);
 Table.IndexDefs.Add('str','str',[]);
 Table.CreateTable;
 Table.Open;
 if (not Table.InMemory) then
  FDatabase.StartTransaction;
 try
  for i := 1 to RecCount do
   begin
    Table.Insert;
    Table.FieldByName('str').AsString := 'Test! ID = '+IntToStr(i mod 10);
    Table.FieldByName('num').AsInteger := i;
    Table.Post;
   end;
 finally
  if (not Table.InMemory) then
   FDatabase.Commit(true);
  Table.Close;
 end;
end;

procedure TUnitTestACRSQLPerformance.TestSQL(SQLtext: string; Memory,
  Live: Boolean);
var q: TACRQuery;
begin
 if (Memory) then
  q := FMemQuery
 else
  q := FQuery;
 q.Close;
 WriteToProcessLog(#13#10#13#10+'SQL: '+#13#10+SQLText+
    #13#10+'Memory = '+BoolToStr(Memory,True)+
    #13#10+'Live = '+BoolToStr(Live,True)
    );
 FTime := GetTickCount;
 q.SQL.Text := SQLtext;
 q.RequestLive := Live;
 q.Open;
 FTime := GetTickCount - FTime;
 FRecCount := q.RecordCount;
 WriteToProcessLog(#13#10#13#10+'SQL: '+#13#10+SQLText+
    #13#10+'Memory = '+BoolToStr(Memory,True)+
    #13#10+'Live = '+BoolToStr(Live,True)+
    #13#10+'RecordCount = '+IntToStr(q.RecordCount)+
    #13#10+'Time = '+IntToStr(FTime)
    );
 if (Live <> (not q.ReadOnly)) then
  WriteToErrorLog('Error - live flag ignored. '+#13#10+'SQL: '+#13#10+SQLText+
    #13#10+'Memory = '+BoolToStr(Memory,True)+
    #13#10+'Live = '+BoolToStr(Live,True)
    );
end;

procedure TUnitTestACRSQLPerformance.RunTest(Memory, Live: Boolean);
var SQLText: String;
    t1,t2: Cardinal;
begin
  SQLText := 'SELECT * FROM test WHERE id <= 100';
  TestSQL(SQLText,Memory,Live);
  if (FRecCount <> 100) then
   WriteToErrorLog('Error - invalid record count = '+IntToStr(FRecCount)+
    #13#10+'SQL: '+#13#10+SQLText+
    #13#10+'Memory = '+BoolToStr(Memory,True)+
    #13#10+'Live = '+BoolToStr(Live,True));
  t1 := FTime;

  SQLText := 'SELECT * FROM test WHERE num <= 100';
  TestSQL(SQLText,Memory,Live);
  if (FRecCount <> 100) then
   WriteToErrorLog('Error - invalid record count = '+IntToStr(FRecCount)+
    #13#10+'SQL: '+#13#10+SQLText+
    #13#10+'Memory = '+BoolToStr(Memory,True)+
    #13#10+'Live = '+BoolToStr(Live,True));
  t2 := FTime;
  if (t1 >= (Round(0.9 * t2))) then
   WriteToErrorLog('Error #1 - query does not use index'+
    #13#10+'Memory = '+BoolToStr(Memory,True)+
    #13#10+'Live = '+BoolToStr(Live,True)+
    #13#10+'Time1 = '+IntToStr(t1)+
    #13#10+'Time2 = '+IntToStr(t2)+
    #13#10+'Time limit t1 >= '+IntToStr(Round(0.9 * t2))
   );


  SQLText := 'SELECT * FROM test WHERE (LOWER(str) like "test%") AND (id <= 100)';
  TestSQL(SQLText,Memory,Live);
  if (FRecCount <> 100) then
   WriteToErrorLog('Error - invalid record count = '+IntToStr(FRecCount)+
    #13#10+'SQL: '+#13#10+SQLText+
    #13#10+'Memory = '+BoolToStr(Memory,True)+
    #13#10+'Live = '+BoolToStr(Live,True));
  t1 := FTime;

  SQLText := 'SELECT * FROM test WHERE (LOWER(str) like "test%") AND (num <= 100)';
  TestSQL(SQLText,Memory,Live);
  if (FRecCount <> 100) then
   WriteToErrorLog('Error - invalid record count = '+IntToStr(FRecCount)+
    #13#10+'SQL: '+#13#10+SQLText+
    #13#10+'Memory = '+BoolToStr(Memory,True)+
    #13#10+'Live = '+BoolToStr(Live,True));
  t2 := FTime;
  if (t1 >= (Round(0.9 * t2))) then
   WriteToErrorLog('Error #2 - query does not use index'+
    #13#10+'Memory = '+BoolToStr(Memory,True)+
    #13#10+'Live = '+BoolToStr(Live,True)+
    #13#10+'Time1 = '+IntToStr(t1)+
    #13#10+'Time2 = '+IntToStr(t2)+
    #13#10+'Time limit t1 >= '+IntToStr(Round(0.9 * t2))
   );

  SQLText := 'SELECT * FROM test WHERE id <= 1000 ORDER BY ID';
  TestSQL(SQLText,Memory,Live);
  if (FRecCount <> 1000) then
   WriteToErrorLog('Error - invalid record count = '+IntToStr(FRecCount)+
    #13#10+'SQL: '+#13#10+SQLText+
    #13#10+'Memory = '+BoolToStr(Memory,True)+
    #13#10+'Live = '+BoolToStr(Live,True));
  t1 := FTime;

  SQLText := 'SELECT * FROM test WHERE num <= 1000 ORDER BY ID';
  TestSQL(SQLText,Memory,Live);
  if (FRecCount <> 1000) then
   WriteToErrorLog('Error - invalid record count = '+IntToStr(FRecCount)+
    #13#10+'SQL: '+#13#10+SQLText+
    #13#10+'Memory = '+BoolToStr(Memory,True)+
    #13#10+'Live = '+BoolToStr(Live,True));
  t2 := FTime;
  if (t1 >= (Round(0.9 * t2))) then
   WriteToErrorLog('Error #3 - query does not use index'+
    #13#10+'Memory = '+BoolToStr(Memory,True)+
    #13#10+'Live = '+BoolToStr(Live,True)+
    #13#10+'Time1 = '+IntToStr(t1)+
    #13#10+'Time2 = '+IntToStr(t2)+
    #13#10+'Time limit t1 >= '+IntToStr(Round(0.9 * t2))
   )
   ;
if (not Live) then
begin
  SQLText := 'SELECT * FROM test WHERE id <= 1000 ORDER BY ID DESC';
  TestSQL(SQLText,Memory,Live);
  if (FRecCount <> 1000) then
   WriteToErrorLog('Error - invalid record count = '+IntToStr(FRecCount)+
    #13#10+'SQL: '+#13#10+SQLText+
    #13#10+'Memory = '+BoolToStr(Memory,True)+
    #13#10+'Live = '+BoolToStr(Live,True));
  t1 := FTime;

  SQLText := 'SELECT * FROM test WHERE num <= 1000 ORDER BY NUM';
  TestSQL(SQLText,Memory,Live);
  if (FRecCount <> 1000) then
   WriteToErrorLog('Error - invalid record count = '+IntToStr(FRecCount)+
    #13#10+'SQL: '+#13#10+SQLText+
    #13#10+'Memory = '+BoolToStr(Memory,True)+
    #13#10+'Live = '+BoolToStr(Live,True));
  t2 := FTime;
  if (t1 >= (Round(0.9 * t2))) then
   WriteToErrorLog('Error #4 - query does not use index'+
    #13#10+'Memory = '+BoolToStr(Memory,True)+
    #13#10+'Live = '+BoolToStr(Live,True)+
    #13#10+'Time1 = '+IntToStr(t1)+
    #13#10+'Time2 = '+IntToStr(t2)+
    #13#10+'Time limit t1 >= '+IntToStr(Round(0.9 * t2))
   );
end;

if (not Live) then
begin
  SQLText := 'SELECT TOP 10 * FROM test WHERE id <= 1000 ORDER BY ID';
  TestSQL(SQLText,Memory,Live);
  if (FRecCount <> 10) then
   WriteToErrorLog('Error - invalid record count = '+IntToStr(FRecCount)+
    #13#10+'SQL: '+#13#10+SQLText+
    #13#10+'Memory = '+BoolToStr(Memory,True)+
    #13#10+'Live = '+BoolToStr(Live,True));
  t1 := FTime;

  SQLText := 'SELECT * FROM test WHERE num <= 1000 ORDER BY ID';
  TestSQL(SQLText,Memory,Live);
  if (FRecCount <> 1000) then
   WriteToErrorLog('Error - invalid record count = '+IntToStr(FRecCount)+
    #13#10+'SQL: '+#13#10+SQLText+
    #13#10+'Memory = '+BoolToStr(Memory,True)+
    #13#10+'Live = '+BoolToStr(Live,True));
  t2 := FTime;
  if (t1 >= (Round(0.9 * t2))) then
   WriteToErrorLog('Error #5 - query does not use index'+
    #13#10+'Memory = '+BoolToStr(Memory,True)+
    #13#10+'Live = '+BoolToStr(Live,True)+
    #13#10+'Time1 = '+IntToStr(t1)+
    #13#10+'Time2 = '+IntToStr(t2)+
    #13#10+'Time limit t1 >= '+IntToStr(Round(0.9 * t2))
   );
end;

if (not Live) then
begin
  SQLText := 'SELECT TOP 100 * FROM test WHERE id <= 1000 ORDER BY ID DESC';
  TestSQL(SQLText,Memory,Live);
  if (FRecCount <> 100) then
   WriteToErrorLog('Error - invalid record count = '+IntToStr(FRecCount)+
    #13#10+'SQL: '+#13#10+SQLText+
    #13#10+'Memory = '+BoolToStr(Memory,True)+
    #13#10+'Live = '+BoolToStr(Live,True));
  t1 := FTime;
  SQLText := 'SELECT TOP 100 * FROM test WHERE num <= 1000 ORDER BY ID';
  TestSQL(SQLText,Memory,Live);
  if (FRecCount <> 100) then
   WriteToErrorLog('Error - invalid record count = '+IntToStr(FRecCount)+
    #13#10+'SQL: '+#13#10+SQLText+
    #13#10+'Memory = '+BoolToStr(Memory,True)+
    #13#10+'Live = '+BoolToStr(Live,True));
  t2 := FTime;
  if (t1 >= (Round(0.9 * t2))) then
   WriteToErrorLog('Error #6 - query does not use index'+
    #13#10+'Memory = '+BoolToStr(Memory,True)+
    #13#10+'Live = '+BoolToStr(Live,True)+
    #13#10+'Time1 = '+IntToStr(t1)+
    #13#10+'Time2 = '+IntToStr(t2)+
    #13#10+'Time limit t1 >= '+IntToStr(Round(0.9 * t2))
   );
end;

  SQLText := 'SELECT * FROM test WHERE (str like "test%") AND (id <= 100)';
  TestSQL(SQLText,Memory,Live);
  if (FRecCount <> 0) then
   WriteToErrorLog('Error - invalid record count = '+IntToStr(FRecCount)+
    #13#10+'SQL: '+#13#10+SQLText+
    #13#10+'Memory = '+BoolToStr(Memory,True)+
    #13#10+'Live = '+BoolToStr(Live,True));
  t1 := FTime;

  SQLText := 'SELECT * FROM test WHERE (LOWER(str) like "test%") AND (num <= 100)';
  TestSQL(SQLText,Memory,Live);
  if (FRecCount <> 100) then
   WriteToErrorLog('Error - invalid record count = '+IntToStr(FRecCount)+
    #13#10+'SQL: '+#13#10+SQLText+
    #13#10+'Memory = '+BoolToStr(Memory,True)+
    #13#10+'Live = '+BoolToStr(Live,True));
  t2 := FTime;
  if (t1 >= (Round(0.9 * t2))) then
   WriteToErrorLog('Error #7 - query does not use index'+
    #13#10+'Memory = '+BoolToStr(Memory,True)+
    #13#10+'Live = '+BoolToStr(Live,True)+
    #13#10+'Time1 = '+IntToStr(t1)+
    #13#10+'Time2 = '+IntToStr(t2)+
    #13#10+'Time limit t1 >= '+IntToStr(Round(0.9 * t2))
   );

end;

initialization

UnitTestACRSQLPerformance := TUnitTestACRSQLPerformance.Create(UnitTestList);

finalization

UnitTestACRSQLPerformance.Free;

end.
