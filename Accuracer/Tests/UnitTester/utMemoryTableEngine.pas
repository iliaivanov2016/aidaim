unit utMemoryTableEngine;

interface

{$I ACRVER.Inc}
{$I UTConfig.Inc}

uses uTestList, SysUtils, DB,
{$IFDEF D6H}
     Variants,
{$ENDIF}
{$IFDEF ACR5H}
     ACRComMain,
{$ENDIF}
    ACRMain, ACRExpressions, ACRConst;

type
  TUnitTestMemoryTableEngine = class(TUnitTest)
   private
    ACRTable: TACRTable;
    procedure TestDoubleCreate;
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
    procedure TestDeleteTable;
    procedure TestRecordBitmap;
    procedure TestLoadSaveTable;
    procedure TestRestructureByFieldDefsAndOpen;
   public
    procedure MainTest;
    procedure TestUniqueIndexes;
    procedure TestShort; override;
    procedure TestExceptions; override;
  end;

var
  UnitTestMemoryTableEngine: TUnitTestMemoryTableEngine;


implementation

uses Math;


procedure TUnitTestMemoryTableEngine.TestDoubleCreate;
var tbl: TACRTable;
begin
   tbl := TACRTable.Create(nil);
   tbl.InMemory := True;
   tbl.TableName := 'create2';
   if (tbl.Exists) then
    UnitTestList.WriteToErrorLog('TestDoubleCreate - Table exists before create');
   tbl.FieldDefs.Add('id',ftAutoInc);
   tbl.CreateTable;

   tbl.CreateTable;
   tbl.Open;
   tbl.Free;
end;

