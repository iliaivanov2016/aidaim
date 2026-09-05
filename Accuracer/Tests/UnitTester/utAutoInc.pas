unit utAutoInc;

interface

{$I UTConfig.Inc}

uses uTestList, SysUtils, DB, Variants,
     ACRMain, 
{$IFDEF ACR5H}
     ACRComMain,
{$ENDIF}
     ACRTypes, ACRBaseEngine, ACRDiskEngine, ACRMemEngine;

type

  TUnitTestAutoinc = class(TUnitTest)
   protected
    procedure InternalDefaultAutoinc(InMemory: Boolean);
    procedure InternalAllAutoincs(InMemory: Boolean);
   public
    procedure TestShort; override;
   public
    procedure DefaultAutoinc;
    procedure AllAutoincs;
    procedure TestSetAutoInc;
    procedure TestRepairRestructure;
  end;

var
  UnitTestAutoinc: TUnitTestAutoinc;


implementation


{ TUnitTestAutoinc }

procedure TUnitTestAutoinc.InternalDefaultAutoinc(InMemory: Boolean);
var
  tbl: TACRTable;
  db:  TACRDatabase;
begin
  tbl := TACRTable.Create(nil);
  db := TACRDatabase.Create(nil);
  try
    tbl.InMemory := InMemory;
    if (not InMemory) then
      begin
       db.DatabaseName := 'test_db';
       db.DatabaseFileName := TempDir+'test.adb';
       if (db.Exists) then
        db.DeleteDatabase;
       db.CreateDatabase;
       db.Open;
       tbl.DatabaseName := db.DatabaseName;
      end;
    tbl.TableName := 'test';

    tbl.FieldDefs.Add('AutoInc', ftInteger,0,False);
    if (tbl.Exists) then
      tbl.DeleteTable;
    tbl.CreateTable;
  finally
    tbl.Free;
    if (not InMemory) then
     begin
      db.Close;
      db.DeleteDatabase;
     end;
    db.Free;
  end;
end;


procedure TUnitTestAutoinc.InternalAllAutoincs(InMemory: Boolean);
var
  db:         TACRDatabase;
  tbl:        TACRTable;
  i,j:        Integer;
  LastValue:  Int64;
begin
  tbl := TACRTable.Create(nil);
  db := TACRDatabase.Create(nil);
  try
    tbl.InMemory := InMemory;
    if (not InMemory) then
      begin
       db.DatabaseName := 'test_db';
       db.DatabaseFileName := TempDir+'test.adb';
       if (db.Exists) then
        db.DeleteDatabase;
       db.CreateDatabase;
       db.Open;
       tbl.DatabaseName := db.DatabaseName;
      end;
    tbl.TableName := 'test';

    tbl.AdvFieldDefs.Add('fAutoInc',          aftAutoinc);
    tbl.AdvFieldDefs.Add('fAutoIncShortint',  aftAutoIncShortint);
    tbl.AdvFieldDefs.Add('fAutoIncSmallint',  aftAutoIncSmallint);
    tbl.AdvFieldDefs.Add('fAutoIncInteger',   aftAutoIncInteger);
    tbl.AdvFieldDefs.Add('fAutoIncLargeint',  aftAutoIncLargeint);
    tbl.AdvFieldDefs.Add('fAutoIncByte',      aftAutoIncByte);
    tbl.AdvFieldDefs.Add('fAutoIncWord',      aftAutoIncWord);
    tbl.AdvFieldDefs.Add('fAutoIncCardinal',  aftAutoIncCardinal);

    if (tbl.Exists) then
      tbl.DeleteTable;
    tbl.CreateTable;

    tbl.Open;
    for i:=1 to 300 do
      begin
        tbl.Insert;
        tbl.Post;
      end;

    tbl.First;  
    for i:=1 to 300 do
      begin
       if i<256 then
         for j:=0 to tbl.Fields.Count-1 do
          if i in [1,5] then
           if (tbl.Fields[j].AsInteger <> i) then
             raise Exception.Create(Format( 'Autoinc error #1 value not correct. i=%d value=%d',[i, tbl.Fields[j].AsInteger]))
           else
          else
           if (tbl.Fields[j].AsInteger <> i mod 256) then
             raise Exception.Create(Format( 'Autoinc error #2 value not correct. i=%d value=%d',[i, tbl.Fields[j].AsInteger]));
        tbl.Next;
      end;

    LastValue := tbl.LastAutoincValue('fAutoInc');
    if (LastValue <> 300) then
      raise Exception.Create('LastAutoincValue error: LastAutoincValue = ' + IntToStr(LastValue));

    LastValue := 8424283;
    tbl.SetLastAutoincValue(LastValue,'fAutoInc');
    tbl.Insert;
    tbl.Post;
    if (tbl.FieldByName('fAutoInc').AsInteger <> LastValue+1) then
     WriteToErrorLog('Error setting autoinc value. value = '+
      tbl.FieldByName('fAutoInc').AsString+' instead of LastValue = '+IntToStr(LastValue+1));

  finally
    tbl.Free;
    if (not InMemory) then
     begin
      db.Close;
      db.DeleteDatabase;
     end;
    db.Free;
  end;
