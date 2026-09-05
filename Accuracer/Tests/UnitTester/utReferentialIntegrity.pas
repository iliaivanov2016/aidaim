unit utReferentialIntegrity;

interface

{$I UTConfig.Inc}

uses SysUtils, Classes, DB,
     uTestList,
     Variants,
     ACRTypes,
{$IFDEF ACR5H}
     ACRComMain,
{$ENDIF}
     ACRConst,
     ACRCriticalSection,
     ACRMain
     ;

type
  TUnitTestReferentialIntegrity = class(TUnitTest)
   private
    Table1:    TACRTable;
    Table2:    TACRTable;
    Table3:    TACRTable;
    Table4:    TACRTable;
    DB:  TACRDatabase;
    Query:     TACRQuery;
   public
    procedure TestShort; override;
    procedure TestExceptions; override;
   protected
    procedure TestWithoutExceptions(InMemory: Boolean);
    procedure TestWithExceptions(InMemory: Boolean);
    procedure TestWithout;
    procedure TestWith;
    procedure Init(InMemory: Boolean);
    procedure CreateTables;
    procedure InsertData;
    procedure DeleteRecords(capt: String);
    procedure TestForeignKeyActions(capt: String);
    procedure TestRestructure(capt: String; UseSQL: Boolean);
    procedure TestRepairTable(capt: String; LowLevel: Boolean);
    procedure TestForeignKeys(capt: String);
    procedure TestDeleteForeignKey(InMemory, UseSQL: Boolean);
  end;


var
  UnitTestReferentialIntegrity: TUnitTestReferentialIntegrity;



implementation


{ TUnitTestReferentialIntegrity }


procedure TUnitTestReferentialIntegrity.TestShort;
begin
  CheckAction(TestWithout, 'Referential Integrity Test without exceptions');
end;

procedure TUnitTestReferentialIntegrity.TestExceptions;
begin
  CheckAction(TestWith, 'Referential Integrity Test with exceptions');
end;


procedure TUnitTestReferentialIntegrity.TestWithoutExceptions(InMemory: Boolean);
var
  s,capt: String;
begin
 if (InMemory) then
  capt := 'RI test without exceptions in memory - '
 else
  capt := 'RI test without exceptions disk - ';

 WriteToProcessLog(capt+'starting main tests ...');
 Table1 := TACRTable.Create(nil);
 Table2 := TACRTable.Create(nil);
 Table3 := TACRTable.Create(nil);
 Table4 := TACRTable.Create(nil);
 Query := TACRQuery.Create(nil);
 DB := TACRDatabase.Create(nil);
 try
   Init(InMemory);
   CreateTables;
   WriteToProcessLog(capt+'tables created');

   InsertData;
   WriteToProcessLog(capt+'records inserted');

   TestForeignKeyActions(capt+'test #1 - ');
   WriteToProcessLog(capt+'foreign key actions tested');

   TestRestructure(capt,False);
   WriteToProcessLog(capt+'restructure wihtout SQL tested');

   DeleteRecords(capt);
   InsertData;
   WriteToProcessLog(capt+'records inserted');

   TestForeignKeyActions(capt+'test #2 - ');
   WriteToProcessLog(capt+'foreign key actions tested #2');

   TestRestructure(capt,True);
   WriteToProcessLog(capt+'restructure wiht SQL tested');

   DeleteRecords(capt);
   InsertData;
   WriteToProcessLog(capt+'records inserted');

   TestForeignKeyActions(capt+'test #3 - ');
   WriteToProcessLog(capt+'foreign key actions tested #3');

   DeleteRecords(capt);
   InsertData;
   WriteToProcessLog(capt+'records inserted');

   TestRepairTable(capt,False);

   TestForeignKeyActions(capt+'test #4 - ');
   WriteToProcessLog(capt+'foreign key actions tested #4');

   if (not InMemory) then
    begin
     DeleteRecords(capt);
     InsertData;
     WriteToProcessLog(capt+'records inserted');

     db.Close;
     s := '';
     if (not db.RepairDatabase(s,False)) then
      WriteToErrorLog(capt+'repair database failed');
     if (s <> '') then
      WriteToErrorLog(capt+'errors during repair database: '+s);
     db.Open;
     Table1.Open;
     Table2.Open;

     TestForeignKeyActions(capt+'test #5 - ');
     WriteToProcessLog(capt+'foreign key actions tested #5');
    end;

   Table1.Close;
   Table2.Close;
   Table3.Close;
   Table4.Close;
   Query.SQL.Text := 'DROP TABLE emp CASCADE; DROP TABLE dept;';
   Query.ExecSQL;
   Query.SQL.Text := 'DROP TABLE emp2 CASCADE; DROP TABLE dept2;';
   Query.ExecSQL;
   WriteToProcessLog(capt+'tables dropped');

 finally
   if (Table1.Exists) then
    Table1.DeleteTable(True);
   if (Table2.Exists) then
    Table2.DeleteTable(True);
   if (Table3.Exists) then
    Table3.DeleteTable(True);
   if (Table4.Exists) then
    Table4.DeleteTable(True);
   Table1.Free;
   Table2.Free;
   Table3.Free;
   Table4.Free;
   Query.Free;
   if (DB.Connected) then
    DB.Close;
   if (not InMemory) then
    DB.DeleteDatabase;
   DB.Free;
 end;
 WriteToProcessLog(capt+'OK.');
