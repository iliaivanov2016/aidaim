unit utSearchAndFilter;

interface

{$I UTConfig.Inc}
{$I ACRVer.Inc}

uses uTestList, SysUtils, Db, Classes,
{$IFDEF D6H}
Variants,
{$ENDIF}
DBTables,
{$IFDEF ACR5H}
     ACRComMain,
{$ENDIF}
    ACRMain;

type
  TUnitTestSearchAndFilter = class(TUnitTest)
   private
    ACRdb:    TACRDatabase;
    ACRTable: TACRTable;
    Table:    TTable;
    procedure TestCreateTable;
    procedure FilterRecord(DataSet: TDataSet; var Accept: Boolean);
    procedure CheckTables(Caption: String);

    procedure InternalTestFilter(Caption: String);
    procedure InternalTestLocate(Caption: String);
    procedure TestLocateOnTwoFields;
   public
    procedure TestFilter(InMemory: Boolean; Temporary: Boolean);
    procedure TestLocate(InMemory: Boolean; Temporary: Boolean);
    procedure MainTest;
    procedure TestShort; override;
  end;

var
  UnitTestSearchAndFilter: TUnitTestSearchAndFilter;


implementation

procedure TUnitTestSearchAndFilter.TestShort;
begin
 CheckAction(TestLocateOnTwoFields,'Test Locate on two fields');
 exit;
 CheckAction(MainTest, 'Main test of search and filter operations');
end;

procedure TUnitTestSearchAndFilter.FilterRecord(DataSet: TDataSet; var Accept: Boolean);
begin
 Accept := False;
 if (Dataset.Fields[0].AsInteger > 10) then
  Accept := True;
end;


procedure TUnitTestSearchAndFilter.CheckTables(Caption: String);
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
end;


procedure TUnitTestSearchAndFilter.TestCreateTable;
begin
  if (ACRTable.InMemory) then
    UnitTestList.WriteToProcessLog('create table in memory mode')
  else
  if (ACRTable.Temporary) then
    UnitTestList.WriteToProcessLog('create table in temporary mode')
  else
    UnitTestList.WriteToProcessLog('create table in disk mode');

  Table.Close;
  Table.FieldDefs.Clear;
  Table.FieldDefs.Add('Field1',ftInteger,0,False);
  Table.FieldDefs.Add('Field2',ftString,300,False);
  Table.FieldDefs.Add('Field_time',ftTime,0,False);
  Table.FieldDefs.Add('Field_date',ftDate,0,False);
  Table.FieldDefs.Add('Field_datetime',ftDateTime,0,False);
  Table.IndexDefs.Clear;
  Table.IndexDefs.Add('','Field1',[ixPrimary]);
  Table.IndexDefs.Add('Index1','Field2;Field1',[ixCaseInsensitive,ixUnique]);

  ACRTable.Close;
  ACRTable.FieldDefs.Clear;
  ACRTable.FieldDefs.Add('Field1',ftInteger,0,False);
  ACRTable.FieldDefs.Add('Field2',ftString,300,False);
  ACRTable.FieldDefs.Add('Field_time',ftTime,0,False);
  ACRTable.FieldDefs.Add('Field_date',ftDate,0,False);
  ACRTable.FieldDefs.Add('Field_datetime',ftDateTime,0,False);
  ACRTable.IndexDefs.Clear;
  ACRTable.IndexDefs.Add('Index1','Field2;Field1',[ixCaseInsensitive,ixUnique]);
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
  ACRTable.Fields[0].AsInteger := 10;
  ACRTable.Fields[1].AsString := 'aaa';
  ACRTable.Fields[2].AsString := '17:35:08';
  ACRTable.Post;
  ACRTable.Insert;
  ACRTable.Fields[0].AsInteger := 15;
  ACRTable.Fields[1].AsString := 'aab';
  ACRTable.Fields[3].AsString := '30.01.2005';
  ACRTable.Post;
  ACRTable.Insert;
  ACRTable.Fields[0].AsInteger := 16;
  ACRTable.Fields[1].AsString := 'aac';
  ACRTable.Fields[4].AsString := '30.01.2005 17:35:08';
  ACRTable.Post;
  ACRTable.Insert;
  ACRTable.Fields[0].AsInteger := -20;
  ACRTable.Fields[1].AsString := 'Aab';
  ACRTable.Post;
  ACRTable.Insert;
  ACRTable.Fields[0].AsInteger := -10;
  ACRTable.Fields[1].AsString := 'bab';
  ACRTable.Post;

  Table.Insert;
  Table.Fields[0].AsInteger := 10;
  Table.Fields[1].AsString := 'aaa';
  Table.Fields[2].AsString := '17:35:08';
  Table.Post;
  Table.Insert;
  Table.Fields[0].AsInteger := 15;
  Table.Fields[1].AsString := 'aab';
  Table.Fields[3].AsString := '30.01.2005';
  Table.Post;
  Table.Insert;
  Table.Fields[0].AsInteger := 16;
  Table.Fields[1].AsString := 'aac';
  Table.Fields[4].AsString := '30.01.2005 17:35:08';
  Table.Post;
  Table.Insert;
  Table.Fields[0].AsInteger := -20;
  Table.Fields[1].AsString := 'Aab';
  Table.Post;
  Table.Insert;
  Table.Fields[0].AsInteger := -10;
  Table.Fields[1].AsString := 'bab';
  Table.Post;

  Table.Last;
  ACRTable.Last;
  CheckTables('CreateTable, after inserts');
