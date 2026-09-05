unit utIndexTest;

interface

{$I ACRVer.inc}
{$I UTConfig.Inc}

uses uTestList, SysUtils, DB,
{$IFDEF MSWINDOWS}
      DBTables,
      Dialogs,
{$ENDIF}
     DBClient,
     SQLTimSt,
     ACRTypes,
     ACRConst,
     ACRBTree,
     ACRBaseEngine,
     ACRDiskEngine,
     ACRLocalEngine,
     ACRBase,
{$IFDEF ACR5H}
     ACRComMain,
{$ENDIF}
     ACRPage,
     ACRMain
;

const MaxCount = 10;

type
  TTestRecord = record
     vString:        String;
     vSmallint:      Smallint;
     vInteger:       Integer;
     vWord:          Word;
     vBoolean:       Boolean;
     vFloat:         double;
     vCurrency:      Currency;
     vDate:          TDateTime;
     vTime:          TDateTime;
     vDateTime:      TDateTime;
     vFixedChar:     String;
     vWideString:    WideString;
     vLargeint:      Int64;
     vTimeStamp:     TSQLTimeStamp;
  end;

  TIndexTest = class(TUnitTest)
   private
    ACRTable: TACRTable;
    ACRdb:    TACRDatabase;
    Table:    TClientDataset;

    procedure DiskTableWithIndexes;
    procedure InMemoryTableWithIndexes;
    procedure TemporaryTableWithIndexes;
    procedure CreateTables;
    procedure InsertRecord(tbl: TDataset; RecNo: Integer);
    procedure EditRecord(tbl: TDataset; RecNo: Integer);
    procedure Insert1(InMemory: Boolean; Temporary: Boolean);
    procedure InsertEdit1(InMemory: Boolean);
    procedure AddInvalidIndex(InMemory: Boolean; Temporary: Boolean);
    procedure CreateTableWithInvalidIndex(InMemory: Boolean; Temporary: Boolean);

    procedure TwoTableComponentsWithIndexes;

    procedure CreateAllFiledsTables;
    procedure CompareTablesWithIndex(IndexName: String; CompareFieldName: String);
    procedure CompareTables(Caption: String; Table1, Table2: TDataset; CompareFieldName: String);
    function CompareACRTables(Table1,Table2: TACRTable): Boolean;

    procedure GenerateAllFieldsRecord(var rec: TTestRecord);
    procedure InsertAllFieldsRecord(rec: TTestRecord; tbl: TDataset);
    procedure CheckIndexOrder1(InMemory: Boolean; Temporary: Boolean);
   public
    procedure Inserts1;
    procedure CheckIndexOrder;
    procedure InvalidIndexParamsCheck;
    procedure TestPrimaryKeyBug;
    procedure TestInsertManyRecords;


    procedure TestShort; override;
    procedure TestExceptions; override;
  end;

var
  UnitTestIndexTest: TIndexTest;

implementation

uses Classes;

function GenerateString(
                       len : Integer // serial length
                       ) : String; // returns serial
var i,x : integer;
    s : string;
    c : char;
begin
 s := '';

 for i := 1 to len do
  begin
   x := Random(101);
   if ((x mod 2) =  0) then
    c := chr(65+(Random(260000000) mod 26))
   else
    c := chr(48+(Random(100000000) mod 10));

   s := s + c;
  end; //len
 result := s;
end; // GenerateString


function GenerateRandomDateTime: TDateTime;
var
  d,m,y,h,n,z : integer;
begin
     m:= 1 + Random(MAXINT) mod 12;
     d:= 1 + Random(MAXINT) mod 28;
     y := 1900 + Random(MAXINT) mod 200;
     h := Random(MAXINT) mod 24;
     n := Random(MAXINT) mod 60;
     z := Random(MAXINT) mod 60;

     Result := EncodeDate(y, m, d) + EncodeTime( h, n, z, Random(1000));
end;


procedure TIndexTest.DiskTableWithIndexes;
var
  tbl:      TACRTable;
  db:       TACRDatabase;
  i:        Integer;
  s:        String;
begin
  db := TACRDatabase.Create(nil);
  db.DatabaseName := 'TestDB';
  db.DatabaseFileName := TempDir + 'test_indexes.adb';
  if (db.Exists) then
   db.DeleteDatabase;
  db.CreateDatabase;
  db.Open;
  try
    tbl := TACRTable.Create(nil);
    tbl.DatabaseName := db.DatabaseName;
    tbl.TableName := 'test';
    tbl.Exclusive := true;
    try
     tbl.FieldDefs.Clear;
     tbl.FieldDefs.Add('int', ftInteger);
     tbl.FieldDefs.Add('string', ftString, 500);
     tbl.IndexDefs.Clear;
     tbl.IndexDefs.Add('idx1','int',[]);
     tbl.IndexDefs.Add('idx2','int;string',[ixCaseInsensitive]);
     tbl.IndexDefs.Add('idx3','string',[ixUnique,ixCaseInsensitive]);
     if (tbl.Exists) then
      tbl.DeleteTable;
     tbl.CreateTable;
    except
     WriteToErrorLog('DiskTableWithIndexes - create table failed');
    end;

    try
     tbl.IndexDefs.Clear;
     tbl.Open;
     if (tbl.IndexDefs.Count <> 3) then
      WriteToErrorLog('DiskTableWithIndexes - wrong number of indexes');
     tbl.Close;
    except
     WriteToErrorLog('DiskTableWithIndexes - open error');
    end;

    try
     tbl.IndexDefs.Clear;
     tbl.Open;
     tbl.Insert;
     tbl.FieldByName('string').AsString := 'aaa';
     tbl.Post;
     tbl.Insert;
     tbl.FieldByName('string').AsString := 'ccc';
     tbl.Post;
     tbl.Insert;
     tbl.FieldByName('string').AsString := 'bbb';
     tbl.Post;
     tbl.AddIndex('idx4','string',[ixUnique],'string','string');
     tbl.Close;
     tbl.IndexDefs.Clear;
     tbl.Open;
     if (tbl.IndexDefs.Count <> 4) then
      WriteToErrorLog('DiskTableWithIndexes - wrong number of indexes');
     tbl.IndexName := 'idx4';
     tbl.First;
     if (tbl.FieldByName('string').AsString <> 'ccc') then
      WriteToErrorLog('DiskTableWithIndexes - wrong string desc index order: First');
     tbl.Last;
     if (tbl.FieldByName('string').AsString <> 'aaa') then
      WriteToErrorLog('DiskTableWithIndexes - wrong string desc index order: Last');
     tbl.Prior;
     if (tbl.FieldByName('string').AsString <> 'bbb') then
      WriteToErrorLog('DiskTableWithIndexes - wrong string desc index order: Prior');
     tbl.Next;
     if (tbl.FieldByName('string').AsString <> 'aaa') then
      WriteToErrorLog('DiskTableWithIndexes - wrong string desc index order: Next');
     tbl.Prior;
     tbl.Delete;
     if (tbl.FieldByName('string').AsString <> 'aaa') then
      WriteToErrorLog('DiskTableWithIndexes - delete - leaf');
     tbl.Delete;
     if (tbl.FieldByName('string').AsString <> 'ccc') then
      WriteToErrorLog('DiskTableWithIndexes - delete - leaf2');

     tbl.Close;
     tbl.IndexName := '';
     tbl.EmptyTable;
     tbl.Open;
     for i:=0 to MaxCount-1 do
      begin
       tbl.Insert;
       tbl.FieldByName('string').AsString := IntToStr(i);
       tbl.Post;
      end;

     tbl.AddIndex('idx5','string',[ixUnique]);
     tbl.IndexName := 'idx5';
     tbl.First;
     if (tbl.FieldByName('string').AsString <> '0') then
      WriteToErrorLog('DiskTableWithIndexes - Node with leaf: First');
     tbl.Next;
     if (tbl.FieldByName('string').AsString <> '1') then
      WriteToErrorLog('DiskTableWithIndexes - Node with leaf: Next');
     tbl.Last;
     if (tbl.FieldByName('string').AsString <>  IntToStr(MaxCount-1)) then
      WriteToErrorLog('DiskTableWithIndexes - Node with leaf: Last');
     tbl.Prior;
     if (tbl.FieldByName('string').AsString <>  IntToStr(MaxCount-2)) then
      WriteToErrorLog('DiskTableWithIndexes - Node with leaf: Prior');

     // full cross
     tbl.First;
     while not tbl.Eof do
      tbl.Next;
     if (tbl.RecNo <> tbl.RecordCount) then
      WriteToErrorLog('DiskTableWithIndexes - RecNo <> RecCount');
     tbl.Last;
     while not tbl.Bof do
      tbl.Prior;
     if (tbl.RecNo <> 1) then
      WriteToErrorLog('DiskTableWithIndexes - RecNo <> 1');

     tbl.First;
     tbl.Edit;
     tbl.FieldByName('string').AsString := '999';
     tbl.Post;
     if (tbl.FieldByName('string').AsString <> '999') then
      WriteToErrorLog('DiskTableWithIndexes - Edit #1');
     tbl.Prior;
     tbl.Next;
     if (tbl.FieldByName('string').AsString <> '999') then
      WriteToErrorLog('DiskTableWithIndexes - Edit #2');
     tbl.First;
     tbl.Last;
     if (tbl.FieldByName('string').AsString <> '999') then
      WriteToErrorLog('DiskTableWithIndexes - Edit #3');
     tbl.Delete;

     tbl.Last;
     tbl.Delete;
     if (tbl.FieldByName('string').AsString <> IntToStr(MaxCount-2)) then
      WriteToErrorLog('DiskTableWithIndexes - Delete last');
     while (not tbl.Eof) do
      begin
        s := tbl.FieldByName('string').AsString;
        tbl.Delete;
        if (not tbl.Eof) then
         if (tbl.FieldByName('string').AsString > s) then
          WriteToErrorLog('DiskTableWithIndexes - Delete loop');
      end;

     tbl.DeleteIndex('idx5');
     tbl.IndexName := 'idx4';
     if (tbl.IndexDefs.Count <> 4) then
      WriteToErrorLog('DiskTableWithIndexes - wrong number of indexes: delete index');

     tbl.Close;
    except
     WriteToErrorLog('DiskTableWithIndexes - exception');
    end;
  
    try
     tbl.Close;
     tbl.DeleteTable;
    except
     WriteToErrorLog('DiskTableWithIndexes - delete table failed');
    end;
    tbl.Free;

  finally
   db.Close;
   db.DeleteDatabase;
   db.Free;
  end;