end;

procedure TUnitTestReferentialIntegrity.TestWithExceptions(InMemory: Boolean);
var
  capt,s: String;
begin
 if (InMemory) then
  capt := 'RI test with exceptions in memory - '
 else
  capt := 'RI test with exceptions disk - ';

 WriteToProcessLog(capt+'starting delete test ...');

 TestDeleteForeignKey(InMemory,True);
 TestDeleteForeignKey(InMemory,False);

 WriteToProcessLog(capt+'starting main tests ...');

 Table1 := TACRTable.Create(nil);
 Table2 := TACRTable.Create(nil);
 Table3 := TACRTable.Create(nil);
 Table4 := TACRTable.Create(nil);
 Query := TACRQuery.Create(nil);
 DB := TACRDatabase.Create(nil);
 try
   Init(InMemory);
   CreateTables;
   WriteToProcessLog(capt+'tables created');

   InsertData;
   WriteToProcessLog(capt+'records inserted');
   TestForeignKeys(capt);


   TestRestructure(capt,False);
   WriteToProcessLog(capt+'restructure wihtout SQL tested');

   DeleteRecords(capt);
   InsertData;
   WriteToProcessLog(capt+'records inserted');

   TestForeignKeys(capt+'test #2 - ');
   WriteToProcessLog(capt+'foreign key actions tested #2');

   TestRestructure(capt,True);
   WriteToProcessLog(capt+'restructure wiht SQL tested');

   DeleteRecords(capt);
   InsertData;
   WriteToProcessLog(capt+'records inserted');
   TestForeignKeys(capt+'test #3 - ');

   DeleteRecords(capt);
   InsertData;
   WriteToProcessLog(capt+'records inserted');

   TestRepairTable(capt,False);
   TestForeignKeys(capt+'test #4 - ');

   if (not InMemory) then
    begin
       DeleteRecords(capt);
       InsertData;
       WriteToProcessLog(capt+'records inserted');
       db.Close;
       s := '';
       if (not db.RepairDatabase(s,False)) then
        WriteToErrorLog(capt+'repair database failed');
       if (s <> '') then
        WriteToErrorLog(capt+'errors during repair database: '+s);
       db.Open;
       Table1.Open;
       Table2.Open;

       TestForeignKeys(capt+'test #5 - ');
    end;

   Table1.Close;
   Table2.Close;
   Table3.Close;
   Table4.Close;
   Query.SQL.Text := 'DROP TABLE emp CASCADE; DROP TABLE dept;';
   Query.ExecSQL;
   Query.SQL.Text := 'DROP TABLE emp2 CASCADE; DROP TABLE dept2;';
   Query.ExecSQL;
   WriteToProcessLog(capt+'tables dropped');

 finally
   if (Table1.Exists) then
    Table1.DeleteTable(True);
   if (Table2.Exists) then
    Table2.DeleteTable(True);
   if (Table3.Exists) then
    Table3.DeleteTable(True);
   if (Table4.Exists) then
    Table4.DeleteTable(True);
   Table1.Free;
   Table2.Free;
   Table3.Free;
   Table4.Free;
   Query.Free;
   if (DB.Connected) then
    DB.Close;
   if (not InMemory) then
    DB.DeleteDatabase;
   DB.Free;
 end;
 WriteToProcessLog(capt+'OK.');
