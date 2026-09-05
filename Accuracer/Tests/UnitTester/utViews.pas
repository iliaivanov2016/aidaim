unit utViews;

interface

{$I UTConfig.Inc}

uses SysUtils, Classes,
     uTestList,
     Db,
     ACRMain,
     ACRTYpes
{$IFDEF ACR5H}
     ,ACRComMain
{$ENDIF}
;

type
  TUnitTestViews = class(TUnitTest)
   private
    FDb:      TACRDatabase;
    FQuery:   TACRQuery;
    FTable:   TACRTable;
   protected
    procedure TestSQL(bInMemory, bExcept: Boolean);
    procedure TestDatabase(bInMemory, bExcept: Boolean);
   public
    procedure TestShort; override;
    procedure TestExceptions; override;
   public
    procedure InternalTestViews;
    procedure InternalTestViewsExcept;
  end;

var
  UnitTestViews: TUnitTestViews;

implementation


{ TUnitTestViews }


procedure TUnitTestViews.TestSQL(bInMemory, bExcept: Boolean);
begin
//
end;

procedure TUnitTestViews.TestDatabase(bInMemory, bExcept: Boolean);
var capt: String;
    sl:   TStringList;
    wsl:  TACRWideStringList;
    i:    Integer;
begin
  FDb := TACRDatabase.Create(nil);
  FTable := TACRTable.Create(nil);
  FQuery := TACRQuery.Create(nil);
  sl := TStringList.Create;
  wsl := TACRWideStringList.Create;
  try
    if (bInMemory) then
    begin
     FDb.InMemory := True;
     capt := 'TUnitTestViews.TestDatabase (MEMORY) - ';
    end
    else
    begin
     FDb.InMemory := False;
     FDb.DatabaseFileName := TempDir+'test_views.adb';
     FDb.CreateDatabase;
     capt := 'TUnitTestViews.TestDatabase (DISK) - ';
    end;
    FDb.Open;
    FQuery.InMemory := bInMemory;
    FQuery.DatabaseName := FDb.DatabaseName;
    FTable.InMemory := bInMemory;
    FTable.DatabaseName := FDb.DatabaseName;
    // create table
    FQuery.SQL.Text :=  'CREATE TABLE t1 (id INTEGER, str CHAR(100), dt DATETIME, PRIMARY KEY (id));'
                      +' INSERT INTO t1 VALUES (1,"aaa",NOW);'
                      +' INSERT INTO t1 VALUES (2,"bbb",NOW);'
                      +' INSERT INTO t1 VALUES (3,"ccc",NULL);'
                        ;
    FQuery.ExecSQL;
    WriteToProcessLog(capt+'table created');
    // last error: 56

    // create view #1 - read only with
    FTable.TableName := 'v1';
    if (FTable.Exists) then
     WriteToErrorLog(capt+'error #1');
    // create full view v1
    if (bExcept) then
    begin
      wsl.Clear;
      wsl.Add('Id');
      wsl.Add('Name');
      wsl.Add('Date');
      wsl.Add('Date2');
      try
       FDb.CreateView('v1','SELECT * FROM t1 ORDER BY id DESC',wsl);
       WriteToErrorLog(capt+'error #40 - v1  with invalid columns count no exception - FAILED');
      except
      on e: Exception do
       begin
        WriteToProcessLog(capt+'v1 invalid columns count exception - OK. Exception:'+#13#10+e.Message);
        WriteToProcessLog('-------- OK ----------');
       end;
      end;
    end;
    wsl.Clear;
    wsl.Add('Id');
    wsl.Add('Name');
    wsl.Add('Date');
    FDb.CreateView('v1','SELECT * FROM t1 ORDER BY id DESC',wsl);
    if (not FTable.Exists) then
     WriteToErrorLog(capt+'error #2');
    FTable.Open;
    // check fields, record count
    if (FTable.RecordCount <> 3) or (FTable.FieldCount <> 3) then
     WriteToErrorLog(capt+'error #11');
    if (FTable.FieldDefs.Items[0].DisplayName <> 'Id') then
     WriteToErrorLog(capt+'error #32'+#9+FTable.FieldDefs.Items[0].DisplayName);
    if (FTable.FieldDefs.Items[1].DisplayName <> 'Name') then
     WriteToErrorLog(capt+'error #33'+#9+FTable.FieldDefs.Items[1].DisplayName);
    if (FTable.FieldDefs.Items[2].DisplayName <> 'Date') then
     WriteToErrorLog(capt+'error #34'+#9+FTable.FieldDefs.Items[2].DisplayName);
    // check rows
    if (FTable.FieldByName('id').AsInteger <> 3) then
     WriteToErrorLog(capt+'error #3');
    FTable.Next;
    if (FTable.FieldByName('id').AsInteger <> 2) then
     WriteToErrorLog(capt+'error #4');
    FTable.Next;
    if (FTable.FieldByName('id').AsInteger <> 1) then
     WriteToErrorLog(capt+'error #5');
    FTable.Next;
    if (not FTable.Eof) then
     WriteToErrorLog(capt+'error #6');
    FTable.Close;

    Fdb.FlushFileBuffers;
    FDb.ClearCache;
    Fdb.Close;
    FDb.Open;
    FTable.Open;
    if (FTable.RecordCount <> 3) or (FTable.FieldCount <> 3) then
     WriteToErrorLog(capt+'error #35');
    if (FTable.FieldDefs.Items[0].DisplayName <> 'Id') then
     WriteToErrorLog(capt+'error #36'+#9+FTable.FieldDefs.Items[0].DisplayName);
    if (FTable.FieldDefs.Items[1].DisplayName <> 'Name') then
     WriteToErrorLog(capt+'error #37'+#9+FTable.FieldDefs.Items[1].DisplayName);
    if (FTable.FieldDefs.Items[2].DisplayName <> 'Date') then
     WriteToErrorLog(capt+'error #38'+#9+FTable.FieldDefs.Items[2].DisplayName);
    // check rows
    if (FTable.FieldByName('id').AsInteger <> 3) then
     WriteToErrorLog(capt+'error #39');
    FTable.Close;

    WriteToProcessLog(capt+'checking v1 finished');

    if (bExcept) then
    begin
     try
      FDb.CreateView('v1','SELECT * FROM t1 WHERE id = 2');
      WriteToErrorLog(capt+'error #15: v1 exists no exception - FAILED');
     except
      on e: Exception do
       begin
        WriteToProcessLog(capt+'v1 exists exception - OK. Exception: '+#13#10+e.Message);
        WriteToProcessLog('-------- OK ----------');
       end;
     end;
     try
       // delete t1 with restrict must raise exception
       FTable.TableName := 't1';
       FTable.DeleteTable(False);
       WriteToErrorLog(capt+'error #44: t1 DeleteTable with RESTRICT no exception - FAILED');
     except
      on e: Exception do
      begin
        WriteToProcessLog(capt+'t1 DeleteTable with RESTRICT exception - OK. Exception: '+#13#10+e.Message);
        WriteToProcessLog('-------- OK ----------');
      end;
     end;

    end; // bExcept

    // create horizontal view v2 (if except then with check option)
    FDb.CreateView('v2','SELECT * FROM t1 WHERE id = 2',nil,bExcept);
    FTable.TableName := 'v2';
    FTable.Open;
    if (FTable.RecordCount <> 1) or (FTable.FieldCount <> 3) then
     WriteToErrorLog(capt+'error #12');
    if (FTable.ReadOnly) then
     WriteToErrorLog(capt+'error #16');
    if (FTable.FieldByName('id').AsInteger <> 2) then
     WriteToErrorLog(capt+'error #13');
    FTable.Next;
    if (not FTable.Eof) then
     WriteToErrorLog(capt+'error #14');
    if (bExcept) then
    begin
     // insert
     try
      FTable.InsertRecord([4,'ddd',Now]); // not visible record
      WriteToErrorLog(capt+'error #27 - WITH CHECK OPTION FAILED, v2 insreted');
     except
      on e: Exception do
      begin
        if (FTable.RecordCount = 1) then
        begin
         WriteToProcessLog(capt+'WITH CHECK OPTION v2 insert failed - OK. Exception:'+#13#10+e.Message);
         WriteToProcessLog('-------- OK ----------');
        end
        else
          WriteToErrorLog(capt+'error #28 - WITH CHECK OPTION FAILED, v2 insreted'+#13#10+e.Message);
      end;
     end;
     // update
     try
      FTable.Edit;
      FTable.FieldByName('id').AsInteger := 5;
      FTable.Post;
      WriteToErrorLog(capt+'error #42 - WITH CHECK OPTION FAILED, v2 updated');
     except
      on e: Exception do
      begin
        if (FTable.RecordCount = 1) then
        begin
         WriteToProcessLog(capt+'WITH CHECK OPTION v2 update failed - OK. Exception:'+#13#10+e.Message);
         WriteToProcessLog('-------- OK ----------');
        end
        else
          WriteToErrorLog(capt+'error #43 - WITH CHECK OPTION FAILED, v2 updated'+#13#10+e.Message);
      end;
     end;
    end
    else
    begin
      FTable.InsertRecord([4,'ddd',Now]); // not visible record
      if (FTable.RecordCount <> 1)  then
       WriteToErrorLog(capt+'error #26');
    end;
    FTable.Close;
    WriteToProcessLog(capt+'checking v2 finished');

    // create vertical-horizontal view v3 with column names and comment
    wsl.Clear;
    wsl.Add('Id');
    wsl.Add('Id_x10');
    FDb.CreateView('v3','SELECT id, id * 10, dt as DT FROM t1 WHERE id = 2',wsl,False,'View #3');
    FTable.TableName := 'v3';
    FTable.Open;
    // check column names
    if (FTable.RecordCount <> 1) or (FTable.FieldCount <> 3) then
     WriteToErrorLog(capt+'error #17');
    if (FTable.FieldDefs.Items[0].DisplayName <> 'Id') then
     WriteToErrorLog(capt+'error #29'+#9+FTable.FieldDefs.Items[0].DisplayName);
    if (FTable.FieldDefs.Items[1].DisplayName <> 'Id_x10') then
     WriteToErrorLog(capt+'error #30'+#9+FTable.FieldDefs.Items[1].DisplayName);
    if (FTable.FieldDefs.Items[2].DisplayName <> 'DT') then
     WriteToErrorLog(capt+'error #31'+#9+FTable.FieldDefs.Items[2].DisplayName);
    // read only - false
    if (FTable.ReadOnly) then
     WriteToErrorLog(capt+'error #18');
    if (FTable.FieldByName('id').AsInteger <> 2) then
     WriteToErrorLog(capt+'error #19');
    FTable.Next;
    if (not FTable.Eof) then
     WriteToErrorLog(capt+'error #20');
    FTable.Close;
    WriteToProcessLog(capt+'checking v3 finished');

    WriteToProcessLog(capt+'checking tables list...');
    sl.Clear;
    wsl.Clear;
    Fdb.GetTablesList(sl);
    if (sl.Count <> 4) then
     WriteToErrorLog(capt+'error #21');
    i := sl.IndexOf('v1');
    if (i < 0) then
     WriteToErrorLog(capt+'error #7');
    i := sl.IndexOf('t1');
    if (i < 0) then
     WriteToErrorLog(capt+'error #8');
    Fdb.GetTablesList(wsl);
    if (wsl.Count <> 4) then
     WriteToErrorLog(capt+'error #22');
    i := wsl.IndexOf('v1');
    if (i < 0) then
     WriteToErrorLog(capt+'error #9');
    i := wsl.IndexOf('t1');
    if (i < 0) then
     WriteToErrorLog(capt+'error #10');
    i := wsl.IndexOf('v2');
    if (i < 0) then
     WriteToErrorLog(capt+'error #23');
    i := wsl.IndexOf('V3');
    if (i >= 0) then
     WriteToErrorLog(capt+'error #24');
    // v4 does not exists
    i := wsl.IndexOf('v4');
    if (i >= 0) then
     WriteToErrorLog(capt+'error #25');
    if (not Fdb.TableExists('V3')) then
     WriteToErrorLog(capt+'error #41');
    if (Fdb.TableExists('v4')) then
     WriteToErrorLog(capt+'error #42');
    WriteToProcessLog(capt+'checking tables list... finished');

    // delete t1 with restrict must raise exception
    FTable.TableName := 't1';
    FTable.DeleteTable(True);
    // check if views deleted
    if (Fdb.TableExists('v1')) then
     WriteToErrorLog(capt+'error #45');
    if (Fdb.TableExists('v2')) then
     WriteToErrorLog(capt+'error #46');
    if (Fdb.TableExists('v3')) then
     WriteToErrorLog(capt+'error #47');

    FTable.TableName := 't2';
    FTable.ClearDefinitions;
    FTable.FieldDefs.Add('id',ftAutoinc);
    FTable.CreateTable;
    Fdb.CreateView('v5','SELECT * FROM t2');
    Fdb.CreateView('v6','SELECT * FROM v5');
    if (not Fdb.TableExists('v5')) then
     WriteToErrorLog(capt+'error #48');
    if (not Fdb.TableExists('v6')) then
     WriteToErrorLog(capt+'error #49');
    Fdb.CreateView('v7','SELECT * FROM v6');
    if (not Fdb.TableExists('v6')) then
     WriteToErrorLog(capt+'error #51');
    Fdb.DropView('v6',True);
    if (Fdb.TableExists('v6')) then
     WriteToErrorLog(capt+'error #52');
    if (Fdb.TableExists('v7')) then
     WriteToErrorLog(capt+'error #53');
    Fdb.CreateView('v6','SELECT * FROM v5');
    if (bExcept) then
    begin
     try
       Fdb.DropView('v5',False);
       WriteToErrorLog(capt+'error #50: v5 DropView with RESTRICT no exception - FAILED');
     except
      on e: Exception do
      begin
        WriteToProcessLog(capt+'t1 v5 DropView with RESTRICT exception - OK. Exception: '+#13#10+e.Message);
        WriteToProcessLog('-------- OK ----------');
      end;
     end;
    end;

    FTable.TableName := 'v5';
// not supported    
//    FTable.RenameTable('vvv');
//    FTable.EmptyTable;
    if (bExcept) then
    begin
     try
       FTable.DeleteTable(False);
       WriteToErrorLog(capt+'error #54: v5 DeleteTable with RESTRICT no exception - FAILED');
     except
      on e: Exception do
      begin
        WriteToProcessLog(capt+'t1 v5 DeleteTable with RESTRICT exception - OK. Exception: '+#13#10+e.Message);
        WriteToProcessLog('-------- OK ----------');
      end;
     end;
    end;
    FTable.DeleteTable(True);
    if (Fdb.TableExists('v5')) then
     WriteToErrorLog(capt+'error #55');
    if (Fdb.TableExists('v6')) then
     WriteToErrorLog(capt+'error #56');
{ TODO : fix memory leaks}
  finally
    FTable.Free;
    FQuery.Free;
    FDb.Close;
    FDb.DeleteDatabase;
    FDb.Free;
    sl.Free;
    wsl.Free;
  end;
end;


procedure TUnitTestViews.TestShort;
begin
  CheckAction(InternalTestViews, 'Test Views');
end;


procedure TUnitTestViews.TestExceptions;
begin
  CheckAction(InternalTestViewsExcept, 'Test Views');
end;


procedure TUnitTestViews.InternalTestViews;
begin
  TestDatabase(False,False);
//  TestDatabase(True,False);
end;

procedure TUnitTestViews.InternalTestViewsExcept;
begin
  TestDatabase(False,True);
//  TestDatabase(True,True);
end;

initialization
  UnitTestViews := TUnitTestViews.Create(UnitTestList);

finalization
  UnitTestViews.Free;

end.