end;


procedure TIndexTest.InMemoryTableWithIndexes;
var
  tbl: TACRTable;
  i:   Integer;
  s:   String;
begin
  tbl := TACRTable.Create(nil);
  tbl.InMemory := True;
  tbl.TableName := 'test';
  try
   tbl.FieldDefs.Clear;
   tbl.FieldDefs.Add('int', ftInteger);
   tbl.FieldDefs.Add('string', ftString, 500);
   tbl.IndexDefs.Clear;
   tbl.IndexDefs.Add('idx1','int',[]);
   tbl.IndexDefs.Add('idx2','int;string',[ixCaseInsensitive]);
   tbl.IndexDefs.Add('idx3','string',[ixUnique,ixCaseInsensitive]);
   if (tbl.Exists) then
    tbl.DeleteTable;
   tbl.CreateTable;
  except
   WriteToErrorLog('InMemoryTableWithIndexes - create table failed');
  end;

  try
   tbl.IndexDefs.Clear;
   tbl.Open;
   if (tbl.IndexDefs.Count <> 3) then
    WriteToErrorLog('InMemoryTableWithIndexes - wrong number of indexes');
   tbl.Close;
  except
   WriteToErrorLog('InMemoryTableWithIndexes - open error');
  end;

  try
   tbl.IndexDefs.Clear;
   tbl.Open;
   tbl.Insert;
   tbl.FieldByName('string').AsString := 'aaa';
   tbl.Post;
   tbl.Insert;
   tbl.FieldByName('string').AsString := 'ccc';
   tbl.Post;
   tbl.Insert;
   tbl.FieldByName('string').AsString := 'bbb';
   tbl.Post;
   tbl.AddIndex('idx4','string',[ixUnique],'string','string');
   tbl.Close;
   tbl.IndexDefs.Clear;
   tbl.Open;
   if (tbl.IndexDefs.Count <> 4) then
    WriteToErrorLog('InMemoryTableWithIndexes - wrong number of indexes');
   tbl.IndexName := 'idx4';
   tbl.First;
   if (tbl.FieldByName('string').AsString <> 'ccc') then
    WriteToErrorLog('InMemoryTableWithIndexes - wrong string desc index order: First');
   tbl.Last;
   if (tbl.FieldByName('string').AsString <> 'aaa') then
    WriteToErrorLog('InMemoryTableWithIndexes - wrong string desc index order: Last');
   tbl.Prior;
   if (tbl.FieldByName('string').AsString <> 'bbb') then
    WriteToErrorLog('InMemoryTableWithIndexes - wrong string desc index order: Prior');
   tbl.Next;
   if (tbl.FieldByName('string').AsString <> 'aaa') then
    WriteToErrorLog('InMemoryTableWithIndexes - wrong string desc index order: Next');
   tbl.Prior;
   tbl.Delete;
   if (tbl.FieldByName('string').AsString <> 'aaa') then
    WriteToErrorLog('InMemoryTableWithIndexes - delete - leaf');
   tbl.Delete;
   if (tbl.FieldByName('string').AsString <> 'ccc') then
    WriteToErrorLog('InMemoryTableWithIndexes - delete - leaf2');


   tbl.Close;
   tbl.IndexName := '';
   tbl.EmptyTable;
   tbl.Open;
   for i:=0 to MaxCount-1 do
    begin
     tbl.Insert;
     tbl.FieldByName('string').AsString := IntToStr(i);
     tbl.Post;
    end;

   tbl.AddIndex('idx5','string',[ixUnique]);
   tbl.IndexName := 'idx5';
   tbl.First;
   if (tbl.FieldByName('string').AsString <> '0') then
    WriteToErrorLog('InMemoryTableWithIndexes - Node with leaf: First');
   tbl.Next;
   if (tbl.FieldByName('string').AsString <> '1') then
    WriteToErrorLog('InMemoryTableWithIndexes - Node with leaf: Next');
   tbl.Last;
   if (tbl.FieldByName('string').AsString <> IntToStr(MaxCount-1)) then
    WriteToErrorLog('InMemoryTableWithIndexes - Node with leaf: Last');
   tbl.Prior;
   if (tbl.FieldByName('string').AsString <> IntToStr(MaxCount-2)) then
    WriteToErrorLog('InMemoryTableWithIndexes - Node with leaf: Prior');

   // full cross
   tbl.First;
   while not tbl.Eof do
    tbl.Next;
   if (tbl.RecNo <> tbl.RecordCount) then
    WriteToErrorLog('InMemoryTableWithIndexes - RecNo <> RecCount');
   tbl.Last;
   while not tbl.Bof do
    tbl.Prior;
   if (tbl.RecNo <> 1) then
    WriteToErrorLog('InMemoryTableWithIndexes - RecNo <> 1');

   tbl.First;
   tbl.Edit;
   tbl.FieldByName('string').AsString := '999';
   tbl.Post;
   if (tbl.FieldByName('string').AsString <> '999') then
    WriteToErrorLog('InMemoryTableWithIndexes - Edit #1');
   tbl.Prior;
   tbl.Next;
   if (tbl.FieldByName('string').AsString <> '999') then
    WriteToErrorLog('InMemoryTableWithIndexes - Edit #2');
   tbl.First;
   tbl.Last;
   if (tbl.FieldByName('string').AsString <> '999') then
    WriteToErrorLog('InMemoryTableWithIndexes - Edit #3');
   tbl.Delete;

   tbl.Last;
   tbl.Delete;
   if (tbl.FieldByName('string').AsString <> IntToStr(MaxCount-2)) then
    WriteToErrorLog('InMemoryTableWithIndexes - Delete last');
   while (not tbl.Eof) do
    begin
      s := tbl.FieldByName('string').AsString;
      tbl.Delete;
      if (not tbl.Eof) then
       if (tbl.FieldByName('string').AsString > s) then
        WriteToErrorLog('InMemoryTableWithIndexes - Delete loop');
    end;

   tbl.DeleteIndex('idx5');
   tbl.IndexName := 'idx4';
   if (tbl.IndexDefs.Count <> 4) then
    WriteToErrorLog('InMemoryTableWithIndexes - wrong number of indexes: delete index');

   tbl.Close;
  except
   WriteToErrorLog('InMemoryTableWithIndexes - exception');
  end;
  
  try
   tbl.Close;
   tbl.DeleteTable;
  except
   WriteToErrorLog('InMemoryTableWithIndexes - delete table failed');
  end;
  tbl.Free;