end;


procedure TUnitTestReferentialIntegrity.TestWith;
begin
  TestWithExceptions(False);
  TestWithExceptions(True);
end;


procedure TUnitTestReferentialIntegrity.TestWithout;
begin
  TestWithoutExceptions(False);
  TestWithoutExceptions(True);
end;


procedure TUnitTestReferentialIntegrity.Init(InMemory: Boolean);
begin
   DB.Exclusive := True;
   if (InMemory) then
    begin
     Table1.InMemory := True;
     Table2.InMemory := True;
     Table3.InMemory := True;
     Table4.InMemory := True;
     Query.InMemory := True;
    end
   else
    begin
     Table1.InMemory := False;
     Table2.InMemory := False;
     Table3.InMemory := False;
     Table4.InMemory := False;
     Query.InMemory := False;
     DB.DatabaseName := 'RITest';
     DB.DatabaseFileName := Self.TempDir+'test_ri.adb';
     if (db.Exists) then
      db.DeleteDatabase;
     db.CreateDatabase;
     db.Open;
     Table1.DatabaseName := DB.DatabaseName;
     Table2.DatabaseName := DB.DatabaseName;
     Table3.DatabaseName := DB.DatabaseName;
     Table4.DatabaseName := DB.DatabaseName;
     Query.DatabaseName := DB.DatabaseName;
    end;
end;

procedure TUnitTestReferentialIntegrity.CreateTables;
begin
 Table1.Close;
 Table1.TableName := 'dept';
 Table1.FieldDefs.Clear;
 Table1.AdvFieldDefs.Clear;
 Table1.IndexDefs.Clear;
 Table1.AdvIndexDefs.Clear;
 Table1.ForeignKeyDefs.Clear;
 Table1.FieldDefs.Add('id',ftInteger);
 Table1.FieldDefs.Add('name',ftFixedChar,50);
 Table1.IndexDefs.Add('pk','id',[ixPrimary]);
 Table1.CreateTable;

 Table2.Close;
 Table2.TableName := 'emp';
 Table2.FieldDefs.Clear;
 Table2.AdvFieldDefs.Clear;
 Table2.IndexDefs.Clear;
 Table2.AdvIndexDefs.Clear;
 Table2.ForeignKeyDefs.Clear;
 Table2.FieldDefs.Add('id',ftInteger);
 Table2.FieldDefs.Add('FirstName',ftFixedChar,50);
 Table2.FieldDefs.Add('LastName',ftFixedChar,50);
 Table2.FieldDefs.Add('DeptID',ftInteger);
 Table2.IndexDefs.Add('pk','id',[ixPrimary]);
 Table2.ForeignKeyDefs.Add('FKDept','DeptID','dept',fkmtDefault,fkaSetNull,fkaCascade);
 Table2.CreateTable;


 Table3.Close;
 Table3.TableName := 'dept2';
 Table3.FieldDefs.Clear;
 Table3.AdvFieldDefs.Clear;
 Table3.IndexDefs.Clear;
 Table3.AdvIndexDefs.Clear;
 Table3.ForeignKeyDefs.Clear;
 Table3.FieldDefs.Add('id',ftInteger);
 Table3.FieldDefs.Add('name',ftFixedChar,50);
 Table3.IndexDefs.Add('pk','id',[ixPrimary]);
 Table3.CreateTable;

 Table4.Close;
 Table4.TableName := 'emp2';
 Table4.FieldDefs.Clear;
 Table4.AdvFieldDefs.Clear;
 Table4.IndexDefs.Clear;
 Table4.AdvIndexDefs.Clear;
 Table4.ForeignKeyDefs.Clear;
 Table4.FieldDefs.Add('id',ftInteger);
 Table4.FieldDefs.Add('FirstName',ftFixedChar,50);
 Table4.FieldDefs.Add('LastName',ftFixedChar,50);
 Table4.FieldDefs.Add('DeptID',ftInteger);
 Table4.IndexDefs.Add('pk','id',[ixPrimary]);
 Table4.ForeignKeyDefs.Add('FKDept2','DeptID','dept2',fkmtDefault,fkaDefault,fkaDefault);
 Table4.CreateTable;
