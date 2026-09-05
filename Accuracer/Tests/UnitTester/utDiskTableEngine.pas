unit utDiskTableEngine;

interface

{$I UTConfig.Inc}
{$I ACRVER.Inc}

uses uTestList, SysUtils, Db, Classes,
{$IFDEF D6H}
     Variants,
{$ENDIF}
    ACRMain, ACRExcept, ACRConst,
{$IFDEF ACR5H}
     ACRComMain,
{$ENDIF}
    ACRTypes;

const LargeLength= 5000;
const SmallLength= 10;

type
  TUnitTestDiskTableEngine = class(TUnitTest)
   private
    table1,
    table2,
    ACRTable:     TACRTable;
    ses1,ses2:    TACRSession;
    db,db1,db2:   TACRDatabase;
    LargeRows:    Boolean;
    procedure TestDoubleCreate;
    procedure TestExists;
    procedure TestCreateTable;
    procedure TestOpenTable;
    procedure TestCloseTable;
    procedure TestInsertRecord;
    procedure TestAddRecord;
    procedure TestUpdateRecord;
    procedure TestDeleteRecords;
    procedure InternalNavigateTable(UseIndexes: Boolean);
    procedure TestNavigateTable;
    procedure TestEmptyTable;
    procedure TestRenameTable;
    procedure TestDeleteTable;
    procedure TestExclusive;
    procedure TestUniqueIndexes;
    procedure TestFileServerSameTable;
    procedure TestDeleteTableBug;
    procedure TestRepairDatabaseBug;
    procedure TestGuid;
   public
    procedure MainTest;
    procedure MainTestExceptions;
    procedure TestShort; override;
    procedure TestExceptions; override;
  end;

function GenerateString(
                       len : Integer // serial length
                       ) : String; // returns serial

var
  UnitTestDiskTableEngine: TUnitTestDiskTableEngine;


implementation

uses Math;

procedure TUnitTestDiskTableEngine.MainTest;

 procedure RunTest;
 begin
  CheckAction(TestDoubleCreate, 'Test exists');
  CheckAction(TestExists, 'Test exists');
  LargeRows := False;
  CheckAction(TestCreateTable, 'Test create table with small rows');
  CheckAction(TestOpenTable, 'Test open table');
  CheckAction(TestCloseTable, 'Test close table');

  CheckAction(TestOpenTable, 'Test open2 table');

  CheckAction(TestInsertRecord, 'Test insert record #1');
  CheckAction(TestInsertRecord, 'Test insert record #2');
  CheckAction(TestInsertRecord, 'Test insert record #3');
  CheckAction(TestUpdateRecord, 'Test update record #3');
  CheckAction(TestInsertRecord, 'Test insert record #4');
  CheckAction(TestInsertRecord, 'Test insert record #5');
  CheckAction(TestInsertRecord, 'Test insert record #6');
  CheckAction(TestInsertRecord, 'Test insert record #7');
  CheckAction(TestInsertRecord, 'Test insert record #8');
  CheckAction(TestAddRecord, 'Test add record ');
  CheckAction(TestDeleteRecords, 'Test delete records');
  CheckAction(TestNavigateTable, 'Test navigate table');

  ACRTable.IndexName := 'Index1';

  CheckAction(TestInsertRecord, 'Test insert record with index #9');
  CheckAction(TestUpdateRecord, 'Test update record with index #9');
  CheckAction(TestDeleteRecords, 'Test delete records with index');

  CheckAction(TestCloseTable, 'Test close2 table');
  CheckAction(TestEmptyTable, 'Test empty table');
  CheckAction(TestRenameTable, 'Test rename table');
  CheckAction(TestDeleteTable, 'Test delete table');

  LargeRows := True;
  CheckAction(TestCreateTable, 'Test create table with large rows');
  CheckAction(TestOpenTable, 'Test open3 table');
  CheckAction(TestInsertRecord, 'Test insert record #1');
  CheckAction(TestInsertRecord, 'Test insert record #2');
  CheckAction(TestInsertRecord, 'Test insert record #3');
  CheckAction(TestUpdateRecord, 'Test update record #3');
  CheckAction(TestInsertRecord, 'Test insert record #4');
  CheckAction(TestInsertRecord, 'Test insert record #5');
  CheckAction(TestInsertRecord, 'Test insert record #6');
  CheckAction(TestInsertRecord, 'Test insert record #7');
  CheckAction(TestInsertRecord, 'Test insert record #8');
  CheckAction(TestAddRecord, 'Test add record ');
  CheckAction(TestDeleteRecords, 'Test delete records');
  CheckAction(TestNavigateTable, 'Test navigate table');


  ACRTable.IndexName := 'Index1';
  CheckAction(TestInsertRecord, 'Test insert record with index #9');
  CheckAction(TestUpdateRecord, 'Test update record with index #9');
  CheckAction(TestDeleteRecords, 'Test delete records with index');

  CheckAction(TestCloseTable, 'Test close3 table');
  CheckAction(TestEmptyTable, 'Test empty3 table');
  CheckAction(TestRenameTable, 'Test rename3 table');
  CheckAction(TestDeleteTable, 'Test delete3 table');
 end;

begin
 db := TACRDatabase.Create(nil);
 db.DatabaseFileName := 'temp\test_mu.adb';
 db.DatabaseName := 'test_db';
 db.CreateDatabase;
 db.Open;
 ACRTable := TACRTable.Create(nil);
 ACRTable.TableName := 'test_table';
 ACRTable.DatabaseName := 'test_db';
 ACRTable.InMemory := False;
 try
  RunTest;
 finally
  ACRTable.Free;
  db.Close;
  db.DeleteDatabase;
  db.Free;
 end;

