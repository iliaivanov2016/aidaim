unit utDistinctAndProjection;


interface

{$I UTConfig.Inc}

uses uTestList, SysUtils, Db,
{$IFDEF D6H}
Variants,
{$ENDIF}
DBTables,
    ACRTypes,
    ACRMain,
{$IFDEF ACR5H}
   ACRComMain,
{$ENDIF}
    Classes, ACRConst;

type
  TUnitTestDistinctAndProjection = class(TUnitTest)
   private
    ACRTable: TACRTable;
    Query:    TQuery;
    Table:    TTable;
    procedure TestCreateTable;
    procedure CheckTables(Caption: String);
    procedure CompareTableQuery(Caption: String);

    procedure InternalTestProjection(Caption: String);
    procedure InternalTestDistinct(Caption: String);
   public
    procedure TestProjection(InMemory: Boolean; Temporary: Boolean);
    procedure TestDistinct(InMemory: Boolean; Temporary: Boolean);
    procedure MainTest;
    procedure TestShort; override;
  end;

var
  UnitTestDistinctAndProjection: TUnitTestDistinctAndProjection;


implementation


procedure TUnitTestDistinctAndProjection.CheckTables(Caption: String);
var i: Integer;
begin
 if (ACRTable.BOF <> Table.BOF) then
  WriteToErrorLog(Caption+' failed #1, BOF = '
    +IntToStr(Word(ACRTable.BOF))+', BDE BOF = '+IntToStr(Word(Table.BOF)));
 if (ACRTable.EOF <> Table.EOF) then
  WriteToErrorLog(Caption+' failed #2, EOF = '
    +IntToStr(Word(ACRTable.EOF))+', BDE EOF = '+IntToStr(Word(Table.EOF)));
 if (ACRTable.RecordCount <> Table.RecordCount) then
  WriteToErrorLog(Caption+' failed #3, record count = '
    +IntToStr(ACRTable.RecordCount)+', BDE record count = '+IntToStr(Table.RecordCount));
 if (ACRTable.FieldDefs.Count <> Table.FieldDefs.Count) then
  WriteToErrorLog(Caption+' failed #4, fielddefs count = '
    +IntToStr(ACRTable.FieldDefs.Count)+', BDE fielddefs count = '+IntToStr(Table.FieldDefs.Count))
 else
   for i := 0 to ACRTable.FieldDefs.Count - 1 do
    begin
     if (ACRTable.FieldDefs[i].Name <> Table.FieldDefs[i].Name) then
      WriteToErrorLog(Caption+' failed #6, field name = ' +
        ACRTable.FieldDefs[i].Name + ', BDE field name = '+Table.FieldDefs[i].Name);

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


procedure TUnitTestDistinctAndProjection.CompareTableQuery(Caption: String);
var i: Integer;
begin
 if (ACRTable.BOF <> Query.BOF) then
  WriteToErrorLog(Caption+' failed #1, BOF = '
    +IntToStr(Word(ACRTable.BOF))+', BDE BOF = '+IntToStr(Word(Query.BOF)));
 if (ACRTable.EOF <> Query.EOF) then
  WriteToErrorLog(Caption+' failed #2, EOF = '
    +IntToStr(Word(ACRTable.EOF))+', BDE EOF = '+IntToStr(Word(Query.EOF)));
 if (ACRTable.RecordCount <> Query.RecordCount) then
  WriteToErrorLog(Caption+' failed #3, record count = '
    +IntToStr(ACRTable.RecordCount)+', BDE record count = '+IntToStr(Query.RecordCount));
 if (ACRTable.FieldDefs.Count <> Query.FieldDefs.Count) then
  WriteToErrorLog(Caption+' failed #4, fielddefs count = '
    +IntToStr(ACRTable.FieldDefs.Count)+', BDE fielddefs count = '+IntToStr(Query.FieldDefs.Count));
 if (ACRTable.FieldCount <> Query.FieldCount) then
  WriteToErrorLog(Caption+' failed #5, field count = '
    +IntToStr(ACRTable.FieldCount)+', BDE field count = '+IntToStr(Query.FieldCount))
 else
  begin
   for i := 0 to ACRTable.FieldDefs.Count - 1 do
    begin
     if (ACRTable.FieldDefs[i].Name <> Query.FieldDefs[i].Name) then
      WriteToErrorLog(Caption+' failed #6, field name = ' +
        ACRTable.FieldDefs[i].Name + ', BDE field name = '+Query.FieldDefs[i].Name);


     if ((ACRTable.FieldDefs[i].DataType <> Query.FieldDefs[i].DataType) and
        (ACRTable.FieldDefs[i].DataType <> ftAutoInc)) or
        ((ACRTable.FieldDefs[i].DataType = ftAutoInc) and
         (Query.FieldDefs[i].DataType <> ftInteger))
         then
      WriteToErrorLog(Caption+' failed #7, field type = ' +
        IntToStr(Integer(ACRTable.FieldDefs[i].DataType)) + ', BDE field type = '+
        IntToStr(Integer(Query.FieldDefs[i].DataType)));

     if (ACRTable.FieldDefs[i].Size <> Query.FieldDefs[i].Size) then
      WriteToErrorLog(Caption+' failed #8, field size = ' +
        IntToStr(Integer(ACRTable.FieldDefs[i].Size)) + ', BDE field size = '+
        IntToStr(Integer(Query.FieldDefs[i].Size)));
{
     if (ACRTable.FieldDefs[i].Required <> Query.FieldDefs[i].Required) then
      WriteToErrorLog(Caption+' failed #9, field required = ' +
        IntToStr(Integer(ACRTable.FieldDefs[i].Required)) + ', BDE field required = '+
        IntToStr(Integer(Query.FieldDefs[i].Required)));
}
    end;
  end;
 ACRTable.First;
 Query.First;
 while (not Query.Eof) do
  begin
   for i := 0 to ACRTable.FieldCount - 1 do
    if (ACRTable.Fields[i].Value <> Query.Fields[i].Value) then
      WriteToErrorLog(Caption+' failed #10, field  value = ' +
        ACRTable.Fields[i].AsString + ', BDE field value = '+
        Query.Fields[i].AsString);
   ACRTable.Next;
   Query.Next;
  end;
 if (ACRTable.EOF <> Query.EOF) then
  WriteToErrorLog(Caption+' failed #11, EOF = '
    +IntToStr(Word(ACRTable.EOF))+', BDE EOF = '+IntToStr(Word(Query.EOF)));
