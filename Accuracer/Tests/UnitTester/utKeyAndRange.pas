unit utKeyAndRange;

interface

{$I UTConfig.Inc}

uses  uTestList, SysUtils, Db,
{$IFDEF D6H}
      Variants,
{$ENDIF}
{$IFDEF MSWINDOWS}
      DBTables,
{$ENDIF}
      DBClient,
{$IFDEF ACR5H}
     ACRComMain,
{$ENDIF}
      ACRMain;

type
  TUnitTestKeyAndRange = class(TUnitTest)
   private
    ACRdb:    TACRDatabase;
    ACRTable: TACRTable;
{$IFDEF MSWINDOWS}
    Table:    TTable;
{$ENDIF}
    cds:    TClientDataSet;
    procedure TestCreateTable;
    procedure FilterRecord(DataSet: TDataSet; var Accept: Boolean);
    procedure CheckTables(Caption: String);

    procedure SetIndex(IndexName: String);
    procedure InternalTestRange(Caption: String);
    procedure InternalTestKey(Caption: String);
   public
    procedure TestRange(InMemory: Boolean; Temporary: Boolean);
    procedure TestKey(InMemory: Boolean; Temporary: Boolean);
    procedure MainTest;
    procedure TestShort; override;
  end;

var
  UnitTestKeyAndRange: TUnitTestKeyAndRange;

implementation

procedure TUnitTestKeyAndRange.FilterRecord(DataSet: TDataSet; var Accept: Boolean);
begin
 Accept := False;
 if (Dataset.FieldByName('ID').AsInteger > 2) then
  Accept := True;
end;


procedure TUnitTestKeyAndRange.CheckTables(Caption: String);
begin
{$IFDEF MSWINDOWS}
 if (ACRTable.BOF <> Table.BOF) then
  WriteToErrorLog(Caption+' failed #1, BOF = '
    +IntToStr(Word(ACRTable.BOF))+', BDE BOF = '+IntToStr(Word(Table.BOF)));
 if (ACRTable.EOF <> Table.EOF) then
  WriteToErrorLog(Caption+' failed #2, EOF = '
    +IntToStr(Word(ACRTable.EOF))+', BDE EOF = '+IntToStr(Word(Table.EOF)));
 if (ACRTable.RecordCount <> Table.RecordCount) then
  WriteToErrorLog(Caption+' failed #3, record count = '
    +IntToStr(ACRTable.RecordCount)+', BDE record count = '+IntToStr(Table.RecordCount));
{$ENDIF}
 if (ACRTable.BOF <> cds.BOF) then
  WriteToErrorLog(Caption+' failed #1, BOF = '
    +IntToStr(Word(ACRTable.BOF))+', TClientDataset BOF = '+IntToStr(Word(cds.BOF)));
 if (ACRTable.EOF <> cds.EOF) then
  WriteToErrorLog(Caption+' failed #2, EOF = '
    +IntToStr(Word(ACRTable.EOF))+', TClientDataset EOF = '+IntToStr(Word(cds.EOF)));
 if (ACRTable.RecordCount <> cds.RecordCount) then
  WriteToErrorLog(Caption+' failed #3, record count = '
    +IntToStr(ACRTable.RecordCount)+', TClientDataset record count = '+IntToStr(cds.RecordCount));
end;


procedure TUnitTestKeyAndRange.TestCreateTable;
begin
  if (ACRTable.InMemory) then
    UnitTestList.WriteToProcessLog('create table in memory mode');
  if (ACRTable.Temporary) then
    UnitTestList.WriteToProcessLog('create table in temporary mode');