end;

procedure TUnitTestReferentialIntegrity.InsertData;
begin
  Table1.Open;
  Table2.Open;
  Table3.Open;
  Table4.Open;

  Table1.AppendRecord([1,'Development']);
  Table1.AppendRecord([2,'Sales']);

  Table2.AppendRecord([1,'Leo','Martin',1]);
  Table2.AppendRecord([2,'Ray','Lahoy',1]);
  Table2.AppendRecord([3,'Ella','Perelman',2]);

  if (Table3.RecordCount = 0) then
   begin
    Table3.AppendRecord([1,'Development']);
    Table3.AppendRecord([2,'Sales']);

    Table4.AppendRecord([1,'Leo','Martin',1]);
    Table4.AppendRecord([2,'Ray','Lahoy',1]);
    Table4.AppendRecord([3,'Ella','Perelman',2]);
   end;
end;

procedure TUnitTestReferentialIntegrity.TestForeignKeyActions(capt: String);
var
    s: String;
begin
   Table1.Open;
   Table3.Open;
   Table2.IndexFieldNames := 'id';
   Table2.Open;

   Table4.Open;
   Table3.Open;
   Table3.Locate('id',1,[]);
   if (Table3.FieldByName('ID').AsInteger <> 1) then
    WriteToErrorLog(capt+'error, table dept2: record with id=1 not found');
   // check edit
   Table3.Edit;
   s := Table1.FieldByName('Name').AsString + ' Department';
   Table3.FieldByName('Name').AsString := s;
   Table3.Post;
   if (Table3.FieldByName('Name').AsString <> s) then
    WriteToErrorLog(capt+'error, table dept2: record with id=1 failed to edit name field');
   Table3.Close;
   Table4.Close;

   table2.Close;
   Table1.Locate('id',2,[]);
   Table1.Edit;
   Table1.Fields[0].AsInteger := 5;
   Table1.Post;
   Table1.Close;
   Table2.Open;
   Table2.Locate('id',3,[]);
   if (Table2.FieldByName('DeptID').AsInteger <> 5) then
    WriteToErrorLog(capt+'error: update rule failed');


   Table1.Open;
   Table1.Locate('id',1,[]);
   if (Table1.FieldByName('ID').AsInteger <> 1) then
    WriteToErrorLog(capt+'error: record with id=1 not found');
   Table1.Delete;

   if (Table2.Locate('DeptID',1,[])) then
    WriteToErrorLog(capt+'error: delete rule failed');
   if (Table2.RecordCount <> 3) then
    WriteToErrorLog(capt+'error: delete rule failed - invalid record count');
   Table2.First;
   if (not Table2.FieldByName('DeptID').IsNull) then
     WriteToErrorLog(capt+'error: delete rule failed - first record not null DeptID');
   Table2.Next;
   if (not Table2.FieldByName('DeptID').IsNull) then
     WriteToErrorLog(capt+'error: delete rule failed - second record not null DeptID');
   Table2.Next;
   if (Table2.FieldByName('DeptID').IsNull) then
     WriteToErrorLog(capt+'error: update rule failed - third record  null DeptID');
   if (Table2.FieldByName('DeptID').AsInteger <> 5) then
     WriteToErrorLog(capt+'error: update rule failed - third record  DeptID <> 5');


   Table1.Close;
   Table2.Close;