procedure TUnitTestMemoryTableEngine.TestCreateTable;
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
  ACRTable.IndexDefs.Clear;
  ACRTable.IndexDefs.Add('Index1','Field2;Field1',[ixDescending,ixCaseInsensitive]);

  UnitTestList.WriteToProcessLog('FieldDefs filled');
  try
   if (ACRTable.Exists) then
     ACRTable.DeleteTable;
   ACRTable.CreateTable;
   UnitTestList.WriteToProcessLog('Table created');
  except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('Error creating table' + #9 + 'Error:'#13#10 + e.Message);
     end;
  end;
end;


procedure TUnitTestMemoryTableEngine.TestOpenTable;
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


procedure TUnitTestMemoryTableEngine.TestInsertRecord;
var x: Integer;
begin
  try
   ACRTable.Insert;
   x := Random(MaxInt);
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
   ACRTable.Post;
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


procedure TUnitTestMemoryTableEngine.TestAddRecord;
begin
  try
   ACRTable.AppendRecord([Random(MaxInt),'add sfs drsp swer80w4 r0w4 r0w rw0ers',
   Now,Now,Now,Null,False,'sdfsfo',4342,6546,2412334.49,323.5]);
   UnitTestList.WriteToProcessLog('Table append record complete');
  except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('Error appending record' + #9 + 'Error:'#13#10 + e.Message);
     end;
  end;
end;


procedure TUnitTestMemoryTableEngine.TestUpdateRecord;
begin
  try
   ACRTable.Edit;
   ACRTable.Fields[0].AsInteger := 483243;
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


procedure TUnitTestMemoryTableEngine.TestDeleteRecords;
var x: Integer;
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


procedure TUnitTestMemoryTableEngine.InternalNavigateTable(UseIndexes: Boolean);
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


procedure TUnitTestMemoryTableEngine.TestNavigateTable;
begin
 InternalNavigateTable(False);
 InternalNavigateTable(True);
end;

procedure TUnitTestMemoryTableEngine.TestCloseTable;
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


procedure TUnitTestMemoryTableEngine.TestEmptyTable;
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


procedure TUnitTestMemoryTableEngine.TestDeleteTable;
begin
  try
   ACRTable.Close;
   ACRTable.DeleteTable;
   UnitTestList.WriteToProcessLog('Table deleted');
  except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('Error deleting table' + #9 + 'Error:'#13#10 + e.Message);
     end;
  end;
end;


procedure TUnitTestMemoryTableEngine.TestRecordBitmap;
var i: Integer;
begin
  ACRTable.IndexName := '';
  TestCreateTable;
  TestOpenTable;
  for i := 0 to 99 do
   TestInsertRecord;
  ACRTable.First;
  ACRTable.Delete;
  ACRTable.Filter := 'Field1 > -1';
  ACRTable.Filtered := True;
  ACRTable.IndexName := 'Index1';
  ACRTable.First;
  i := 0;
  while not ACRTable.Eof do
   begin
    Inc(i);
    ACRTable.Next;
   end;
  if (ACRTable.RecordCount <> i) then
   WriteToErrorLog('test record bitmap failed');
  TestCloseTable;
  TestDeleteTable; 
end;


procedure TUnitTestMemoryTableEngine.MainTest;
begin
 ACRTable := TACRTable.Create(nil);
 ACRTable.TableName := 'test';
 ACRTable.InMemory := True;
 try
  CheckAction(TestRestructureByFieldDefsAndOpen,'Test Restructure By FieldDefs and Open');
  CheckAction(TestDoubleCreate, 'Test exists');
  CheckAction(TestCreateTable, 'Test create table');
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
  CheckAction(TestDeleteTable, 'Test delete table');

  CheckAction(TestRecordBitmap, 'Test record bitmap');


 finally
  ACRTable.Free;
 end;
end;


procedure TUnitTestMemoryTableEngine.TestUniqueIndexes;
var Caption, FileName: string;
begin
 Caption := 'Unique indexes test - ';
 FileName := Self.TempDir+'\test_unique.tbl';
 ACRTable := TACRTable.Create(nil);
 ACRTable.TableName := 'test1';
 ACRTable.InMemory := True;
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
 ACRTable.SaveTableToFile(FileName);
 finally
  ACRTable.DeleteTable(True);
  ACRTable.Free;
 end;
 ACRTable := TACRTable.Create(nil);
 ACRTable.TableName := '';
 ACRTable.InMemory := True;
 try
  ACRTable.LoadTableFromFile(FileName);
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
  DeleteFile(FileName);
  ACRTable.Close;
  ACRTable.DeleteTable(True);
  ACRTable.Free;
 end;
end;


procedure TUnitTestMemoryTableEngine.TestShort;
begin
 CheckAction(MainTest, 'Main test of memory table engine');
end;

procedure TUnitTestMemoryTableEngine.TestExceptions;
begin
 CheckAction(TestLoadSaveTable, 'Load/save table');
 CheckAction(TestUniqueIndexes, 'Unique indexes test of memory engine');
end;


procedure TUnitTestMemoryTableEngine.TestLoadSaveTable;
var mt: TACRTable;
    caption: String;
begin
 caption := 'TUnitTestMemoryTableEngine.TestLoadSaveTable - ';
 mt := TACRTable.Create(nil);
 try
   mt.InMemory := True;
   mt.FieldDefs.Clear;
   mt.FieldDefs.Add('id',ftAutoInc);
   mt.FieldDefs.Add('name',ftString,50);
   mt.IndexDefs.Clear;
   mt.IndexDefs.Add('PK','id',[ixPrimary]);
   mt.IndexDefs.Add('idx_name','name',[]);
   mt.TableName := 'TestSave';
   mt.CreateTable;
   mt.Open;
   mt.Insert;
   mt.Fields[1].AsString := 'aaa';
   mt.Post;
   mt.Close;
   mt.TableName := 'dummy';
   try
     mt.SaveTableToFile(TempDir+'dummy.smt',caZLIB,9);
     WriteToErrorLog(caption+'save with dummy name - no exception!!!');
   except
    on e: Exception do
     WriteToProcessLog(caption+'save with dummy name - exception, OK. Exception: '+#13#10+e.Message)
    else
     WriteToProcessLog(caption+'save with dummy name - exception, OK. Unknown exception.');
   end;
   mt.TableName := 'TestSave';
   mt.SaveTableToFile(TempDir+'test.smt',caZlib,9);
   mt.DeleteTable(True);
   try
     mt.LoadTableFromFile(TempDir+'test.smt');
     mt.Open;
   except
    on e: Exception do
     WriteToProcessLog(caption+'load failed. Exception: '+#13#10+e.Message)
    else
     WriteToProcessLog(caption+'load failed. Unknown exception.');
   end;
   if (mt.TableName <> 'TestSave') then
    WriteToErrorLog(caption+'load failed - invalid TableName = '+mt.TableName);
   if (mt.RecordCount <> 1) then
    WriteToErrorLog(caption+'load failed - invalid record count = '+IntToStr(mt.RecordCount));
   mt.Close;
   mt.DeleteTable(True);
 finally
   mt.Free;
   DeleteFile(TempDir+'dummy.smt');
   DeleteFile(TempDir+'test.smt');
 end;
end;

// test like in deisgn-time
procedure TUnitTestMemoryTableEngine.TestRestructureByFieldDefsAndOpen;
var t: TACRTable;
    capt: String;
begin
  capt := 'TestRestructureByFieldDefsAndOpen - ';
  t := TACRTable.Create(nil);
  IsDesignMode := True;
  try
    t.InMemory := True;
    t.FieldDefs.Add('f1',ftInteger);
    t.TableName := 'test_restructure';
    t.Open;
    t.Close;

    t.FieldDefs.Add('f2',ftString,10);
    t.Open;
    if t.FieldCount <> 2 then
     WriteToErrorLog(capt + 'Error #1')
    else
     begin
      t.InsertRecord([1,'aaa']);
      t.Close;
      t.FieldDefs.Add('f3',ftString,10);
      t.Open;
      if t.FieldCount <> 2 then
       WriteToErrorLog(capt + 'Error #2');
     end;
  finally
    IsDesignMode := False;
    t.Close;
    t.DeleteTable(True);
    t.Free;
  end;
end; // TestRestructureByFieldDefsAndOpen


initialization
  UnitTestMemoryTableEngine := TUnitTestMemoryTableEngine.Create(UnitTestList);

finalization
  UnitTestMemoryTableEngine.Free;
end.
