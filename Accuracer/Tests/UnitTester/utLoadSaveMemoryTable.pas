unit utLoadSaveMemoryTable;

interface

{$I UTConfig.Inc}

uses uTestList, SysUtils, Db,
{$IFDEF D6H}
Variants,
{$ENDIF}
Classes,
    ACRMain, 
{$IFDEF ACR5H}
    ACRComMain,
{$ENDIF}
    ACRCompression, ACRTypes;

type

  TUnitLoadSaveMemoryTable = class(TUnitTest)
  private
    function CompareTables(Table1,Table2: TACRTable): Boolean;
    procedure TestLoadSave;
   public
    procedure TestShort; override;
  end;

var
  UnitTestLoadSaveMemoryTable: TUnitLoadSaveMemoryTable;

implementation

function TUnitLoadSaveMemoryTable.CompareTables(Table1,Table2: TACRTable): Boolean;
var i: integer;
begin
 Result := False;

 if (Table1.RecordCount <> Table2.RecordCount) then
  Exit;
 if (Table1.AdvFieldDefs.Count <> Table2.AdvFieldDefs.Count) then
  Exit;
 if (Table1.IndexDefs.Count <> Table2.IndexDefs.Count) then
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
 for i := 0 to Table1.IndexDefs.Count-1 do
  begin
   if (Table1.IndexDefs[i].Fields <> Table2.IndexDefs[i].Fields) then
    Exit;
   if (Table1.IndexDefs[i].CaseInsFields <> Table2.IndexDefs[i].CaseInsFields) then
    Exit;
   if (Table1.IndexDefs[i].DescFields <> Table2.IndexDefs[i].DescFields) then
    Exit;
  end;

 Table1.First;
 Table2.First;

 while not Table1.Eof do
  begin

   for i := 0 to Table1.FieldCount-1 do
    if (Table1.Fields[i].AsString <> Table2.Fields[i].AsString)
     then Exit;

   Table1.Next;
   Table2.Next;
  end;

 if (Table1.Eof = Table2.Eof) then
   Result := True;

end;


procedure TUnitLoadSaveMemoryTable.TestLoadSave;
var Table1, Table2:   TACRTable;
    FieldDef:         TACRAdvFieldDef;
    FirstStr,LastStr: String;
