unit utMasterDetail;

interface

{$I UTConfig.Inc}

uses uTestList, SysUtils, Db,
{$IFDEF D6H}
Variants,
{$ENDIF}
DBTables,
{$IFDEF ACR5H}
     ACRComMain,
{$ENDIF}
    ACRMain;

type
  TUnitTestMasterDetail = class(TUnitTest)
   private
    ACRdb:    TACRDatabase;
    ACRTable: TACRTable;
    Table:    TTable;
    ACRTable1:TACRTable;
    Table1:   TTable;
    procedure TestCreateTable;
    procedure CheckTables(Caption: String);

    procedure SetIndex(IndexName: String);
    procedure InternalTestMasterDetail(Caption: String);
   public
    procedure TestMasterDetail;
    procedure TestMasterDetailDisk;
    procedure TestShort; override;
  end;

var
  UnitTestMasterDetail: TUnitTestMasterDetail;


implementation

procedure TUnitTestMasterDetail.CheckTables(Caption: String);
begin
 if (ACRTable1.BOF <> Table1.BOF) then
  WriteToErrorLog(Caption+' failed #1, BOF = '
    +IntToStr(Word(ACRTable1.BOF))+', BDE BOF = '+IntToStr(Word(Table1.BOF)));
 if (ACRTable1.EOF <> Table1.EOF) then
  WriteToErrorLog(Caption+' failed #2, EOF = '
    +IntToStr(Word(ACRTable1.EOF))+', BDE EOF = '+IntToStr(Word(Table1.EOF)));
// if (ACRTable.RecNo <> Table.RecNo) then
//  WriteToErrorLog(Caption+' failed #3, RecNo = '
//    +IntToStr(ACRTable.RecNo)+', BDE RecNo = '+IntToStr(Table.RecNo));
 if (ACRTable1.RecordCount <> Table1.RecordCount) then
  WriteToErrorLog(Caption+' failed #3, record count = '
    +IntToStr(ACRTable1.RecordCount)+', BDE record count = '+IntToStr(Table1.RecordCount));
end;


