unit utSharedTables;

interface

{$I ACRVer.Inc}
{$I UTConfig.Inc}

uses SysUtils, Classes, DB, Windows,
     uTestList,
     ACRMain, 
{$IFDEF ACR5H}
     ACRComMain,
{$ENDIF}
    ACRConst, ACRTypes, ACRBase, ACRBaseEngine, ACRLocalEngine;

type
  TUnitTestSharedTables = class(TUnitTest)
   private
    FTime:     Cardinal;
    FRecCount: Integer;
    FDatabase: TACRDatabase;
    FTable:    TACRTable;
    FQuery:    TACRQuery;
    // in memory mode
    FMemQuery: TACRQuery;
    FMemTable: TACRTable;
   public
    procedure TestShort; override;
    procedure TestExceptions; override;
   protected
    procedure TestSharedTables;
  end;

var UnitTestSharedTables: TUnitTestSharedTables;

implementation

procedure TUnitTestSharedTables.TestShort;
begin
  CheckAction(TestSharedTables, 'Test Shared Tables');
end;


procedure TUnitTestSharedTables.TestExceptions;
begin
end;


procedure TUnitTestSharedTables.TestSharedTables;
var t1,t2:   TACRTable;
    Caption: String;
begin
 Caption := 'TestSharedTables - ';
 t1 := TACRTable.Create(nil);
 t2 := TACRTable.Create(nil);
 try
   t1.TableName := 'test_shared';
   t1.AdvFieldDefs.Add('id',aftAutoInc);
   t1.IndexDefs.Add('PK','id',[ixPrimary]);
   t1.InMemory := True;
   t1.CreateTable;
   t1.Open;
   // add 3 records - id = 1,2,3
   t1.Insert;
   t1.Post;
   t1.Insert;
   t1.Post;
   t1.Insert;
   t1.Post;
   t1.RecNo := 2;
   if (t1.Fields[0].AsInteger <> 2) then
    WriteToErrorLog(Caption+'t1.SetRecNo failed - id = '+t1.Fields[0].AsString);

   t2.InMemory := t1.InMemory;
   t2.TableName := t1.TableName;
   t2.Open;
   t2.RecNo := t1.RecNo;
   if (t2.Fields[0].AsInteger <> 2) then
    WriteToErrorLog(Caption+'t2.SetRecNo failed - id = '+t2.Fields[0].AsString);

   t1.Delete;
   if (t1.Fields[0].AsInteger <> 3) then
    WriteToErrorLog(Caption+'t1.Delete failed - id = '+t1.Fields[0].AsString);
   t2.Refresh;
   if (t2.Fields[0].AsInteger <> 3) then
    WriteToErrorLog(Caption+'t2.Refresh failed - id = '+t2.Fields[0].AsString);

   t1.First;
   if (t1.Fields[0].AsInteger <> 1) then
    WriteToErrorLog(Caption+'t1.First failed - id = '+t1.Fields[0].AsString);
   t2.GotoCurrent(t1);
   if (t2.Fields[0].AsInteger <> 1) then
    WriteToErrorLog(Caption+'t2.GotoCurrent failed - id = '+t2.Fields[0].AsString);
 finally
   t2.Close;
   t1.Close;
   t1.DeleteTable(True);
   t1.Free;
   t2.Free;
 end;
end; // TestSharedTables


initialization

UnitTestSharedTables := TUnitTestSharedTables.Create(UnitTestList);

finalization

UnitTestSharedTables.Free;

end.
