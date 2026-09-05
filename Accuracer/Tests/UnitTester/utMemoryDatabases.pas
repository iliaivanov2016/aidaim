unit utMemoryDatabases;

interface

{$I UTConfig.Inc}

uses SysUtils, Classes, DB, uTestList,
     ACRMain,  ACRTypes, ACRConst,
{$IFDEF ACR5H}
     ACRComMain,
{$ENDIF}
     ACRLocalEngine, ACRBase, ACRBaseEngine
     ,ACRMemEngine
     ,ACRSQLProcessor,ACRExpressions,ACRVariant
     ,ACRRelationalAlgebra
     ,ACRMemory
     ;

type

  TUnitTestMemoryDatabases = class(TUnitTest)
   private
    procedure TestDatabases;
    procedure TestTables;
    procedure TestQueries;
   public
    procedure TestShort; override;
  end;

var
  UnitTestMemoryDatabases: TUnitTestMemoryDatabases;

implementation


{ TUnitTestMemoryDatabases }

procedure TUnitTestMemoryDatabases.TestDatabases;
var capt:   AnsiString;
    db1,db2: TACRDatabase;
begin
 capt := 'TUnitTestMemoryDatabases.TestDatabases - ';
 db1 := TACRDatabase.Create(nil);
 db2 := TACRDatabase.Create(nil);
 try
   db1.InMemory := True;
   db2.InMemory := True;

   WriteToProcessLog(capt+'starting...');
   db1.DatabaseName := ACRMemoryDatabaseName;
   if (not db1.Exists) then
    WriteToErrorLog(capt+'#1: db1 not exists');
   if (db2.Exists) then
    WriteToErrorLog(capt+'#2: db2 exists');
   db2.Connected := true;
   if (not db2.Exists) then
    WriteToErrorLog(capt+'#3: db2 not exists');
   if (db1.Connected) then
    WriteToErrorLog(capt+'#4: db1 connected');
   db2.Close;
   if (not db2.Exists) then
    WriteToErrorLog(capt+'#5: db2 not exists');
   db2.DeleteDatabase;
   if (db2.Exists) then
    WriteToErrorLog(capt+'#6: db2 exists');

   db1.DeleteDatabase;
   if (db1.Exists) then
    WriteToErrorLog(capt+'#7: db2 exists');
   db1.CreateDatabase;
   if (not db1.Exists) then
    WriteToErrorLog(capt+'#8: db2 not exists');

 finally
   db1.Free;
   db2.Free;
   WriteToProcessLog(capt+'finished.');
 end;
end;

procedure TUnitTestMemoryDatabases.TestTables;
var db1,db2: TACRDatabase;
    t1,t2:   TACRTable;
    capt:    AnsiString;
    sl:      TStringList;
begin
 capt := 'TUnitTestMemoryDatabases.TestTables - ';
 db1 := TACRDatabase.Create(nil);
 db2 := TACRDatabase.Create(nil);
 t1 := TACRTable.Create(nil);
 t2 := TACRTable.Create(nil);
 try
   t1.InMemory := True;
   t2.InMemory := True;
   db1.InMemory := True;
   db2.InMemory := True;
   db1.DatabaseName := ACRMemoryDatabaseName;
   db2.DatabaseName := 'MemoryDB2';
   db1.Open;
   db2.CreateDatabase;
   db2.Open;
   WriteToProcessLog(capt+'starting...');

   // insert into t1
   t1.FieldDefs.Clear;
   t1.AdvFieldDefs.Clear;
   t1.IndexDefs.Clear;
   t1.AdvIndexDefs.Clear;
   t1.ForeignKeyDefs.Clear;
   t1.DatabaseName := db1.DatabaseName;
   if (not t1.InMemory) then
    WriteToErrorLog(capt+'error #1  - InMemory = false');
   t1.TableName := 'MT1';
   t1.FieldDefs.Add('id',ftAutoInc);
   t1.FieldDefs.Add('name',ftFixedChar,20);
   t1.IndexDefs.Add('pk','id',[ixPrimary]);
   t1.IndexDefs.Add('idx_name','name',[ixCaseInsensitive]);
   t1.Open;
   t1.Insert;
   t1.FieldByName('name').AsString := 'test1';
   t1.Post;
   t1.Insert;
   t1.FieldByName('name').AsString := 'test2';
   t1.Post;

   // insert into t2
   t2.FieldDefs.Clear;
   t2.AdvFieldDefs.Clear;
   t2.IndexDefs.Clear;
   t2.AdvIndexDefs.Clear;
   t2.ForeignKeyDefs.Clear;
   t2.DatabaseName := db2.DatabaseName;
   t2.TableName := t1.TableName;
   if (not t2.InMemory) then
    WriteToErrorLog(capt+'error #2 - InMemory = false');
   t2.ImportTable(t1);
   t2.Open;
   if (t2.TableName <> t1.TableName) then
    WriteToErrorLog(capt+'error #3');
   if (t2.RecordCount <> t1.RecordCount) then
    WriteToErrorLog(capt+'error #4');
   t2.Delete;
   if (t2.RecordCount <> (t1.RecordCount-1)) then
    WriteToErrorLog(capt+'error #5');
   t2.Close;

   sl := TStringList.Create;
   try
     db1.GetTablesList(sl);
     if (sl.Count <> 1) then
      WriteToErrorLog(capt+'error #6');
     if (sl.Strings[0] <> t1.TableName) then
      WriteToErrorLog(capt+'error #7');
   finally
     sl.Free;
   end;

 finally
   t1.Free;
   db1.Close;
   db1.DeleteDatabase;
   t2.Close;
   t2.DeleteTable(True);
   db1.Free;
   db2.Free;
   t2.Free;
   WriteToProcessLog(capt+'finished.');
 end;
