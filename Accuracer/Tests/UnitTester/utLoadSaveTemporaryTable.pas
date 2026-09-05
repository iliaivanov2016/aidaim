unit utLoadSaveTemporaryTable;

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

  TUnitLoadSaveTemporaryTable = class(TUnitTest)
  private
    function CompareTables(Table1,Table2: TACRTable): Boolean;
    procedure TestLoadSave;
   public
    procedure TestShort; override;
  end;

var
  UnitTestLoadSaveTemporaryTable: TUnitLoadSaveTemporaryTable;

implementation

function TUnitLoadSaveTemporaryTable.CompareTables(Table1,Table2: TACRTable): Boolean;
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
    if (Table1.Fields[i].Value <> Table2.Fields[i].Value)
     then Exit;

   Table1.Next;
   Table2.Next;
  end;

 if (Table1.Eof = Table2.Eof) then
   Result := True;

end;


procedure TUnitLoadSaveTemporaryTable.TestLoadSave;
var Table1, Table2:   TACRTable;
    FieldDef:         TACRAdvFieldDef;
    FirstStr,LastStr: String;
    ms:               TMemoryStream;
begin
 WriteToProcessLog('Test load and save Temporary tables - start');
 Table1 := TACRTable.Create(nil);
 Table2 := TACRTable.Create(nil);

 Table2.InMemory := True;
 Table2.TableName := 'test_copy';
 Table1.Temporary := True;
 Table1.TableName := 'test';
 Table1.AdvFieldDefs.Clear;
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

 WriteToProcessLog('Test load and save Temporary tables - table1 created');
 Table1.Open;
 WriteToProcessLog('Test load and save Temporary tables - table1 opened');
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
 WriteToProcessLog('Test load and save Temporary tables - table1 filled');

 Table1.IndexName := 'Index1';

 Table2.AdvFieldDefs.Assign(Table1.AdvFieldDefs);
 Table2.IndexDefs.Assign(Table1.IndexDefs);
 Table2.CreateTable;
 Table2.IndexName := 'Index1';
 Table2.Open;
 CopyDatasets(Table1,Table2,True,tbopCopy);
 if (not CompareTables(Table1,Table2)) then
  WriteToErrorLog('Test load and save Temporary tables - tables not equal #1');

 ms := TMemoryStream.Create;
 try
   Table1.Handle.SaveTableToStream(ms);
   WriteToProcessLog('Test load and save Temporary tables - table1 saved');

   Table1.Close;
   ms.Position := 0;
   Table1.LoadTableFromStream(ms);
   Table1.Open;
   Table2.First;
   if (not CompareTables(Table1,Table2)) then
    WriteToErrorLog('Test load and save Temporary tables - tables not equal #2');

   Table1.Close;
   Table2.Close;
   Table2.DeleteTable(True);
 finally
   ms.Free;
 end;


 Table1.ForeignKeyDefs.Clear;
 Table1.FieldDefs.Clear;
 Table1.IndexDefs.Clear;
 Table1.AdvIndexDefs.Clear;
 Table1.AdvFieldDefs.Clear;
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
 Table1.Open;

 Table2.AdvFieldDefs.Assign(Table1.AdvFieldDefs);
 Table2.IndexDefs.Assign(Table1.IndexDefs);
 Table2.CreateTable;
 Table2.Open;
 CopyDatasets(Table1,Table2,True,tbopCopy);
 if (not CompareTables(Table1,Table2)) then
  WriteToErrorLog('Test load and save Temporary tables - tables not equal #1');

 ms := TMemoryStream.Create;
 try
   Table1.Handle.SaveTableToStream(ms);
   WriteToProcessLog('Test load and save Temporary tables - table1 saved');

   Table1.Close;
   ms.Position := 0;
   Table1.LoadTableFromStream(ms);
   Table1.Open;
   Table2.First;
   if (not CompareTables(Table1,Table2)) then
    WriteToErrorLog('Test load and save Temporary tables - tables not equal #2');

   Table1.Close;
   Table2.Close;
   Table2.DeleteTable(True);
 finally
   ms.Free;
 end;

 Table2.Free;
 Table1.Free;
 WriteToProcessLog('Test load and save Temporary tables - finish');
end;

procedure TUnitLoadSaveTemporaryTable.TestShort;
begin
 CheckAction(TestLoadSave, 'Test load and save Temporary tables');
end;


initialization
  UnitTestLoadSaveTemporaryTable := TUnitLoadSaveTemporaryTable.Create(UnitTestList);

finalization
  UnitTestLoadSaveTemporaryTable.Free;

end.