end;


procedure TUnitTestSearchAndFilter.InternalTestFilter(Caption: String);
begin
   // filter
   ACRTable.Filtered := False;
   ACRTable.Filter := '';
   ACRTable.OnFilterRecord := FilterRecord;
   ACRTable.Filtered := True;
   Table.Filtered := False;
   Table.Filter := '';
   Table.OnFilterRecord := FilterRecord;
   Table.Filtered := True;
   CheckTables(Caption + 'OnFilterRecord');
   ACRTable.OnFilterRecord := nil;
   Table.OnFilterRecord := nil;

   ACRTable.Filtered := False;
   ACRTable.Filter := 'Field1 < 0';
   ACRTable.Filtered := True;
   Table.Filtered := False;
   Table.Filter := 'Field1 < 0';
   Table.Filtered := True;
   CheckTables(Caption + 'Filter: '+ACRTable.Filter);

   ACRTable.Filtered := False;
   ACRTable.Filter := 'Field2 = ''a''';
   ACRTable.FilterOptions := [];
   ACRTable.Filtered := True;
   Table.Filtered := False;
   Table.Filter := 'Field2 = ''a''';
   Table.FilterOptions := [];
   Table.Filtered := True;
   CheckTables(Caption + 'Filter, []: '+ACRTable.Filter);

   ACRTable.Filtered := False;
   ACRTable.Filter := 'Field2 = ''a*''';
   ACRTable.FilterOptions := [];
   ACRTable.Filtered := True;
   Table.Filtered := False;
   Table.Filter := 'Field2 = ''a*''';
   Table.FilterOptions := [];
   Table.Filtered := True;
   CheckTables(Caption + 'Filter, []: '+ACRTable.Filter);

   ACRTable.Filtered := False;
   ACRTable.Filter := 'Field2 = ''a''';
   ACRTable.FilterOptions := [foNoPartialCompare];
   ACRTable.Filtered := True;
   Table.Filtered := False;
   Table.Filter := 'Field2 = ''a''';
   Table.FilterOptions := [foNoPartialCompare];
   Table.Filtered := True;
   CheckTables(Caption + 'Filter, [foNoPartialCompare]: '+ACRTable.Filter);

   ACRTable.Filtered := False;
   ACRTable.Filter := 'Field2 = ''a*''';
   ACRTable.FilterOptions := [foNoPartialCompare];
   ACRTable.Filtered := True;
   Table.Filtered := False;
   Table.Filter := 'Field2 = ''a*''';
   Table.FilterOptions := [foNoPartialCompare];
   Table.Filtered := True;
   CheckTables(Caption + 'Filter, [foNoPartialCompare]: '+ACRTable.Filter);

   ACRTable.Filtered := False;
   ACRTable.Filter := 'Field2 = ''aaa''';
   ACRTable.FilterOptions := [];
   ACRTable.Filtered := True;
   Table.Filtered := False;
   Table.Filter := 'Field2 = ''aaa''';
   Table.FilterOptions := [];
   Table.Filtered := True;
   CheckTables(Caption + 'Filter: '+ACRTable.Filter);

   ACRTable.Filtered := False;
   ACRTable.Filter := 'Field2 = ''aaa''';
   ACRTable.FilterOptions := [foCaseInsensitive];
   ACRTable.Filtered := True;
   Table.Filtered := False;
   Table.Filter := 'Field2 = ''aaa''';
   Table.FilterOptions := [foCaseInsensitive];
   Table.Filtered := True;
   CheckTables(Caption + 'Filter, [foCaseInsensitive]: '+ACRTable.Filter);

   ACRTable.Filtered := False;
   ACRTable.Filter := 'Field1 < 0';
   ACRTable.FilterOptions := [];
   Table.Filtered := False;
   Table.Filter := 'Field1 < 0';
   Table.FilterOptions := [];
   if (ACRTable.FindFirst <> Table.FindFirst) then
    WriteToErrorLog(Caption + 'FindFirst: Field < 0 failed #1');
   if (ACRTable.FindNext <> Table.FindNext) then
    WriteToErrorLog(Caption + 'FindFirst: Field < 0 failed #2');
   if (ACRTable.FindNext <> Table.FindNext) then
    WriteToErrorLog(Caption + 'FindFirst: Field < 0 failed #3');

   ACRTable.Filtered := False;
   ACRTable.Filter := 'Field1 > 0';
   ACRTable.Filtered := True;
   Table.Filtered := False;
   Table.Filter := 'Field1 > 0';
   Table.Filtered := True;
   ACRTable.Insert;
   ACRTable.FieldByName('Field1').AsInteger := -11;
   ACRTable.Post;
   Table.Insert;
   Table.FieldByName('Field1').AsInteger := -11;
   Table.Post;
   if (ACRTable.FieldByName('Field1').AsInteger < 0) then
     WriteToErrorLog('Error - field1 is invalid value after insert make invisible record');
   CheckTables(Caption + 'Filter insert invisible record: '+ACRTable.Filter);

   ACRTable.Insert;
   ACRTable.FieldByName('Field1').AsInteger := 13;
   ACRTable.Post;
   Table.Insert;
   Table.FieldByName('Field1').AsInteger := 13;
   Table.Post;
   if (ACRTable.FieldByName('Field1').AsInteger <> 13) then
     WriteToErrorLog('Error - field1 is invalid value after insert make visible record');
   CheckTables(Caption + 'Filter insert visible record: '+ACRTable.Filter);

   if (ACRTable.Temporary) then Exit;

   ACRTable.Edit;
   ACRTable.FieldByName('Field1').AsInteger := 23;
   ACRTable.Post;
   Table.Edit;
   Table.FieldByName('Field1').AsInteger := 23;
   Table.Post;
   if (ACRTable.FieldByName('Field1').AsInteger <>
       Table.FieldByName('Field1').AsInteger) then
     WriteToErrorLog('Error - field1 is invalid value after edit make visible record');
   CheckTables(Caption + 'Filter edit make visible record: '+ACRTable.Filter);

   ACRTable.Edit;
   ACRTable.FieldByName('Field1').AsInteger := -123;
   ACRTable.Post;
   Table.Edit;
   Table.FieldByName('Field1').AsInteger := -123;
   Table.Post;
   if (ACRTable.FieldByName('Field1').AsInteger <= 0) then
     WriteToErrorLog('Error - field1 is invalid value after edit make invisible record');
   CheckTables(Caption + 'Filter edit make invisible record: '+ACRTable.Filter);

   ACRTable.First;
   Table.First;
   ACRTable.Delete;
   Table.Delete;
   CheckTables(Caption + 'Filter delete first record: '+ACRTable.Filter);

   ACRTable.Last;
   Table.Last;
   ACRTable.Delete;
   Table.Delete;
   CheckTables(Caption + 'Filter delete last record: '+ACRTable.Filter);