end;


procedure TUnitTestDistinctAndProjection.TestCreateTable;
begin
  if (ACRTable.InMemory) then
    UnitTestList.WriteToProcessLog('create table in memory mode');
  if (ACRTable.Temporary) then
    UnitTestList.WriteToProcessLog('create table in temporary mode');

  Table.FieldDefs.Clear;
  Table.FieldDefs.Add('ID',ftInteger,0,False);
  Table.FieldDefs.Add('Field1',ftInteger,0,False);
  Table.FieldDefs.Add('Field2',ftString,100,not ACRTable.Temporary);
  Table.IndexDefs.Clear;
  Table.IndexDefs.Add('Index','ID',[ixPrimary]);
  Table.IndexDefs.Add('Index2','Field2',[ixDescending]);

  ACRTable.FieldDefs.Clear;
  ACRTable.FieldDefs.Add('ID',ftInteger,0,False);
  ACRTable.FieldDefs.Add('Field1',ftInteger,0,False);
  ACRTable.FieldDefs.Add('Field2',ftString,100,not ACRTable.Temporary);
  ACRTable.IndexDefs.Clear;
  ACRTable.IndexDefs.Add('Index','ID',[]);
  ACRTable.IndexDefs.Add('Index2','Field2',[ixDescending]);
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
   CheckTables('CreateTable, after open');
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
  CheckTables('CreateTable, after inserts');
end;


{$IFDEF ACR5H}
procedure TUnitTestDistinctAndProjection.InternalTestProjection(Caption: String);
var fl,al: TACRWideStringList;
begin
  fl := TACRWideStringList.Create;
  al := TACRWideStringList.Create;
  try
    fl.Add('field2');
    fl.Add('ID');
    al.Add('F2');
    al.Add('ID');
    Query.SQL.Text := 'select field2 as F2, ID from '+Table.TableName + ' order by ID';
    Query.Open;
    ACRTable.IndexName := 'Index';
    ACRTable.ApplyProjection(fl,al);
    CompareTableQuery(Caption + ' '+ Query.Text);
  finally
   al.Free;
   fl.Free;
  end;
end;


procedure TUnitTestDistinctAndProjection.InternalTestDistinct(Caption: String);
var fl,dl,cl,al: TACRWideStringList;
begin
  fl := TACRWideStringList.Create;
  dl := TACRWideStringList.Create;
  cl := TACRWideStringList.Create;
  al := TACRWideStringList.Create;
  try
    fl.Add('field2');
    dl.Add(ACR_DESC);
    cl.Add(ACR_CASE);
    al.Add('field2');
    Query.SQL.Text := 'select field2 from '+Table.TableName + ' order by field2 desc';
    Query.Open;

//    ACRTable.ApplyDistinct(fl,dl,cl);
    ACRTable.ApplyProjection(fl,al);
    CompareTableQuery(Caption + ' '+ Query.Text);

    fl.Clear;
    dl.Clear;
    al.Clear;
    fl.Add('field1');
    dl.Add(ACR_ASC);
    al.Add('f1');
    Query.SQL.Text := 'select field1 as f1 from '+Table.TableName + ' order by field1';
    Query.Open;
//    ACRTable.ApplyDistinct(fl,dl,cl);
    ACRTable.ApplyProjection(fl,al);
    CompareTableQuery(Caption + ' '+ Query.Text);

  finally
   dl.Free;
   fl.Free;
   cl.Free;
   al.Free;
  end;