end;


procedure TUnitTestMemoryDatabases.TestQueries;
var
    q1,q2:   TACRQuery;
    capt:    AnsiString;
    sl:      TStringList;
    s:       AnsiString;
begin
 capt := 'TUnitTestMemoryDatabases.TestQueries - ';
 q1 := TACRQuery.Create(nil);
 q2 := TACRQuery.Create(nil);
 try
  q1.InMemory := True;
  q2.InMemory := True;
  WriteToProcessLog(capt+'starting...');
  s :=         'CREATE DATABASE MEMORY MemDB1;'
       +#13#10+'CREATE TABLE MEMORY MemDB1.t1(id AutoInc, name Char(10), PRIMARY KEY (id));'
       +#13#10+'INSERT INTO MEMORY MemDB1.t1(name) VALUES("Leo");'
       ;
  q1.SQL.Text := s;
  q1.ExecSQL;

  s :=         'CREATE DATABASE MEMORY MemDB2;'
       +#13#10+'CREATE TABLE MEMORY MemDB2.t1(id AutoInc, name Char(10), PRIMARY KEY (id));'
       +#13#10+'INSERT INTO MEMORY MemDB2.t1(name) VALUES("Ray");'
       ;
  q2.SQL.Text := s;
  q2.ExecSQL;
  WriteToProcessLog(capt+'DBs created');

  q1.SQL.Text := 'SELECT * FROM MEMORY MemDB1.t1';
  q1.RequestLive := True;
  q1.Open;

  q2.SQL.Text := 'SELECT * FROM MEMORY MemDB2.t1';
  q2.RequestLive := True;
  q2.Open;

  if (q1.RecordCount <> 1) then
   WriteToErrorLog(capt+'error #1');
  if (q2.RecordCount <> 1) then
   WriteToErrorLog(capt+'error #2');
  if (q1.FieldByName('name').AsString <> 'Leo') then
   WriteToErrorLog(capt+'error #3');
  if (q2.FieldByName('name').AsString <> 'Ray') then
   WriteToErrorLog(capt+'error #4');

   q1.Close;
   q2.Close;

   q1.InMemory := True;
   q1.DatabaseName := 'MemDB1';
   q1.SQL.Text := 'SELECT * FROM t1';
   q1.RequestLive := False;
   q1.Open;
   if (q1.RecordCount <> 1) then
    WriteToErrorLog(capt+'error #5');
   if (q1.FieldByName('name').AsString <> 'Leo') then
    WriteToErrorLog(capt+'error #6');
   q1.Close;

  WriteToProcessLog(capt+'SELECT passed');

   q1.InMemory := True;
   q1.DatabaseName := 'MemDB1';
   q1.SQL.Text :=  'SELECT * FROM MemDB1.t1 as t11 INNER JOIN MemDB2.t1 as t21 ON '
                  +'(t11.id = t21.id) '
                  +'where (t11.id > 0) and (t21.name <> "aaa")';
   q1.RequestLive := False;
   q1.Open;
   if (q1.RecordCount <> 1) then
    WriteToErrorLog(capt+'error #17');
   if (q1.FieldCount <> 4) then
    WriteToErrorLog(capt+'error #18');
   if (q1.Fields[0].AsInteger <> 1) then
    WriteToErrorLog(capt+'error #19');
   if (q1.Fields[2].AsInteger <> 1) then
    WriteToErrorLog(capt+'error #20');
   q1.Close;

  WriteToProcessLog(capt+'SELECT with JOIN passed');

   q2.SQL.Text := 'SELECT * INTO MemDB1.t3 FROM MemDB2.t1';
   q2.ExecSQL;
   q2.RequestLive := True;
   q2.SQL.Text := 'SELECT * FROM MemDB1.t3';
   q2.Open;
   if (q2.RecordCount <> 1) then
    WriteToErrorLog(capt+'error #29');
   if (q2.FieldByName('name').AsString <> 'Ray') then
    WriteToErrorLog(capt+'error #30');
   q2.Close;

   // insert .. select
   q2.SQL.Text := 'INSERT INTO MEMORY MemDB1.t3 SELECT * FROM MemDB1.t1';
   q2.ExecSQL;
   q2.RequestLive := True;
   q2.SQL.Text := 'SELECT * FROM MEMORY MemDB1.t3 ORDER BY name';
   q2.Open;
   if (q2.RecordCount <> 2) then
    WriteToErrorLog(capt+'error #31');
   if (q2.FieldByName('name').AsString <> 'Leo') then
    WriteToErrorLog(capt+'error #32');
   q2.Next;
   if (q2.FieldByName('name').AsString <> 'Ray') then
    WriteToErrorLog(capt+'error #33');
   q2.Close;

   // select INTO .. UNION .. select
   q2.SQL.Text := 'SELECT * INTO MEMORY MemDB1.t4 FROM MemDB1.t1 UNION SELECT * FROM MemDB2.t1';
   q2.ExecSQL;
   q2.RequestLive := True;
   q2.SQL.Text := 'SELECT * FROM MEMORY MemDB1.t4 ORDER BY name';
   q2.Open;
   if (q2.RecordCount <> 2) then
    WriteToErrorLog(capt+'error #34');
   if (q2.FieldByName('name').AsString <> 'Leo') then
    WriteToErrorLog(capt+'error #35');
   q2.Next;
   if (q2.FieldByName('name').AsString <> 'Ray') then
    WriteToErrorLog(capt+'error #36');
   q2.Close;

   // INSERT .. SELECT .. UNION .. SELECT
   q2.SQL.Text := 'DELETE FROM MEMORY MemDB1.T4';
   q2.ExecSQL;
   q2.SQL.Text := 'INSERT INTO MEMORY MemDB1.t4 SELECT * FROM MemDB1.t1 UNION SELECT * FROM MemDB2.t1';
   q2.ExecSQL;
   q2.RequestLive := True;
   q2.SQL.Text := 'SELECT * FROM MEMORY MemDB1.t4 ORDER BY name';
   q2.Open;
   if (q2.RecordCount <> 2) then
    WriteToErrorLog(capt+'error #37');
   if (q2.FieldByName('name').AsString <> 'Leo') then
    WriteToErrorLog(capt+'error #38');
   q2.Next;
   if (q2.FieldByName('name').AsString <> 'Ray') then
    WriteToErrorLog(capt+'error #39');
   q2.Close;


   q1.InMemory := True;
   q1.DatabaseName := 'MemDB1';
   q1.SQL.Text :=  'SELECT * FROM MemDB1.t1 as t11 UNION SELECT * FROM MemDB2.t1 as t21 '
                  +'ORDER BY id,name desc';
   q1.RequestLive := False;
   q1.Open;
   if (q1.RecordCount <> 2) then
    WriteToErrorLog(capt+'error #21');
   if (q1.FieldCount <> 2) then
    WriteToErrorLog(capt+'error #22');
   if (q1.Fields[0].AsInteger <> 1) then
    WriteToErrorLog(capt+'error #23');
   if (q1.Fields[1].AsString <> 'Ray') then
    WriteToErrorLog(capt+'error #24');
   q1.Next;
   if (q1.Fields[1].AsString <> 'Leo') then
    WriteToErrorLog(capt+'error #25');
   q1.Close;

   q1.SQL.Text := 'UPDATE t1 SET Name = "Leo Martin"';
   q1.ExecSQL;
   if (q1.RowsAffected <> 1) then
    WriteToErrorLog(capt+'error #7');
   q1.SQL.Text := 'SELECT * FROM t1';
   q1.RequestLive := True;
   q1.Open;
   if (q1.RecordCount <> 1) then
    WriteToErrorLog(capt+'error #8');
   if (q1.FieldByName('name').AsString <> 'Leo Martin') then
    WriteToErrorLog(capt+'error #9');
   q1.Close;

   q2.SQL.Text := 'UPDATE MEMORY MemDB2.t1 SET Name = "Ray Lahoy"';
   q2.ExecSQL;
   if (q2.RowsAffected <> 1) then
    WriteToErrorLog(capt+'error #10');
   q2.SQL.Text := 'SELECT * FROM MEMORY MemDB2.t1';
   q2.RequestLive := True;
   q2.Open;
   if (q2.RecordCount <> 1) then
    WriteToErrorLog(capt+'error #11');
   if (q2.FieldByName('name').AsString <> 'Ray Lahoy') then
    WriteToErrorLog(capt+'error #12');
   q2.Close;

  WriteToProcessLog(capt+'UPDATE passed');

   q1.SQL.Text := 'DELETE FROM t1 WHERE Name = "Leo Martin"';
   q1.ExecSQL;
   if (q1.RowsAffected <> 1) then
    WriteToErrorLog(capt+'error #13');
   q1.SQL.Text := 'SELECT * FROM t1';
   q1.RequestLive := True;
   q1.Open;
   if (q1.RecordCount <> 0) then
    WriteToErrorLog(capt+'error #14');
   q1.Close;

   q2.SQL.Text := 'DELETE FROM MEMORY MemDB2.t1 WHERE Name = "Ray Lahoy"';
   q2.ExecSQL;
   if (q2.RowsAffected <> 1) then
    WriteToErrorLog(capt+'error #15');
   q2.SQL.Text := 'SELECT * FROM MEMORY MemDB2.t1';
   q2.RequestLive := True;
   q2.Open;
   if (q2.RecordCount <> 0) then
    WriteToErrorLog(capt+'error #16');
   q2.Close;

  WriteToProcessLog(capt+'DELETE passed');

   q1.InMemory := True;
   q1.DatabaseName := 'MemDB1';
   q1.SQL.Text :=  'ALTER TABLE t1 ADD(new_field integer)';
   q1.ExecSQL;
   q1.RequestLive := True;
   q1.SQL.Text := 'SELECT * FROM MEMORY MemDB1.t1';
   q1.Open;
   if (q1.RecordCount <> 0) then
    WriteToErrorLog(capt+'error #26');
   if (q1.FieldCount <> 3) then
    WriteToErrorLog(capt+'error #27');
   q1.Close;

  WriteToProcessLog(capt+'ALTER TABLE passed');

   q2.SQL.Text :=  'RENAME TABLE MemDB2.t1 TO r1';
   q2.ExecSQL;
   q2.RequestLive := True;
   q2.SQL.Text := 'SELECT * FROM MEMORY MemDB2.r1';
   q2.Open;
   if (q2.RecordCount <> 0) then
    WriteToErrorLog(capt+'error #28');
   q2.Close;
//39 - last error

  WriteToProcessLog(capt+'RENAME TABLE passed');

   q1.SQL.Text := 'DROP TABLE MEMORY MemDB1.t1 CASCADE';
   q1.ExecSQL;

   q1.SQL.Text := 'DROP DATABASE MEMORY MemDB1';
   q1.ExecSQL;
   if (ACRFindDatabaseData(True,False,'MemDB1') <> nil) then
    WriteToErrorLog(capt+'MemDB1 was not deleted!');


   q2.SQL.Text := 'DROP DATABASE MEMORY MemDB2';
   q2.ExecSQL;
   if (ACRFindDatabaseData(True,False,'MemDB2') <> nil) then
    WriteToErrorLog(capt+'MemDB2 was not deleted!');

 finally
  q1.Free;
  q2.Free;


 end;
end;


procedure TUnitTestMemoryDatabases.TestShort;
begin
 CheckAction(TestDatabases,'Test memory databases');
 CheckAction(TestTables,'Test memory tables');
 CheckAction(TestQueries,'Test memory queries');
end;

initialization
  UnitTestMemoryDatabases := TUnitTestMemoryDatabases.Create(UnitTestList);

finalization
  UnitTestMemoryDatabases.Free;


end.
