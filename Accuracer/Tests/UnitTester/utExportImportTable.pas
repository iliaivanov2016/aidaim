unit utExportImportTable;

interface

{$I UTConfig.Inc}

uses uTestList, SysUtils, DB,
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

  TUnitImportExportTable = class(TUnitTest)
  private
    function CompareTables(Table1,Table2: TACRTable): Boolean;
    procedure TestImportExport;
   public
    procedure TestShort; override;
  end;

var
  UnitTestImportExportTable: TUnitImportExportTable;
  Table1, Table2, Table3: TACRTable;

implementation

function TUnitImportExportTable.CompareTables(Table1,Table2: TACRTable): Boolean;
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


procedure CreateTable;
begin
 Table3.CreateTable;
end;


procedure TUnitImportExportTable.TestImportExport;
var
    FieldDef:               TACRAdvFieldDef;
    s:                      String;
begin
 WriteToProcessLog('Test import and export tables - start');
 Table1 := TACRTable.Create(nil);
 Table2 := TACRTable.Create(nil);
 Table3 := TACRTable.Create(nil);

 Table3.InMemory := True;
 Table3.TableName := 'test3';
 Table2.InMemory := True;
 Table2.TableName := 'test2';
 Table1.InMemory := True;
 Table1.TableName := 'test1';
 Table1.AdvFieldDefs.Clear;
 Table1.AdvFieldDefs.Add('ID',aftAutoInc);
 FieldDef := Table1.AdvFieldDefs.AddFieldDef;
 //FieldDef.DefaultValueType := dvtConst;
 FieldDef.DefaultValue.AsString := 'test';
 FieldDef.Name := 'str';
 FieldDef.DataType := aftString;
 FieldDef.Size := 50;
// FieldDef.Required := True;
 FieldDef := Table1.AdvFieldDefs.AddFieldDef;
 FieldDef.Name := 'memo';
 FieldDef.DataType := aftMemo;
 FieldDef.BLOBCompressionAlgorithm := caBZIP;
 FieldDef.BLOBCompressionMode := 9;
 FieldDef.BLOBBlockSize := 20;
 Table1.CreateTable;

 WriteToProcessLog('Test import and export tables - table1 created');
 Table1.Open;
 WriteToProcessLog('Test import and export tables - table1 opened');
 Table1.Insert;
 Table1.FieldByName('str').AsString := 'test';
 Table1.FieldByName('memo').AsString := 'test 23 2i - 42i- 2resd test 23 2i - 42i- 2resd test 23 2i - 42i- 2resd test 23 2i - 42i- 2resd test 23 2i - 42i- 2resd test 23 2i - 42i- 2resd test 23 2i - 42i- 2resd test 23 2i - 42i- 2resd test 23 2i - 42i- 2resd test 23 2i - 42i- 2resd test 23 2i -';
 Table1.Post;
 Table1.Insert;
 Table1.FieldByName('str').AsString := 'test2';
 Table1.FieldByName('memo').AsString := 'test42w  23 2i - 42i- 2resd ';
 Table1.Post;
 Table1.Insert;
 Table1.FieldByName('str').AsString := 'test2223 2323 ~!#@3';
 Table1.Post;
 WriteToProcessLog('Test import and export tables - table1 filled');

 // import -  export
 if (not Table2.ImportTable(Table1,s)) then
  WriteToErrorLog('Test import and export tables - import failed. Log: '+s);
 Table2.Open;
 if (not CompareTables(Table1,Table2)) then
  WriteToErrorLog('Test import and export tables - tables not equal #1');

 Table2.First; 
 if (not Table2.ExportTable(Table3,CreateTable,s)) then
  WriteToErrorLog('Test import and export tables - export failed. Log: '+s);
 Table3.Open;

 if (not CompareTables(Table3,Table2)) then
  WriteToErrorLog('Test import and export tables - tables not equal #2');

 if (not CompareTables(Table1,Table3)) then
  WriteToErrorLog('Test import and export tables - tables not equal #3');

 Table3.Close;
 Table3.DeleteTable;
 Table3.Free;

 Table2.Close;
 Table2.DeleteTable;
 Table2.Free;

 Table1.Close;
 Table1.DeleteTable;
 Table1.Free;
 WriteToProcessLog('Test import and export tables - finish');
end;

procedure TUnitImportExportTable.TestShort;
begin
 CheckAction(TestImportExport, 'Test import and export tables');
end;


initialization
  UnitTestImportExportTable := TUnitImportExportTable.Create(UnitTestList);

finalization
  UnitTestImportExportTable.Free;

end.