end;

procedure TUnitTestReferentialIntegrity.TestRestructure(capt: String;
  UseSQL: Boolean);
var s: String;
begin
  Table1.Close;
  Table2.Close;
  if (not UseSQL) then
   begin
    capt := capt + 'restructure without SQL - ';
    Table2.Open;
    Table2.Close;
    if (Table2.ForeignKeyDefs.Count <> 1) then
     WriteToErrorLog(capt+'error: no foreign key in empt table');
    Table2.RestructureForeignKeyDefs.Clear;
    s := '';
    if (not Table2.RestructureTable(s)) then
     WriteToErrorLog(capt+'error: restructure #1 failed.');

    if (s <> '') then
     WriteToErrorLog(capt+'error: delete foreign key failed. Error log: '+s);
    Table2.Open;
    if (Table2.ForeignKeyDefs.Count <> 0) then
     WriteToErrorLog(capt+'error: delete foreign key failed.');
    if (Table2.RestructureForeignKeyDefs.Count <> 0) then
     WriteToErrorLog(capt+'error: delete foreign key failed #2.');
    Table2.Close;
    Table2.RestructureForeignKeyDefs.Add('FKDept','DeptID','dept',fkmtDefault,fkaSetNull,fkaCascade);
    s := '';
    if (not Table2.RestructureTable(s)) then
     WriteToErrorLog(capt+'error: restructure #2 failed.');
    if (s <> '') then
     WriteToErrorLog(capt+'error: add foreign key failed. Error log: '+s);
    Table2.Open;
    if (Table2.ForeignKeyDefs.Count <> 1) then
     WriteToErrorLog(capt+'error: add foreign key failed.');
    Table2.Close;

    Table1.Open;
    Table1.Close;
    s := '';
    if (not Table1.RestructureTable(s)) then
     WriteToErrorLog(capt+'error: restructure #1 failed.');
   end // no SQL
  else
   begin
    capt := capt + 'restructure with SQL - ';
    Query.SQL.Text := 'ALTER TABLE Emp DROP CONSTRAINT FKDept';
    Query.ExecSQL;
    Table2.Open;
    if (Table2.ForeignKeyDefs.Count <> 0) then
     WriteToErrorLog(capt+'error: delete foreign key failed.');
    if (Table2.RestructureForeignKeyDefs.Count <> 0) then
     WriteToErrorLog(capt+'error: delete foreign key failed #2.');
    Table2.Close;

    Query.SQL.Text := 'ALTER TABLE Emp ADD FOREIGN KEY FKDept (DeptID) REFERENCES Dept ON DELETE SET NULL ON UPDATE CASCADE';
    Query.ExecSQL;
    Table2.Open;
    if (Table2.ForeignKeyDefs.Count <> 1) then
     WriteToErrorLog(capt+'error: add foreign key failed.');
    Table2.Close;
   end; // SQL
end;

procedure TUnitTestReferentialIntegrity.TestRepairTable(capt: String;
  LowLevel: Boolean);