end;


procedure TUnitTestSearchAndFilter.InternalTestLocate(Caption: String);
var IntValue:  Integer;
    IntValue2: Integer;
    V:         Variant;
    StrValue:  String;
    t: TDateTime;
    d: TDateTime;
    dt: TDateTime;
begin
   // lookup
   IntValue := -20;
   V := ACRTable.Lookup('Field1',IntValue,'Field2;Field1');
   StrValue := V[0];
   IntValue2 := V[1];
   if (StrValue <> 'Aab') then
    WriteToErrorLog(Caption+'Lookup Field1 = -20 failed #1');
   if (IntValue2 <> IntValue) then
    WriteToErrorLog(Caption+'Lookup Field1 = -20 failed #2');


   // locate
   IntValue := 10;
   if (ACRTable.Locate('Field1',IntValue,[]) <> Table.Locate('Field1',IntValue,[])) then
    WriteToErrorLog(Caption+'Locate Field1 = 10 failed #1');
   if (not ACRTable.Locate('Field1',IntValue,[])) then
    WriteToErrorLog(Caption+'Locate Field1 = 10 failed #2');
   if (ACRTable.FieldByName('Field1').AsInteger <> IntValue) then
    WriteToErrorLog(Caption+'Locate Field1 = 10 failed - IntValue = '+IntToStr(IntValue)+
      ', value = '+ACRTable.FieldByName('Field1').AsString);

   IntValue := 0;
   if (ACRTable.Locate('Field1',IntValue,[])) then
    WriteToErrorLog(Caption+'Locate Field1 = 0 failed');

   StrValue := 'aAb';
   if (ACRTable.Locate('Field2',StrValue,[])) then
    WriteToErrorLog(Caption+'Locate Field2 = aAb failed');

   StrValue := 'aAb';
   if (not ACRTable.Locate('Field2',StrValue,[loCaseInsensitive])) then
    WriteToErrorLog(Caption+'Locate Field2 = aAb case insensitive failed');
   if (UpperCase(ACRTable.FieldByName('Field2').AsString) <> UpperCase(StrValue)) then
    WriteToErrorLog(Caption+'Locate Field2 = aAb case insensitive - StrValue = '+
        (StrValue)+
      ', value = '+ACRTable.FieldByName('Field2').AsString);

   StrValue := 'A';
   if (ACRTable.Locate('Field2',StrValue,[])) then
    WriteToErrorLog(Caption+'Locate Field2 = A failed');
   if (not ACRTable.Locate('Field2',StrValue,[loPartialKey])) then
    WriteToErrorLog(Caption+'Locate Field2 = A with partial key failed');
   if (ACRTable.FieldByName('Field2').AsString <> 'Aab') then
    WriteToErrorLog(Caption+'Locate Field2 = aab with partial key - StrValue = '+
        ('Aab')+
      ', value = '+ACRTable.FieldByName('Field2').AsString);

   StrValue := 'B';
   if (ACRTable.Locate('Field2',StrValue,[loPartialKey])) then
    WriteToErrorLog(Caption+'Locate Field2 = B with partial key failed');
   if (not ACRTable.Locate('Field2',StrValue,[loPartialKey,loCaseInsensitive])) then
    WriteToErrorLog(Caption+'Locate Field2 = B with partial key and acse insensitive failed');
   if (ACRTable.FieldByName('Field2').AsString <> 'bab') then
    WriteToErrorLog(Caption+'Locate Field2 = aab with partial key and case insensitive - StrValue = '+
        ('bab')+
      ', value = '+ACRTable.FieldByName('Field2').AsString);

   t := StrToTime('17:35:08');
   d := StrToDate('30.01.2005');
   dt := StrToDateTime('30.01.2005 17:35:08');
   if (not Table.Locate('Field_time',t,[])) then
    WriteToErrorLog(Caption+'Locate Field_time time failed 1');
   if (not ACRTable.Locate('Field_time',t,[])) then
    WriteToErrorLog(Caption+'Locate Field_time time failed');
   if (ACRTable.Fields[0].ASInteger <> Table.Fields[0].AsInteger) then
    WriteToErrorLog(Caption+'Locate Field_time time failed 2');

   if (not Table.Locate('Field_date',d,[])) then
    WriteToErrorLog(Caption+'Locate Field_date failed 1');
   if (not ACRTable.Locate('Field_date',d,[])) then
    WriteToErrorLog(Caption+'Locate Field_date  failed');
   if (ACRTable.Fields[0].ASInteger <> Table.Fields[0].AsInteger) then
    WriteToErrorLog(Caption+'Locate Field_date  failed 2');

   if (not Table.Locate('Field_datetime',dt,[])) then
    WriteToErrorLog(Caption+'Locate Field_datetime failed 1');
   if (not ACRTable.Locate('Field_datetime',dt,[])) then
    WriteToErrorLog(Caption+'Locate Field_datetime  failed');
   if (ACRTable.Fields[0].ASInteger <> Table.Fields[0].AsInteger) then
    WriteToErrorLog(Caption+'Locate Field_datetime  failed 2');