// test single user
 db := TACRDatabase.Create(nil);
 db.DatabaseFileName := 'temp\test_su.adb';
 db.DatabaseName := 'test_db';
// db.Exclusive := True;
 db.Options.MaxSessionCount := 1;
 db.CreateDatabase;
 db.Open;
 ACRTable := TACRTable.Create(nil);
 ACRTable.TableName := 'test_table';
 ACRTable.DatabaseName := 'test_db';
 ACRTable.InMemory := False;
 try
  RunTest;
 finally
  ACRTable.Free;
  db.Close;
  db.DeleteDatabase;
  db.Free;
 end;
end;

procedure TUnitTestDiskTableEngine.MainTestExceptions;
begin
  CheckAction(TestFileServerSameTable,'Test File-Server on same table');
  db := TACRDatabase.Create(nil);
  db.DatabaseFileName := 'temp\test.adb';
  db.DatabaseName := 'test';
  db.CreateDatabase;
//  db.Open;

  ses1 := TACRSession.Create(nil);
  ses1.SessionName := 'ses1';
  ses2 := TACRSession.Create(nil);
  ses2.SessionName := 'ses2';
  db1 := TACRDatabase.Create(nil);
  db1.SessionName := ses1.SessionName;
  db1.DatabaseFileName := 'temp\test.adb';
  db1.DatabaseName := 'test';
  db1.LockParams.Delay := 1;
  db1.LockParams.RetryCount := 10;
  db1.Open;
  db2 := TACRDatabase.Create(nil);
  db2.SessionName := ses2.SessionName;
  db2.DatabaseFileName := 'temp\test.adb';
  db2.DatabaseName := 'test';
  db2.Open;

  table1 := TACRTable.Create(nil);
  table1.InMemory := False;
  table1.TableName := 'table1';
  table1.DatabaseName := db1.DatabaseName;
  table1.SessionName := ses1.SessionName;
  table1.FieldDefs.Clear;
  table1.FieldDefs.Add('Field0',ftAutoInc,0,False);
  table1.FieldDefs.Add('Field1',ftInteger,0,False);
  table1.FieldDefs.Add('Field2',ftString,500,False);
  table1.IndexDefs.Clear;
  table1.IndexDefs.Add('Index1','Field1',[ixPrimary]);
  table1.IndexDefs.Add('Index2','Field2;Field1',[ixUnique,ixDescending,ixCaseInsensitive]);
  table1.CreateTable;

  table2 := TACRTable.Create(nil);
  table2.InMemory := False;
  table2.TableName := 'table2';
  table2.DatabaseName := db2.DatabaseName;
  table2.SessionName := ses2.SessionName;
  table2.FieldDefs.Clear;
  table2.FieldDefs.Add('Field0',ftAutoInc,0,False);
  table2.FieldDefs.Add('Field1',ftInteger,0,False);
  table2.FieldDefs.Add('Field2',ftString,500,False);
  table2.IndexDefs.Clear;
  table2.IndexDefs.Add('Index1','Field1',[ixPrimary]);
  table2.IndexDefs.Add('Index2','Field2;Field1',[ixUnique,ixDescending,ixCaseInsensitive]);
  table2.CreateTable;

  WriteToProcessLog('UnitTestDiskTableEngine - test exceptions started');
 try
  CheckAction(TestExclusive, 'Exclusive table open test');
  CheckAction(TestUniqueIndexes, 'Unique indexes test of disk engine');
 finally
  table1.Free;
  table2.Free;
  db1.Close;
  db2.Close;
  ses1.Free;
  ses2.Free;
  db1.Free;
  db2.Free;
  db.Close;
  db.DeleteDatabase;
  db.Free;
 end;
  WriteToProcessLog('UnitTestDiskTableEngine - test exceptions finished');
end;

procedure TUnitTestDiskTableEngine.TestDoubleCreate;
var tbl: TACRTable;
begin
   tbl := TACRTable.Create(nil);
   tbl.DatabaseName := db.DatabaseName;
   tbl.TableName := 'create2';
   if (tbl.Exists) then
    UnitTestList.WriteToErrorLog('TestDoubleCreate - Table exists before create');
   tbl.FieldDefs.Add('id',ftAutoInc);
   tbl.CreateTable;

   tbl.CreateTable;

   tbl.Open;

   tbl.Free;
end;


procedure TUnitTestDiskTableEngine.TestExists;
var tbl: TACRTable;
    sl:  TStringList;
begin

   tbl := TACRTable.Create(nil);
   tbl.DatabaseName := db.DatabaseName;
   tbl.TableName := 'sdriofhwo';
   if (tbl.Exists) then
    UnitTestList.WriteToErrorLog('Table exists before create');
   tbl.FieldDefs.Add('id',ftAutoInc);
   tbl.CreateTable;

   if (not tbl.Exists) then
    UnitTestList.WriteToErrorLog('Table does not exists after create #1');
   tbl.Free;

   sl := TStringList.Create;
   db.GetTablesList(sl);

   if (sl.Count = 0) or (sl.IndexOf('Sdriofhwo') = -1) then
    UnitTestList.WriteToErrorLog('Table does not exists after create #3');

   if (sl.IndexOf('Sdaseofh034-riofhwo') <> -1) then
    UnitTestList.WriteToErrorLog('Dummy table exists');

   sl.Free;

   tbl := TACRTable.Create(nil);
   tbl.DatabaseName := db.DatabaseName;
   tbl.TableName := 'Sdriofhwo';
   if (not tbl.Exists) then
    UnitTestList.WriteToErrorLog('Table does not exists after create #2');
   tbl.DeleteTable;
   tbl.Free;