end;


procedure TUnitTestAutoinc.TestShort;
begin
{$IFDEF ACR5H}
  CheckAction(TestSetAutoInc, 'Test Set AutoInc');
{$ENDIF}
  CheckAction(DefaultAutoinc, 'Test Fielddef AutoInc');
  CheckAction(AllAutoincs, 'Test All AutoInc types');
  CheckAction(TestRepairRestructure,'Test Autoinc repair and restructure');
end;


procedure TUnitTestAutoinc.DefaultAutoinc;
begin
 InternalDefaultAutoinc(False);
 InternalDefaultAutoinc(True);
end;


procedure TUnitTestAutoinc.AllAutoincs;
begin
 InternalAllAutoincs(False);
 InternalAllAutoincs(True);
end;

procedure TUnitTestAutoinc.TestSetAutoInc;
var db: TACRDatabase;
    t:  TACRTable;
    capt: AnsiString;
    x:    Integer;
begin
 db := TACRDatabase.Create(nil);
 t := TACRTable.Create(nil);
 capt := 'TUnitTestAutoinc.TestRepairRestructure - ';
 WriteToProcessLog(capt + 'starting....');
 try
   db.DatabaseFileName := TempDir+'test_autoinc_repair.adb';
   db.CreateDatabase;
   db.Open;
   t.DatabaseName := db.DatabaseName;
   t.TableName := 'test_autoinc';
   t.ClearDefinitions;
   t.AdvFieldDefs.Add('id',aftAutoInc);
   t.AdvFieldDefs.Add('name',aftChar,20);
   t.IndexDefs.Add('PK','id',[ixPrimary]);
   t.CreateTable;
   WriteToProcessLog(capt + 'table created....');
   t.Open;
   WriteToProcessLog(capt + 'table opened....');

   t.AppendRecord([10,'aaa']);
   x := t.LastAutoincValue(0);
   if (x <> 10) then
    WriteToErrorLog(capt+'1 LastAutoInc is not correct: '+IntToStr(x));
   x := t.FieldByName('id').AsInteger;
   if (x <> 10) then
    WriteToErrorLog(capt+'1 ID value is not correct: '+IntToStr(x));

   t.AppendRecord([Null,'bbb']);
   x := t.LastAutoincValue(0);
   if (x <> 11) then
    WriteToErrorLog(capt+'2 LastAutoInc is not correct: '+IntToStr(x));
   x := t.FieldByName('id').AsInteger;
   if (x <> 11) then
    WriteToErrorLog(capt+'2 ID value is not correct: '+IntToStr(x));

   t.AppendRecord([3,'aaa']);
   x := t.LastAutoincValue(0);
   if (x <> 3) then
    WriteToErrorLog(capt+'3 LastAutoInc is not correct: '+IntToStr(x));
   x := t.FieldByName('id').AsInteger;
   if (x <> 3) then
    WriteToErrorLog(capt+'3 ID value is not correct: '+IntToStr(x));

   t.Append;
   t.Post;
   x := t.LastAutoincValue(0);
   if (x <> 12) then
    WriteToErrorLog(capt+'4 LastAutoInc is not correct: '+IntToStr(x));
   x := t.FieldByName('id').AsInteger;
   if (x <> 12) then
    WriteToErrorLog(capt+'4 ID value is not correct: '+IntToStr(x));
   t.Close;
 finally
   t.Free;
   db.Close;
   db.DeleteDatabase;
   db.Free;
 end;