end;


procedure TIndexTest.TemporaryTableWithIndexes;
var
  tbl: TACRTable;
  i:   Integer;
begin
  tbl := TACRTable.Create(nil);
  tbl.Temporary := True;
  tbl.TableName := 'test';
  try
   tbl.FieldDefs.Clear;
   tbl.FieldDefs.Add('int', ftInteger);
   tbl.FieldDefs.Add('string', ftString, 500);
   tbl.IndexDefs.Clear;
   tbl.IndexDefs.Add('idx1','int',[]);
   tbl.IndexDefs.Add('idx2','int;string',[ixCaseInsensitive]);
   tbl.IndexDefs.Add('idx3','string',[ixUnique,ixCaseInsensitive]);
   if (tbl.Exists) then
    tbl.DeleteTable;
   tbl.CreateTable;
  except
   WriteToErrorLog('TemporaryTableWithIndexes - create table failed');
  end;

  try
   tbl.IndexDefs.Clear;
   tbl.Open;
   if (tbl.IndexDefs.Count <> 3) then
    WriteToErrorLog('TemporaryTableWithIndexes - wrong number of indexes');
//   tbl.Close;
  except
   WriteToErrorLog('TemporaryTableWithIndexes - open error');
  end;

  try
   tbl.IndexDefs.Clear;
//   tbl.Open;
   tbl.Insert;
   tbl.FieldByName('string').AsString := 'aaa';
   tbl.Post;
   tbl.Insert;
   tbl.FieldByName('string').AsString := 'ccc';
   tbl.Post;
   tbl.Insert;
   tbl.FieldByName('string').AsString := 'bbb';
   tbl.Post;
   tbl.AddIndex('idx4','string',[ixUnique],'string','string');
//   tbl.Close;
   tbl.IndexDefs.Update;
//   tbl.Open;
   if (tbl.IndexDefs.Count <> 4) then
    WriteToErrorLog('TemporaryTableWithIndexes - wrong number of indexes');
   tbl.IndexName := 'idx4';
   tbl.First;
   if (tbl.FieldByName('string').AsString <> 'ccc') then
    WriteToErrorLog('TemporaryTableWithIndexes - wrong string desc index order: First');
   tbl.Last;
   if (tbl.FieldByName('string').AsString <> 'aaa') then
    WriteToErrorLog('TemporaryTableWithIndexes - wrong string desc index order: Last');
   tbl.Prior;
   if (tbl.FieldByName('string').AsString <> 'bbb') then
    WriteToErrorLog('TemporaryTableWithIndexes - wrong string desc index order: Prior');
   tbl.Next;
   if (tbl.FieldByName('string').AsString <> 'aaa') then
    WriteToErrorLog('TemporaryTableWithIndexes - wrong string desc index order: Next');

   tbl.Close;
   tbl.IndexName := '';
   tbl.CreateTable;
   tbl.Open;
   for i:=0 to MaxCount-1 do
    begin
     tbl.Insert;
     tbl.FieldByName('string').AsString := IntToStr(i);
     tbl.Post;
    end;

   tbl.AddIndex('idx5','string',[ixUnique]);
   tbl.IndexName := 'idx5';
   tbl.First;
   if (tbl.FieldByName('string').AsString <> '0') then
    WriteToErrorLog('TemporaryTableWithIndexes - Node with leaf: First');
   tbl.Next;
   if (tbl.FieldByName('string').AsString <> '1') then
    WriteToErrorLog('TemporaryTableWithIndexes - Node with leaf: Next');
   tbl.Last;
   if (tbl.FieldByName('string').AsString <> IntToStr(MaxCount-1)) then
    WriteToErrorLog('TemporaryTableWithIndexes - Node with leaf: Last');
   tbl.Prior;
   if (tbl.FieldByName('string').AsString <> IntToStr(MaxCount-2)) then
    WriteToErrorLog('TemporaryTableWithIndexes - Node with leaf: Prior');
   tbl.RecNo := tbl.RecordCount;
   if (tbl.FieldByName('string').AsString <> IntToStr(MaxCount-1)) then
    WriteToErrorLog('TemporaryTableWithIndexes - RecNo or RecordCount failed');

   // full cross
   tbl.First;
   while not tbl.Eof do
    tbl.Next;
   if (tbl.RecNo <> tbl.RecordCount) then
    WriteToErrorLog('TemporaryTableWithIndexes - RecNo <> RecCount');
   tbl.Last;
   while not tbl.Bof do
    tbl.Prior;
   if (tbl.RecNo <> 1) then
    WriteToErrorLog('TemporaryTableWithIndexes - RecNo <> 1');

   tbl.DeleteIndex('idx5');
   tbl.IndexName := 'idx4';
   if (tbl.IndexDefs.Count <> 4) then
    WriteToErrorLog('TemporaryTableWithIndexes - wrong number of indexes: delete index');

   tbl.Close;
  except
   WriteToErrorLog('TemporaryTableWithIndexes - exception');
  end;

  try
   tbl.Close;
   if (tbl.Exists) then
     WriteToErrorLog('TemporaryTableWithIndexes - close does not delete table');
 //  tbl.DeleteTable;
  except
   WriteToErrorLog('TemporaryTableWithIndexes - delete table failed');
  end;
  tbl.Free;
end;

procedure TIndexTest.CreateTables;
begin
   ACRTable.FieldDefs.Clear;
   ACRTable.FieldDefs.Add('ID', ftAutoInc, 0, false);
   ACRTable.FieldDefs.Add('fInteger', ftInteger, 0, false);
   ACRTable.FieldDefs.Add('fString', ftString, 100, False);
   ACRTable.FieldDefs.Add('fDate', ftDateTime, 0, False);