{$IFDEF MSWINDOWS}
  Table.FieldDefs.Clear;
  Table.FieldDefs.Add('ID',ftAutoInc,0,False);
  Table.FieldDefs.Add('Field1',ftInteger,0,False);
  Table.FieldDefs.Add('Field2',ftString,2000,False);
  Table.IndexDefs.Clear;
  Table.IndexDefs.Add('','ID',[ixPrimary]);
  Table.IndexDefs.Add('Index21','Field2;Field1',[ixCaseInsensitive]);
  Table.IndexDefs.Add('Index1','Field1',[ixCaseInsensitive]);
  Table.IndexDefs.Add('Index2','Field2',[ixCaseInsensitive]);
  Table.IndexDefs.Add('Index3','Field2',[ixDescending]);
{$ENDIF}

  cds.FieldDefs.Clear;
  cds.FieldDefs.Add('ID',ftAutoInc,0,False);
  cds.FieldDefs.Add('Field1',ftInteger,0,False);
  cds.FieldDefs.Add('Field2',ftString,2000,False);
  cds.IndexDefs.Clear;
  cds.IndexDefs.Add('','ID',[ixPrimary]);
  cds.IndexDefs.Add('Index21','Field2;Field1',[ixCaseInsensitive]);
  cds.IndexDefs.Add('Index1','Field1',[ixCaseInsensitive]);
  cds.IndexDefs.Add('Index2','Field2',[ixCaseInsensitive]);
  cds.IndexDefs.Add('Index3','Field2',[ixDescending]);

  ACRTable.FieldDefs.Clear;
  ACRTable.FieldDefs.Add('ID',ftAutoInc,0,False);
  ACRTable.FieldDefs.Add('Field1',ftInteger,0,False);
  ACRTable.FieldDefs.Add('Field2',ftString,300,False);
  ACRTable.IndexDefs.Clear;
  ACRTable.IndexDefs.Add('Primary','ID',[]);
  ACRTable.IndexDefs.Add('Index21','Field2;Field1',[ixCaseInsensitive]);
  ACRTable.IndexDefs.Add('Index1','Field1',[ixCaseInsensitive]);
  ACRTable.IndexDefs.Add('Index2','Field2',[ixCaseInsensitive]);
  ACRTable.IndexDefs.Add('Index3','Field2',[ixDescending]);
  UnitTestList.WriteToProcessLog('FieldDefs filled');
  try
   if (ACRTable.Exists) then
    ACRTable.DeleteTable;
   ACRTable.CreateTable;