end;


procedure TUnitTestSearchAndFilter.TestFilter(InMemory: Boolean; Temporary: Boolean);
begin
 ACRTable := TACRTable.Create(nil);
 Table := TTable.Create(nil);
 ACRdb := TACRDatabase.Create(nil);
 try
   ACRTable.TableName := 'test';
   Table.TableType := ttParadox;
   Table.TableName := 'test';
   Table.DatabaseName := Self.TempDir;
   if (InMemory) then
     ACRTable.InMemory := True
   else
   if (Temporary) then
     ACRTable.Temporary := True;
   if (not InMemory) and (not Temporary) then
    begin
     ACRdb.DatabaseName := 'test_db';
     ACRdb.DatabaseFileName := TempDir+'test.adb';
     if (ACRdb.Exists) then
      ACRdb.DeleteDatabase;
     ACRdb.CreateDatabase;
     ACRdb.Open;
     ACRTable.DatabaseName := ACRdb.DatabaseName;
    end;
   CheckAction(TestCreateTable, 'Test create table');

   WriteToProcessLog('Testing filter without indexes');
   InternalTestFilter('Testing filter without indexes - ');

   CheckAction(TestCreateTable, 'Test create table with indexes');

   ACRTable.IndexName := 'Index1';
   Table.IndexName := 'Index1';

   WriteToProcessLog('Testing filter with indexes');
   InternalTestFilter('Testing filter with indexes - ');

   WriteToProcessLog('Testing filter complete');

 finally
   ACRTable.Close;
   if (ACRTable.InMemory) then
    ACRTable.DeleteTable(True);
   ACRTable.Free;
   Table.Close;
   Table.DeleteTable;
   Table.Free;
   if (not InMemory) and (not Temporary) then
    begin
     ACRdb.Close;
     ACRdb.DeleteDatabase;
    end;
   ACRdb.Free;
 end;