//   ACRTable.FieldDefs.Add('Notes',ftMemo,0,False);
//   ACRTable.FieldDefs.Add('fGraphic',ftGraphic,0,False);
   ACRTable.IndexDefs.Clear;
   ACRTable.IndexDefs.Add('ID_key','ID',[ixPrimary,ixUnique]);
   ACRTable.IndexDefs.Add('String_key','fString;fInteger',[ixCaseInsensitive]);
   ACRTable.IndexDefs.Add('Integer_key','fInteger',[ixDescending]);
   ACRTable.IndexDefs.Add('Date_key','fDate',[ixCaseInsensitive]);
   if (ACRTable.Exists) then
    ACRTable.DeleteTable;
   ACRTable.CreateTable;
end;


procedure TIndexTest.InsertRecord(tbl: TDataset; RecNo: Integer);
var
  aInt: Integer;
  s: String;
  aDate: TDateTime;
begin
   aInt := 1000;
   s := 'TeSt'+IntToStr(Random(aInt))+IntTostr(RecNo);
   aDate := Now;

//   aaStartTime;
   tbl.Insert;
   tbl.FieldByName('fInteger').AsInteger := aInt;
   tbl.FieldByName('fString').AsString := s;
   tbl.FieldByName('fDate').AsDateTime := aDate;
   tbl.Post;
//aaStopTime;
end;

procedure TIndexTest.EditRecord(tbl: TDataset; RecNo: Integer);
var
  aInt: Integer;
  s: String;
begin
   aInt := 1000;
   s := 'TeSt'+IntToStr(Random(aInt))+IntTostr(RecNo);

//   aaStartTime;
   tbl.Edit;
   tbl.FieldByName('fString').AsString := s;
   tbl.Post;
//   aaStopTime;
end;


procedure TIndexTest.Insert1(InMemory: Boolean; Temporary: Boolean);
var
  i, RecCount: Integer;
begin
 if (InMemory) then
   RecCount := MaxCount * 2
 else
   RecCount := MaxCount div 2;
 if (not InMemory) and (not Temporary) then
  begin
    ACRdb := TACRDatabase.Create(nil);
    ACRdb.DatabaseName := 'TestDB';
    ACRdb.DatabaseFileName := TempDir + 'test_indexes.adb';
    if (ACRdb.Exists) then
     ACRdb.DeleteDatabase;
    ACRdb.CreateDatabase;
    ACRdb.Open;
    ACRTable := TACRTable.Create(nil);
    ACRTable.DatabaseName := ACRdb.DatabaseName;
    ACRTable.Exclusive := true;
  end
 else
  ACRTable := TACRTable.Create(nil);
 try
   ACRTable.TableName := 'test';
   if (InMemory) then
     ACRTable.InMemory := True
   else
     ACRTable.InMemory := False;
   if (Temporary) then
     ACRTable.Temporary := True
   else
     ACRTable.Temporary := False;

   CreateTables;
   ACRTable.Open;

//   aaInitTime;
   for i := 0 to RecCount-1 do
    begin
     InsertRecord(ACRTable, i);
//     InsertRecord(Table, i);
    end;
//   ShowMessage(IntToStr(aaGetTime));

 finally
   ACRTable.Free;
   if (not InMemory) and (not Temporary) then
    begin
     ACRdb.Close;
     ACRdb.DeleteDatabase;
     ACRdb.Free;
    end;
 end;
end;


procedure TIndexTest.InsertEdit1(InMemory: Boolean);
var
  i, RecCount: Integer;
begin
 if (InMemory) then
   RecCount := MaxCount
 else
   RecCount := MaxCount div 2;
 if (not InMemory) then
  begin
    ACRdb := TACRDatabase.Create(nil);
    ACRdb.DatabaseName := 'TestDB';
    ACRdb.DatabaseFileName := TempDir + 'test_indexes.adb';
    if (ACRdb.Exists) then
     ACRdb.DeleteDatabase;
    ACRdb.CreateDatabase;
    ACRdb.Open;
    ACRTable := TACRTable.Create(nil);
    ACRTable.DatabaseName := ACRdb.DatabaseName;
    ACRTable.Exclusive := true;
  end
 else
  ACRTable := TACRTable.Create(nil);
 try
   ACRTable.TableName := 'test';
   if (InMemory) then
     ACRTable.InMemory := True
   else
     ACRTable.InMemory := False;

   CreateTables;
   ACRTable.Open;

//   aaInitTime;
   for i := 0 to RecCount-1 do
    begin
     InsertRecord(ACRTable, i);
//     InsertRecord(Table, i);
    end;
//   ShowMessage(IntToStr(aaGetTime));
   ACRTable.First;
   for i := 0 to RecCount-1 do
    begin
     EditRecord(ACRTable, i);
     ACRTable.Next;
//     EditRecord(Table, i);
    end;

 finally
   ACRTable.Free;
   if (not InMemory) then
    begin
     ACRdb.Close;
     ACRdb.DeleteDatabase;
     ACRdb.Free;
    end;
 end;
end;


procedure TIndexTest.Inserts1;
begin
  InsertEdit1(False);
  InsertEdit1(True);
  Insert1(False, False);
  Insert1(True, False);
  Insert1(False, True);
end;


procedure TIndexTest.AddInvalidIndex(InMemory: Boolean; Temporary: Boolean);
var
  TestStr: String;
begin
 TestStr := 'AddInvalidIndex-';
 if (not InMemory) and (not Temporary) then
  begin
    ACRdb := TACRDatabase.Create(nil);
    ACRdb.DatabaseName := 'TestDB';
    ACRdb.DatabaseFileName := TempDir + 'test_indexes.adb';
    if (ACRdb.Exists) then
     ACRdb.DeleteDatabase;
    ACRdb.CreateDatabase;
    ACRdb.Open;
    ACRTable := TACRTable.Create(nil);
    ACRTable.DatabaseName := ACRdb.DatabaseName;
    ACRTable.Exclusive := true;
  end
 else
  ACRTable := TACRTable.Create(nil);
 try
   ACRTable.TableName := 'test';
   if (InMemory) then
    begin
      TestStr := TestStr + 'memory: ';
      ACRTable.InMemory := True
    end
   else
     ACRTable.InMemory := False;
   if (Temporary) then
    begin
      TestStr := TestStr + 'temporary: ';
      ACRTable.Temporary := True
    end
   else
     ACRTable.Temporary := False;

   ACRTable.FieldDefs.Clear;
   ACRTable.FieldDefs.Add('ID', ftAutoInc, 0, false);
   ACRTable.FieldDefs.Add('fInteger', ftInteger, 0, false);
   ACRTable.FieldDefs.Add('fString', ftString, 100, False);
   ACRTable.FieldDefs.Add('fDate', ftDateTime, 0, False);
//   ACRTable.FieldDefs.Add('Notes',ftMemo,0,False);
//   ACRTable.FieldDefs.Add('fGraphic',ftGraphic,0,False);
   ACRTable.IndexDefs.Clear;
   ACRTable.IndexDefs.Add('idx1','ID',[ixPrimary,ixUnique]);
   if (ACRTable.Exists) then
    ACRTable.DeleteTable;
   ACRTable.CreateTable;
   try
    ACRTable.AddIndex('idx1', 'ID', []);
    WriteToErrorLog(TestStr+'invalid index accepted #1');
   except
   end;
   try
    ACRTable.AddIndex('idx3', '', []);
    WriteToErrorLog(TestStr+'invalid index accepted #2');
   except
   end;
   try
    ACRTable.AddIndex('', 'ID', []);
    WriteToErrorLog(TestStr+'invalid index accepted #3');
   except
   end;
   try
    ACRTable.AddIndex('idx4', 'non existing field', []);
    WriteToErrorLog(TestStr+'invalid index accepted #4');
   except
   end;
 finally
   ACRTable.Free;
   if (not InMemory) and (not Temporary) then
    begin
     ACRdb.Close;
     ACRdb.DeleteDatabase;
     ACRdb.Free;
    end;
 end;