procedure TUnitTestMasterDetail.TestCreateTable;
begin
  if (ACRTable.InMemory) then
    UnitTestList.WriteToProcessLog('create table in memory mode');
  if (ACRTable.Temporary) then
    UnitTestList.WriteToProcessLog('create table in temporary mode');

  Table.FieldDefs.Clear;
  Table.FieldDefs.Add('ID',ftAutoInc,0,False);
  Table.IndexDefs.Clear;
  Table.IndexDefs.Add('','ID',[ixPrimary]);

  Table1.FieldDefs.Clear;
  Table1.FieldDefs.Add('ID',ftAutoInc,0,False);
  Table1.FieldDefs.Add('Field1',ftInteger,0,False);
  Table1.IndexDefs.Clear;
  Table1.IndexDefs.Add('','ID',[ixPrimary]);
  Table1.IndexDefs.Add('Index1','Field1',[ixCaseInsensitive]);

  ACRTable.FieldDefs.Clear;
  ACRTable.FieldDefs.Add('ID',ftAutoInc,0,False);
  ACRTable.IndexDefs.Clear;
  ACRTable.IndexDefs.Add('idx','ID',[ixPrimary]);

  ACRTable1.FieldDefs.Clear;
  ACRTable1.FieldDefs.Add('ID',ftAutoInc,0,False);
  ACRTable1.FieldDefs.Add('Field1',ftInteger,0,False);
  ACRTable1.IndexDefs.Clear;
  ACRTable1.IndexDefs.Add('idx','ID',[ixPrimary]);
  ACRTable1.IndexDefs.Add('Index1','Field1',[ixCaseInsensitive]);

  UnitTestList.WriteToProcessLog('FieldDefs filled');
  try
   if (ACRTable.Exists) then
    ACRTable.DeleteTable;
   ACRTable.CreateTable;

   if (ACRTable1.Exists) then
    ACRTable1.DeleteTable;
   ACRTable1.CreateTable;

   if (Table.Exists) then
    Table.DeleteTable;
   Table.CreateTable;

   if (Table1.Exists) then
    Table1.DeleteTable;
   Table1.CreateTable;

   UnitTestList.WriteToProcessLog('Tables created');
  except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('Error creating table' + #9 + 'Error:'#13#10 + e.Message);
     end;
  end;
  try
   ACRTable.Open;
   Table.Open;
   ACRTable1.Open;
   Table1.Open;
   CheckTables('CreateTable, after open');
   UnitTestList.WriteToProcessLog('Table opened');
  except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('Error opening table' + #9 + 'Error:'#13#10 + e.Message);
     end;
  end;
  ACRTable.Insert;
  ACRTable.Post;
  ACRTable.Insert;
  ACRTable.Post;
  ACRTable.Insert;
  ACRTable.Post;
  ACRTable.Insert;
  ACRTable.Post;
  ACRTable.Insert;
  ACRTable.Post;

  ACRTable1.Insert;
  ACRTable1.Fields[1].AsInteger := 1;
  ACRTable1.Post;
  ACRTable1.Insert;
  ACRTable1.Fields[1].AsInteger := 2;
  ACRTable1.Post;
  ACRTable1.Insert;
  ACRTable1.Fields[1].AsInteger := 5;
  ACRTable1.Post;
  ACRTable1.Insert;
  ACRTable1.Fields[1].AsInteger := 1;
  ACRTable1.Post;
  ACRTable1.Insert;
  ACRTable1.Fields[1].AsInteger := 3;
  ACRTable1.Post;
  ACRTable1.Insert;
  ACRTable1.Fields[1].AsInteger := 5;
  ACRTable1.Post;
  ACRTable1.Insert;
  ACRTable1.Fields[1].AsInteger := 3;
  ACRTable1.Post;
  ACRTable1.Insert;
  ACRTable1.Fields[1].AsInteger := 5;
  ACRTable1.Post;

  ACRTable.First;
  while not ACRTable.Eof do
   begin
    Table.Insert;
    Table.Post;
    ACRTable.Next;
   end;
  if (ACRTable.RecordCount <> Table.RecordCount) then
   WriteToErrorLog('ACRTable.RecordCount <> Table.RecordCount');

  ACRTable1.First;
  while not ACRTable1.Eof do
   begin
    Table1.Insert;
    Table1.Fields[1].Assign(ACRTable1.Fields[1]);
    Table1.Post;
    ACRTable1.Next;
   end;

  Table1.Last;
  ACRTable1.Last;
  CheckTables('CreateTable, after inserts');
end;


procedure TUnitTestMasterDetail.SetIndex(IndexName: String);
begin
  ACRTable1.IndexName := IndexName;
  Table1.IndexName := IndexName;
  if (Table1.IndexName <> ACRTable1.IndexName) then
   WriteToErrorLog('Cannot set index - '+IndexName);
end;


procedure TUnitTestMasterDetail.InternalTestMasterDetail(Caption: String);
var i:        Integer;
    ds,ads:   TDataSource;
begin
  SetIndex('Index1');
  i := 1;
  ACRTable.First;
  Table.First;
  ds := TDataSource.Create(nil);
  ads := TDataSource.Create(nil);
  try
    ds.DataSet := Table;
    ads.DataSet := ACRTable;
    WriteToProcessLog('Datasources are created');
    try
     Table1.MasterSource := ds;
    except
     WriteToErrorLog('Table1.MasterSource set failed');
     raise;
    end;
    try
     Table1.MasterFields := 'ID';
    except
     WriteToErrorLog('Table1.MasterFields set failed');
     raise;
    end;
    try
     ACRTable1.MasterSource := ads;
    except
     WriteToErrorLog('ACRTable1.MasterSource set failed');
     raise;
    end;
    try
     ACRTable1.MasterFields := 'ID';
    except
     WriteToErrorLog('ACRTable1.MasterFields set failed');
     raise;
    end;
    while (not Table.Eof) do
     begin
      CheckTables('MasterDetail, RecordNo = '+IntToStr(i));
      Inc(i);
      ACRTable.Next;
      Table.Next;
     end;
    if (Table.Eof <> ACRTable.Eof) then
      WriteToErrorLog('Table.Eof <> ACRTable.Eof');
  finally
    Table1.MasterSource := nil;
    ACRTable1.MasterSource := nil;
    ads.Free;
    ds.Free;
  end;
end;


procedure TUnitTestMasterDetail.TestMasterDetail;
begin
 ACRTable := TACRTable.Create(nil);
 Table := TTable.Create(nil);
 ACRTable1 := TACRTable.Create(nil);
 Table1 := TTable.Create(nil);
 try
   ACRTable1.TableName := 'test2';
   ACRTable1.InMemory := True;
   ACRTable.TableName := 'test';
   ACRTable.InMemory := True;
   Table.TableType := ttParadox;
   Table.TableName := 'test';
   Table.DatabaseName := Self.TempDir;
   Table1.TableType := ttParadox;
   Table1.TableName := 'test2';
   Table1.DatabaseName := Self.TempDir;
   CheckAction(TestCreateTable, 'Test create table');

   WriteToProcessLog('Testing master/detail');
   InternalTestMasterDetail('Testing master/detail - ');
   WriteToProcessLog('Testing master/detail complete');

 finally
   ACRTable.Close;
   if (not ACRTable.Temporary) then
     ACRTable.DeleteTable(True);
   ACRTable.Free;
   Table.Close;
   Table.DeleteTable;
   Table.Free;
   ACRTable1.Close;
   if (not ACRTable1.Temporary) then
     ACRTable1.DeleteTable(True);
   ACRTable1.Free;
   Table1.Close;
   Table1.DeleteTable;
   Table1.Free;
 end;
end;

procedure TUnitTestMasterDetail.TestMasterDetailDisk;
begin
 ACRdb := TACRDatabase.Create(nil);
 ACRdb.DatabaseName := 'testDB';
 ACRdb.DatabaseFileName := TempDir+'testDB.adb';
 if (ACRdb.Exists) then
  ACRdb.DeleteDatabase;
 ACRdb.CreateDatabase;
 ACRdb.Open;
 ACRTable := TACRTable.Create(nil);
 Table := TTable.Create(nil);
 ACRTable1 := TACRTable.Create(nil);
 Table1 := TTable.Create(nil);
 try
   ACRTable1.TableName := 'test2';
   ACRTable1.DatabaseName := 'testDB';
   ACRTable.TableName := 'test';
   ACRTable.DatabaseName := 'testDB';
   Table.TableType := ttParadox;
   Table.TableName := 'test';
   Table.DatabaseName := Self.TempDir;
   Table1.TableType := ttParadox;
   Table1.TableName := 'test2';
   Table1.DatabaseName := Self.TempDir;
   CheckAction(TestCreateTable, 'Test create table');

   WriteToProcessLog('Testing master/detail');
   InternalTestMasterDetail('Testing master/detail - ');
   WriteToProcessLog('Testing master/detail complete');

 finally
   ACRTable.Close;
   ACRTable.DeleteTable(True);
   ACRTable.Free;
   Table.Close;
   Table.DeleteTable;
   Table.Free;
   ACRTable1.Close;
   ACRTable1.DeleteTable(True);
   ACRTable1.Free;
   Table1.Close;
   Table1.DeleteTable;
   Table1.Free;
   ACRdb.Close;
   ACRdb.DeleteDatabase;
   ACRdb.Free;
 end;
end;

procedure TUnitTestMasterDetail.TestShort;
begin
 CheckAction(TestMasterDetail, 'Main test of master/detail operations');
 CheckAction(TestMasterDetailDisk, 'Main test of master/detail operations on disk tables');
end;


initialization
  UnitTestMasterDetail := TUnitTestMasterDetail.Create(UnitTestList);

finalization
  UnitTestMasterDetail.Free;
end.