end; // TestSetAutoInc


procedure TUnitTestAutoinc.TestRepairRestructure;
var db: TACRDatabase;
    t:  TACRTable;
    capt: AnsiString;
begin
 db := TACRDatabase.Create(nil);
 t := TACRTable.Create(nil);
 capt := 'TUnitTestAutoinc.TestRepairRestructure - ';
 WriteToProcessLog(capt + 'starting....');
 try
   db.DatabaseFileName := TempDir+'test_autoinc_repair.adb';
   db.CreateDatabase;
   db.Open;
   t.DatabaseName := db.DatabaseName;
   t.TableName := 'test_autoinc';
   t.ClearDefinitions;
   t.AdvFieldDefs.Add('id',aftAutoInc);
   t.AdvFieldDefs.Add('name',aftChar,20);
   t.IndexDefs.Add('PK','id',[ixPrimary]);
   t.CreateTable;
   WriteToProcessLog(capt + 'table created....');
   t.Open;
   WriteToProcessLog(capt + 'table opened....');
{$IFDEF ACR5H}
   t.AppendRecord(['','aaa']);
   t.AppendRecord(['','bbb']);
   t.AppendRecord(['','ccc']);
{$ELSE}
   t.Append; t.Fields[1].AsString := 'aaa'; t.Post;
   t.Append; t.Fields[1].AsString := 'bbb'; t.Post;
   t.Append; t.Fields[1].AsString := 'ccc'; t.Post;
{$ENDIF}
   t.Locate('id',2,[]);
   t.Delete;
   t.Close;
   WriteToProcessLog(capt + 'table closed....');
   t.RepairTable(False);
   WriteToProcessLog(capt + 't.RepairTable(False) ok');
   t.IndexName := 'PK';
   t.Open;
   t.First;
   if (t.RecordCount <> 2) then
    WriteToErrorLog(capt + '#0');
   if (t.FieldValues['id'] <> 1) then
    WriteToErrorLog(capt + '#1');
   t.Next;
   if (t.FieldValues['id'] <> 3) then
    WriteToErrorLog(capt + '#2');
   t.Close;
   t.RepairTable(True);
   t.Open;
   t.First;
   if (t.RecordCount <> 2) then
    WriteToErrorLog(capt + '#3');
   if (t.FieldValues['id'] <> 1) then
    WriteToErrorLog(capt + '#4');
   t.Next;
   if (t.FieldValues['id'] <> 3) then
    WriteToErrorLog(capt + '#5');
   t.Close;
   t.RestructureFieldDefs.Add('dt',aftDateTime);
   t.RestructureTable;
   t.Open;
   t.First;
   if (t.RecordCount <> 2) then
    WriteToErrorLog(capt + '#6');
   if (t.FieldValues['id'] <> 1) then
    WriteToErrorLog(capt + '#7');
   t.Next;
   if (t.FieldValues['id'] <> 3) then
    WriteToErrorLog(capt + '#8');
   t.Close;
 finally
   t.Free;
   db.Close;
   db.DeleteDatabase;
   db.Free;
 end;
end; // TestRepairRestructure


initialization
  UnitTestAutoinc := TUnitTestAutoinc.Create(UnitTestList);

finalization
  UnitTestAutoinc.Free;

end.