end;


procedure TIndexTest.CreateTableWithInvalidIndex(InMemory: Boolean; Temporary: Boolean);
var
  TestStr: String;
begin
 TestStr := 'CreateTableWithInvalidIndex-';
 if (not InMemory) and (not Temporary) then
  begin
    ACRdb := TACRDatabase.Create(nil);
    ACRdb.DatabaseName := 'TestDB';
    ACRdb.DatabaseFileName := TempDir + 'test_indexes.adb';
    if (ACRdb.Exists) then
     ACRdb.DeleteDatabase;
    ACRdb.CreateDatabase;
    ACRdb.Open;
    ACRTable := TACRTable.Create(nil);
    ACRTable.DatabaseName := ACRdb.DatabaseName;
    ACRTable.Exclusive := true;
  end
 else
  ACRTable := TACRTable.Create(nil);
 try
   ACRTable.TableName := 'test';
   if (InMemory) then
    begin
      TestStr := TestStr + 'memory: ';
      ACRTable.InMemory := True
    end
   else
     ACRTable.InMemory := False;
   if (Temporary) then
    begin
      TestStr := TestStr + 'temporary: ';
      ACRTable.Temporary := True
    end
   else
     ACRTable.Temporary := False;

   ACRTable.FieldDefs.Clear;
   ACRTable.FieldDefs.Add('ID', ftAutoInc, 0, false);

   try
    ACRTable.IndexDefs.Clear;
    ACRTable.IndexDefs.Add('idx1','ID',[ixPrimary,ixUnique]);
    ACRTable.IndexDefs.Add('idx1','ID',[]);
    ACRTable.CreateTable;
    WriteToErrorLog(TestStr+'invalid index accepted #1');
   except
   end;
   try
    ACRTable.IndexDefs.Clear;
    ACRTable.IndexDefs.Add('idx3', '', []);
    ACRTable.CreateTable;
    WriteToErrorLog(TestStr+'invalid index accepted #2');
   except
   end;
   try
    ACRTable.IndexDefs.Clear;
    ACRTable.IndexDefs.Add('', 'ID', []);
    ACRTable.CreateTable;
    WriteToErrorLog(TestStr+'invalid index accepted #3');
   except
   end;
   try
    ACRTable.IndexDefs.Clear;
    ACRTable.IndexDefs.Add('idx4', 'non existing field', []);
    ACRTable.CreateTable;
    WriteToErrorLog(TestStr+'invalid index accepted #4');
   except
   end;
 finally
   ACRTable.Free;
   if (not InMemory) and (not Temporary) then
    begin
     ACRdb.Close;
     ACRdb.DeleteDatabase;
     ACRdb.Free;
    end;
 end;
end;


procedure TIndexTest.TwoTableComponentsWithIndexes;
var
  ACRTable1, ACRTable2: TACRTable;
begin
  ACRTable1 := TACRTable.Create(nil);
  ACRTable2 := TACRTable.Create(nil);
  try
    ACRTable1.TableName := 'Test';
    ACRTable1.InMemory := True;
    ACRTable1.FieldDefs.Clear;
    ACRTable1.FieldDefs.Add('fString', ftString, 100, False);
    ACRTable1.IndexDefs.Clear;
    ACRTable1.CreateTable;
    ACRTable1.Open;

    ACRTable2.TableName := 'test';
    ACRTable2.InMemory := True;
    ACRTable2.Open;

    ACRTable1.AddIndex('idx1', 'fString', [ixDescending]);
    ACRTable2.IndexName := 'idx1';
    if (ACRTable2.IndexDefs.Count <> 1) then
     WriteToErrorLog('TIndexTest.TwoTableComponentsWithIndexes - #1');

  finally
    ACRTable1.Free;
    ACRTable2.Free;
  end;
end;


procedure TIndexTest.CreateAllFiledsTables;
begin
   // Accuracer
   ACRTable.FieldDefs.Clear;
   ACRTable.FieldDefs.Add('fString', ftString, 100, False);
   ACRTable.FieldDefs.Add('fSmallint', ftSmallint, 0, False);
   ACRTable.FieldDefs.Add('fInteger', ftInteger, 0, False);
   ACRTable.FieldDefs.Add('fWord', ftWord, 0, False);
   ACRTable.FieldDefs.Add('fBoolean', ftBoolean, 0, False);
   ACRTable.FieldDefs.Add('fFloat', ftFloat, 0, False);
   ACRTable.FieldDefs.Add('fCurrency', ftCurrency, 0, False);
   ACRTable.FieldDefs.Add('fDate', ftDate, 0, False);
   ACRTable.FieldDefs.Add('fTime', ftTime, 0, False);
   ACRTable.FieldDefs.Add('fDateTime', ftDateTime, 0, False);
   ACRTable.FieldDefs.Add('fFixedChar', ftFixedChar, 50, False);
   ACRTable.FieldDefs.Add('fWideString', ftWideString, 100, False);
   ACRTable.FieldDefs.Add('fLargeint', ftLargeint, 0, False);
   ACRTable.FieldDefs.Add('fTimeStamp', ftTimeStamp, 0, False);

   ACRTable.IndexDefs.Clear;
   ACRTable.IndexDefs.Add('idxString1','fString',[ixDescending]);
   ACRTable.IndexDefs.Add('idxString2','fString',[ixCaseInsensitive]);
   ACRTable.IndexDefs.Add('idxSmallint','fSmallint',[]);
   ACRTable.IndexDefs.Add('idxInteger','fInteger',[]);
   ACRTable.IndexDefs.Add('idxWord','fWord',[]);
   ACRTable.IndexDefs.Add('idxBoolean','fBoolean',[]);
   ACRTable.IndexDefs.Add('idxFloat','fFloat',[]);
   ACRTable.IndexDefs.Add('idxCurrency','fCurrency',[]);
   ACRTable.IndexDefs.Add('idxDate','fDate',[]);
   ACRTable.IndexDefs.Add('idxTime','fTime',[]);
   ACRTable.IndexDefs.Add('idxDateTime','fDateTime',[]);
   ACRTable.IndexDefs.Add('idxFixedChar','fFixedChar',[]);
   ACRTable.IndexDefs.Add('idxWideString','fWideString',[]);
   ACRTable.IndexDefs.Add('idxLargeint','fLargeint',[]);
   ACRTable.IndexDefs.Add('idxTimeStamp','fTimeStamp',[]);
   if (ACRTable.Exists) then
    ACRTable.DeleteTable;
   ACRTable.CreateTable;

   // Paradox
{$IFDEF MSWINDOWS}
{$ENDIF}
   Table.FieldDefs.Clear;
   Table.FieldDefs.Add('fString', ftString, 100, False);
   Table.FieldDefs.Add('fSmallint', ftSmallint, 0, False);
   Table.FieldDefs.Add('fInteger', ftInteger, 0, False);
   Table.FieldDefs.Add('fWord', ftWord, 0, False);
   Table.FieldDefs.Add('fBoolean', ftBoolean, 0, False);
   Table.FieldDefs.Add('fFloat', ftFloat, 0, False);
   Table.FieldDefs.Add('fCurrency', ftCurrency, 0, False);
   Table.FieldDefs.Add('fDate', ftDate, 0, False);
   Table.FieldDefs.Add('fTime', ftTime, 0, False);
   Table.FieldDefs.Add('fDateTime', ftDateTime, 0, False);
   Table.FieldDefs.Add('fFixedChar', ftFixedChar, 50, False);
   Table.FieldDefs.Add('fWideString', ftWideString, 100, False);
   Table.FieldDefs.Add('fLargeint', ftLargeint, 0, False);
   Table.FieldDefs.Add('fTimeStamp', ftTimeStamp, 0, False);

   Table.IndexDefs.Clear;
   Table.IndexDefs.Add('','fInteger',[ixPrimary]);
   Table.IndexDefs.Add('idxString1','fString',[ixDescending]);
   Table.IndexDefs.Add('idxString2','fString',[ixCaseInsensitive]);
   Table.IndexDefs.Add('idxSmallint','fSmallint',[ixCaseInsensitive]);
   Table.IndexDefs.Add('idxWord','fWord',[ixCaseInsensitive]);
   Table.IndexDefs.Add('idxInteger','fInteger',[ixCaseInsensitive]);
   Table.IndexDefs.Add('idxBoolean','fBoolean',[ixCaseInsensitive]);
   Table.IndexDefs.Add('idxFloat','fFloat',[ixCaseInsensitive]);
   Table.IndexDefs.Add('idxCurrency','fCurrency',[ixCaseInsensitive]);
   Table.IndexDefs.Add('idxDate','fDate',[ixCaseInsensitive]);
   Table.IndexDefs.Add('idxTime','fTime',[ixCaseInsensitive]);
   Table.IndexDefs.Add('idxDateTime','fDateTime',[ixCaseInsensitive]);
   Table.IndexDefs.Add('idxFixedChar','fFixedChar',[]);
   Table.IndexDefs.Add('idxWideString','fWideString',[]);
   Table.IndexDefs.Add('idxLargeint','fLargeint',[ixCaseInsensitive]);
   Table.IndexDefs.Add('idxTimeStamp','fTimeStamp',[ixCaseInsensitive]);
   Table.CreateDataset;
