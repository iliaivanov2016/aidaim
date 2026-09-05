unit utTransactions;

interface

{$I UTConfig.inc}
{$I ACRVer.inc}

uses Controls, SysUtils, db,
     uTestList, ACRMain,
{$IFDEF ACR5H}
     ACRComMain,
{$ENDIF}
    ACRConverts, ACRDiskEngine, ACRTypes, ACRConst, ACRLocalEngine;

type
  TUnitTestTransactions = class(TUnitTest)
   private
    procedure RunSQLTest(Caption: string);
    procedure RunDiskTest(Caption: String);
    procedure RunDiskTestMultiUser(Caption: String);
    procedure RunDiskTestMultiUserExceptions(Caption: String);
    procedure Test1;
    procedure Test2;
   public
    procedure TestShort; override;
    procedure TestExceptions; override;
  end;

var
  UnitTestTransactions: TUnitTestTransactions;


implementation


{ TUnitTestTransactions }

procedure TUnitTestTransactions.RunSQLTest(Caption: string);
var
  db:         TACRDatabase;
  table:      TACRTable;
  query:      TACRQuery;
  i,n:        Integer;
begin
  WriteToProcessLog(Caption+'starting test...');
  db := TACRDatabase.Create(nil);
  query := TACRQuery.Create(nil);
  table := TACRTable.Create(nil);
  try
    db.DatabaseFileName := TempDir+'test.adb';
    db.DatabaseName := 'test_fk_pk_tr';
    db.DeleteDatabase;
    if (db.Exists) then
     WriteToErrorLog(Caption+'cannot delete database #1');
    db.CreateDatabase;
    db.Open;
    query.DatabaseName := db.DatabaseName;
    table.DatabaseName := db.DatabaseName;
    table.TableName := 'customer';
    table.FieldDefs.Clear;
    table.FieldDefs.Add('customerNo', ftAutoInc, 0, False);
    table.FieldDefs.Add('customerID', ftString, 50, False);
    table.FieldDefs.Add('Title', ftInteger, 0, False);
    table.FieldDefs.Add('lastName', ftString, 100, False);
    table.FieldDefs.Add('firstName', ftString, 100, False);
    table.IndexDefs.Clear;
    table.IndexDefs.Add('PrimaryKey', 'customerID', [ixPrimary]);
    table.CreateTable;

    table.TableName := 'customer_email';
    table.AdvIndexDefs.Clear;
    table.AdvFieldDefs.Clear;

    table.FieldDefs.Clear;
    table.FieldDefs.Add('emailNo', ftAutoInc, 0, False);
    table.FieldDefs.Add('customerID', ftString, 50, False);
    table.FieldDefs.Add('email', ftString, 256, False);

    table.IndexDefs.Clear;
    table.IndexDefs.Add('PrimaryKey', 'emailNo', [ixPrimary]);
    table.IndexDefs.Add('ByEmailCase', 'email', [ixCaseInsensitive]);

    table.ForeignKeyDefs.Clear;
    table.ForeignKeyDefs.Add('FK_CustomerID','customerID', 'customer',
                              fkmtFull, fkaCascade, fkaCascade);
    table.CreateTable;

    table.TableName := 'customer';
    table.Open;

    n := 0;
    db.StartTransaction;
    try
      query.SQL.Clear;
      query.SQL.Add('INSERT INTO customer (' +
                         'customerID,' +
                         'lastName,' +
                         'firstName)' + #13 +
                       'VALUES (71381,"test","test")'
                       );

      query.ExecSQL;
      n := n + query.RowsAffected;

      for i := 0 to 2 do
      begin
        query.SQL.Text := 'INSERT INTO customer_email (' +
                               'customerID,' +
                               'EMail)' + #13 +
                             'VALUES (71381,"test@test'+IntToStr(i)+ '.com")';
        query.ExecSQL;
        n := n + query.RowsAffected;
      end;
    db.Commit;
   except
    on e: Exception do
     begin
      WriteToErrorLog(Caption+' transaction error:'+#13#10+e.Message);
      db.Rollback;
     end;
   end;
   
   if (n <> 4) then
    WriteToErrorLog(Caption+' error: overall recordCount = '+IntToStr(n));

   if (table.RecordCount <> 1) then
    WriteToErrorLog(Caption+' error: customer recordCount = '+IntToStr(table.RecordCount));

   table.Close;
   table.TableName:='customer_email';
   table.Open;
   if (table.RecordCount <> 3) then
    WriteToErrorLog(Caption+' error: customer_email recordCount = '+IntToStr(table.RecordCount));
   table.Close;
  finally
   query.free;
   table.free;
   db.free;
   WriteToProcessLog(Caption+'starting test...OK');
  end;
end;


procedure TUnitTestTransactions.RunDiskTest(Caption: String);
var
  db:         TACRDatabase;
  table:      TACRTable;
  query:      TACRQuery;
  TableName:  String;
  RecordID:   TACRRecordID;
begin
  WriteToProcessLog(Caption+'starting test...');
  db := TACRDatabase.Create(nil);
  db.DatabaseFileName := TempDir+'test.adb';
  db.DatabaseName := 'test';
  db.DeleteDatabase;
  if (db.Exists) then
   WriteToErrorLog(Caption+'cannot delete database #1');
  db.CreateDatabase;
  db.Open;
  TableName := 'test_table1';
  table := TACRTable.Create(nil);
  table.DatabaseName := db.DatabaseName;
  table.TableName := TableName;
  table.FieldDefs.Clear;
  table.FieldDefs.Add('id',ftAutoInc);
  table.FieldDefs.Add('name',ftString,50);
  table.IndexDefs.Clear;
  table.IndexDefs.Add('idx_name','name',[]);
  table.CreateTable;
  table.Open;
  query := TACRQuery.Create(nil);
  query.DatabaseName := db.DatabaseName;
  try
    if (db.InTransaction) then
     WriteToErrorLog(Caption + 'db.InTransaction #1');

    db.StartTransaction;
    table.Insert;
    table.Post;

    if (not db.InTransaction) then
     WriteToErrorLog(Caption + 'not db.InTransaction #1');

    db.Commit;
    if (table.RecordCount <> 1) then
     WriteToErrorLog(Caption + 'commit failed #1');

    if (db.InTransaction) then
     WriteToErrorLog(Caption + 'db.InTransaction #2');

    db.StartTransaction;
    table.Insert;
    table.Post;

    if (not db.InTransaction) then
     WriteToErrorLog(Caption + 'not db.InTransaction #2');

    db.Rollback;

    if (db.InTransaction) then
     WriteToErrorLog(Caption + 'db.InTransaction #3');

    if (table.RecordCount <> 1) then
     WriteToErrorLog(Caption + 'rollback failed #1');

{$IFDEF ACR5H}
    // Rollback in v.5 does not restore cursor position
    table.First;
{$ENDIF}
    db.StartTransaction;
    table.Edit;
    table.FieldByName('name').AsString := 'aaa';
    table.Post;
    db.Commit;
    if (table.FieldByName('name').AsString <> 'aaa') then
     WriteToErrorLog(Caption + 'commit failed #2');

    db.StartTransaction;
    table.Delete;
    db.Commit;
    if (table.RecordCount <> 0) then
     WriteToErrorLog(Caption + 'commit failed #3');

    table.Close;
    table.EmptyTable;
    if (table.RecordCount <> 0) then
     WriteToErrorLog(Caption + 'empty table');

    query.SQL.Clear;
    query.SQL.Add('START TRANSACTION;');
    query.SQL.Add('insert into '+TableName+' (name) values ("InsertSQLTest");');
    query.SQL.Add('ROLLBACK;');
    query.ExecSQL;

    table.Open;
    if (table.RecordCount <> 0) then
     WriteToErrorLog(Caption + 'sql insert with rollback failed');
    table.Close;

    query.SQL.Clear;
    query.SQL.Add('START TRANSACTION;');
    query.SQL.Add('insert into '+TableName+' (name) values ("InsertSQLTest");');
    query.SQL.Add('COMMIT NOFLUSH;');
    query.ExecSQL;

    table.Open;
    if (table.RecordCount <> 1) then
     WriteToErrorLog(Caption + 'sql insert with commit failed');
    table.Close;

    query.SQL.Clear;
    query.SQL.Add('START TRANSACTION;');
    query.SQL.Add('delete from '+TableName+';');
    query.SQL.Add('ROLLBACK;');
    query.ExecSQL;

    table.Open;
    if (table.RecordCount <> 1) then
     WriteToErrorLog(Caption + 'sql delete with rollback failed');
    table.Close;

    query.SQL.Clear;
    query.SQL.Add('START TRANSACTION;');
    query.SQL.Add('delete from '+TableName+';');
    query.SQL.Add('COMMIT;');
    query.ExecSQL;

    table.Open;
    if (table.RecordCount <> 0) then
     WriteToErrorLog(Caption + 'sql delete with commit failed');
    table.Close;


    query.RequestLive := True;
    query.SQL.Text := 'SELECT * FROM '+TableName+' ORDER BY NAME';
    query.Open;

    db.StartTransaction;
    table.Open;
    table.Insert;
    table.FieldByName('name').AsString := 'aaa';
    table.Post;
    db.Commit;
    if (table.FieldByName('name').AsString <> 'aaa') then
     WriteToErrorLog(Caption + 'commit failed #3');

    query.Refresh;
    if (query.RecordCount <> 1) then
     WriteToErrorLog(Caption + 'invalid live query record count');

    db.StartTransaction;
    query.SQL.Text := 'DELETE FROM '+TableName;
    query.ExecSQL;
    if (query.RowsAffected <> 1) then
     WriteToErrorLog(Caption + 'invalid WowsAffected after delete');
    db.Commit(True);

    db.StartTransaction;
    query.RequestLive := True;
    query.SQL.Text := 'SELECT * FROM '+TableName+' WHERE ID = 0';
    query.Open;
    if (query.ReadOnly) then
     WriteToErrorLog(Caption + 'RequestLive fails');
    query.Insert;
    query.FieldByName('name').AsString := TableName+'_!!!';
    query.Post;
    db.Commit;

    table.Open;
    if (table.RecordCount <> 1) then
     WriteToErrorLog(Caption + 'Insert fails - invalid record count #1');
    table.Close;

    query.SQL.Text := 'SELECT * FROM '+TableName+' WHERE name = "'+TableName+'_!!!'+'"';
    query.Open;
    if (query.ReadOnly) then
     WriteToErrorLog(Caption + 'RequestLive fails #2');
    if (query.RecordCount <> 1) then
     WriteToErrorLog(Caption + 'Insert fails - invalid record count #2');
    if (query.IsEmpty) then
     WriteToErrorLog(Caption + 'Insert fails - empty result set');


  finally
    table.Free;
    query.Free;
    db.Close;
    db.DeleteDatabase;
    if (db.Exists) then
     WriteToErrorLog(Caption+'cannot delete database #2');
    db.Free;
  end;
 WriteToProcessLog(Caption+'test complete');
end;

procedure TUnitTestTransactions.RunDiskTestMultiUser(Caption: String);
var
  db:     TACRDatabase;
  db2:    TACRDatabase;
  table:  TACRTable;
  table2: TACRTable;
  TableName:  String;
  RecordID:   TACRRecordID;
begin
  WriteToProcessLog(Caption+'starting test...');
  db := TACRDatabase.Create(nil);
  db2 := TACRDatabase.Create(nil);
  db.DatabaseFileName := TempDir+'test.adb';
  db.DatabaseName := 'test';
  db2.DatabaseName := 'test1';
  db2.DatabaseFileName := db.DatabaseFileName;
  db.DeleteDatabase;
  if (db.Exists) then
   WriteToErrorLog(Caption+'cannot delete database #1');
  db.CreateDatabase;
  db.Open;
  db2.Open;
  TableName := 'test_table1';
  table := TACRTable.Create(nil);
  table.DatabaseName := db.DatabaseName;
  table.TableName := TableName;
  table.FieldDefs.Clear;
  table.IndexDefs.Clear;
  table.FieldDefs.Add('id',ftAutoInc);
  table.FieldDefs.Add('name',ftString,50);
  table.CreateTable;
  table.Open;
  table2 := TACRTable.Create(nil);
  table2.DatabaseName := db2.DatabaseName;
  table2.TableName := TableName;
  table2.Open;
  try
    if (db.InTransaction) then
     WriteToErrorLog(Caption + 'db.InTransaction #1');

    table2.Insert;
    table2.FieldByName('name').AsString := table2.DatabaseName;
    table2.Post;


    db.StartTransaction;
    if (not db.InTransaction) then
     WriteToErrorLog(Caption + 'not db.InTransaction #1');

    table2.Refresh;

    table.Insert;
    table.FieldByName('name').AsString := table.DatabaseName;
    table.Post;

    table2.Refresh;

    if (table2.RecordCount <> 1) then
     WriteToErrorLog(Caption + 'commit failed #1');

    db.Commit;
    if (table.RecordCount <> 2) then
     WriteToErrorLog(Caption + 'commit failed #2');

    if (table2.RecordCount <> 2) then
     WriteToErrorLog(Caption + 'commit failed #3');

    if (db.InTransaction) then
     WriteToErrorLog(Caption + 'db.InTransaction #2');

    table.First;
    table2.First;
    table2.Next;

    table2.Edit;
    table2.FieldByName('name').AsString := 'aaa';

    db.StartTransaction;

    table.Edit;
    table.FieldByName('name').AsString := 'bbb';
    table.Post;

    db.Commit;

    table2.Post;

    table.Refresh;
    table2.Refresh;
    if (table2.FieldByName('name').AsString <> 'aaa') then
     WriteToErrorLog(Caption+'edit in table2 failed');
    if (table.FieldByName('name').AsString <> 'bbb') then
     WriteToErrorLog(Caption+'edit in table failed');

  finally
    table2.Free;
    db2.Free;
    table.Free;
    db.Close;
    db.DeleteDatabase;
    if (db.Exists) then
     WriteToErrorLog(Caption+'cannot delete database #2');
    db.Free;
  end;
 WriteToProcessLog(Caption+'test complete');
end;

procedure TUnitTestTransactions.RunDiskTestMultiUserExceptions(Caption: String);
var
  db:     TACRDatabase;
  db2:    TACRDatabase;
  table:  TACRTable;
  table2: TACRTable;
  query:  TACRQuery;
  query2: TACRQuery;
  TableName:  String;
  RecordID:   TACRRecordID;
begin
  WriteToProcessLog(Caption+'starting test...');
  db := TACRDatabase.Create(nil);
  db2 := TACRDatabase.Create(nil);
  db.DatabaseFileName := TempDir+'test.adb';
  db.DatabaseName := 'test';
  db2.DatabaseName := 'test1';
  db2.DatabaseFileName := db.DatabaseFileName;

db.LockParams.Delay := 10;
db.LockParams.RetryCount := 10;

  db.DeleteDatabase;
  if (db.Exists) then
   WriteToErrorLog(Caption+'cannot delete database #1');
  db.CreateDatabase;
  db.Open;
  db2.Open;
  TableName := 'test_table1';
  query := TACRQuery.Create(nil);
  query.DatabaseName := db.DatabaseName;
  table := TACRTable.Create(nil);
  table.DatabaseName := db.DatabaseName;
  table.TableName := TableName;
  table.FieldDefs.Clear;
  table.IndexDefs.Clear;
  table.FieldDefs.Add('id',ftAutoInc);
  table.FieldDefs.Add('name',ftString,50);
  table.CreateTable;
  table.Open;
  table2 := TACRTable.Create(nil);
  table2.DatabaseName := db2.DatabaseName;
  table2.TableName := TableName;
  table2.Open;
  query2 := TACRQuery.Create(nil);
  query2.DatabaseName := db2.DatabaseName;
  try
    if (db.InTransaction) then
     WriteToErrorLog(Caption + 'db.InTransaction #1');

    table2.Insert;
    table2.FieldByName('name').AsString := table2.DatabaseName;
    table2.Post;


    db.StartTransaction;
    if (not db.InTransaction) then
     WriteToErrorLog(Caption + 'not db.InTransaction #1');

    try
      db.StartTransaction;
      WriteToErrorLog(Caption + '2nd StartTransaction passed - error #1');
    except
      WriteToProcessLog(Caption + '2nd StartTransaction failed - ok #1');
    end;

    // to start transaction that modifies the table
    table.Insert;
    table.Post;


    try
      table2.Delete;
      WriteToErrorLog(Caption + 'delete passed - error #1');
    except
      WriteToProcessLog(Caption + 'delete failed - ok #1');
    end;

    try
      table2.Edit;
      WriteToErrorLog(Caption + 'edit passed - error #1');
    except
      WriteToProcessLog(Caption + 'edit failed - ok #1');
    end;

    try
      db.Commit;
      WriteToProcessLog(Caption + 'commit passed - ok');
    except
      WriteToErrorLog(Caption + 'commit failed - error');
    end;

    table2.Insert;
    table2.FieldByName('name').AsString := 'aaa';
    table2.Post;

    table2.First;
    table.First;
    table2.Edit;
    table2.FieldByName('name').AsString := '222';

    db.StartTransaction;

    try
     table.Edit;
     WriteToErrorLog(Caption + 'edit passed - error #2');
    except
     WriteToProcessLog(Caption + 'edit failed - ok #2');
    end;

    try
      table.Next;
      table.Edit;
      table.FieldByName('name').AsString := '111';
      table.Post;
      db.Commit;
      WriteToProcessLog(Caption + 'edit passed - ok #3');
    except
     WriteToErrorLog(Caption + 'edit failed - error #3');
    end;

    table2.Post;

    table.Refresh;
    if (not table.Locate('name','111',[])) then
       WriteToErrorLog(Caption + 'locate failed - error #4');
    if (not table.Locate('name','222',[])) then
       WriteToErrorLog(Caption + 'locate failed - error #5');

    db.StartTransaction;

    try
      query2.SQL.Text := 'DROP TABLE '+TableName;
      query2.ExecSQL;
      WriteToErrorLog(Caption + 'DROP passed - error #11')
    except
      WriteToProcessLog(Caption + 'DROP - ok #11');
    end;

    table.Insert;
    table.FieldByName('name').AsString := '111';
    table.Post;

    try
      table2.Insert;
      table2.Post;
      WriteToErrorLog(Caption + 'insert passed - error #6');
    except
     WriteToProcessLog(Caption + 'insert failed - ok #6');
    end;


    query2.SQL.Text := 'select * from '+TableName+' where name = ''111''';
    try

      query2.Open;
      if (query2.RecordCount <> 1) then
       WriteToErrorLog(Caption + 'SELECT failed - error #7.1')
      else
       WriteToProcessLog(Caption + 'SELECT - ok #7');
    except
      WriteToErrorLog(Caption + 'SELECT failed - error #7.2');
    end;

    try
      query.SQL.Text := 'delete from '+TableName+' where name = ''111''';
      query.ExecSQL;
      if (query.RowsAffected <> 2) then
       WriteToErrorLog(Caption + 'DELETE failed - error #8.1')
      else
       WriteToProcessLog(Caption + 'DELETE - ok #8');
    except
      WriteToErrorLog(Caption + 'DELETE failed - error #8.2');
    end;

    try
      query2.SQL.Text := 'UPDATE '+TableName+' set name = ''test''';
      query2.ExecSQL;
      WriteToErrorLog(Caption + 'UPDATE passed - error #9')
    except
      WriteToProcessLog(Caption + 'UPDATE - ok #9');
    end;

    try
      query2.SQL.Text := 'INSERT INTO '+TableName+' (name) values(''test'')';
      query2.ExecSQL;
      WriteToErrorLog(Caption + 'INSERT passed - error #10')
    except
      WriteToProcessLog(Caption + 'INSERT - ok #10');
    end;

    try
      query2.SQL.Text := 'CREATE TABLE '+TableName+'_new (id AUTOINC)';
      query2.ExecSQL;
      WriteToProcessLog(Caption + 'CREATE passed - ok #12')
    except
      WriteToErrorLog(Caption + 'CREATE failed - error #12');
    end;

    db.Commit;

  finally
    table2.Free;
    query2.Free;
    db2.Free;
    query.Free;
    table.Free;
    db.Close;
    db.DeleteDatabase;
    if (db.Exists) then
     WriteToErrorLog(Caption+'cannot delete database #2');
    db.Free;
  end;
 WriteToProcessLog(Caption+'test complete');
end;


procedure TUnitTestTransactions.Test1;
begin
  WriteToProcessLog('UnitTestTransactions - test short started');

{$IFDEF FILE_SERVER_VERSION}
  RunDiskTestMultiUser('UnitTestTransactions - multi user, ');
{$ENDIF}
  RunDiskTest('UnitTestTransactions - single user, ');

  RunSQLTest('UnitTestTransactions - SQL test');

  WriteToProcessLog('UnitTestTransactions - test short finished');
end;

procedure TUnitTestTransactions.Test2;
begin
  WriteToProcessLog('UnitTestTransactions - test exceptions started');

{$IFDEF FILE_SERVER_VERSION}
  RunDiskTestMultiUserExceptions('UnitTestTransactions - multi user, ');
{$ENDIF}

  WriteToProcessLog('UnitTestTransactions - test exceptions finished');
end;

procedure TUnitTestTransactions.TestShort;
begin
  CheckAction(Test1, 'Transactions TestShort');
end;

procedure TUnitTestTransactions.TestExceptions;
begin
  CheckAction(Test2, 'Transactions TestExceptions');
end;


initialization
  UnitTestTransactions := TUnitTestTransactions.Create(UnitTestList);

finalization
  UnitTestTransactions.Free;


end.