var s: String;
begin
  Table1.Close;
  Table2.Close;
  s := '';
  if (LowLevel) then
   WriteToProcessLog(capt+' repairing table (low level)....')
  else
   WriteToProcessLog(capt+' repairing table (high level)....');
  if (not Table1.RepairTable(s,LowLevel)) then
   WriteToErrorLog(capt+'repair failed, low level = '+BoolToStr(LowLevel,True));
  if (s <> '') then
   WriteToErrorLog(capt+'repair failed, low level = '+BoolToStr(LowLevel,True)+
    ', error log:'+#13#10+s);
  if (not Table2.RepairTable(s,LowLevel)) then
   WriteToErrorLog(capt+'repair failed #2, low level = '+BoolToStr(LowLevel,True));
  if (s <> '') then
   WriteToErrorLog(capt+'repair failed #2, low level = '+BoolToStr(LowLevel,True)+
    ', error log:'+#13#10+s);
  if (LowLevel) then
   WriteToProcessLog(capt+' repairing table (low level).... OK')
  else
   WriteToProcessLog(capt+' repairing table (high level).... OK');
end;

procedure TUnitTestReferentialIntegrity.DeleteRecords(capt: String);
begin
   WriteToProcessLog(capt+'deleting records...');
   Query.SQL.Text := 'delete from emp; delete from dept;';
   Query.ExecSQL;
   Query.SQL.Text := 'select * from emp';
   Query.Open;
   if (Query.RecordCount <> 0) then
    WriteToErrorLog(capt+'delete records failed');
   Query.Close;
   Query.SQL.Text := 'select * from dept';
   Query.Open;
   if (Query.RecordCount <> 0) then
    WriteToErrorLog(capt+'delete records failed #2');
   Query.Close;
   WriteToProcessLog(capt+'records deleted');
end;

procedure TUnitTestReferentialIntegrity.TestForeignKeys(capt: String);
begin
   Table1.Open;
   Table2.IndexFieldNames := 'id';
   Table2.Open;
   try
    Table2.Insert;
    Table2.FieldByName('id').AsInteger := 10;
    Table2.FieldByName('DeptID').AsInteger := -1;
    Table2.Post;
    WriteToErrorLog(capt+'foreign key does not work in insert');
   except
    Table2.Cancel;
    WriteToProcessLog(capt+'foreign key works in insert');
   end;

   Table2.First;
   try
    Table2.Edit;
    Table2.FieldByName('DeptID').AsInteger := -1;
    Table2.Post;
    WriteToErrorLog(capt+'foreign key does not work in update');
   except
    Table2.Cancel;
    WriteToProcessLog(capt+'foreign key works in update');
   end;
end;


procedure TUnitTestReferentialIntegrity.TestDeleteForeignKey(InMemory, UseSQL: Boolean);
var capt: String;
    s:    String;
    t1:   TACRTable;
    t2:   TACRTable;
    t3:   TACRTable;
    q:    TACRQuery;
    db:   TACRDatabase;
begin
  capt := 'TestDeleteForeignKey ';
  if (InMemory) then
   capt := capt + 'MEMORY'
  else
   capt := capt + 'DISK';
  if (UseSQL) then
   capt := capt + ' SQL - '
  else
   capt := capt + ' TABLE - ';
  db := TACRDatabase.Create(nil);
  t1 := TACRTable.Create(nil);
  t2 := TACRTable.Create(nil);
  q := TACRQuery.Create(nil);
  try
    db.InMemory := InMemory;
    db.DatabaseFileName := TempDir+'fk_add_delete.adb';
    db.DatabaseName := 'FK_db';
    db.CreateDatabase;
    db.Open;
    t1.InMemory := db.InMemory;
    t2.InMemory := db.InMemory;
    q.InMemory := db.InMemory;
    t1.DatabaseName := db.DatabaseName;
    t2.DatabaseName := db.DatabaseName;
    q.DatabaseName := db.DatabaseName;
    if (UseSQL) then
     begin
      q.SQL.Text :=         'CREATE TABLE t1 (id Integer, name char(10), PRIMARY KEY (id));'
                    +#13#10+'CREATE TABLE t2 (id AutoInc, t1_id integer, name char(10), PRIMARY KEY(id));'
                    +#13#10+'CREATE TABLE t3 (id Integer, t1_id integer, name char(10), PRIMARY KEY(id));'
                    +#13#10+'CREATE INDEX idx1 ON t2 (t1_id);'
                    +#13#10+'CREATE INDEX idx1 ON t3 (t1_id);'
                    +#13#10+'INSERT INTO t1 VALUES (1,"aaa");'
                    +#13#10+'INSERT INTO t1 VALUES (2,"bbb");'
                    +#13#10+'INSERT INTO t1 VALUES (3,"ccc");'
                    +#13#10+'INSERT INTO t2(t1_id,name) VALUES (1,"a1");'
                    +#13#10+'INSERT INTO t2(t1_id,name) VALUES (2,"b2");'
                    +#13#10+'INSERT INTO t2(t1_id,name) VALUES (3,"c3");'
                    +#13#10+'INSERT INTO t3 VALUES (1,NULL,"aaa");'
                    +#13#10+'INSERT INTO t3 VALUES (2,NULL,"bbb");'
                    +#13#10+'INSERT INTO t3 VALUES (3,NULL,"ccc");'
                    ;
      q.ExecSQL;
      q.SQL.Text := 'ALTER TABLE t2 ADD FOREIGN KEY FK1(t1_id) REFERENCES t1 ON DELETE CASCADE ON UPDATE CASCADE;';
      q.ExecSQL;
      try
        q.SQL.Text := 'INSERT INTO t2(t1_id,name) VALUES (4,"d4");';
        q.ExecSQL;
        WriteToErrorLog(capt+'no exception - foreign key NOT created');
      except
        WriteToProcessLog(capt+'exception OK - foreign key created');
      end;
      q.SQL.Text := 'ALTER TABLE t2 DROP CONSTRAINT FK1;';
      q.ExecSQL;
      try
        q.SQL.Text := 'INSERT INTO t2(t1_id,name) VALUES (4,"c4");';
        q.ExecSQL;
        if (q.RowsAffected <> 1) then
          WriteToErrorLog(capt+'no exception - foreign key deleted, but record not inserted')
        else
          WriteToProcessLog(capt+'no exception - foreign key deleted');
      except
        WriteToErrorLog(capt+'exception - foreign key NOT deleted');
      end;
      // self reference
      q.SQL.Text := 'ALTER TABLE t3 ADD FOREIGN KEY FK1(t1_id) REFERENCES t3;';
      q.ExecSQL;
      try
        q.SQL.Text := 'INSERT INTO t3 VALUES (4,1,"exists");';
        q.ExecSQL;
        if (q.RowsAffected <> 1) then
          WriteToErrorLog(capt+'no exception - self reference foreign key: Error #1')
        else
          WriteToProcessLog(capt+'no exception - self reference foreign key: OK #1');
      except
        WriteToErrorLog(capt+'exception - self reference foreign key: Error #2')
      end;
      try
        q.SQL.Text := 'INSERT INTO t3 VALUES (5,10,"not exists");';
        q.ExecSQL;
        WriteToErrorLog(capt+'no exception - self reference foreign key: Error #3')
      except
        WriteToProcessLog(capt+'exception - self reference foreign key: OK #2');
      end;
      // drop foreign key
      q.SQL.Text := 'ALTER TABLE t3 DROP CONSTRAINT FK1;';
      q.ExecSQL;
      try
        q.SQL.Text := 'INSERT INTO t3 VALUES (5,10,"not exists");';
        q.ExecSQL;
        WriteToProcessLog(capt+'exception - self reference foreign key: OK #3');
      except
        WriteToErrorLog(capt+'no exception - self reference foreign key: Error #4')
      end;
     end // SQL
    else
     begin
       t1.TableName := 't1';
       t1.FieldDefs.Add('id',ftInteger);
       t1.FieldDefs.Add('name',ftFixedChar,20);
       t1.IndexDefs.Add('PK','id',[ixPrimary]);
       t1.CreateTable;
       t1.Open;
       t1.InsertRecord([1,'aaa']);
       t1.InsertRecord([2,'bbb']);
       t1.InsertRecord([3,'ccc']);
       t2.TableName := 't2';
       t2.FieldDefs.Add('id',ftAutoInc);
       t2.FieldDefs.Add('t1_id',ftInteger);
       t2.FieldDefs.Add('name',ftFixedChar,20);
       t2.IndexDefs.Add('PK','id',[ixPrimary]);
       t2.IndexDefs.Add('idx1','t1_id',[]);
       t2.ForeignKeyDefs.Add('FK1','t1_id','t1',fkmtDefault,fkaCascade,fkaCascade);
       t2.CreateTable;
       t2.Open;
       {$IFDEF ACR5H}
       t2.InsertRecord([Null,1,'a1']);
       t2.InsertRecord([Null,2,'b2']);
       t2.InsertRecord([Null,3,'c3']);
       {$ELSE}
       t2.Insert; t2.FieldValues['t1_id'] := 1; t2.FieldValues['name'] := 'a1'; t2.Post;
       t2.Insert; t2.FieldValues['t1_id'] := 2; t2.FieldValues['name'] := 'b2'; t2.Post;
       t2.Insert; t2.FieldValues['t1_id'] := 3; t2.FieldValues['name'] := 'c3'; t2.Post;
       {$ENDIF}
       try
       {$IFDEF ACR5H}
         t2.InsertRecord([Null,4,'d4']);
       {$ELSE}
         t2.Insert; t2.FieldValues['t1_id'] := 4; t2.FieldValues['name'] := 'd4'; t2.Post;
       {$ENDIF}
         WriteToErrorLog(capt+'no exception - foreign key NOT created');
       except
        WriteToProcessLog(capt+'exception OK - foreign key created');
       end;
       t2.Close;
       t2.DeleteConstraint('FK1');
       t2.Open;
       try
       {$IFDEF ACR5H}
         t2.InsertRecord([Null,4,'d4']);
       {$ELSE}
         t2.Insert; t2.FieldValues['t1_id'] := 4; t2.FieldValues['name'] := 'd4'; t2.Post;
       {$ENDIF}
        WriteToProcessLog(capt+'no exception - foreign key deleted');
        t2.Delete;
       except
        WriteToErrorLog(capt+'exception - foreign key NOT deleted');
       end;
       // restructure using RestructureTable
       t1.Close;
       t2.Close;
       t2.RestructureForeignKeyDefs.Add('FK_Restructure','t1_id','t1');
       s := '';
       if (not t2.RestructureTable(s)) then
        WriteToErrorLog(capt+'Restructure failed: '+#13#10+s);
       if (s <> '') then
        WriteToErrorLog(capt+'Restructure failed: '+#13#10+s);
       t2.Open;
       try
       {$IFDEF ACR5H}
         t2.InsertRecord([Null,4,'d4']);
       {$ELSE}
         t2.Insert; t2.FieldValues['t1_id'] := 4; t2.FieldValues['name'] := 'd4'; t2.Post;
       {$ENDIF}
         WriteToErrorLog(capt+'no exception - foreign key NOT created #2');
       except
        WriteToProcessLog(capt+'exception OK - foreign key created #2');
       end;
       t2.Close;
       t2.RestructureForeignKeyDefs.DeleteForeignKeyDef('FK_Restructure');
       s := '';
       if (not t2.RestructureTable(s)) then
        WriteToErrorLog(capt+'Restructure failed #1: '+#13#10+s);
       if (s <> '') then
        WriteToErrorLog(capt+'Restructure failed #1: '+#13#10+s);
       t2.Open;
       try
       {$IFDEF ACR5H}
         t2.InsertRecord([Null,4,'d4']);
       {$ELSE}
         t2.Insert; t2.FieldValues['t1_id'] := 4; t2.FieldValues['name'] := 'd4'; t2.Post;
       {$ENDIF}
        WriteToProcessLog(capt+'no exception - foreign key deleted #3');
        t2.Delete;
       except
        WriteToErrorLog(capt+'exception - foreign key NOT deleted #3');
       end;
       t2.Close;
     end; // no SQL
  finally
    q.Free;
    t1.Free;
    t2.Free;
    db.Close;
    db.DeleteDatabase;
    if (db.Exists) then
     WriteToErrorLog(capt+'db exists');
    db.Free;
  end;
end; // TestDeleteForeignKey


initialization
  UnitTestReferentialIntegrity := TUnitTestReferentialIntegrity.Create(UnitTestList);

finalization
  UnitTestReferentialIntegrity.Free;

end.
