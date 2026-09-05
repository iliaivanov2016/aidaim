unit utComments;

interface

{$I UTConfig.Inc}
{$I ACRVER.Inc}

uses uTestList, SysUtils, Db, Classes,
{$IFDEF D6H}
     Variants,
{$ENDIF}
     ACRMain, 
{$IFDEF ACR5H}
     ACRComMain,
{$ENDIF}
     ACRTypes;

type
  TUnitTestComments = class(TUnitTest)
   private
    procedure TestComments(InMemory: Boolean);
    procedure DiskTest;
    procedure MemoryTest;
   public
    procedure TestShort; override;
  end;

var
  UnitTestComments: TUnitTestComments;


implementation

procedure TUnitTestComments.DiskTest;
begin
 TestComments(False);
end;

procedure TUnitTestComments.MemoryTest;
begin
 TestComments(True);
end;

procedure TUnitTestComments.TestComments(InMemory: Boolean);
var Caption:  string;
    comment1: WideString;
    comment2: WideString;
    ACRTable: TACRTable;
    ACRQuery: TACRQuery;
    db:       TACRDatabase;
begin
 Caption := 'TestComments - InMemory = '+BoolToStr(InMemory,True)+': ';
 comment1 := 'This is a test table for comments.'+#13#10+#$00A9+' AidAim Software, 2009.'+#13#10+'http://www.aidaim.com';
 db := TACRDatabase.Create(nil);
 ACRTable := TACRTable.Create(nil);
 ACRQuery := TACRQuery.Create(nil);
 try
  if (InMemory) then
   begin
    db.InMemory := True;
    db.DatabaseName := 'MemDB1';
   end
  else
    db.DatabaseFileName := TempDir+'comments.adb';
//db.CryptoParams.CryptoAlgorithm := craRijndael_256;
  db.CreateDatabase;
  db.Open;
  ACRTable.InMemory := InMemory;
  ACRQuery.InMemory := InMemory;
  ACRTable.DatabaseName := db.DatabaseName;
  ACRQuery.DatabaseName := db.DatabaseName;
  ACRTable.TableName := 'test_comments';
  ACRTable.Comment := comment1;
  ACRTable.FieldDefs.Clear;
  ACRTable.FieldDefs.Add('Field0',ftAutoInc,0,False);
  ACRTable.FieldDefs.Add('Field1',ftInteger,0,False);
  ACRTable.FieldDefs.Add('Field2',ftString,500,False);
  ACRTable.IndexDefs.Clear;
  ACRTable.IndexDefs.Add('Index1','Field1',[ixPrimary]);
  ACRTable.IndexDefs.Add('Index2','Field2;Field1',[ixUnique,ixDescending,ixCaseInsensitive]);
  ACRTable.CreateTable;
  ACRTable.Comment := '';
  ACRTable.Open;
  ACRTable.Close;
  if (ACRTable.Comment <> comment1) then
   WriteToErrorLog(Caption+'Error #1');
  comment1 := comment1 + #13#10+'A small addition!;';
  ACRTable.Comment := comment1;
  ACRTable.RestructureTable;
  ACRTable.Comment := '';
  ACRTable.Open;
  ACRTable.Close;
  if (ACRTable.Comment <> comment1) then
   WriteToErrorLog(Caption+'Error #2');
  db.ClearCache;
  db.FlushFileBuffers;
  db.Close;
  ACRTable.Comment := '';
  db.Open;
  ACRTable.Open;
  if (ACRTable.Comment <> comment1) then
   WriteToErrorLog(Caption+'Error #3');
  ACRTable.Close;
  if (InMemory) then
   begin
    ACRTable.SaveTableToFile(TempDir+'test.smt');
    ACRTable.DeleteTable(True);
    if (ACRTable.Exists) then
     WriteToErrorLog(Caption+'Error #4');
    ACRTable.Comment := '';
    ACRTable.LoadTableFromFile(TempDir+'test.smt');
    DeleteFile(TempDir+'test.smt');
    ACRTable.Open;
    if (ACRTable.Comment <> comment1) then
     WriteToErrorLog(Caption+'Error #8');
    ACRTable.Close;
   end;
  comment2 := comment1+#13#10+'SQL version of comment :-)';
  ACRQuery.SQL.Text := 'CREATE TABLE test_sql_comments (id AutoInc, str CHAR(20), PRIMARY KEY(id)) COMMENT "'+comment2+'"';
  ACRQuery.ExecSQL;
  ACRTable.TableName := 'test_sql_comments';
  ACRTable.Comment := '';
  ACRTable.Open;
  if (ACRTable.Comment <> comment2) then
   WriteToErrorLog(Caption+'Error #4');
  ACRTable.Close;
  ACRTable.Comment := 'failure';
  ACRQuery.SQL.Text := 'ALTER TABLE test_sql_comments MODIFY COMMENT NULL';
  ACRQuery.ExecSQL;
  ACRTable.Open;
  if (ACRTable.Comment <> '') then
   WriteToErrorLog(Caption+'Error #5');
  ACRTable.Close;

  comment2 := 'test123!';
  ACRTable.Comment := '';
  ACRQuery.SQL.Text := 'ALTER TABLE test_sql_comments MODIFY COMMENT "'+comment2+'"';
  ACRQuery.ExecSQL;
  ACRTable.Comment := '';
  ACRTable.Open;
  if (ACRTable.Comment <> comment2) then
   WriteToErrorLog(Caption+'Error #6');
  ACRTable.Close;

  ACRTable.Comment := 'failure';
  ACRQuery.SQL.Text := 'ALTER TABLE test_sql_comments MODIFY COMMENT ""';
  ACRQuery.ExecSQL;
  ACRTable.Open;
  if (ACRTable.Comment <> '') then
   WriteToErrorLog(Caption+'Error #7');
  ACRTable.Close;

  // TableName, Comment, CreationDate, LastModificationDate, LastTableOperation
  ACRQuery.SQL.Text := 'GET TABLES';
  ACRQuery.Open;
  if (ACRQuery.RecordCount <> 2) then
   WriteToErrorLog(Caption+'Error #9');
  if (ACRQuery.Fields[0].AsString <> 'test_comments') then
   WriteToErrorLog(Caption+'Error #10');
  if (ACRQuery.Fields[7].AsString <> comment1) then
   WriteToErrorLog(Caption+'Error #11');
  ACRQuery.Next;
  if (ACRQuery.Fields[0].AsString <> 'test_sql_comments') then
   WriteToErrorLog(Caption+'Error #12');
  if (ACRQuery.Fields[7].AsString <> '') then
   WriteToErrorLog(Caption+'Error #13');
  if (not ACRQuery.Fields[7].IsNull) then
   WriteToErrorLog(Caption+'Error #14');
  ACRQuery.Next;
  if (not ACRQuery.Eof) then
   WriteToErrorLog(Caption+'Error #15');
  if (not ACRQuery.ReadOnly) then
   WriteToErrorLog(Caption+'Error #16');
 finally
  ACRTable.Free;
  ACRQuery.Free;
  db.Close;
  db.DeleteDatabase;
  db.Free;
 end;
end;


procedure TUnitTestComments.TestShort;
begin
  CheckAction(MemoryTest,'Disk table comments test');
  CheckAction(DiskTest,'Disk table comments test');
end; // TestShort


initialization
  UnitTestComments := TUnitTestComments.Create(UnitTestList);

finalization
  UnitTestComments.Free;


end.
