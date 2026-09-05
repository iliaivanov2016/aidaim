unit utRestructure;

interface

{$I UTConfig.Inc}

uses uTestList, SysUtils, Db,
{$IFDEF D6H}
Variants,
{$ENDIF}
DBTables,
    ACRMain, 
{$IFDEF ACR5H}
   ACRComMain,
{$ENDIF}
   Classes, ACRConst, ACRTypes;

type
  TUnitTestRestructure = class(TUnitTest)
   private
    ACRTable: TACRTable;
    Table:    TTable;
    procedure TestCreateTable;
    procedure TestCreateTableAutoInc;
    procedure CompareTables(Caption: String; RestructureAutoInc: Boolean = False);

    procedure InternalRestructure(Caption: String);
   public
    procedure MainTest;
    procedure TestShort; override;
  end;

var
  UnitTestRestructure: TUnitTestRestructure;


implementation


procedure TUnitTestRestructure.CompareTables(Caption: String; RestructureAutoInc: Boolean = False);
var i: Integer;
begin
 if (ACRTable.RecordCount <> Table.RecordCount) then
  WriteToErrorLog(Caption+' failed #3, record count = '
    +IntToStr(ACRTable.RecordCount)+', BDE record count = '+IntToStr(Table.RecordCount));
 if (ACRTable.FieldDefs.Count <> Table.FieldDefs.Count) then
  WriteToErrorLog(Caption+' failed #4, fielddefs count = '
    +IntToStr(ACRTable.FieldDefs.Count)+', BDE fielddefs count = '+IntToStr(Table.FieldDefs.Count));
 if (ACRTable.IndexDefs.Count <> Table.IndexDefs.Count) then
  WriteToErrorLog(Caption+' failed #1, indexdefs count = '
    +IntToStr(ACRTable.IndexDefs.Count)+', BDE indexdes count = '+IntToStr(Table.IndexDefs.Count))
 else
 for i := 0 to Table.IndexDefs.Count-1 do
  begin
   if (Table.IndexDefs[i].Fields <> ACRTable.IndexDefs[i].Fields) then
    WriteToErrorLog(Caption+' failed #12, fields = '
      +(ACRTable.IndexDefs[i].Fields)+', BDE fields = '+(Table.IndexDefs[i].Fields));

{ bde does not set it }
{
   if (Table.IndexDefs[i].CaseInsFields <> ACRTable.IndexDefs[i].CaseInsFields) then
    WriteToErrorLog(Caption+' failed #13, case ins fields = '
      +(ACRTable.IndexDefs[i].CaseInsFields)+', BDE case ins fields = '+(Table.IndexDefs[i].CaseInsFields));
   if (Table.IndexDefs[i].DescFields <> ACRTable.IndexDefs[i].DescFields) then
    WriteToErrorLog(Caption+' failed #14, desc fields = '
      +(ACRTable.IndexDefs[i].DescFields)+', BDE desc fields = '+(Table.IndexDefs[i].DescFields));
}
  end;

 if (ACRTable.FieldCount <> Table.FieldCount) then
  WriteToErrorLog(Caption+' failed #5, field count = '
    +IntToStr(ACRTable.FieldCount)+', BDE field count = '+IntToStr(Table.FieldCount))
 else
  begin
   for i := 0 to ACRTable.FieldDefs.Count - 1 do
    begin
     if (ACRTable.FieldDefs[i].Name <> Table.FieldDefs[i].Name) then
      WriteToErrorLog(Caption+' failed #6, field name = ' +
        ACRTable.FieldDefs[i].Name + ', BDE field name = '+Table.FieldDefs[i].Name);

    if (not RestructureAutoInc) then
     if ((ACRTable.FieldDefs[i].DataType <> Table.FieldDefs[i].DataType) and
        (ACRTable.FieldDefs[i].DataType <> ftAutoInc)) or
        ((ACRTable.FieldDefs[i].DataType = ftAutoInc) and
         (Table.FieldDefs[i].DataType <> ftInteger))
         then
      WriteToErrorLog(Caption+' failed #7, field type = ' +
        IntToStr(Integer(ACRTable.FieldDefs[i].DataType)) + ', BDE field type = '+
        IntToStr(Integer(Table.FieldDefs[i].DataType)));
    if (RestructureAutoInc) then
     if (ACRTable.FieldDefs[i].DataType <> Table.FieldDefs[i].DataType) then
      WriteToErrorLog(Caption+' failed #7, field type = ' +
        IntToStr(Integer(ACRTable.FieldDefs[i].DataType)) + ', BDE field type = '+
        IntToStr(Integer(Table.FieldDefs[i].DataType)));


     if (ACRTable.FieldDefs[i].Size <> Table.FieldDefs[i].Size) then
      WriteToErrorLog(Caption+' failed #8, field size = ' +
        IntToStr(Integer(ACRTable.FieldDefs[i].Size)) + ', BDE field size = '+
        IntToStr(Integer(Table.FieldDefs[i].Size)));

     if (ACRTable.FieldDefs[i].Required <> Table.FieldDefs[i].Required) then
      WriteToErrorLog(Caption+' failed #9, field required = ' +
        IntToStr(Integer(ACRTable.FieldDefs[i].Required)) + ', BDE field required = '+
        IntToStr(Integer(Table.FieldDefs[i].Required)));

    end;
  end;
 ACRTable.First;
 Table.First;
 while (not Table.Eof) do
  begin
   for i := 0 to ACRTable.FieldCount - 1 do
    if (RestructureAutoInc and (ACRTable.Fields[i].DataType = ftAutoInc)) then
     continue
    else
    if (ACRTable.Fields[i].Value <> Table.Fields[i].Value) then
      WriteToErrorLog(Caption+' failed #10, field  value = ' +
        ACRTable.Fields[i].AsString + ', BDE field value = '+
        Table.Fields[i].AsString);
   ACRTable.Next;
   Table.Next;
  end;
 if (ACRTable.EOF <> Table.EOF) then
  WriteToErrorLog(Caption+' failed #11, EOF = '
    +IntToStr(Word(ACRTable.EOF))+', BDE EOF = '+IntToStr(Word(Table.EOF)));
