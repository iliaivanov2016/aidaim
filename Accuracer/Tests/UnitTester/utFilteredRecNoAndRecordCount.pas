unit utFilteredRecNoAndRecordCount;

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

const TestShortMaxRecordCount = 10;
const TestLongMaxRecordCount = 100;

type
  TUnitTestFilteredRecNoAndRecordCount = class(TUnitTest)
   private
    FCaption: String;
    FMaxRecCount: Integer;
    ACRdb:        TACRDatabase;
    ACRTable:     TACRTable;
    procedure TestCreateTable(UseIndexes: Boolean);
    procedure InternalTestFilter(Caption: String);
   public
    procedure TestFilter(InMemory: Boolean; Temporary: Boolean);
    procedure MainTest;
    procedure TestShort; override;
    procedure TestLong; override;
  end;

var
  UnitTestFilteredRecNoAndRecordCount: TUnitTestFilteredRecNoAndRecordCount;


implementation

uses Math;


procedure TUnitTestFilteredRecNoAndRecordCount.TestCreateTable(UseIndexes: Boolean);
begin
  if (ACRTable.InMemory) then
    UnitTestList.WriteToProcessLog('create table in memory mode')
  else
  if (ACRTable.Temporary) then
    UnitTestList.WriteToProcessLog('create table in temporary mode')
  else
    UnitTestList.WriteToProcessLog('create table in disk mode');

  ACRTable.Close;
  ACRTable.IndexName := '';
  ACRTable.FieldDefs.Clear;
  ACRTable.FieldDefs.Add('Field1',ftInteger,0,False);
  ACRTable.IndexDefs.Clear;
  if (UseIndexes) then
   ACRTable.IndexDefs.Add('Index1','Field1',[]);
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
  try
   ACRTable.Open;
   if (UseIndexes) then
    ACRTable.IndexName := 'Index1';
   UnitTestList.WriteToProcessLog('Table opened');
  except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('Error opening table' + #9 + 'Error:'#13#10 + e.Message);
     end;
  end;
end; // TestCreateTable


//------------------------------------------------------------------------------
// test
//------------------------------------------------------------------------------
procedure TUnitTestFilteredRecNoAndRecordCount.InternalTestFilter(Caption: String);
var i: Integer;

 procedure EmptyTable;
 begin
  if (ACRTable.Temporary) then
   begin
    ACRTable.Close;
    ACRTable.CreateTable;
    ACRTable.Open;
   end
  else
   begin
    ACRTable.Close;
    ACRTable.EmptyTable;
    ACRTable.Open;
   end;
 end;

 procedure InsertRecord(Visible: Boolean);
 begin
  ACRTable.Insert;
  if (Visible) then
   ACRTable.Fields[0].AsInteger := 1
  else
   ACRTable.Fields[0].AsInteger := 0;
  ACRTable.Post;
 end;

 procedure SetFilter;
 begin
   ACRTable.Filtered := False;
   ACRTable.Filter := 'Field1 = 1';
   ACRTable.Filtered := True;
 end;

 procedure CheckRecordCount(RecCount: Integer; Caption: String);
 var RecNo: Integer;
 begin
  if (ACRTable.RecordCount <> RecCount) then
   UnitTestList.WriteToErrorLog(FCaption+Caption + ' - invalid record count, '+
    ', ACRTable.RecordCount = '+IntToStr(ACRTable.RecordCount)+
    ', RecCount = '+IntToStr(RecCount));
  ACRTable.First;
  if (RecCount = 0) then
   if (ACRTable.RecNo <> -1) then
    UnitTestList.WriteToErrorLog(FCaption+Caption + ' - invalid ACRTable.RecNo = ' +
      IntToStr(ACRTable.RecNo) + ', RecCount = '+IntToStr(RecCount));
  RecNo := 1;
  while not ACRTable.Eof do
   begin
    if (ACRTable.RecNo <> RecNo) then
     begin
      UnitTestList.WriteToErrorLog(FCaption+Caption + ' - invalid get ACRTable.RecNo = ' +
        IntToStr(ACRTable.RecNo) +
        ', RecNo = '+IntToStr(RecNo)+
        ', RecCount = '+IntToStr(RecCount));
      break;
     end;

    ACRTable.RecNo := RecNo;
    if (ACRTable.RecNo <> RecNo) then
      UnitTestList.WriteToErrorLog(FCaption+Caption + ' - invalid set ACRTable.RecNo = ' +
        IntToStr(ACRTable.RecNo) +
        ', RecNo = '+IntToStr(RecNo)+
        ', RecCount = '+IntToStr(RecCount));
    Inc(RecNo);
    ACRTable.Next;
   end;
 end;

 function GetMaxBitNo(x: Integer): Integer;
 var i: Integer;
 begin
  Result := 0;
  for i := 0 to 30 do
   if (((1 shl i) and x) <> 0) then
    Result := i;
 end;

 procedure TestAllBitmapVariants(RecordCount: Integer);
 var i,j,x,n,k: Integer;
 begin
  n := GetMaxBitNo(RecordCount);
  k := (1 shl (n+1)) - 1;
  for i := 0 to k do
   begin
    EmptyTable;
    x := 0;
    for j := 0 to n do
     if (i and (1 shl j) = 0) then
      InsertRecord(False)
     else
      begin
       Inc(x);
       InsertRecord(True);
      end;
    SetFilter;
    CheckRecordCount(x,'filter on table, i = '+IntToStr(i));
   end;

 end;

begin
 // test empty filter
 EmptyTable;
 SetFilter;
 CheckRecordCount(0,'filter on empty table ');
 if (FMaxRecCount = TestShortMaxRecordCount) then
  TestAllBitmapVariants(FMaxRecCount)
 else
 for i := 1 to FMaxRecCount do
  TestAllBitmapVariants(i);
end;


procedure TUnitTestFilteredRecNoAndRecordCount.TestFilter(InMemory: Boolean; Temporary: Boolean);
begin
 ACRTable := TACRTable.Create(nil);
 ACRdb := TACRDatabase.Create(nil);
 try
   ACRTable.TableName := 'test';
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
   TestCreateTable(False);
   if ACRTable.InMemory then
    begin
     FCaption := 'Memory without indexes - ';
    end
   else
   if ACRTable.Temporary then
    begin
     FCaption := 'Temporary without indexes - ';
    end
   else
    begin
     FCaption := 'Disk without indexes - ';
    end; // disk


   WriteToProcessLog('Testing filtered RecNo and RecordCount without indexes');
   InternalTestFilter('Testing filtered RecNo and RecordCount without indexes - ');

   TestCreateTable(True);

   if ACRTable.InMemory then
    begin
     FCaption := 'Memory with indexes - ';
    end
   else
   if ACRTable.Temporary then
    begin
     FCaption := 'Temporary with indexes - ';
    end
   else
    begin
     FCaption := 'Disk with indexes - ';
    end; // disk

   WriteToProcessLog('Testing filtered RecNo and RecordCount with indexes');
   InternalTestFilter('Testing filtered RecNo and RecordCount with indexes - ');

   WriteToProcessLog('Testing filtered RecNo and RecordCount complete');

 finally
   if (not Temporary) then
   begin
    ACRTable.Close;
    ACRTable.DeleteTable(True);
   end;
   ACRTable.Free;
   if (not InMemory) and (not Temporary) then
    begin
     ACRdb.Close;
     ACRdb.DeleteDatabase;
    end;
   ACRdb.Free;
 end;
end;




procedure TUnitTestFilteredRecNoAndRecordCount.MainTest;
begin
 TestFilter(False,False);
 TestFilter(True,False);
 TestFilter(False,True);
end;


procedure TUnitTestFilteredRecNoAndRecordCount.TestShort;
begin
 FMaxRecCount := TestShortMaxRecordCount;
 CheckAction(MainTest, 'Main test of RecNo and RecordCount on filtered table');
end;

procedure TUnitTestFilteredRecNoAndRecordCount.TestLong;
begin
 FMaxRecCount := TestLongMaxRecordCount;
 CheckAction(MainTest, 'Main test of RecNo and RecordCount on filtered table');
end;

initialization
  UnitTestFilteredRecNoAndRecordCount := TUnitTestFilteredRecNoAndRecordCount.Create(UnitTestList);

finalization
  UnitTestFilteredRecNoAndRecordCount.Free;
end.