end;


procedure TIndexTest.CompareTablesWithIndex(IndexName: String; CompareFieldName: String);
begin
   ACRTable.IndexName := IndexName;
   Table.IndexName := IndexName;
   CompareTables(IndexName, ACRTable, Table, CompareFieldName);
end;


procedure TIndexTest.CompareTables(Caption: String; Table1, Table2: TDataset; CompareFieldName: String);
var
  i:      Integer;
  bError: Boolean;

  procedure CompareLargeInt;
  var value: Int64;
      bNull: Boolean;
  begin
   if (Table1.RecordCount > 1) then
    begin
     Table1.First;
     repeat
      value := TLargeIntField(Table1.FieldByName(CompareFieldName)).AsLargeInt;
      bNull := Table1.FieldByName(CompareFieldName).IsNull;
      Table1.Next;
      if (not Table1.Eof) then
       begin
        if ((not bNull) and
            (TLargeIntField(Table1.FieldByName(CompareFieldName)).AsLargeInt
                < value)) or
           (Table1.FieldByName(CompareFieldName).IsNull and (not bNull))
             then
         begin
          WriteToErrorLog(Caption+' failed #14, prior value = ' + IntToStr(value) +
            ', next value = ' + Table1.FieldByName(CompareFieldName).AsString);
          break;
         end;
       end;
     until (Table1.Eof);
    end;
  end;

begin
 if (Table1.BOF <> Table2.BOF) then
  WriteToErrorLog(Caption+' failed #1, BOF = '
    +IntToStr(Word(Table1.BOF))+', BDE BOF = '+IntToStr(Word(Table2.BOF)));
 if (Table1.EOF <> Table2.EOF) then
  WriteToErrorLog(Caption+' failed #2, EOF = '
    +IntToStr(Word(Table1.EOF))+', BDE EOF = '+IntToStr(Word(Table2.EOF)));
 if (Table1.RecordCount <> Table2.RecordCount) then
  WriteToErrorLog(Caption+' failed #3, record count = '
    +IntToStr(Table1.RecordCount)+', BDE record count = '+IntToStr(Table2.RecordCount));
 if (Table1.FieldDefs.Count <> Table2.FieldDefs.Count) then
  WriteToErrorLog(Caption+' failed #4, fielddefs count = '
    +IntToStr(Table1.FieldDefs.Count)+', BDE fielddefs count = '+IntToStr(Table2.FieldDefs.Count));
 if (Table1.FieldCount <> Table2.FieldCount) then
  WriteToErrorLog(Caption+' failed #5, field count = '
    +IntToStr(Table1.FieldCount)+', BDE field count = '+IntToStr(Table2.FieldCount))
 else
  begin
   for i := 0 to Table1.FieldDefs.Count - 1 do
    begin
     if (Table1.FieldDefs[i].Name <> Table2.FieldDefs[i].Name) then
      WriteToErrorLog(Caption+' failed #6, field name = ' +
        Table1.FieldDefs[i].Name + ', BDE field name = '+Table2.FieldDefs[i].Name);


     if (Table1.FieldDefs[i].DataType <> Table2.FieldDefs[i].DataType) then
      if (not (Table1.FieldDefs[i].DataType = ftFixedChar) and
              (Table1.FieldDefs[i].DataType = ftString)) then
      WriteToErrorLog(Caption+' failed #7, field type = ' +
        IntToStr(Integer(Table1.FieldDefs[i].DataType)) + ', BDE field type = '+
        IntToStr(Integer(Table2.FieldDefs[i].DataType)));

     if (Table1.FieldDefs[i].Size <> Table2.FieldDefs[i].Size) then
      WriteToErrorLog(Caption+' failed #8, field size = ' +
        IntToStr(Integer(Table1.FieldDefs[i].Size)) + ', BDE field size = '+
        IntToStr(Integer(Table2.FieldDefs[i].Size)));
{
     if (Table1.FieldDefs[i].Required <> Table2.FieldDefs[i].Required) then
      WriteToErrorLog(Caption+' failed #9, field required = ' +
        IntToStr(Integer(Table1.FieldDefs[i].Required)) + ', BDE field required = '+
        IntToStr(Integer(Table2.FieldDefs[i].Required)));
}
    end;
  end;

 bError := False;
 if (Table1.FieldByName(CompareFieldName).DataType = ftLargeInt) then
  CompareLargeInt
 else
  begin
     Table1.First;
     Table2.First;
     while (not Table2.Eof) do
      begin
        if (Table1.FieldByName(CompareFieldName).IsNull <> Table2.FieldByName(CompareFieldName).IsNull) then
         begin
           WriteToErrorLog(Caption+' failed #12, ACR null flag = ' +
             IntToStr(Word(Table1.FieldByName(CompareFieldName).IsNull)) + ', BDE null flag = '+
             IntToStr(Word(Table2.FieldByName(CompareFieldName).IsNull)));
           bError := True;
         end
        else
         begin
          if (not Table1.FieldByName(CompareFieldName).IsNull) then
           if  (Table1.FieldByName(CompareFieldName).AsString <>
                Table2.FieldByName(CompareFieldName).AsString) then
            begin
             WriteToErrorLog(Caption+' failed #10, field  value = ' +
               Table1.FieldByName(CompareFieldName).AsString + ', BDE field value = '+
               Table2.FieldByName(CompareFieldName).AsString);
             bError := True;
            end;
         end;
       if (bError) then
        break;
       Table1.Next;
       Table2.Next;
      end;

     if (Table1.EOF <> Table2.EOF) then
      WriteToErrorLog(Caption+' failed #13, EOF = '
        +IntToStr(Word(Table1.EOF))+', BDE EOF = '+IntToStr(Word(Table2.EOF)));
  end;