end;


procedure TUnitTestRestructure.TestCreateTable;
begin
  UnitTestList.WriteToProcessLog('create tables');

  Table.FieldDefs.Clear;
  Table.FieldDefs.Add('ID',ftInteger,0,False);
  Table.FieldDefs.Add('Field1',ftInteger,0,True);
  Table.FieldDefs.Add('Field2',ftString,100,False);
  Table.FieldDefs.Add('Field3',ftString,20,False);
  Table.IndexDefs.Clear;
  Table.IndexDefs.Add('Index','ID',[ixPrimary]);
  Table.IndexDefs.Add('Index3','Field2',[ixDescending]);

  ACRTable.AdvFieldDefs.Clear;
  ACRTable.AdvFieldDefs.Add('ID',aftInteger);
  ACRTable.AdvFieldDefs.Add('Field1',aftInteger);
  ACRTable.AdvFieldDefs.Add('Field2',aftString,100,True);
  ACRTable.IndexDefs.Clear;
  ACRTable.IndexDefs.Add('Index','ID',[]);
  ACRTable.IndexDefs.Add('Index2','Field2',[ixDescending]);
  ACRTable.IndexDefs.Add('Index3','Field1',[ixDescending]);
  UnitTestList.WriteToProcessLog('FieldDefs filled');
  try
   if (ACRTable.Exists) then
    ACRTable.DeleteTable;
   ACRTable.CreateTable;

   if (Table.Exists) then
    Table.DeleteTable;
   Table.CreateTable;
   UnitTestList.WriteToProcessLog('Table created');
  except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('Error creating table' + #9 + 'Error:'#13#10 + e.Message);
     end;
  end;
  try
   ACRTable.Open;
   Table.Open;
   UnitTestList.WriteToProcessLog('Table opened');
  except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('Error opening table' + #9 + 'Error:'#13#10 + e.Message);
     end;
  end;
  ACRTable.Insert;
  ACRTable.Fields[0].AsInteger := ACRTable.RecordCount + 1;
  ACRTable.Fields[1].AsInteger := 10;
  ACRTable.Fields[2].AsString := 'aaa';
  ACRTable.Post;
  ACRTable.Insert;
  ACRTable.Fields[0].AsInteger := ACRTable.RecordCount + 1;
  ACRTable.Fields[1].AsInteger := 15;
  ACRTable.Fields[2].AsString := 'aab';
  ACRTable.Post;
  ACRTable.Insert;
  ACRTable.Fields[0].AsInteger := ACRTable.RecordCount + 1;
  ACRTable.Fields[1].AsInteger := 16;
  ACRTable.Fields[2].AsString := 'aaa';
  ACRTable.Post;
  ACRTable.Insert;
  ACRTable.Fields[0].AsInteger := ACRTable.RecordCount + 1;
  ACRTable.Fields[1].AsInteger := 15;
  ACRTable.Fields[2].AsString := 'bab';
  ACRTable.Post;
  ACRTable.Insert;
  ACRTable.Fields[0].AsInteger := ACRTable.RecordCount + 1;
  ACRTable.Fields[1].AsInteger := -20;
  ACRTable.Fields[2].AsString := 'aab';
  ACRTable.Post;
  ACRTable.Insert;
  ACRTable.Fields[0].AsInteger := ACRTable.RecordCount + 1;
  ACRTable.Fields[1].AsInteger := -10;
  ACRTable.Fields[2].AsString := 'bab';
  ACRTable.Post;

  ACRTable.First;
  while not ACRTable.Eof do
   begin
    Table.Insert;
    Table.Fields[0].Assign(ACRTable.Fields[0]);
    Table.Fields[1].Assign(ACRTable.Fields[1]);
    Table.Fields[2].Assign(ACRTable.Fields[2]);
    Table.Post;
    ACRTable.Next;
   end;

  Table.Last;
  ACRTable.Last;
end;


procedure TUnitTestRestructure.TestCreateTableAutoInc;
begin
  UnitTestList.WriteToProcessLog('create tables autoinc');

  Table.FieldDefs.Clear;
  Table.FieldDefs.Add('ID',ftAutoInc,0,False);
  Table.FieldDefs.Add('Field1',ftInteger,0,False);
  Table.FieldDefs.Add('Field2',ftString,100,False);
  Table.IndexDefs.Clear;
  Table.IndexDefs.Add('Index','ID',[ixPrimary]);
  Table.IndexDefs.Add('Index2','Field1',[ixDescending]);
  Table.IndexDefs.Add('Index3','Field2',[ixDescending]);

  ACRTable.IndexDefs.Clear;
  ACRTable.FieldDefs.Clear;
  ACRTable.AdvFieldDefs.Clear;
  ACRTable.AdvFieldDefs.Add('ID',aftAutoInc);
  ACRTable.AdvFieldDefs.Add('Field1',aftInteger);
  ACRTable.AdvFieldDefs.Add('Field2',aftString,100);
  ACRTable.IndexDefs.Clear;
  ACRTable.IndexDefs.Add('Index','ID',[ixPrimary]);
  ACRTable.IndexDefs.Add('Index2','Field1',[ixDescending]);
  ACRTable.IndexDefs.Add('Index3','Field2',[ixDescending]);
  UnitTestList.WriteToProcessLog('FieldDefs filled');
  try
   if (ACRTable.Exists) then
    ACRTable.DeleteTable;
   ACRTable.CreateTable;

   if (Table.Exists) then
    Table.DeleteTable;
   Table.CreateTable;
   UnitTestList.WriteToProcessLog('Table created');
  except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('Error creating table' + #9 + 'Error:'#13#10 + e.Message);
     end;
  end;
  try
   ACRTable.Open;
   Table.Open;
   UnitTestList.WriteToProcessLog('Table opened');
  except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('Error opening table' + #9 + 'Error:'#13#10 + e.Message);
     end;
  end;
  ACRTable.Insert;
  ACRTable.Fields[1].AsInteger := 10;
  ACRTable.Fields[2].AsString := 'aaa';
  ACRTable.Post;
  ACRTable.Insert;
  ACRTable.Fields[1].AsInteger := 15;
  ACRTable.Fields[2].AsString := 'aab';
  ACRTable.Post;
  ACRTable.Insert;
  ACRTable.Fields[1].AsInteger := 16;
  ACRTable.Fields[2].AsString := 'aaa';
  ACRTable.Post;
  ACRTable.Insert;
  ACRTable.Fields[1].AsInteger := 15;
  ACRTable.Fields[2].AsString := 'bab';
  ACRTable.Post;
  ACRTable.Insert;
  ACRTable.Fields[1].AsInteger := -20;
  ACRTable.Fields[2].AsString := 'aab';
  ACRTable.Post;
  ACRTable.Insert;
  ACRTable.Fields[0].AsInteger := ACRTable.RecordCount + 1;
  ACRTable.Fields[1].AsInteger := -10;
  ACRTable.Fields[2].AsString := 'bab';
  ACRTable.Post;

  ACRTable.First;
  while not ACRTable.Eof do
   begin
    Table.Insert;
    Table.Fields[1].Assign(ACRTable.Fields[1]);
    Table.Fields[2].Assign(ACRTable.Fields[2]);
    Table.Post;
    ACRTable.Next;
   end;

  Table.Last;
  ACRTable.Last;

end; // autoinc


procedure TUnitTestRestructure.InternalRestructure(Caption: String);
var s: string;
begin
 ACRTable := TACRTable.Create(nil);
 Table := TTable.Create(nil);
 try
   ACRTable.TableName := 'test_restr';
   Table.TableType := ttParadox;
   Table.TableName := 'test_restr';
   Table.DatabaseName := Self.TempDir;
   ACRTable.InMemory := True;
   TestCreateTable;

  ACRTable.Close;

  ACRTable.RestructureFieldDefs.Clear;
  ACRTable.RestructureFieldDefs.Add('ID',aftInteger);
  ACRTable.RestructureFieldDefs.Add('Field1',aftInteger,0,True);
  ACRTable.RestructureFieldDefs.Add('Field2',aftString,100);
  ACRTable.RestructureFieldDefs.Add('Field3',aftString,20);
  ACRTable.RestructureIndexDefs.Clear;
  ACRTable.RestructureIndexDefs.Add('Index','ID',[ixPrimary]);
  ACRTable.RestructureIndexDefs.Add('Index3','Field2',[ixDescending]);
  ACRTable.RestructureForeignKeyDefs.Clear;

  s := '';
  if (not ACRTable.RestructureTable(s)) then
   WriteToErrorLog(Caption + ' - restructure failed. Log: '+s);
  if (s <> '') then
   WriteToErrorLog(Caption + ' - restructure failed 2. Log: '+s);

  try
    // Rename Column
    ACRTable.RenameField('Field1', 'FiElD00');

    // Check new Name
    ACRTable.Open;
    if (ACRTable.FindField('Field1') <> nil) then
      WriteToErrorLog('Rename Column error: Old Field name found');
    if (ACRTable.FindField('field00') = nil) then
      WriteToErrorLog('Rename Column error: New Field name not found');
    ACRTable.Close;


    // Rename Column
    ACRTable.RenameField('field00', 'Field1');
  except
    on e: Exception do
      WriteToErrorLog('Rename Column Failed error: ' + e.Message);
  end;


  ACRTable.Open;

  CompareTables(Caption + ' - after restructure');
  ACRTable.Close;
  Table.Close;

  TestCreateTableAutoInc;
  Table.Prior;
  Table.Delete;
  ACRTable.Prior;
  ACRTable.Delete;

  ACRTable.Close;
  s := '';
  if (not ACRTable.RestructureTable(s)) then
   WriteToErrorLog(Caption + ' - restructure failed 3. Log: '+s);
  if (s <> '') then
   WriteToErrorLog(Caption + ' - restructure failed 4. Log: '+s);
  ACRTable.Open;
  Table.Insert;
  Table.Fields[1].AsInteger := 555;
  Table.Fields[2].AsString := 'Yes!!!';
  Table.Post;

  ACRTable.Insert;
  ACRTable.Fields[1].AsInteger := 555;
  ACRTable.Fields[2].AsString := 'Yes!!!';
  ACRTable.Post;
  CompareTables(Caption + ' - after restructure 2',True);

  // check Case Insensitive / descending fields bug in TIndexDefs.Assign
  ACRTable.Close;
  ACRTable.RestructureIndexDefs.Clear;
  ACRTable.RestructureIndexDefs.Add('Index','Field1;Field2',[]);
  ACRTable.RestructureIndexDefs.Items[0].DescFields := 'Field1';
  ACRTable.RestructureIndexDefs.Items[0].CaseInsFields := 'Field2';
  s := '';
  if (not ACRTable.RestructureTable(s)) then
   WriteToErrorLog(Caption + ' - restructure failed 5. Log: '+s);
  ACRTable.Open;
  if (ACRTable.IndexDefs.Count <> 1) then
   WriteToErrorLog(Caption + ' - restructure failed 6. IndexDefs.Count = '+IntToStr(ACRTable.IndexDefs.Count));
  if (ACRTable.IndexDefs.Items[0].Fields <> 'Field1;Field2') then
   WriteToErrorLog(Caption + ' - restructure failed 7. Fields <> "Field1;Field2". Fields = '+ACRTable.IndexDefs.Items[0].Fields);
  if (ACRTable.IndexDefs.Items[0].DescFields <> 'Field1') then
   WriteToErrorLog(Caption + ' - restructure failed 8. DescFields <> "Field1". DescFields = '+ACRTable.IndexDefs.Items[0].DescFields);
  if (ACRTable.IndexDefs.Items[0].CaseInsFields <> 'Field2') then
   WriteToErrorLog(Caption + ' - restructure failed 9. CaseInsFields <> "Field2". DescFields = '+ACRTable.IndexDefs.Items[0].CaseInsFields);
  ACRTable.Close;
 finally
  Table.Close;
  Table.DeleteTable;
  Table.Free;
  ACRTable.DeleteTable(True);
  ACRTable.Free;
 end;
end;


procedure TUnitTestRestructure.MainTest;
begin
 InternalRestructure('Testing restructure');
end;


procedure TUnitTestRestructure.TestShort;
begin
 CheckAction(MainTest, 'Main test of restructure');
end;


initialization
  UnitTestRestructure := TUnitTestRestructure.Create(UnitTestList);

finalization
  UnitTestRestructure.Free;
end.



