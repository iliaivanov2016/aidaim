unit utLoadSaveMemoryDatabases;

interface

{$I UTConfig.Inc}

uses
      Windows, Controls,
      SysUtils,
     uTestList, DB,
     ACRMain, 
     ACRVariant,
{$IFDEF ACR5H}
     ACRComMain,
{$ENDIF}
     ACRLocalEngine, ACRBaseEngine, ACRMemEngine,
     ACRConst, ACRTypes, ACRConverts,
     ACRCompression, ACRExpressions;

type
  TUnitTestLoadSaveMemoryDatabases = class(TUnitTest)
   private
    procedure TestLoadSaveMemoryDatabases;
   public
    procedure TestShort; override;
  end;

var
  UnitTestLoadSaveMemoryDatabases: TUnitTestLoadSaveMemoryDatabases;


implementation


{ TUnitTestLoadSaveMemoryDatabases }


procedure TUnitTestLoadSaveMemoryDatabases.TestShort;
begin
  CheckAction(TestLoadSaveMemoryDatabases, 'Load/Save memory databases');
end;


procedure TUnitTestLoadSaveMemoryDatabases.TestLoadSaveMemoryDatabases;
var
    tEmp:   TACRTable;
    tDept:  TACRTable;
    q:      TACRQuery;
    db:     TACRDatabase;
    capt:   String;
    s,s1:   AnsiString;
    i,n:    Integer;
    bOk:    Boolean;