end;

function TIndexTest.CompareACRTables(Table1,Table2: TACRTable): Boolean;
var i: integer;
begin
 Result := False;

 if (Table1.RecordCount <> Table2.RecordCount) then
  Exit;
 if (Table1.AdvFieldDefs.Count <> Table2.AdvFieldDefs.Count) then
  Exit;
 for i := 0 to Table1.AdvFieldDefs.Count-1 do
  begin
   if (Table1.AdvFieldDefs.Items[i].Name <>
       Table2.AdvFieldDefs.Items[i].Name) then
       Exit;
   if (Table1.AdvFieldDefs.Items[i].DataType <>
       Table2.AdvFieldDefs.Items[i].DataType) then
       Exit;
   if (Table1.AdvFieldDefs.Items[i].Required <>
       Table2.AdvFieldDefs.Items[i].Required) then
       Exit;
   {if (Table1.AdvFieldDefs.Items[i].DefaultValueType <>
       Table2.AdvFieldDefs.Items[i].DefaultValueType) then
       Exit;}
   {if (Table1.AdvFieldDefs.Items[i].SequenceName <>
       Table2.AdvFieldDefs.Items[i].SequenceName) then
       Exit;}
  end;

 Table1.First;
 Table2.First;

 while not Table1.Eof do
  begin

   for i := 0 to Table1.FieldCount-1 do
    begin
     if (Table1.Fields[i].IsNull or Table2.Fields[i].IsNull) then
      if (Table1.Fields[i].IsNull <> Table2.Fields[i].IsNull) then Exit;
     if (Table1.Fields[i].AsString <> Table2.Fields[i].AsString)
      then Exit;
    end;

   Table1.Next;
   Table2.Next;
  end;

 if (Table1.Eof = Table2.Eof) then
   Result := True;

end; // CompareACRTables

procedure TIndexTest.GenerateAllFieldsRecord(var rec: TTestRecord);
begin
  rec.vString := 's'+GenerateString(10+Random(90));
  rec.vSmallint := Random(abs(Low(SmallInt))+High(Smallint))-abs(Low(SmallInt));
  if ((Random(MaxInt) mod 2) = 0) then
    rec.vInteger := Random(MaxInt)
  else
    rec.vInteger := -Random(MaxInt);
  rec.vWord := Random(abs(Low(Word))+High(Word))-abs(Low(Word));
  rec.vBoolean := Boolean(Random(2));
  rec.vFloat := Random(High(Integer))+
                1/(1+Random(High(Word)));

  if ((Random(MaxInt) mod 2) = 0) then
   rec.vCurrency := Random(High(Integer))+1/(1+Random(High(Integer)))
  else
   rec.vCurrency := -(Random(High(Integer))+1/(1+Random(High(Integer))));
  rec.vDate := GenerateRandomDateTime;
  rec.vTime := GenerateRandomDateTime;
  rec.vDateTime := GenerateRandomDateTime;
  rec.vFixedChar := 's'+GenerateString(Random(50));
  rec.vWideString := 's'+GenerateString(Random(50));
  if ((Random(MaxInt) mod 2) = 0) then
    rec.vLargeint := Random(High(Int64))
  else
    rec.vLargeint := -Random(High(Int64));
  rec.vTimeStamp := DateTimeToSQLTimeStamp(GenerateRandomDateTime);
end;


procedure TIndexTest.InsertAllFieldsRecord(rec: TTestRecord; tbl: TDataset);
begin
  tbl.Insert;

  tbl.FieldByName('fString').AsString := rec.vString;
  tbl.FieldByName('fSmallInt').Value := rec.vSmallInt;
  tbl.FieldByName('fInteger').Value := rec.vInteger;
  tbl.FieldByName('fWord').Value := rec.vWord;
  tbl.FieldByName('fBoolean').Value := rec.vBoolean;
  tbl.FieldByName('fFloat').Value := rec.vFloat;
  tbl.FieldByName('fCurrency').Value := rec.vCurrency;
  tbl.FieldByName('fDate').Value := rec.vDate;
  tbl.FieldByName('fTime').Value := rec.vTime;
  tbl.FieldByName('fDateTime').Value := rec.vDateTime;
  tbl.FieldByName('fFixedChar').Value := rec.vFixedChar;
  tbl.FieldByName('fWideString').Value := rec.vWideString;
  TLargeIntField(tbl.FieldByName('fLargeint')).AsLargeInt := rec.vLargeint;
  TSQLTimeStampField(tbl.FieldByName('fTimeStamp')).AsSQLTimeStamp := rec.vTimeStamp;

  tbl.Post;
end;


procedure TIndexTest.CheckIndexOrder1(InMemory: Boolean; Temporary: Boolean);
var
  i, RecCount: Integer;
  rec: TTestRecord;

begin
 if (InMemory) then
   RecCount := MaxCount * 2
 else
   RecCount := MaxCount div 2;
 if (not InMemory) and (not Temporary) then
  begin
    ACRdb := TACRDatabase.Create(nil);
    ACRdb.DatabaseName := 'TestDB';
    ACRdb.DatabaseFileName := TempDir + 'test_indexes.adb';
    if (ACRdb.Exists) then
     ACRdb.DeleteDatabase;
    ACRdb.CreateDatabase;
    ACRdb.Open;
    ACRTable := TACRTable.Create(nil);
    ACRTable.DatabaseName := ACRdb.DatabaseName;
    ACRTable.Exclusive := true;
  end
 else
  ACRTable := TACRTable.Create(nil);
 Table := TClientDataset.Create(nil);
 try
   ACRTable.TableName := 'test';
   if (InMemory) then
     ACRTable.InMemory := True
   else
     ACRTable.InMemory := False;
   if (Temporary) then
     ACRTable.Temporary := True
   else
     ACRTable.Temporary := False;

   CreateAllFiledsTables;
   ACRTable.Open;
   Table.Open;

   // insert nulls
   ACRTable.Insert;
   ACRTable.Post;
   Table.Insert;
   Table.Post;

//   aaInitTime;
   for i := 0 to RecCount-1 do
    begin
     GenerateAllFieldsRecord(rec);
     InsertAllFieldsRecord(rec, Table);
     InsertAllFieldsRecord(rec, ACRTable);
    end;
//   ShowMessage(IntToStr(aaGetTime));

   CompareTablesWithIndex('idxString1','fString');
   CompareTablesWithIndex('idxString2','fString');
   CompareTablesWithIndex('idxSmallint','fSmallInt');
   CompareTablesWithIndex('idxInteger','fInteger');
   CompareTablesWithIndex('idxWord','fWord');
   CompareTablesWithIndex('idxBoolean','fBoolean');
   CompareTablesWithIndex('idxFloat','fFloat');
   CompareTablesWithIndex('idxCurrency','fCurrency');
   CompareTablesWithIndex('idxDate','fDate');
   CompareTablesWithIndex('idxTime','fTime');
   CompareTablesWithIndex('idxDateTime','fDateTime');
   CompareTablesWithIndex('idxFixedChar','fFixedChar');
   CompareTablesWithIndex('idxWideString','fWideString');
   CompareTablesWithIndex('idxLargeint','fLargeInt');
   CompareTablesWithIndex('idxTimeStamp','fTimeStamp');

 finally
   ACRTable.Free;
   Table.Free;
   if (not InMemory) and (not Temporary) then
    begin
     ACRdb.Close;
     ACRdb.DeleteDatabase;
     ACRdb.Free;
    end;
 end;