{$IFDEF MSWINDOWS}
   if (Table.Exists) then
    Table.DeleteTable;
   Table.CreateTable;
{$ENDIF}
   cds.CreateDataset;

   UnitTestList.WriteToProcessLog('Table created');
  except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('Error creating table' + #9 + 'Error:'#13#10 + e.Message);
     end;
  end;
  try
   ACRTable.Open;
{$IFDEF MSWINDOWS}
   Table.Open;
{$ENDIF}
   cds.Open;
   CheckTables('CreateTable, after open');
   UnitTestList.WriteToProcessLog('Table opened');
  except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('Error opening table' + #9 + 'Error:'#13#10 + e.Message);
     end;
  end;
  ACRTable.Insert;
  if (ACRTable.Temporary) then
    ACRTable.Fields[0].AsInteger := ACRTable.RecordCount+1;
  ACRTable.Fields[1].AsInteger := 10;
  ACRTable.Fields[2].AsString := 'aaa';
  ACRTable.Post;
  ACRTable.Insert;
  if (ACRTable.Temporary) then
    ACRTable.Fields[0].AsInteger := ACRTable.RecordCount+1;
  ACRTable.Fields[1].AsInteger := 15;
  ACRTable.Fields[2].AsString := 'aac';
  ACRTable.Post;
  ACRTable.Insert;
  if (ACRTable.Temporary) then
    ACRTable.Fields[0].AsInteger := ACRTable.RecordCount+1;
  ACRTable.Fields[1].AsInteger := 15;
  ACRTable.Fields[2].AsString := 'aab';
  ACRTable.Post;
  ACRTable.Insert;
  if (ACRTable.Temporary) then
    ACRTable.Fields[0].AsInteger := ACRTable.RecordCount+1;
  ACRTable.Fields[1].AsInteger := 20;
  ACRTable.Fields[2].AsString := 'Aab';
  ACRTable.Post;
  ACRTable.Insert;
  if (ACRTable.Temporary) then
    ACRTable.Fields[0].AsInteger := ACRTable.RecordCount+1;
  ACRTable.Fields[1].AsInteger := 25;
  ACRTable.Fields[2].AsString := 'aac';
  ACRTable.Post;
  ACRTable.Insert;
  if (ACRTable.Temporary) then
    ACRTable.Fields[0].AsInteger := ACRTable.RecordCount+1;
  ACRTable.Fields[1].AsInteger := 5;
  ACRTable.Fields[2].AsString := 'bab';
  ACRTable.Post;

  ACRTable.First;
  while not ACRTable.Eof do
   begin
{$IFDEF MSWINDOWS}
    Table.Insert;
    Table.Fields[1].Assign(ACRTable.Fields[1]);
    Table.Fields[2].Assign(ACRTable.Fields[2]);
    Table.Post;
{$ENDIF}
    cds.Insert;
    cds.Fields[1].Assign(ACRTable.Fields[1]);
    cds.Fields[2].Assign(ACRTable.Fields[2]);
    cds.Post;
    ACRTable.Next;
   end;

{$IFDEF MSWINDOWS}
  Table.Last;
{$ENDIF}
  cds.Last;
  ACRTable.Last;
  CheckTables('CreateTable, after inserts');
end;


procedure TUnitTestKeyAndRange.SetIndex(IndexName: String);
begin
  ACRTable.IndexName := IndexName;
{$IFDEF MSWINDOWS}
  Table.IndexName := IndexName;
  if (Table.IndexName <> ACRTable.IndexName) then
   WriteToErrorLog('Cannot set TTable index - '+IndexName);
{$ENDIF}
  cds.IndexName := IndexName;
  if (cds.IndexName <> ACRTable.IndexName) then
   WriteToErrorLog('Cannot set TClientDataset index - '+IndexName);
end;


procedure TUnitTestKeyAndRange.InternalTestRange(Caption: String);
begin
  SetIndex('Index1');
  ACRTable.SetRangeStart;
  ACRTable.Fields[1].AsInteger := 5;
  ACRTable.SetRangeEnd;
  ACRTable.Fields[1].AsInteger := 15;
  ACRTable.ApplyRange;

{$IFDEF MSWINDOWS}
  Table.SetRangeStart;
  Table.Fields[1].AsInteger := 5;
  Table.SetRangeEnd;
  Table.Fields[1].AsInteger := 15;
  Table.ApplyRange;
{$ENDIF}
  cds.SetRangeStart;
  cds.Fields[1].AsInteger := 5;
  cds.SetRangeEnd;
  cds.Fields[1].AsInteger := 15;
  cds.ApplyRange;

  CheckTables('Range 5-15 not exclusive');

  if (not ACRTable.FindKey([10])) then
   WriteToErrorLog('Find key 10 with Range 5-15 not exclusive failed');

  ACRTable.SetRangeStart;
  ACRTable.Fields[1].AsInteger := 5;
  ACRTable.SetRangeEnd;
  ACRTable.Fields[1].AsInteger := 5;
  ACRTable.ApplyRange;
{$IFDEF MSWINDOWS}
  Table.SetRangeStart;
  Table.Fields[1].AsInteger := 5;
  Table.SetRangeEnd;
  Table.Fields[1].AsInteger := 5;
  Table.ApplyRange;
{$ENDIF}
  cds.SetRangeStart;
  cds.Fields[1].AsInteger := 5;
  cds.SetRangeEnd;
  cds.Fields[1].AsInteger := 5;
  cds.ApplyRange;

  CheckTables('Range 5-5 not exclusive');

  ACRTable.SetRangeStart;
  ACRTable.Fields[1].AsInteger := 15;
  ACRTable.SetRangeEnd;
  ACRTable.Fields[1].AsInteger := 5;
  ACRTable.ApplyRange;

{$IFDEF MSWINDOWS}
  Table.SetRangeStart;
  Table.Fields[1].AsInteger := 15;
  Table.SetRangeEnd;
  Table.Fields[1].AsInteger := 5;
  Table.ApplyRange;
{$ENDIF}
  cds.SetRangeStart;
  cds.Fields[1].AsInteger := 15;
  cds.SetRangeEnd;
  cds.Fields[1].AsInteger := 5;
  cds.ApplyRange;

  CheckTables('Range 15-5 not exclusive');

  ACRTable.SetRangeStart;
  ACRTable.Fields[1].AsInteger := 5;
  ACRTable.SetRangeEnd;
  ACRTable.Fields[1].AsInteger := 15;
  ACRTable.ApplyRange;
  ACRTable.Filter := 'Field1 = 5';
  ACRTable.Filtered := True;

{$IFDEF MSWINDOWS}
  Table.SetRangeStart;
  Table.Fields[1].AsInteger := 5;
  Table.SetRangeEnd;
  Table.Fields[1].AsInteger := 15;
  Table.ApplyRange;
  Table.Filter := 'Field1 = 5';
  Table.Filtered := True;
{$ENDIF}
  cds.SetRangeStart;
  cds.Fields[1].AsInteger := 5;
  cds.SetRangeEnd;
  cds.Fields[1].AsInteger := 15;
  cds.ApplyRange;
  cds.Filter := 'Field1 = 5';
  cds.Filtered := True;

  CheckTables('Range 5-15 with filter not exclusive');

  ACRTable.Filtered := False;
{$IFDEF MSWINDOWS}
  Table.Filtered := False;
{$ENDIF}
  cds.Filtered := False;

  ACRTable.SetRangeStart;
  ACRTable.Fields[1].AsInteger := 5;
  ACRTable.SetRangeEnd;
  ACRTable.Fields[1].AsInteger := 15;
  ACRTable.ApplyRange;
  ACRTable.Filter := '(Field1 >= 5) AND (Field1 < 26) AND (Field2=''aac'')';
  ACRTable.Filtered := True;

{$IFDEF MSWINDOWS}
  Table.SetRangeStart;
  Table.Fields[1].AsInteger := 5;
  Table.SetRangeEnd;
  Table.Fields[1].AsInteger := 15;
  Table.ApplyRange;
  Table.Filter := '(Field1 >= 5) AND (Field1 < 26) AND (Field2=''aac'')';
  Table.Filtered := True;
{$ENDIF}
  cds.SetRangeStart;
  cds.Fields[1].AsInteger := 5;
  cds.SetRangeEnd;
  cds.Fields[1].AsInteger := 15;
  cds.ApplyRange;
  cds.Filter := '(Field1 >= 5) AND (Field1 < 26) AND (Field2=''aac'')';
  cds.Filtered := True;

  CheckTables('Range 5-15 with filter#2 not exclusive');

  ACRTable.Filtered := False;
{$IFDEF MSWINDOWS}
  Table.Filtered := False;
{$ENDIF}
  cds.Filtered := False;

  //-------------------------
  ACRTable.SetRangeStart;
  ACRTable.Fields[1].AsInteger := 5;
  ACRTable.SetRangeEnd;
  ACRTable.Fields[1].AsInteger := 15;
  ACRTable.ApplyRange;
  ACRTable.Filter := '(Field1 >= 1) AND (Field1 <= 10)';
  ACRTable.Filtered := True;

{$IFDEF MSWINDOWS}
  Table.SetRangeStart;
  Table.Fields[1].AsInteger := 5;
  Table.SetRangeEnd;
  Table.Fields[1].AsInteger := 15;
  Table.ApplyRange;
  Table.Filter := '(Field1 >= 1) AND (Field1 <= 10)';
  Table.Filtered := True;
{$ENDIF}
  cds.SetRangeStart;
  cds.Fields[1].AsInteger := 5;
  cds.SetRangeEnd;
  cds.Fields[1].AsInteger := 15;
  cds.ApplyRange;
  cds.Filter := '(Field1 >= 1) AND (Field1 <= 10)';
  cds.Filtered := True;

  CheckTables('Range 5-15 with filter#3 not exclusive');

  ACRTable.Filtered := False;
{$IFDEF MSWINDOWS}
  Table.Filtered := False;
{$ENDIF}
  cds.Filtered := False;

  //-------------------------
  ACRTable.SetRangeStart;
  ACRTable.Fields[1].AsInteger := 5;
  ACRTable.SetRangeEnd;
  ACRTable.Fields[1].AsInteger := 15;
  ACRTable.ApplyRange;
  ACRTable.Filter := '(Field1 >= 10) AND (Field1 <= 25)';
  ACRTable.Filtered := True;

{$IFDEF MSWINDOWS}
  Table.SetRangeStart;
  Table.Fields[1].AsInteger := 5;
  Table.SetRangeEnd;
  Table.Fields[1].AsInteger := 15;
  Table.ApplyRange;
  Table.Filter := '(Field1 >= 10) AND (Field1 <= 25)';
  Table.Filtered := True;
{$ENDIF}
  cds.SetRangeStart;
  cds.Fields[1].AsInteger := 5;
  cds.SetRangeEnd;
  cds.Fields[1].AsInteger := 15;
  cds.ApplyRange;
  cds.Filter := '(Field1 >= 10) AND (Field1 <= 25)';
  cds.Filtered := True;

  CheckTables('Range 5-15 with filter#4 not exclusive');

  ACRTable.Filtered := False;
{$IFDEF MSWINDOWS}
  Table.Filtered := False;
{$ENDIF}
  cds.Filtered := False;

  //-------------------------
  ACRTable.SetRangeStart;
  ACRTable.Fields[1].AsInteger := 5;
  ACRTable.SetRangeEnd;
  ACRTable.Fields[1].AsInteger := 15;
  ACRTable.ApplyRange;
  ACRTable.Filter := '(Field1 >= 7) AND (Field1 <= 10)';
  ACRTable.Filtered := True;

{$IFDEF MSWINDOWS}
  Table.SetRangeStart;
  Table.Fields[1].AsInteger := 5;
  Table.SetRangeEnd;
  Table.Fields[1].AsInteger := 15;
  Table.ApplyRange;
  Table.Filter := '(Field1 >= 7) AND (Field1 <= 10)';
  Table.Filtered := True;
{$ENDIF}
  cds.SetRangeStart;
  cds.Fields[1].AsInteger := 5;
  cds.SetRangeEnd;
  cds.Fields[1].AsInteger := 15;
  cds.ApplyRange;
  cds.Filter := '(Field1 >= 7) AND (Field1 <= 10)';
  cds.Filtered := True;

  CheckTables('Range 5-15 with filter#5 not exclusive');
  ACRTable.Filtered := False;
{$IFDEF MSWINDOWS}
  Table.Filtered := False;
{$ENDIF}
  cds.Filtered := False;

  //-------------------------
  ACRTable.SetRangeStart;
  ACRTable.Fields[1].AsInteger := 15;
  ACRTable.SetRangeEnd;
  ACRTable.Fields[1].AsInteger := 5;
  ACRTable.ApplyRange;
  ACRTable.Filter := 'Field1 = 15';
  ACRTable.Filtered := True;

{$IFDEF MSWINDOWS}
  Table.SetRangeStart;
  Table.Fields[1].AsInteger := 15;
  Table.SetRangeEnd;
  Table.Fields[1].AsInteger := 5;
  Table.ApplyRange;
  Table.Filter := 'Field1 = 15';
  Table.Filtered := True;
{$ENDIF}
  cds.SetRangeStart;
  cds.Fields[1].AsInteger := 15;
  cds.SetRangeEnd;
  cds.Fields[1].AsInteger := 5;
  cds.ApplyRange;
  cds.Filter := 'Field1 = 15';
  cds.Filtered := True;

  CheckTables('Range 15-5 with filter not exclusive');

  ACRTable.Filtered := False;
{$IFDEF MSWINDOWS}
  Table.Filtered := False;
{$ENDIF}
  cds.Filtered := False;

  ACRTable.SetRangeStart;
  ACRTable.Fields[1].AsInteger := 5;
  ACRTable.SetRangeEnd;
  ACRTable.Fields[1].AsInteger := 5;
  ACRTable.ApplyRange;
  ACRTable.Filter := 'Field1 = 5';
  ACRTable.Filtered := True;

{$IFDEF MSWINDOWS}
  Table.SetRangeStart;
  Table.Fields[1].AsInteger := 5;
  Table.SetRangeEnd;
  Table.Fields[1].AsInteger := 5;
  Table.ApplyRange;
  Table.Filter := 'Field1 = 5';
  Table.Filtered := True;
{$ENDIF}
  cds.SetRangeStart;
  cds.Fields[1].AsInteger := 5;
  cds.SetRangeEnd;
  cds.Fields[1].AsInteger := 5;
  cds.ApplyRange;
  cds.Filter := 'Field1 = 5';
  cds.Filtered := True;

  CheckTables('Range 5-5 with filter not exclusive');
  ACRTable.Filtered := False;
{$IFDEF MSWINDOWS}
  Table.Filtered := False;
{$ENDIF}
  cds.Filtered := False;

  ACRTable.SetRangeStart;
  ACRTable.Fields[1].AsInteger := 5;
  ACRTable.SetRangeEnd;
  ACRTable.Fields[1].AsInteger := 25;
  ACRTable.ApplyRange;
  ACRTable.Filter := 'Field2 = ''aac''';
  ACRTable.Filtered := True;

{$IFDEF MSWINDOWS}
  Table.SetRangeStart;
  Table.Fields[1].AsInteger := 5;
  Table.SetRangeEnd;
  Table.Fields[1].AsInteger := 25;
  Table.ApplyRange;
  Table.Filter := 'Field2 = ''aac''';
  Table.Filtered := True;
{$ENDIF}
  cds.SetRangeStart;
  cds.Fields[1].AsInteger := 5;
  cds.SetRangeEnd;
  cds.Fields[1].AsInteger := 25;
  cds.ApplyRange;
  cds.Filter := 'Field2 = ''aac''';
  cds.Filtered := True;

  CheckTables('Range 5-25 with filter not exclusive');
  ACRTable.Filtered := False;
{$IFDEF MSWINDOWS}
  Table.Filtered := False;
{$ENDIF}
  cds.Filtered := False;

  ACRTable.EditRangeStart;
  ACRTable.Fields[1].AsInteger := 15;
  ACRTable.EditRangeEnd;
  ACRTable.KeyExclusive := True;
  ACRTable.Fields[1].AsInteger := 25;
  ACRTable.ApplyRange;

{$IFDEF MSWINDOWS}
  Table.EditRangeStart;
  Table.Fields[1].AsInteger := 15;
  Table.EditRangeEnd;
  Table.KeyExclusive := True;
  Table.Fields[1].AsInteger := 25;
  Table.ApplyRange;
{$ENDIF}
  cds.EditRangeStart;
  cds.Fields[1].AsInteger := 15;
  cds.EditRangeEnd;
  cds.KeyExclusive := True;
  cds.Fields[1].AsInteger := 25;
  cds.ApplyRange;

  CheckTables('Range 15-25 exclusive');

  ACRTable.CancelRange;
{$IFDEF MSWINDOWS}
  Table.CancelRange;
{$ENDIF}
  cds.CancelRange;

  CheckTables('Range cancelled');

  SetIndex('Index21');
  ACRTable.SetRangeStart;
  ACRTable.KeyExclusive := False;
  ACRTable.Fields[1].AsInteger := 15;
  ACRTable.Fields[2].AsString := 'aaa';
  ACRTable.SetRangeEnd;
  ACRTable.Fields[1].AsInteger := 25;
  ACRTable.Fields[2].AsString := 'aac';
  ACRTable.ApplyRange;

{$IFDEF MSWINDOWS}
  Table.SetRangeStart;
  Table.KeyExclusive := False;
  Table.Fields[1].AsInteger := 15;
  Table.Fields[2].AsString := 'aaa';
  Table.SetRangeEnd;
  Table.Fields[1].AsInteger := 25;
  Table.Fields[2].AsString := 'aac';
  Table.ApplyRange;
{$ENDIF}
  cds.SetRangeStart;
  cds.KeyExclusive := False;
  cds.Fields[1].AsInteger := 15;
  cds.Fields[2].AsString := 'aaa';
  cds.SetRangeEnd;
  cds.Fields[1].AsInteger := 25;
  cds.Fields[2].AsString := 'aac';
  cds.ApplyRange;

  CheckTables('Range aaa-aac, 15-25 not exclusive, 2 fields');

  ACRTable.EditRangeStart;
  ACRTable.KeyFieldCount := 1;
  ACRTable.Fields[1].AsInteger := 58;
  ACRTable.Fields[2].AsString := 'aaa';
  ACRTable.EditRangeEnd;
  ACRTable.KeyFieldCount := 1;
  ACRTable.Fields[1].AsInteger := 10;
  ACRTable.Fields[2].AsString := 'aac';
  ACRTable.ApplyRange;
{$IFDEF MSWINDOWS}
  Table.EditRangeStart;
  Table.KeyFieldCount := 1;
  Table.Fields[1].AsInteger := 58;
  Table.Fields[2].AsString := 'aaa';
  Table.EditRangeEnd;
  Table.KeyFieldCount := 1;
  Table.Fields[1].AsInteger := 10;
  Table.Fields[2].AsString := 'aac';
  Table.ApplyRange;
{$ENDIF}
  cds.EditRangeStart;
  cds.KeyFieldCount := 1;
  cds.Fields[1].AsInteger := 58;
  cds.Fields[2].AsString := 'aaa';
  cds.EditRangeEnd;
  cds.KeyFieldCount := 1;
  cds.Fields[1].AsInteger := 10;
  cds.Fields[2].AsString := 'aac';
  cds.ApplyRange;

  CheckTables('Range aaa-aac, 58-10 not exclusive, 2 fields');
end;


procedure TUnitTestKeyAndRange.InternalTestKey(Caption: String);
var IntValue:  Integer;
    IntValue2: Integer;
    StrValue:  String;
begin
  SetIndex('Index1');
  if (ACRTable.FindKey([16])) then
    WriteToErrorLog(Caption+'FindKey Field1 = 16 failed');
  if (not ACRTable.FindKey([15])) then
    WriteToErrorLog(Caption+'FindKey Field1 = 15 failed #1');
  if (ACRTable.Fields[1].AsInteger <> 15) then
    WriteToErrorLog(Caption+'FindKey Field1 = 15 failed #2');
  SetIndex('Index2');
  ACRTable.SetKey;
  if (ACRTable.GotoKey) then
    WriteToErrorLog(Caption+'GotoKey Field2 = NULL failed');
  ACRTable.EditKey;
  ACRTable.Fields[2].AsString := 'aac';
  if (not ACRTable.GotoKey) then
    WriteToErrorLog(Caption+'GotoKey Field2 = "aac" failed #1');
  if (ACRTable.Fields[2].AsString <> 'aac') then
    WriteToErrorLog(Caption+'GotoKey Field2 = "aac" failed #2');

  ACRTable.FindNearest(['aaf']);

{$IFDEF MSWINDOWS}
  Table.FindNearest(['aaf']);
  if (Table.Fields[0].AsInteger <> ACRTable.Fields[0].AsInteger) then
    WriteToErrorLog(Caption+'FindNearest TTable Field2 = "aaf" failed #2');
{$ENDIF}
  cds.FindNearest(['aaf']);
  if (cds.Fields[0].AsInteger <> ACRTable.Fields[0].AsInteger) then
    WriteToErrorLog(Caption+'FindNearest TClientDataset Field2 = "aaf" failed #2');

  SetIndex('Index1');
  ACRTable.SetKey;
  ACRTable.Fields[1].AsInteger := 3;
  ACRTable.GotoNearest;

{$IFDEF MSWINDOWS}
  Table.SetKey;
  Table.Fields[1].AsInteger := 3;
  Table.GotoNearest;
  if (Table.Fields[0].AsInteger <> ACRTable.Fields[0].AsInteger) then
    WriteToErrorLog(Caption+'GotoNearest TTable Field1 = 3 failed #1');
{$ENDIF}
  cds.SetKey;
  cds.Fields[1].AsInteger := 3;
  cds.GotoNearest;
  if (cds.Fields[0].AsInteger <> ACRTable.Fields[0].AsInteger) then
    WriteToErrorLog(Caption+'GotoNearest TClientDataset Field1 = 3 failed #1');

  ACRTable.EditKey;
  ACRTable.Fields[1].AsInteger := 21;
  ACRTable.GotoNearest;
{$IFDEF MSWINDOWS}
  Table.EditKey;
  Table.Fields[1].AsInteger := 21;
  Table.GotoNearest;
  if (Table.Fields[0].AsInteger <> ACRTable.Fields[0].AsInteger) then
    WriteToErrorLog(Caption+'GotoNearest TTable Field1 = 21 failed #1');
{$ENDIF}
  cds.EditKey;
  cds.Fields[1].AsInteger := 21;
  cds.GotoNearest;
  if (cds.Fields[0].AsInteger <> ACRTable.Fields[0].AsInteger) then
    WriteToErrorLog(Caption+'GotoNearest TClientDataset Field1 = 21 failed #1');

  // filter
  ACRTable.Filtered := False;
  ACRTable.OnFilterRecord := FilterRecord;
  ACRTable.Filtered := True;
{$IFDEF MSWINDOWS}
  Table.Filtered := False;
  Table.OnFilterRecord := FilterRecord;
  Table.Filtered := True;
{$ENDIF}
  cds.Filtered := False;
  cds.OnFilterRecord := FilterRecord;
  cds.Filtered := True;

  CheckTables(Caption + 'OnFilterRecord');

  ACRTable.FindNearest([15]);
{$IFDEF MSWINDOWS}
  Table.FindNearest([15]);
  if (Table.Fields[0].AsInteger <> ACRTable.Fields[0].AsInteger) then
    WriteToErrorLog(Caption+'GotoNearest TTable with filter Field1 = 15 failed #1');
{$ENDIF}
  cds.FindNearest([15]);
  if (cds.Fields[0].AsInteger <> ACRTable.Fields[0].AsInteger) then
    WriteToErrorLog(Caption+'GotoNearest TClientDataset with filter Field1 = 15 failed #1');

  ACRTable.OnFilterRecord := nil;
  ACRTable.Filtered := False;
{$IFDEF MSWINDOWS}
  Table.OnFilterRecord := nil;
  Table.Filtered := False;
{$ENDIF}
  cds.OnFilterRecord := nil;
  cds.Filtered := False;
end;


procedure TUnitTestKeyAndRange.TestRange(InMemory: Boolean; Temporary: Boolean);
begin
 ACRdb := TACRDatabase.Create(nil);
 ACRTable := TACRTable.Create(nil);
{$IFDEF MSWINDOWS}
 Table := TTable.Create(nil);
{$ENDIF}
 cds := TClientDataset.Create(nil);
 try
   ACRTable.TableName := 'test';
{$IFDEF MSWINDOWS}
   Table.TableType := ttParadox;
   Table.TableName := 'test';
   Table.DatabaseName := Self.TempDir;
{$ENDIF}
   cds.FileName := Self.TempDir + 'test.xml';
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

   WriteToProcessLog('Testing range');
   InternalTestRange('Testing range - ');
   WriteToProcessLog('Testing range complete');

 finally
   ACRTable.Close;
   if (not ACRTable.Temporary) then
    ACRTable.DeleteTable(True);
   ACRTable.Free;
{$IFDEF MSWINDOWS}
   Table.Close;
   Table.DeleteTable;
   Table.Free;
{$ENDIF}
   cds.Free;
   DeleteFile(Self.TempDir + 'test.xml');
   if (not InMemory) and (not Temporary) then
    begin
     ACRdb.Close;
     ACRdb.DeleteDatabase;
    end;
   ACRdb.Free;
 end;
end;


procedure TUnitTestKeyAndRange.TestKey(InMemory: Boolean; Temporary: Boolean);
begin
 ACRdb := TACRDatabase.Create(nil);
 ACRTable := TACRTable.Create(nil);
{$IFDEF MSWINDOWS}
 Table := TTable.Create(nil);
{$ENDIF}
 cds := TClientDataset.Create(nil);
 try
   ACRTable.TableName := 'test';
{$IFDEF MSWINDOWS}
   Table.TableType := ttParadox;
   Table.TableName := 'test';
   Table.DatabaseName := Self.TempDir;
{$ENDIF}
   cds.FileName := Self.TempDir + 'test.xml';
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

   WriteToProcessLog('Testing key');
   InternalTestKey('Testing key - ');
   WriteToProcessLog('Testing key complete');

 finally
   ACRTable.Close;
   if (not ACRTable.Temporary) then
    ACRTable.DeleteTable(True);
   ACRTable.Free;
{$IFDEF MSWINDOWS}
   Table.Close;
   Table.DeleteTable;
   Table.Free;
{$ENDIF}
   cds.Free;
   DeleteFile(Self.TempDir + 'test.xml');
   if (not InMemory) and (not Temporary) then
    begin
     ACRdb.Close;
     ACRdb.DeleteDatabase;
    end;
   ACRdb.Free;
 end;
end;


procedure TUnitTestKeyAndRange.MainTest;
begin
 TestKey(False,False);
 TestKey(True,False);
 TestKey(False,True);
 TestRange(False,False);
 TestRange(True,False);
 TestRange(False,True);
end;


procedure TUnitTestKeyAndRange.TestShort;
begin
 CheckAction(MainTest, 'Main test of key and range operations');
end;


initialization
  UnitTestKeyAndRange := TUnitTestKeyAndRange.Create(UnitTestList);

finalization
  UnitTestKeyAndRange.Free;
end.