end;

procedure TUnitTestDiskTableEngine.TestCreateTable;
{$IFDEF ACR5H}
var state: TACRTableState;
{$ENDIF}
begin
  ACRTable.FieldDefs.Clear;
  ACRTable.FieldDefs.Add('Field1',ftInteger,0,False);
  ACRTable.FieldDefs.Add('Field2',ftString,500,False);
  ACRTable.FieldDefs.Add('Field3',ftDateTime,0,False);
  ACRTable.FieldDefs.Add('Field4',ftDate,0,False);
  ACRTable.FieldDefs.Add('Field5',ftTime,0,False);
  ACRTable.FieldDefs.Add('Field6',ftLargeInt,0,False);
  ACRTable.FieldDefs.Add('Field7',ftBoolean,0,False);
{$IFDEF D5H}
  ACRTable.FieldDefs.Add('Field8',ftWideString,100,False);
{$ELSE}
  ACRTable.FieldDefs.Add('Field8',ftString,100,False);
{$ENDIF}
  ACRTable.FieldDefs.Add('Field9',ftSmallInt,0,False);
  ACRTable.FieldDefs.Add('Field10',ftWord,0,False);
  ACRTable.FieldDefs.Add('Field11',ftFloat,0,False);
  ACRTable.FieldDefs.Add('Field12',ftCurrency,0,False);

  if (LargeRows) then
    ACRTable.FieldDefs.Add('Field13',ftFixedChar,LargeLength,False)
  else
    ACRTable.FieldDefs.Add('Field13',ftFixedChar,SmallLength,False);
  if (LargeRows) then
    ACRTable.FieldDefs.Add('Field14',ftString,LargeLength,False)
  else
    ACRTable.FieldDefs.Add('Field14',ftString,SmallLength,False);

  ACRTable.IndexDefs.Clear;
  ACRTable.IndexDefs.Add('Index1','Field2;Field1',[ixDescending,ixCaseInsensitive]);

  UnitTestList.WriteToProcessLog('FieldDefs filled');
  try
   if (ACRTable.Exists) then
     ACRTable.DeleteTable;
   ACRTable.CreateTable;
{$IFDEF ACR5H}
   state := ACRTable.GetTableState;
   if (state.LastTableOperation <> ltoCreateTable) then
    UnitTestList.WriteToErrorLog('TUnitTestDiskTableEngine.TestCreateTable - invalid table state');
{$ENDIF}
   UnitTestList.WriteToProcessLog('Table created');
  except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('Error creating table' + #9 + 'Error:'#13#10 + e.Message);
     end;
  end;
end;


procedure TUnitTestDiskTableEngine.TestOpenTable;
begin
  try
   ACRTable.Open;
   UnitTestList.WriteToProcessLog('Table opened');
  except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('Error opening table' + #9 + 'Error:'#13#10 + e.Message);
     end;
  end;
end;


procedure TUnitTestDiskTableEngine.TestInsertRecord;
var x:      Integer;
    s,s1:   String;
{$IFDEF ACR5H}
    state:  TACRTableState;
{$ENDIF}
begin
  try
   ACRTable.Insert;
//   x := Random(MaxInt);
x:= 123456;

   ACRTable.Fields[0].AsInteger := x;
   ACRTable.Fields[1].AsString := 'sfs drsp swer80w4 r0w4 r0w rw0ers';
   ACRTable.Fields[2].AsDateTime := Now;
   ACRTable.Fields[3].AsDateTime := Now;
   ACRTable.Fields[4].AsDateTime := Now;
   TLargeIntField(ACRTable.Fields[5]).AsLargeInt := 2121432424483243;
   ACRTable.Fields[6].AsBoolean := True;
   ACRTable.Fields[7].AsString := 'rsts rsers  483243';
   ACRTable.Fields[8].AsInteger := -12747;
   ACRTable.Fields[9].AsInteger := 34659;
   ACRTable.Fields[10].AsFloat := 4455043.430943;
   ACRTable.Fields[11].AsCurrency:= 98530.36;

   if (LargeRows) then
    s := GenerateString(LargeLength)
   else
    s := GenerateString(SmallLength);
   ACRTable.Fields[12].AsString := s;
   if (LargeRows) then
    s1 := GenerateString(LargeLength)
   else
    s1 := GenerateString(SmallLength);
   ACRTable.Fields[13].AsString := s1;

   ACRTable.Post;
{$IFDEF ACR5H}
   state := ACRTable.GetTableState;
   if (state.LastTableOperation <> ltoInsert) then
    UnitTestList.WriteToErrorLog('TUnitTestDiskTableEngine.TestInsertRecord - invalid table state');
{$ENDIF}    
{
   if (ACRTable.Fields[12].AsString <> s) then
    UnitTestList.WriteToErrorLog('Error inserting record - field 12 = '+
      ACRTable.Fields[12].AsString + ', insted of s = ' + s);
   if (ACRTable.Fields[13].AsString <> s1) then
    UnitTestList.WriteToErrorLog('Error inserting record - field 13 = '+
      ACRTable.Fields[13].AsString + ', insted of s1 = ' + s1);
}
   if (ACRTable.Fields[0].AsInteger <> x) then
    UnitTestList.WriteToErrorLog('Error inserting record - integer field = '+
      ACRTable.Fields[0].AsString+', x = '+IntToStr(x)+', indexname = '+ACRTable.IndexName);
   UnitTestList.WriteToProcessLog('Table update complete');
  except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('Error updating table' + #9 + 'Error:'#13#10 + e.Message);
     end;
  end;
end;


procedure TUnitTestDiskTableEngine.TestAddRecord;
begin
  try
   ACRTable.AppendRecord([565656,'add sfs drsp swer80w4 r0w4 r0w rw0ers',
   Now,Now,Now,Null,False,'sdfsfo',4342,6546,2412334.49,323.5]);
   UnitTestList.WriteToProcessLog('Table append record complete');
  except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('Error appending record' + #9 + 'Error:'#13#10 + e.Message);
     end;
  end;
end;


procedure TUnitTestDiskTableEngine.TestUpdateRecord;
begin
  try
   ACRTable.Edit;
   ACRTable.Fields[0].AsInteger := 483243;
   ACRTable.Fields[1].AsString := 'edit sfs drsp swer80w4 r0w4 r0w rw0ers';
   ACRTable.Fields[2].AsDateTime := Now;
   ACRTable.Fields[3].AsDateTime := Now;
   ACRTable.Fields[4].AsDateTime := Now;
   TLargeIntField(ACRTable.Fields[5]).AsLargeInt := 2121432424483243;
   ACRTable.Fields[6].AsBoolean := True;
   ACRTable.Fields[7].AsString := 'rsts rsers  483243';
   ACRTable.Fields[8].AsInteger := -12747;
   ACRTable.Fields[9].AsInteger := 34659;
   ACRTable.Fields[10].AsFloat := 4455043.430943;
   ACRTable.Fields[11].AsCurrency:= 98530.36;
   ACRTable.Post;
   if (ACRTable.Fields[0].AsInteger <> 483243) then
    UnitTestList.WriteToErrorLog('Error updating record - integer field = '+
      ACRTable.Fields[0].AsString+', x = '+IntToStr(483243)+', indexname = '+ACRTable.IndexName);
   UnitTestList.WriteToProcessLog('Table update complete');
  except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('Error updating record' + #9 + 'Error:'#13#10 + e.Message);
     end;
  end;
end;


procedure TUnitTestDiskTableEngine.TestDeleteRecords;
var r,x: Integer;
    b: Boolean;
begin
  try
   ACRTable.RecNo := (ACRTable.RecordCount div 2) +  1;
   UnitTestList.WriteToProcessLog('Table delete records: record #' +
     IntToStr(ACRTable.RecNo) + '...');
   b := ACRTable.EOF;
   if (not b) then
    begin
     ACRTable.Next;
     x := ACRTable.Fields[0].AsInteger;
     ACRTable.Prior;
    end;
   ACRTable.Delete;
   if (not b) then
    begin
     if (ACRTable.Fields[0].AsInteger <> x) then
      WriteToErrorLog('Error deleting record #1, integer field = '+ACRTable.Fields[0].AsString+
        ', x = '+IntToStr(x));
    end
   else
    begin
     if (not ACRTable.Eof) then
      WriteToErrorLog('Error deleting record #1, eof not set');
    end;
   UnitTestList.WriteToProcessLog('deleted.');

   ACRTable.RecNo := ACRTable.RecordCount;
   UnitTestList.WriteToProcessLog('Table delete records: record #' +
     IntToStr(ACRTable.RecNo) + '...');
   b := ACRTable.EOF;
   if (not b) then
    begin
     ACRTable.Next;
     x := ACRTable.Fields[0].AsInteger;
     ACRTable.Prior;
    end;
   ACRTable.Delete;

   r := ACRTable.RecNo;

   if (not b) then
    begin
     if (ACRTable.Fields[0].AsInteger <> x) then
      WriteToErrorLog('Error deleting record #2, integer field = '+ACRTable.Fields[0].AsString+
        ', x = '+IntToStr(x));
    end
   else
    begin
     if (not ACRTable.Eof) then
      WriteToErrorLog('Error deleting record #2, eof not set');
    end;
   UnitTestList.WriteToProcessLog('deleted.');
   UnitTestList.WriteToProcessLog('Table delete records complete');
  except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('Error updating table' + #9 + 'Error:'#13#10 + e.Message);
     end;
  end;
end;


procedure TUnitTestDiskTableEngine.InternalNavigateTable(UseIndexes: Boolean);
var Bookmark:   TBookmark;
    Bookmark2:  TBookmark;
    Caption:    String;
begin
  if (UseIndexes) then
   begin
    ACRTable.IndexName := 'Index1';
    Caption := 'Navigate with indexes - ';
   end
  else
   begin
    ACRTable.IndexName := '';
    Caption := 'Navigate without indexes - ';
   end;

  try
   ACRTable.First;
   UnitTestList.WriteToProcessLog(Caption+'First record, RecNo = ' + IntToStr(ACRTable.RecNo));
   if (not ACRTable.Bof) then
    UnitTestList.WriteToErrorLog(Caption+'BOF not set at first record');
   if (ACRTable.Eof) then
    UnitTestList.WriteToErrorLog(Caption+'EOF is set at first record');
   if (ACRTable.RecNo <> 1) then
    UnitTestList.WriteToErrorLog(Caption+'Invalid RecNo = '+ IntToStr(ACRTable.RecNo) +' at first record');
   UnitTestList.WriteToProcessLog(Caption+'First complete');

   ACRTable.Last;
   UnitTestList.WriteToProcessLog(Caption+'Last record, RecNo = ' + IntToStr(ACRTable.RecNo));
   if (ACRTable.Bof) then
    UnitTestList.WriteToErrorLog(Caption+'BOF is set at last record');
   if (not ACRTable.Eof) then
    UnitTestList.WriteToErrorLog(Caption+'EOF is not set at last record');
   if (ACRTable.RecNo <> ACRTable.RecordCount) then
    UnitTestList.WriteToErrorLog(Caption+'Invalid RecNo = '+ IntToStr(ACRTable.RecNo) +' at last record');
   UnitTestList.WriteToProcessLog(Caption+'Last complete');

   ACRTable.RecNo := ACRTable.RecordCount div 2;
   if (ACRTable.RecNo <> ACRTable.RecordCount div 2) then
    UnitTestList.WriteToErrorLog(Caption+'Invalid RecNo = '+ IntToStr(ACRTable.RecNo) +' at middle record');
   UnitTestList.WriteToProcessLog(Caption+'Middle complete');

   Bookmark := ACRTable.GetBookmark;
   UnitTestList.WriteToProcessLog(Caption+'Get bookmark complete');

   ACRTable.Prior;
   if (ACRTable.RecNo <> (ACRTable.RecordCount div 2) - 1) then
    UnitTestList.WriteToErrorLog(Caption+'Invalid RecNo = '+ IntToStr(ACRTable.RecNo) +' at middle record - 1');
   UnitTestList.WriteToProcessLog(Caption+'Prior ok complete');

   ACRTable.GotoBookmark(Bookmark);
   if (ACRTable.RecNo <> (ACRTable.RecordCount div 2)) then
    UnitTestList.WriteToErrorLog(Caption+'Invalid RecNo = '+ IntToStr(ACRTable.RecNo) +' at middle record #2');
   UnitTestList.WriteToProcessLog(Caption+'Goto bookmark complete');

   ACRTable.Next;
   if (ACRTable.RecNo <> (ACRTable.RecordCount div 2) + 1) then
    UnitTestList.WriteToErrorLog(Caption+'Invalid RecNo = '+ IntToStr(ACRTable.RecNo) +' at middle record + 1');
   UnitTestList.WriteToProcessLog(Caption+'Next complete');

   Bookmark2 := ACRTable.GetBookmark;
   UnitTestList.WriteToProcessLog(Caption+'Get bookmark2 complete');

   if (ACRTable.CompareBookmarks(Bookmark,Bookmark2) <> -1) then
    UnitTestList.WriteToErrorLog(Caption+'Compare bookmark failed #1');

   if (ACRTable.CompareBookmarks(Bookmark,Bookmark) <> 0) then
    UnitTestList.WriteToErrorLog(Caption+'Compare bookmark failed #2');

   if (ACRTable.CompareBookmarks(Bookmark2,Bookmark) <> 1) then
    UnitTestList.WriteToErrorLog(Caption+'Compare bookmark failed #3');

   ACRTable.FreeBookmark(Bookmark);
   UnitTestList.WriteToProcessLog(Caption+'Bookmark free complete');

   ACRTable.FreeBookmark(Bookmark2);
   UnitTestList.WriteToProcessLog(Caption+'Bookmark2 free complete');

   UnitTestList.WriteToProcessLog(Caption+'Table navigate complete');
  except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog(Caption+'Error navigating table' + #9 + 'Error:'#13#10 + e.Message);
     end;
  end;
  ACRTable.IndexName := '';
end;


procedure TUnitTestDiskTableEngine.TestNavigateTable;
begin
 InternalNavigateTable(False);
 InternalNavigateTable(True);
end;

procedure TUnitTestDiskTableEngine.TestCloseTable;
begin
  try
   ACRTable.Close;
   UnitTestList.WriteToProcessLog('Table closed');
  except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('Error closing table' + #9 + 'Error:'#13#10 + e.Message);
     end;
  end;
end;


procedure TUnitTestDiskTableEngine.TestEmptyTable;
begin
  try
   TestCloseTable;
   ACRTable.EmptyTable;
   UnitTestList.WriteToProcessLog('Table is empty #1');
   TestOpenTable;
   if (ACRTable.RecordCount <> 0) then
    UnitTestList.WriteToErrorLog('RecordCount is not zero = ' +
      IntToStr(ACRTable.RecordCount));
   TestInsertRecord;
   TestCloseTable;
   ACRTable.EmptyTable;
   UnitTestList.WriteToProcessLog('Table is empty #2');
  except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('Error emptying table' + #9 + 'Error:'#13#10 + e.Message);
     end;
  end;
end;


procedure TUnitTestDiskTableEngine.TestRenameTable;
var
  OldTableName, NewTableName :   String;
begin
   TestCloseTable;
   OldTableName := ACRTable.TableName;
   NewTableName := 'new_table';

  try
   ACRTable.RenameTable(NewTableName);
  except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('1 table rename failed' + #9 + 'Error:'#13#10 + e.Message);
      ACRTable.TableName := OldTableName;
      Exit;
     end;
  end;
   ACRTable.TableName := OldTableName;
   if ACRTable.Exists then
     UnitTestList.WriteToErrorLog('Error renaming 1 table: Old table name is present yet');
   ACRTable.TableName := NewTableName;
   if not ACRTable.Exists then
     UnitTestList.WriteToErrorLog('Error renaming 1 table: New table name is not present yet');

  try
   ACRTable.Open;
   UnitTestList.WriteToProcessLog('Renamed table successfully opened');
  except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('Error opening renamed table' + #9 + 'Error:'#13#10 + e.Message);
     end;
  end;
  TestCloseTable;
{
  ACRTable.TableName := OldTableName;
  try
   ACRTable.Open;
       UnitTestList.WriteToErrorLog('Error: Table with old name has opened!');
  except
    on e: Exception do
     begin
       UnitTestList.WriteToProcessLog('Table with old name is not opened');
     end;
  end;
  TestCloseTable;
}
   ACRTable.TableName := NewTableName;
  try
   ACRTable.RenameTable(OldTableName);
  except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('2 table rename failed' + #9 + 'Error:'#13#10 + e.Message);
      ACRTable.TableName := OldTableName;
      Exit;
     end;
  end;
   ACRTable.TableName := NewTableName;
   if ACRTable.Exists then
     UnitTestList.WriteToErrorLog('Error renaming 2 table: Old table name is present yet');
   ACRTable.TableName := OldTableName;
   if not ACRTable.Exists then
     UnitTestList.WriteToErrorLog('Error renaming 2 table: New table name is not present yet');

   UnitTestList.WriteToProcessLog('Table successfully renamed twice');
end;


procedure TUnitTestDiskTableEngine.TestDeleteTable;
begin
  ACRTable.Close;

  try
   ACRTable.DeleteTable;
  except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('Error deleting table' + #9 + 'Error:'#13#10 + e.Message);
     end;
  end;

  if ACRTable.Exists
  then
   UnitTestList.WriteToErrorLog('Error deleting table: table is present yet')
  else
   UnitTestList.WriteToProcessLog('Table deleted');

end;


procedure TUnitTestDiskTableEngine.TestUniqueIndexes;
var Caption: string;
begin
 Caption := 'Unique indexes test - ';
 ACRTable := TACRTable.Create(nil);
 ACRTable.TableName := 'test1';
 ACRTable.InMemory := False;
 ACRTable.DatabaseName := db.DatabaseName;
 try
  ACRTable.FieldDefs.Clear;
  ACRTable.FieldDefs.Add('Field0',ftAutoInc,0,False);
  ACRTable.FieldDefs.Add('Field1',ftInteger,0,False);
  ACRTable.FieldDefs.Add('Field2',ftString,500,False);
  ACRTable.IndexDefs.Clear;
  ACRTable.IndexDefs.Add('Index1','Field1',[ixPrimary]);
  ACRTable.IndexDefs.Add('Index2','Field2;Field1',[ixUnique,ixDescending,ixCaseInsensitive]);
  ACRTable.CreateTable;
  WriteToProcessLog(Caption+'Table created');
  ACRTable.Open;
  WriteToProcessLog(Caption+'Table opened');
  ACRTable.Insert;
  ACRTable.FieldByName('Field1').AsInteger := -1;
  ACRTable.FieldByName('Field2').AsString := '0';
  ACRTable.Post;
  ACRTable.Insert;
  ACRTable.FieldByName('Field1').AsInteger := 1;
  ACRTable.FieldByName('Field2').AsString := '0';
  ACRTable.Post;
  ACRTable.Insert;
  try
   ACRTable.FieldByName('Field1').AsInteger := 1;
   ACRTable.FieldByName('Field2').AsString := '0';
   ACRTable.Post;
   WriteToErrorLog(Caption+'insert duplicate record did not raised an exception #1');
  except
   ACRTable.Cancel;
   WriteToProcessLog(Caption+'insert ok - exception raised #1');
  end;
  ACRTable.Insert;
  try
   ACRTable.FieldByName('Field2').AsString := '0';
   ACRTable.Post;
   WriteToErrorLog(Caption+'insert duplicate record did not raised an exception #2');
  except
   ACRTable.Cancel;
   WriteToProcessLog(Caption+'insert ok - exception raised #2');
  end;
  ACRTable.Insert;
  try
   ACRTable.FieldByName('Field1').AsInteger := 1;
   ACRTable.FieldByName('Field2').AsString := 'dasfaes';
   ACRTable.Post;
   WriteToErrorLog(Caption+'insert duplicate record did not raised an exception #3');
  except
   ACRTable.Cancel;
   WriteToProcessLog(Caption+'insert ok - exception raised #3');
  end;
  ACRTable.Insert;
  try
   ACRTable.FieldByName('Field2').AsString := 'dsfasd';
   ACRTable.Post;
   WriteToErrorLog(Caption+'insert duplicate record did not raised an exception #4');
  except
   ACRTable.Cancel;
   WriteToProcessLog(Caption+'insert ok - exception raised #4');
  end;
  ACRTable.Insert;
  ACRTable.FieldByName('Field1').AsInteger := 234;
  ACRTable.FieldByName('Field2').AsString := '0se4w';
  try
    ACRTable.Post;
    WriteToProcessLog(Caption+'insert ok - exception not raised #5');
  except
   ACRTable.Cancel;
   WriteToErrorLog(Caption+'insert unique record raised an exception #5');
  end;
  ACRTable.Insert;
  ACRTable.FieldByName('Field1').AsInteger := 237;
  ACRTable.FieldByName('Field2').AsString := '0se4w';
  try
    ACRTable.Post;
    WriteToProcessLog(Caption+'insert ok - exception not raised #6');
  except
   ACRTable.Cancel;
   WriteToErrorLog(Caption+'insert unique record raised an exception #6');
  end;
 ACRTable.Close;
 finally
  ACRTable.Free;
 end;
 ACRTable := TACRTable.Create(nil);
 ACRTable.TableName := 'Test1';
 ACRTable.InMemory := False;
 ACRTable.DatabaseName := db.DatabaseName;
 try
  ACRTable.Open;
  ACRTable.Insert;
  try
   ACRTable.FieldByName('Field2').AsString := 'dsfasd';
   ACRTable.Post;
   WriteToErrorLog(Caption+'insert duplicate record after load did not raised an exception #7');
  except
   WriteToProcessLog(Caption+'insert ok - exception raised #7');
  end;
 finally
  ACRTable.Free;
 end;
end;

procedure TUnitTestDiskTableEngine.TestFileServerSameTable;
var adb1,adb2:  TACRDatabase;
    t1,t2:      TACRTable;
    capt:       String;
begin
{$IFNDEF ACR5H}
exit;   // v.4. does not support auto-inc insert null
{$ENDIF}
 capt := 'TestFileServerSameTable - ';
 adb1 := TACRDatabase.Create(nil);
 adb2 := TACRDatabase.Create(nil);
 t1 := TACRTable.Create(nil);
 t2 := TACRTable.Create(nil);
 try
   adb1.DatabaseFileName := TempDir+'test_fs_same_table.adb';
   adb1.DatabaseName := 'test_db1';
   adb1.CreateDatabase;
   adb1.LockParams.RetryCount := 1;
   adb1.LockParams.Delay := 1;
   adb1.Open;
   adb2.DatabaseName := 'test_db2';
   adb2.DatabaseFileName := adb1.DatabaseFileName;
   adb2.LockParams.RetryCount := 1;
   adb2.LockParams.Delay := 1;
   adb2.Open;
   t1.DatabaseName := adb1.DatabaseName;
   t1.TableName := 'test';
   t2.DatabaseName := adb2.DatabaseName;
   t2.TableName := t1.TableName;
   t1.AdvFieldDefs.Add('id',aftAutoInc);
   t1.AdvFieldDefs.Add('name',aftChar,20);
   t1.IndexDefs.Add('pk','id',[ixPrimary]);
   t1.CreateTable;
   t1.Open;
   t2.Open;
   t1.IndexFieldNames := 'id';
   t2.IndexFieldNames := 'id';
   t1.InsertRecord([NULL,'aaa']);
   t1.InsertRecord([NULL,'ccc']);
   t1.InsertRecord([NULL,'bbb']);
   t2.First;
   t1.First;

   t1.Edit;
   try
     t2.Edit;
     WriteToErrorLog(capt+'Error #0');
   except on e: Exception do
     if (Pos('10583',e.Message) > 0) then
      WriteToProcessLog(capt+'OK #0')
     else
      WriteToErrorLog(capt+'Error #1');
   end;

 finally
   adb1.Close;
   adb2.Close;
   adb1.DeleteDatabase;
   t1.Free;
   t2.Free;
   adb1.Free;
   adb2.Free;
 end;

end; // TestFileServerSameTable


procedure TUnitTestDiskTableEngine.TestDeleteTableBug;
const testCount = 10;
var s,capt: String;
    q:    TACRQuery;
    db:   TACRDatabase;
    sl:   TStringList;
    i:    Integer;
begin
 capt := 'TestDeleteTableBug - ';
 db := TACRDatabase.Create(nil);
 q := TACRQuery.Create(nil);
 sl := TStringList.Create;
 try
   WriteToProcessLog(capt+'Test started');
   db.DatabaseFileName := TempDir+'test_delete_table_bug.adb';
   db.CreateDatabase;
   db.Open;
   WriteToProcessLog(capt+'DB created');
   q.DatabaseName := db.DatabaseName;
   q.SQL.LoadFromFile(SQLDir+'customer_sort.sql');
   q.ExecSQL;

   for i := 1 to testCount do
   begin
    WriteToProcessLog(capt+'Creatng table #'+IntToStr(i));
    s := 't'+  StringReplace(Format('%3d',[i]),' ','0',[rfReplaceAll]);
    q.SQL.Text := 'SELECT * INTO '+s+' FROM customer_sort';
    q.ExecSQL;
    WriteToProcessLog(capt+'Creating table #'+IntToStr(i)+' - '+s+' ... OK');
   end;


//   q.SQL.LoadFromFile(SQLDir+'DBDemos.sql');
//   q.ExecSQL;

   WriteToProcessLog(capt+'Tables created');

   db.Close;
//   db.Exclusive := True;
//   db.RepairDatabase(True);
//   db.Exclusive := False;
   db.Open;

   db.GetTablesList(sl);

   if (sl.Count <> (testCount+1)) then
    WriteToErrorLog(capt + 'Invalid tables count: '+IntToStr(sl.Count));

   for i := 0 to sl.Count-1 do
   begin
    WriteToProcessLog(capt+'Deleting table #'+IntToStr(i)+' - '+sl.Strings[i]);
    q.SQL.Text := 'DROP TABLE ['+sl.Strings[i]+'] CASCADE';
    q.ExecSQL;
    WriteToProcessLog(capt+'Deleting table #'+IntToStr(i)+' - '+sl.Strings[i]+' ... OK');
   end;

   sl.Clear;
   db.GetTablesList(sl);

   if (sl.Count <> 0) then
    WriteToErrorLog(capt + 'Invalid tables count #2: '+IntToStr(sl.Count));

   WriteToProcessLog(capt+'Test finished');
 finally
   sl.Free;
   q.Free;
   db.Close;
   db.DeleteDatabase;
   if (db.Exists) then
    WriteToErrorLog(capt+'cannot delete database');
   db.Free;
 end;
end; // TestDeleteTableBug


procedure TUnitTestDiskTableEngine.TestRepairDatabaseBug;
var capt: String;
var t:    TACRTable;
    db:   TACRDatabase;
    ses:  TACRSession;
    s,s1: AnsiString;
    bOK:  Boolean;
begin
  capt := 'TestRepairDatabaseBug - ';
  db := TACRDatabase.Create(nil);
  t :=  TACRTable.Create(nil);
  ses := TACRSession.Create(nil);
  try
    ses.SessionName := 'ses1';
    db.SessionName := ses.SessionName;
    db.DatabaseName := 'DB1';
    db.DatabaseFileName := TempDir+'test_repair.adb';
    if (not db.Exists) then
     db.CreateDatabase;
    db.Open;
    t.DatabaseName := db.DatabaseName;
    t.SessionName := db.SessionName;
    t.TableName := 'test';
    if (t.Exists) then
     t.DeleteTable(True);
    t.FieldDefs.Add('field1',ftFixedChar,100);
    t.FieldDefs.Add('field2',ftFloat,0);
    t.CreateTable;
    if (not t.Exists) then
     WriteToErrorLog(capt+'table was not created');

    db.Close;
    db.Exclusive := True;
    bOK := db.RepairDatabase(s,False);
    if (bOK) then
     bOK := db.RepairDatabase(s1,True)
    else
     WriteToErrorLog(capt+'database was not repaired');
    if (bOK) then
     bOK := db.RepairDatabase(s1,False);

    if (Length(s) > 0) or (Length(s1) > 0) then
     WriteToErrorLog(capt+'Repair errors #1: '+#13#10+s+#13#10+s1);
    db.Open;

    s := '';
    bOK := t.RepairTable(s,False);
    if (not bOK) or (Length(s) > 0) then
     WriteToErrorLog(capt+'Repair errors #2: '+#13#10+s);

    s := '';
    bOK := t.RepairTable(s,True);
    if (not bOK) or (Length(s) > 0) then
     WriteToErrorLog(capt+'Repair errors #3: '+#13#10+s);

    if (not t.Exists) then
     WriteToErrorLog(capt+'TABLE DESTROYED');

  finally
    db.Close;
    db.DeleteDatabase;
    t.Free;
    ses.Free;
    db.Free;
  end;
end; // TestRepairDatabaseBug


procedure TUnitTestDiskTableEngine.TestGuid;
var capt: String;
var t:    TACRTable;
    db:   TACRDatabase;
    s,s1: AnsiString;
    bOK:  Boolean;
begin
  capt := 'TestGuid - ';
  db := TACRDatabase.Create(nil);
  t :=  TACRTable.Create(nil);
  try
    db.DatabaseName := 'DB1';
    db.DatabaseFileName := TempDir+'test_guid.adb';
    if (not db.Exists) then
     db.CreateDatabase;
    db.Open;
    t.DatabaseName := db.DatabaseName;
    t.SessionName := db.SessionName;
    t.TableName := 'test';
    if (t.Exists) then
     t.DeleteTable(True);
    t.FieldDefs.Add('id',ftAutoInc);
    t.FieldDefs.Add('guid',ftGuid);
    t.IndexDefs.Add('PK','id',[ixPrimary]);
    t.IndexDefs.Add('idx1','guid',[ixUnique]);
    t.CreateTable;
    if (not t.Exists) then
     WriteToErrorLog(capt+'table was not created');
    WriteToProcessLog(capt+'GUID table created');
    t.Open;
    t.Insert;
    t.Fields[1].AsString := '{BED38FF4-E3FE-4DF1-B947-EA069CF63509}';
    t.Post;
    t.Insert;
    t.Fields[1].AsString := '{BED38FF4-E3FE-4DF1-B947-EA069CF63508}';
    t.Post;
    t.IndexName := 'idx1';
    t.First;
    if (t.Fields[1].AsString <> '{BED38FF4-E3FE-4DF1-B947-EA069CF63508}') then
     WriteToErrorLog(capt+'Error #1');
    WriteToProcessLog(capt+'GUID test finished');

  finally
    db.Close;
    db.DeleteDatabase;
    t.Free;
    db.Free;
  end;
end; // TestGuid


procedure TUnitTestDiskTableEngine.TestExclusive;
begin
  table1.Exclusive := False;
  table1.Open;
  WriteToProcessLog('table1 is opened in non-exclusive mode');
  table2.TableName := 'table1';
  table2.Exclusive := False;
  try
   table2.Open;
   WriteToProcessLog('table2 is opened too');
  except
   WriteToErrorLog('2 tables open error');
  end;
  table1.Close;
  WriteToProcessLog('table1 is closed');
  table2.Close;
  WriteToProcessLog('table2 is closed, too');

  table1.Exclusive := True;
  table1.Open;
  WriteToProcessLog('table1 is opened in exclusive mode');
  try
   WriteToProcessLog('Try to open second table in non-exclusive mode...');
   table2.Open;
   WriteToErrorLog('Exclusive open table error: table2 is opened in non-exclusive mode');
   table2.Close;
  except
   WriteToProcessLog('... OK: non-exclusive opening blocked');
  end;
  table2.Exclusive := True;
  try
   WriteToProcessLog('Try to open second table in exclusive mode...');
   table2.Open;
   WriteToErrorLog('Exclusive open table error: table2 is opened in exclusive mode too');
   table2.Close;
  except
   WriteToProcessLog('... OK: exclusive opening blocked');
  end;
  table1.Close;
end;


procedure TUnitTestDiskTableEngine.TestShort;
begin
{$IFDEF ACR5H}
 CheckAction(TestGuid,'Test Guid');
{$ENDIF}
 CheckAction(TestRepairDatabaseBug,'Test ReapirDatabase bug');
 CheckAction(TestDeleteTableBug,'Test delete table bug');
 CheckAction(MainTest, 'Main test of disk table engine');
end;

procedure TUnitTestDiskTableEngine.TestExceptions;
begin
 CheckAction(MainTestExceptions, 'Main test exceptions of disk table engine');
end;


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


initialization
  UnitTestDiskTableEngine := TUnitTestDiskTableEngine.Create(UnitTestList);

finalization
  UnitTestDiskTableEngine.Free;

end.