begin
 WriteToProcessLog('Test load and save memory tables - start');
 Table1 := TACRTable.Create(nil);
 Table2 := TACRTable.Create(nil);

 Table2.InMemory := True;
 Table2.TableName := 'test3232';
 Table1.InMemory := True;
 Table1.TableName := 'test';
 Table1.AdvFieldDefs.Clear;
 Table1.AdvFieldDefs.Add('ID',aftAutoInc);
 FieldDef := Table1.AdvFieldDefs.AddFieldDef;
 FieldDef.Name := 'str';
 FieldDef.DataType := aftString;
 FieldDef.Size := 50;
 FieldDef.Required := True;
 FieldDef := Table1.AdvFieldDefs.AddFieldDef;
 FieldDef.Name := 'memo';
 FieldDef.DataType := aftMemo;
 FieldDef.BLOBCompressionAlgorithm := caBZIP;
 FieldDef.BLOBCompressionMode := 9;
 FieldDef.BLOBBlockSize := 20;
 Table1.IndexDefs.Clear;
 Table1.IndexDefs.Add('Index1','str',[ixCaseInsensitive,ixDescending]);
 Table1.CreateTable;

 WriteToProcessLog('Test load and save memory tables - table1 created');
 Table1.Open;
 WriteToProcessLog('Test load and save memory tables - table1 opened');
 Table1.Insert;
 Table1.FieldByName('str').AsString := 'tEst';
 Table1.FieldByName('memo').AsString := 'test 23 2i - 42i- 2resd test 23 2i - 42i- 2resd test 23 2i - 42i- 2resd test 23 2i - 42i- 2resd test 23 2i - 42i- 2resd test 23 2i - 42i- 2resd test 23 2i - 42i- 2resd test 23 2i - 42i- 2resd test 23 2i - 42i- 2resd test 23 2i - 42i- 2resd test 23 2i -';
 Table1.Post;
 Table1.Insert;
 Table1.FieldByName('str').AsString := 'Test2';
 Table1.FieldByName('memo').AsString := 'test42w  23 2i - 42i- 2resd ';
 Table1.Post;
 Table1.Insert;
 Table1.FieldByName('str').AsString := 'teSt2223 2323 ~!#@3';
 Table1.Post;
 WriteToProcessLog('Test load and save memory tables - table1 filled');

 Table1.IndexName := 'Index1';
 Table1.First;
 FirstStr := Table1.FieldByName('str').AsString;
 Table1.Last;
 LastStr := Table1.FieldByName('str').AsString;
 Table1.IndexName := '';
 Table1.Close;


 Table1.SaveTableToFile(UnitTestList.TempDir + 'test.tbl',caZLIB,9,100);
 WriteToProcessLog('Test load and save memory tables - table1 saved');

 WriteToProcessLog('Test load and save memory tables - table1 closed');
 Table1.RenameTable('old_test');
 WriteToProcessLog('Test load and save memory tables - table1 renamed');
 Table1.Open;
 WriteToProcessLog('Test load and save memory tables - table1 reopened');
 if (Table1.TableName <> 'old_test') then
  WriteToErrorLog('Test load and save memory tables - rename failed. TableName = '
    +Table1.TableName);
 Table1.Close;

 if (not Table1.Exists) then
  WriteToErrorLog('Test load and save memory tables - table1 does not exists!');

 if (Table2.Exists) then
  WriteToErrorLog('Test load and save memory tables - table2 exists!');

 Table1.Open;
 Table1.Insert;
 Table1.FieldByName('str').AsString := 'test222';
 Table1.FieldByName('memo').AsString := 'test42w  23 2i - 42i- 2resd 3q2 ';
 Table1.Post;

 Table2.LoadTableFromFile(UnitTestList.TempDir + 'test.tbl');
 WriteToProcessLog('Test load and save memory tables - table2 loaded');

 Table2.Open;
 WriteToProcessLog('Test load and save memory tables - tables opened');

 if (Table2.TableName <> 'test') then
  WriteToErrorLog('Test load and save memory tables - load failed. TableName = '
    +Table2.TableName);
 if (Table2.RecordCount <> 3) then
  WriteToErrorLog('Test load and save memory tables - load failed. RecordCount = '
    +IntToStr(Table2.RecordCount));

 Table1.Delete;

 if (not CompareTables(Table1,Table2)) then
  WriteToErrorLog('Test load and save memory tables - tables not equal #1');

 Table2.IndexName := 'Index1';
 Table2.First;
 if (FirstStr <> Table2.FieldByName('str').AsString) then
  WriteToErrorLog('Error loading index - first str = '+FirstStr+
    ', current str = '+Table1.FieldByName('str').AsString);
 Table2.Last;
 if (LastStr <> Table2.FieldByName('str').AsString) then
  WriteToErrorLog('Error loading index - last str = '+LastStr+
    ', current str = '+Table1.FieldByName('str').AsString);

 Table2.Close;
 Table1.Close;
 Table1.EmptyTable;
 Table1.SaveTableToFile(UnitTestList.TempDir + 'test.tbl',caZLIB,9,100);
 Table2.DeleteTable(True);
 Table2.LoadTableFromFile(UnitTestList.TempDir + 'test.tbl');

 Table1.Open;
 Table2.Open;

 if (not CompareTables(Table1,Table2)) then
  WriteToErrorLog('Test load and save memory tables - tables not equal #1');

 Table2.Close;
 Table1.Close;

 if (Table2.Exists) then
   Table2.DeleteTable;
 Table2.Free;

 if (Table1.Exists) then
   Table1.DeleteTable;
 Table1.Free;
 SysUtils.DeleteFile(UnitTestList.TempDir + 'test.tbl');
 WriteToProcessLog('Test load and save memory tables - finish');
end;

procedure TUnitLoadSaveMemoryTable.TestShort;
begin
 CheckAction(TestLoadSave, 'Test load and save memory tables');
end;


initialization
  UnitTestLoadSaveMemoryTable := TUnitLoadSaveMemoryTable.Create(UnitTestList);

finalization
  UnitTestLoadSaveMemoryTable.Free;

end.