end;


procedure TUnitTestSearchAndFilter.TestLocate(InMemory: Boolean; Temporary: Boolean);
begin
 ACRTable := TACRTable.Create(nil);
 Table := TTable.Create(nil);
 ACRdb := TACRDatabase.Create(nil);
 try
   ACRTable.TableName := 'test';
   Table.TableType := ttParadox;
   Table.TableName := 'test';
   Table.DatabaseName := TempDir;
   ACRTable.InMemory := InMemory;
   ACRTable.Temporary := Temporary;
   if (not InMemory) and (not Temporary) then
    begin
     ACRdb.DatabaseName := 'test_db';
     ACRdb.DatabaseFileName := TempDir+'test.adb';
     if (ACRdb.Exists) then
      ACRdb.DeleteDatabase;
     ACRdb.CreateDatabase;
     ACRdb.Open;
     ACRTable.DatabaseName := ACRdb.DatabaseName;
    end;
   CheckAction(TestCreateTable, 'Test create table');

   WriteToProcessLog('Testing locate without indexes');
   InternalTestLocate('Testing locate without indexes - ');

   ACRTable.IndexName := 'Index1';
   Table.IndexName := 'Index1';

   WriteToProcessLog('Testing locate with indexes');
   InternalTestLocate('Testing locate with indexes - ');

   // test 000 partial Locate bug - 0 found
   if (not Temporary) then
    begin
     ACRTable.Close;
     ACRTable.EmptyTable;
     ACRTable.Open;
     ACRTable.Insert;
     ACRTable.FieldByName('Field2').AsString := '0';
     ACRTable.Post;
     ACRTable.Insert;
     ACRTable.FieldByName('Field2').AsString := '000 070 50 53';
     ACRTable.Post;
     if (ACRTable.Locate('Field2','000',[loPartialKey,loCaseInsensitive])) then
      begin
       if (ACRTable.FieldByName('Field2').AsString <> '000 070 50 53') then
        WriteToErrorLog('Locate 000 failed - found field:'+ACRTable.FieldByName('Field2').AsString);
      end
     else
      WriteToErrorLog('Locate 000 failed');
    end;
 finally
   ACRTable.Close;
   if (ACRTable.InMemory) then
    ACRTable.DeleteTable(True);
   ACRTable.Free;
   Table.Close;
   Table.DeleteTable;
   Table.Free;
   if (not InMemory) and (not Temporary) then
    begin
     ACRdb.Close;
     ACRdb.DeleteDatabase;
    end;
   ACRdb.Free;
 end;