begin
  capt := 'TestLoadSaveMemoryDatabases - ';
  db := TACRDatabase.Create(nil);
  tEmp := TACRTable.Create(nil);
  tDept := TACRTable.Create(nil);
  q := TACRQuery.Create(nil);
  try
   db.InMemory := True;
   db.DatabaseName := 'MemDBLoadSave';
   db.CreateDatabase;
   db.Open;
   tEmp.InMemory := True;
   tDept.InMemory := True;
   q.InMemory := True;
   tEmp.DatabaseName := db.DatabaseName;
   tDept.DatabaseName := db.DatabaseName;
   tEmp.TableName := 'emp';
   tDept.TableName := 'dept';
   q.DatabaseName := db.DatabaseName;
   tDept.FieldDefs.Clear;
   tDept.AdvFieldDefs.Clear;
   tDept.AdvFieldDefs.Add('ID',aftAutoInc);
   tDept.AdvFieldDefs.Add('Name',aftChar,50);
   tDept.IndexDefs.Clear;
   tDept.IndexDefs.Add('PK','ID,Name',[ixPrimary]);
   tDept.ForeignKeyDefs.Clear;
   tDept.CreateTable;
   tDept.Open;

   tEmp.FieldDefs.Clear;
   tEmp.AdvFieldDefs.Clear;
   tEmp.AdvFieldDefs.Add('ID',aftAutoInc);
   tEmp.AdvFieldDefs.Add('Name',aftChar,50);
   tEmp.AdvFieldDefs.Add('Surname',aftChar,50);
   tEmp.AdvFieldDefs.Add('DeptID',aftInteger);
   tEmp.AdvFieldDefs.Add('DeptName',aftChar,50);
   tEmp.AdvFieldDefs.Find('DeptID').DefaultValue.AsInteger := -1;
   tEmp.AdvFieldDefs.Find('DeptName').DefaultValue.AsString := 'UNKNOWN DEPARTMENT';
   tEmp.IndexDefs.Clear;
   tEmp.IndexDefs.Add('PK','ID',[ixPrimary]);
   tEmp.ForeignKeyDefs.Clear;
   tEmp.ForeignKeyDefs.Add('FK_DeptID','DeptID,DeptName','dept',
                           fkmtFull,fkaCascade,fkaCascade);
   tEmp.CreateTable;
   tEmp.Open;

   tDept.Insert;
   tDept.FieldByName('Name').AsString := 'Development Department';
   tDept.Post;
   tDept.Insert;
   tDept.FieldByName('Name').AsString := 'Technical Support Team';
   tDept.Post;
   tDept.Insert;
   tDept.FieldByName('Name').AsString := 'Sales Department';
   tDept.Post;
   tDept.Insert;
   tDept.FieldByName('ID').AsInteger := -1;
   tDept.FieldByName('Name').AsString := 'UNKNOWN DEPARTMENT';
   tDept.Post;

   tEmp.Insert;
   tEmp.FieldByName('Name').AsString := 'Leo';
   tEmp.FieldByName('Surname').AsString := 'Martin';
   tEmp.FieldByName('DeptID').AsInteger := 1;
   tEmp.FieldByName('DeptName').AsString := 'Development Department';
   tEmp.Post;

   tEmp.Insert;
   tEmp.FieldByName('Name').AsString := 'Richard';
   tEmp.FieldByName('Surname').AsString := 'Watson';
   tEmp.FieldByName('DeptID').AsInteger := 1;
   tEmp.FieldByName('DeptName').AsString := 'Development Department';
   tEmp.Post;

   tEmp.Insert;
   tEmp.FieldByName('Name').AsString := 'Garry';
   tEmp.FieldByName('Surname').AsString := 'Robinson';
   tEmp.FieldByName('DeptID').AsInteger := 1;
   tEmp.FieldByName('DeptName').AsString := 'Development Department';
   tEmp.Post;

   tEmp.Insert;
   tEmp.FieldByName('Name').AsString := 'Alex';
   tEmp.FieldByName('Surname').AsString := 'Lambert';
   tEmp.FieldByName('DeptID').AsInteger := 1;
   tEmp.FieldByName('DeptName').AsString := 'Development Department';
   tEmp.Post;

   tEmp.Insert;
   tEmp.FieldByName('Name').AsString := 'Fred';
   tEmp.FieldByName('Surname').AsString := 'Bolt';
   tEmp.FieldByName('DeptID').AsInteger := 1;
   tEmp.FieldByName('DeptName').AsString := 'Development Department';
   tEmp.Post;

   tEmp.Insert;
   tEmp.FieldByName('Name').AsString := 'Ray';
   tEmp.FieldByName('Surname').AsString := 'Lahoy';
   tEmp.FieldByName('DeptID').AsInteger := 2;
   tEmp.FieldByName('DeptName').AsString := 'Technical Support Team';
   tEmp.Post;

   tEmp.Insert;
   tEmp.FieldByName('Name').AsString := 'Ella';
   tEmp.FieldByName('Surname').AsString := 'Perelman';
   tEmp.FieldByName('DeptID').AsInteger := 3;
   tEmp.FieldByName('DeptName').AsString := 'Sales Department';
   tEmp.Post;

   tEmp.Insert;
   tEmp.FieldByName('Name').AsString := 'John';
   tEmp.FieldByName('Surname').AsString := 'Smith';
   tEmp.FieldByName('DeptID').AsInteger := 3;
   tEmp.FieldByName('DeptName').AsString := 'Sales Department';
   tEmp.Post;

   q.SQL.Text := 'SELECT * FROM emp Where ID >= 2';
   q.RequestLive := True;
   q.Open;

   WriteToProcessLog(capt+'DB created, tables opened');
   s := db.ExportDatabaseToSQL;
   WriteToProcessLog(capt+'DB exported');
   db.SaveDatabaseToFile(TempDir+'save.smt','',caZLIB,9,512*1024);
   WriteToProcessLog(capt+'DB saved');
   tEmp.Last;
   tEmp.Delete;
   tDept.First;
   tDept.Delete;
   WriteToProcessLog(capt+'Before loading DB');
   db.LoadDatabaseFromFile(TempDir+'save.smt');
   WriteToProcessLog(capt+'After loading DB');
   s1 := db.ExportDatabaseToSQL;
   WriteToProcessLog(capt+'After exporting DB');
   n := Length(s);
   if (n <> Length(s1)) then
    WriteToErrorLog(capt+
      'Error #1 - SQL Differs. Original SQL: '+#13#10+s+#13#10
      +'Result SQL:'+#13#10+s1)
   else
    begin
     bOk := True;
     for i := 1 to n do
      if (s[i] <> s1[i]) then
       begin
        bOk := False;
        WriteToErrorLog(capt+'i = '+IntToStr(i)+#9+
          's[i] = '+s[i]+#9+'s1[i] = '+s1[i]);
        break;
       end;
     if (not bOK) then
      WriteToErrorLog(capt+
        'Error #2 - SQL Differs. Original SQL: '+#13#10+s+#13#10
        +'Result SQL:'+#13#10+s1)
     else
      WriteToProcessLog(capt+'Save / Load SQL OK!');
    end;
   if (not tEmp.Active) then
    WriteToErrorLog(capt+'Error - tEmp is not active!');
   if (not tDept.Active) then
    WriteToErrorLog(capt+'Error - tDept is not active!');
   if (not q.Active) then
    WriteToErrorLog(capt+'Error - query is not active!');
   WriteToProcessLog(capt+'test finished');

  finally
    db.Close;
    db.DeleteDatabase;
    tEmp.Free;
    tDept.Free;
    q.Free;
    db.Free;
    DeleteFile(TempDir+'save.smt');
  end;
end;

initialization
  UnitTestLoadSaveMemoryDatabases := TUnitTestLoadSaveMemoryDatabases.Create(UnitTestList);

finalization
  UnitTestLoadSaveMemoryDatabases.Free;


end.