end;


procedure TIndexTest.CheckIndexOrder;
begin
  CheckIndexOrder1(False, False);
  CheckIndexOrder1(True, False);
  CheckIndexOrder1(False, True);
end;


procedure TIndexTest.InvalidIndexParamsCheck;
begin
  AddInvalidIndex(False, False);
  AddInvalidIndex(True, False);
  AddInvalidIndex(False, True);
  CreateTableWithInvalidIndex(False, False);
  CreateTableWithInvalidIndex(True, False);
  CreateTableWithInvalidIndex(False, True);
end;

procedure TIndexTest.TestShort;
begin
  CheckAction(TestInsertManyRecords,'TestInsertManyRecords');
  CheckAction(TestPrimaryKeyBug,'TestPrimaryKeyBug');
  CheckAction(DiskTableWithIndexes, 'DiskTableWithIndexes');
  CheckAction(InMemoryTableWithIndexes, 'InMemoryTableWithIndexes');
  CheckAction(TemporaryTableWithIndexes, 'TemporaryTableWithIndexes');
  CheckAction(TwoTableComponentsWithIndexes, 'TwoTableComponentsWithIndexes');
  CheckAction(Inserts1, 'Inserts1');
  CheckAction(CheckIndexOrder, 'CheckIndexOrder');
end;

procedure TIndexTest.TestExceptions;
begin
  CheckAction(InvalidIndexParamsCheck, 'InvalidIndexParamsCheck');
end;


{$IFDEF D6H}
procedure TIndexTest.TestPrimaryKeyBug;
var db:   TACRDatabase;
    t,mt: TACRTable;
    q:    TACRQuery;
    capt: String;
    s:    String;
begin
 capt := 'TIndexTest.TestPrimaryKeyBug - ';
 db := TACRDatabase.Create(nil);
 t := TACRTable.Create(nil);
 mt := TACRTable.Create(nil);
 q := TACRQuery.Create(nil);
 try
   q.DatabaseName := db.DatabaseName;
   t.DatabaseName := db.DatabaseName;
   db.DatabaseFileName := TempDir+'pk_bug.adb';
   if (db.Exists) then
    db.DeleteDatabase;
   db.CreateDatabase;
   db.Open;
   WriteToProcessLog(capt+'creating database...');
   q.SQL.LoadFromFile(SQLDir+'primary_key_bug.sql');
   q.ExecSQL;
   WriteToProcessLog(capt+'creating database...OK');
   t.TableName := 'tsUserProperties';
   t.Open;
   mt.InMemory := True;
   mt.TableName := t.TableName;
   WriteToProcessLog(capt+'importing table to memory table...');
   s := '';
   if (not mt.ImportTable(t,s)) then
    WriteToErrorLog(capt+'cannot import table to memory table. Errors:'+#13#10+s)
   else
    begin
     WriteToProcessLog(capt+'importing table to memory table...OK');
     mt.Open;
     if (not CompareACRTables(t,mt)) then
      WriteToErrorLog(Capt+'compare tables #1 failed');
     t.Close;
     t.AddIndex('PK_ID','UserID, PropertyName',[ixPrimary]);
     t.Open;
     t.Filtered := False;
     t.Filter := 'UserID=1 AND PropertyName LIKE "UserPrefereneces;%"';
     t.Filtered := True;
     mt.Filtered := False;
     mt.Filter := 'UserID=1 AND PropertyName LIKE "UserPrefereneces;%"';
     mt.Filtered := True;
     if (not CompareACRTables(t,mt)) then
      WriteToErrorLog(Capt+'compare tables #2 failed');
     // SQL
     mt.First;
     while (mt.RecordCount > 0) do
      mt.Delete;
{
     t.First;
     while (t.RecordCount > 0) do
      t.Delete;
}
     t.DeleteVisibleRecords;
{
     t.Close;
     q.SQL.Text := 'DELETE FROM tsUserProperties WHERE UserID=1 AND PropertyName LIKE "UserPrefereneces;%"';
     q.ExecSQL;
     if (q.RowsAffected <> 7) then
      WriteToErrorLog(Capt+'DELETE with index failed');
}
     t.Filtered := False;
     mt.Filtered := False;
     t.Open;
     if (not CompareACRTables(t,mt)) then
      WriteToErrorLog(Capt+'compare tables #3 failed');
    end;
 finally
   db.Close;
   db.DeleteDatabase;
   db.Free;
   q.Free;
   mt.Close;
   mt.DeleteTable(True);
   mt.Free;
   t.Free;
 end;
end;

procedure TIndexTest.TestInsertManyRecords;
const RecCount = 10000;
var db:   TACRDatabase;
    t:    TACRTable;
    capt: String;
    s:    AnsiString;
    i:    Integer;

 procedure TestLocate(capt: String);
 var i,n: Integer;
 begin
   try
    i := 1;
    while (i <= RecCount) do
     begin
       t.First;
       s := 'test_'+Format('%06d',[i]);
       if (not t.Locate('str',s,[])) then
        WriteToErrorLog(capt+'#1 record not found, i ='+IntToStr(i));
       if (t.FieldByName('id').AsInteger <> i) then
        WriteToErrorLog(capt+'#2 record not found, i ='+IntToStr(i));
       if (t.FieldByName('str').AsString <> s) then
        WriteToErrorLog(capt+'#3 record not found, i ='+IntToStr(i));
       Inc(i);
     end;
   except
    on e: Exception do
     begin
      WriteToErrorLog(capt+', i = '+IntToStr(i)+'. Error: '+#13#10+e.Message);
      raise;
     end;
   end;
 end; // TestLocate


begin
 capt := 'TIndexTest.TestInsertManyRecords - ';
 db := TACRDatabase.Create(nil);
 t := TACRTable.Create(nil);
 try
   db.Exclusive := True;
   WriteToProcessLog(capt+'creating database...');
   t.DatabaseName := db.DatabaseName;
   db.DatabaseFileName := TempDir+'many_records.adb';
   if (db.Exists) then
    db.DeleteDatabase;
   db.CreateDatabase;
   db.Open;
   WriteToProcessLog(capt+'creating table...');
   t.TableName := 'test';
   t.Exclusive := true;
   t.ClearDefinitions;
   t.AdvFieldDefs.Add('id',aftAutoInc);
   t.AdvFieldDefs.Add('str',aftChar,100);
//   t.IndexDefs.Add('PK','id',[ixPrimary]);
   t.IndexDefs.Add('i_str','str',[]);
   t.CreateTable;
   t.Open;
   WriteToProcessLog(capt+'insert records...');
   for i := 1 to RecCount do
    begin
     t.Insert;
     t.Fields[1].AsString := 'test_'+Format('%06d',[i]);
     t.Post;
    end;
   WriteToProcessLog(capt+'locate after insert...');
   TestLocate(capt+'Locate after insert: ');
   t.Close;
   db.ClearCache;
   db.Close;
   db.Open;
   t.Open;
   WriteToProcessLog(capt+'locate after reopening...');
   TestLocate(capt+'Locate after reopening: ');

   t.IndexFieldNames := 'str';
   t.First;
   TestLocate(capt+'Locate with active index: ');

 finally
   t.Free;
   db.Close;
   db.DeleteDatabase;
   db.Free;
 end;
end; // TestInsertManyRecords;



initialization
  UnitTestIndexTest := TIndexTest.Create(UnitTestList);

finalization
  UnitTestIndexTest.Free;
{$ENDIF}

end.