end;


procedure TUnitTestSearchAndFilter.MainTest;
var s1,s2,s3,s4: String;
    ts,ds: char;
begin
  s1 := ShortDateFormat;
  s2 := ShortTimeFormat;
  s3 := LongDateFormat;
  s4 := LongTimeFormat;
  ds := DateSeparator;
  ts := TimeSeparator;
  try
   ShortDateFormat := 'DD.MM.YYYY';
   ShortTimeFormat := 'HH:MM:SS';
   LongDateFormat := ShortDateFormat;
   LongTimeFormat := ShortTimeFormat;
   DateSeparator := '.';
   TimeSeparator := ':';

   TestLocate(False,False);
   TestLocate(True,False);
   TestLocate(False,True);

   TestFilter(False,False);
   TestFilter(True,False);
   TestFilter(False,True);
  finally
   ShortDateFormat := s1;
   ShortTimeFormat := s2;
   LongDateFormat := s3;
   LongTimeFormat := s4;
   DateSeparator := ds;
   TimeSeparator := ts;
  end;
end;




procedure TUnitTestSearchAndFilter.TestLocateOnTwoFields;
var v1,v2:      Variant;
    capt:       String;
    ACRTable1:  TACRTable;
begin
  capt := 'TestLocateOnTwoFields - ';
  WriteToProcessLog(capt+'started');
  ACRTable1 := TACRTable.Create(nil);
  try
    ACRTable1.FieldDefs.Clear;
    ACRTable1.FieldDefs.Add('int1',ftInteger);
    ACRTable1.FieldDefs.Add('int2',ftInteger);
    ACRTable1.TableName := 'test';
    ACRTable1.InMemory := True;
    ACRTable1.CreateTable;
    ACRTable1.Open;
    ACRTable1.InsertRecord([1,1]);
    ACRTable1.InsertRecord([1,2]);
    ACRTable1.InsertRecord([2,2]);
    v1 := 1;
    v2 := 2;
    ACRTable1.First;
    if (not ACRTable1.Locate('int1; int2;', VarArrayOf([1,2]),[])) then
     WriteToErrorLog(capt+'error #1 - not found')
    else
    begin
     if (ACRTable1.Fields[0].AsInteger <> 1) or (ACRTable1.Fields[1].AsInteger <> 2) then
      WriteToErrorLog(capt+ 'Locate found wrong record: '+#9+ACRTable1.Fields[0].AsString+#9+ACRTable1.Fields[1].AsString);
    end;
    WriteToProcessLog(capt+'finished');
  finally
    if (ACRTable1.Active) then
     ACRTable1.Close;
    ACRTable1.DeleteTable(True);
    ACRTable1.Free;
  end;
end; // TestLocateOnTwoFields

initialization
  UnitTestSearchAndFilter := TUnitTestSearchAndFilter.Create(UnitTestList);

finalization
  UnitTestSearchAndFilter.Free;
end.