end;
// v.5

{$ELSE}

// v.4
procedure TUnitTestDistinctAndProjection.InternalTestProjection(Caption: String);
var fl,al: TStringList;
begin
  fl := TStringList.Create;
  al := TStringList.Create;
  try
    fl.Add('field2');
    fl.Add('ID');
    al.Add('F2');
    al.Add('ID');
    Query.SQL.Text := 'select field2 as F2, ID from '+Table.TableName + ' order by ID';
    Query.Open;
    ACRTable.IndexName := 'Index';
    ACRTable.ApplyProjection(fl,al);
    CompareTableQuery(Caption + ' '+ Query.Text);
  finally
   al.Free;
   fl.Free;
  end;
end;


procedure TUnitTestDistinctAndProjection.InternalTestDistinct(Caption: String);
var fl,dl,cl,al: TStringList;
begin
  fl := TStringList.Create;
  dl := TStringList.Create;
  cl := TStringList.Create;
  al := TStringList.Create;
  try
    fl.Add('field2');
    dl.Add(ACR_DESC);
    cl.Add(ACR_CASE);
    al.Add('field2');
    Query.SQL.Text := 'select field2 from '+Table.TableName + ' order by field2 desc';
    Query.Open;

//    ACRTable.ApplyDistinct(fl,dl,cl);
    ACRTable.ApplyProjection(fl,al);
    CompareTableQuery(Caption + ' '+ Query.Text);

    fl.Clear;
    dl.Clear;
    al.Clear;
    fl.Add('field1');
    dl.Add(ACR_ASC);
    al.Add('f1');
    Query.SQL.Text := 'select field1 as f1 from '+Table.TableName + ' order by field1';
    Query.Open;
//    ACRTable.ApplyDistinct(fl,dl,cl);
    ACRTable.ApplyProjection(fl,al);
    CompareTableQuery(Caption + ' '+ Query.Text);

  finally
   dl.Free;
   fl.Free;
   cl.Free;
   al.Free;
  end;
end;
{$ENDIF}


procedure TUnitTestDistinctAndProjection.TestProjection(InMemory: Boolean; Temporary: Boolean);
begin
 ACRTable := TACRTable.Create(nil);
 Query := TQuery.Create(nil);
 Table := TTable.Create(nil);
 try
   ACRTable.TableName := 'test';
   Table.TableType := ttParadox;
   Table.TableName := 'test';
   Table.DatabaseName := Self.TempDir;
   Query.DatabaseName := Table.DatabaseName;
   if (InMemory) then
     ACRTable.InMemory := True
   else
   if (Temporary) then
     ACRTable.Temporary := True;
   CheckAction(TestCreateTable, 'Test create table');

   WriteToProcessLog('Testing projection');
   if (InMemory) then
     InternalTestProjection('Testing projection in memory - ')
   else
   if (Temporary) then
     InternalTestProjection('Testing projection in temporary - ')
   else
     InternalTestProjection('Testing projection in disk - ');
   WriteToProcessLog('Testing projection complete');

 finally
   Query.Free;
   ACRTable.Close;
   if (not ACRTable.Temporary) then
     ACRTable.DeleteTable(True);
   ACRTable.Free;
   Table.Close;
   Table.DeleteTable;
   Table.Free;
 end;
end;


procedure TUnitTestDistinctAndProjection.TestDistinct(InMemory: Boolean; Temporary: Boolean);
begin
 ACRTable := TACRTable.Create(nil);
 Query := TQuery.Create(nil);
 Table := TTable.Create(nil);
 try
   ACRTable.TableName := 'test';
   Table.TableType := ttParadox;
   Table.TableName := 'test';
   Table.DatabaseName := TempDir;
   Query.DatabaseName := Table.DatabaseName;
   if (InMemory) then
     ACRTable.InMemory := True
   else
   if (Temporary) then
     ACRTable.Temporary := True;
   CheckAction(TestCreateTable, 'Test create table');

   WriteToProcessLog('Testing distinct');
   InternalTestDistinct('Testing distinct - ');
   WriteToProcessLog('Testing distinct complete');

 finally
   ACRTable.Close;
   if (not ACRTable.Temporary) then
     ACRTable.DeleteTable(True);
   ACRTable.Free;
   Table.Free;
   Query.Free;
 end;
end;


procedure TUnitTestDistinctAndProjection.MainTest;
begin
 TestProjection(True,False);
 TestProjection(False,True);
// TestDistinct(True,False);
// TestDistinct(False,True);
end;


procedure TUnitTestDistinctAndProjection.TestShort;
begin
 CheckAction(MainTest, 'Main test of distinct and projection operations');
end;


initialization
  UnitTestDistinctAndProjection := TUnitTestDistinctAndProjection.Create(UnitTestList);

finalization
  UnitTestDistinctAndProjection.Free;
end.



