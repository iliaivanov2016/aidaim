unit utLockManager;

interface

{$I UTConfig.Inc}

uses
{$IFDEF MSWINDOWS}
     Controls,
{$ENDIF}
     SysUtils, DB,
     uTestList,
     ACRMain, 
{$IFDEF ACR5H}
     ACRComMain,
{$ENDIF}
    ACRConverts, ACRDiskEngine, ACRTypes, ACRConst, ACRLocalEngine;

type
  TUnitTestLockManager = class(TUnitTest)
   private

    procedure RunTest(InMemory: Boolean);
    procedure Test1;
   public
    procedure TestShort; override;
  end;

var
  UnitTestLockManager: TUnitTestLockManager;


implementation


{ TUnitTestLockManager }

procedure TUnitTestLockManager.RunTest(InMemory: Boolean);
var
  db:     TACRDatabase;
  table:  TACRTable;
  lm:     TACRTableLocksManager;
  TableName:  String;
  Caption:    String;
  RecordID:   TACRRecordID;
  TableItem:  TACRTableListItem;
begin
  Caption := 'UnitTestLockManager, ';
  if (InMemory) then
   Caption := Caption + 'in memory mode - '
  else
   Caption := Caption + 'file server mode - ';
  WriteToProcessLog(Caption+'run short started');

  db := TACRDatabase.Create(nil);
  db.DatabaseFileName := TempDir+'test.adb';
  db.DatabaseName := 'test';
  db.DeleteDatabase;
  if (db.Exists) then
   WriteToErrorLog(Caption+'cannot delete database #1');
  db.CreateDatabase;
  db.LockParams.Delay := 10;
  db.LockParams.RetryCount := 1;
  db.Open;


  TableName := 'test_table1';
  table := TACRTable.Create(nil);
  table.DatabaseName := db.DatabaseName;
  table.TableName := TableName;
  table.FieldDefs.Clear;
  table.FieldDefs.Add('id',ftAutoInc);
  table.FieldDefs.Add('name',ftString,100);
  table.CreateTable;

  if (not TACRDiskDatabaseData(TACRLocalSession(db.Handle).DatabaseData).GetTableItemIfExists(TableName,TableItem)) then
   WriteToErrorLog(Caption+'cannot get table item for table '+TableName);
  if (UpperCase(TableItem.TableName) <> UpperCase(TableName)) then
   WriteToErrorLog(Caption+'invalid table item for table '+TableName);

  lm := TACRTableLocksManager.Create(TACRDiskDatabaseData(
      TACRLocalSession(db.Handle).DatabaseData));
  lm.InMemory := InMemory;
  try
    RecordID.PageNo := 25;
    RecordID.PageItemNo := 3;

    if (not lm.TryToLockTable(TableItem,TableName,0,ltX,nil)) then
     WriteToErrorLog(Caption+'#0 table is not locked in X');

//    if (lm.IsRecordLocked(TableName,0,RecordID)) then
//     WriteToErrorLog(Caption+'#1 record is locked');

    if (not lm.LockRecord(TableName,0,RecordID)) then
     WriteToErrorLog(Caption+'#1 record can not be locked');

//    if (not lm.IsRecordLocked(TableName,0,RecordID)) then
//     WriteToErrorLog(Caption+'#1 record is not locked');

    if (not lm.UnlockRecord(TableName,0,RecordID)) then
     WriteToErrorLog(Caption+'#1 record can not be unlocked');

    if (lm.TryToLockTable(TableItem,TableName,1,ltIS,nil)) then
     WriteToErrorLog(Caption+'#2 table can be locked by other session');

    if (not lm.UnlockTable(TableName,0,ltX,nil)) then
     WriteToErrorLog(Caption+'#0 table is not unlocked in X');

    if (not lm.TryToLockTable(TableItem,TableName,0,ltIS,nil)) then
     WriteToErrorLog(Caption+'#3 table cannot be locked in IS');

    if (not lm.TryToLockTable(TableItem,TableName,0,ltS,nil)) then
     WriteToErrorLog(Caption+'#3 table cannot be locked in S');

    if (not lm.TryToLockTable(TableItem,TableName,0,ltS,nil)) then
     WriteToErrorLog(Caption+'#4 table cannot be locked in S');

    if (not lm.UnlockTable(TableName,0,ltS,nil)) then
     WriteToErrorLog(Caption+'#5 table cannot be unlocked in S');

    if (not lm.UnlockTable(TableName,0,ltS,nil)) then
     WriteToErrorLog(Caption+'#6 table cannot be unlocked in S');

    if (not lm.UnlockTable(TableName,0,ltIS,nil)) then
     WriteToErrorLog(Caption+'#3 table cannot be unlocked in IS');

    WriteToProcessLog(Caption+'run test finished');
  finally
    lm.Free;
    table.Free;
    db.Close;
    db.DeleteDatabase;
    if (db.Exists) then
     WriteToErrorLog(Caption+'cannot delete database #2');
    db.Free;
  end;
end; // RunTest

procedure TUnitTestLockManager.Test1;
begin
  WriteToProcessLog('UnitTestLockManager - test short started');

  RunTest(True);
  RunTest(False);

  WriteToProcessLog('UnitTestLockManager - test short finished');
end;

procedure TUnitTestLockManager.TestShort;
begin
  CheckAction(Test1, 'LockManager Test');
end;


initialization
  UnitTestLockManager := TUnitTestLockManager.Create(UnitTestList);

finalization
  UnitTestLockManager.Free;


end.
