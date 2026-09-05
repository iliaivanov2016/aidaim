unit utRecNoAndRecordCount;

interface

{$I UTConfig.Inc}

uses uTestList, SysUtils, Db,
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

const TestShortMaxRecordCount = 10;
const TestLongMaxRecordCount = 100;

type
  TUnitTestRecNoAndRecordCount = class(TUnitTest)
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
  UnitTestRecNoAndRecordCount: TUnitTestRecNoAndRecordCount;


implementation

uses Math;


procedure TUnitTestRecNoAndRecordCount.TestCreateTable(UseIndexes: Boolean);
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
procedure TUnitTestRecNoAndRecordCount.InternalTestFilter(Caption: String);

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

 procedure TestAllVariants(RecordCount: Integer);
 var i,j: Integer;
 begin
    EmptyTable;
    for i := 1 to RecordCount do
     InsertRecord(True);
    CheckRecordCount(RecordCount,'test table with RecordCount =  '+IntToStr(RecordCount));

    // test with deleted records
    if (not ACRTable.Temporary) then
     begin
      for j := 1 to RecordCount do
       begin
        EmptyTable;
        for i := 1 to RecordCount do
         InsertRecord(True);
        ACRTable.RecNo := j;
        if (ACRTable.RecNo <> j) then
          UnitTestList.WriteToErrorLog(FCaption+Caption + ' - invalid set ACRTable.RecNo = ' +
            IntToStr(ACRTable.RecNo) +
            ', RecNo = '+IntToStr(j));
        ACRTable.Delete;
        CheckRecordCount(RecordCount-1,'test table with j =  '+IntToStr(j));
       end;
     end;
 end;

begin
 // test empty filter
 EmptyTable;
 ACRTable.Filtered := False;
 CheckRecordCount(0,'recno on empty table ');
 TestAllVariants(FMaxRecCount);
end;


procedure TUnitTestRecNoAndRecordCount.TestFilter(InMemory: Boolean; Temporary: Boolean);
begin
 ACRTable := TACRTable.Create(nil);
 ACRdb := TACRDatabase.Create(nil);
 try
   ACRTable.Exclusive := True;
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


   WriteToProcessLog('Testing not filtered RecNo and RecordCount without indexes');
   InternalTestFilter('Testing not filtered RecNo and RecordCount without indexes - ');

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

   WriteToProcessLog('Testing not filtered RecNo and RecordCount with indexes');
   InternalTestFilter('Testing not filtered RecNo and RecordCount with indexes - ');

   WriteToProcessLog('Testing not filtered RecNo and RecordCount complete');

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




procedure TUnitTestRecNoAndRecordCount.MainTest;
begin
 TestFilter(False,False);
 TestFilter(True,False);
 TestFilter(False,True);
end;


procedure TUnitTestRecNoAndRecordCount.TestShort;
begin
 FMaxRecCount := TestShortMaxRecordCount;
 CheckAction(MainTest, 'Main test of RecNo and RecordCount on not filtered table');
end;

procedure TUnitTestRecNoAndRecordCount.TestLong;
begin
 FMaxRecCount := TestLongMaxRecordCount;
 CheckAction(MainTest, 'Main test of RecNo and RecordCount on not filtered table');
end;

initialization
  UnitTestRecNoAndRecordCount := TUnitTestRecNoAndRecordCount.Create(UnitTestList);

finalization
  UnitTestRecNoAndRecordCount.Free;
end.



