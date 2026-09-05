unit utIndexTestd4;

interface

// for memory and temporary engines only

{$I UTConfig.Inc}
{$I ACRVer.inc}

uses uTestList, SysUtils, Dialogs, Db, DBTables,
{$IFDEF ACR5H}
     ACRComMain,
{$ENDIF}
     ACRMain;

type
  TTestRecord = record
     vString:        String;
     vSmallint:      Smallint;
     vInteger:       Integer;
     vWord:          Word;
     vBoolean:       Boolean;
     vFloat:         double;
     vCurrency:      Currency;
     vDate:          TDateTime;
     vTime:          TDateTime;
     vDateTime:      TDateTime;
     vFixedChar:     String;
  end;

  TIndexTestD4 = class(TUnitTest)
   private
    ACRTable: TACRTable;
    Table:    TTable;

    procedure InMemoryTableWithIndexes;
    procedure TemporaryTableWithIndexes;
    procedure CreateTables;
    procedure InsertRecord(tbl: TDataset; RecNo: Integer);
    procedure EditRecord(tbl: TDataset; RecNo: Integer);
    procedure Insert1(InMemory: Boolean; Temporary: Boolean);
    procedure InsertEdit1(InMemory: Boolean);
    procedure AddInvalidIndex(InMemory: Boolean; Temporary: Boolean);
    procedure CreateTableWithInvalidIndex(InMemory: Boolean; Temporary: Boolean);

    procedure TwoTableComponentsWithIndexes;

    procedure CreateAllFiledsTables;
    procedure CompareTablesWithIndex(IndexName: String; CompareFieldName: String);
    procedure CompareTables(Caption: String; Table1, Table2: TDataset; CompareFieldName: String);
    procedure GenerateAllFieldsRecord(var rec: TTestRecord);
    procedure InsertAllFieldsRecord(rec: TTestRecord; tbl: TDataset);
    procedure CheckIndexOrder1(InMemory: Boolean; Temporary: Boolean);
   public
    procedure Inserts1;
    procedure CheckIndexOrder;
    procedure InvalidIndexParamsCheck;

    procedure TestShort; override;
    procedure TestExceptions; override;
  end;

var
  IndexTest: TIndexTestD4;

implementation

function GenerateString(
                       len : Integer // serial length
                       ) : String; // returns serial
var i,x : integer;
    s : string;
    c : char;
begin
 s := '';

 for i := 1 to len do
  begin
   x := Random(101);
   if ((x mod 2) =  0) then
    c := chr(65+(Random(260000000) mod 26))
   else
    c := chr(48+(Random(100000000) mod 10));

   s := s + c;
  end; //len
 result := s;
end; // GenerateString


function GenerateRandomDateTime: TDateTime;
var
  d,m,y,h,n,z : integer;
begin
     m:= 1 + Random(MAXINT) mod 12;
     d:= 1 + Random(MAXINT) mod 28;
     y := 1900 + Random(MAXINT) mod 200;
     h := Random(MAXINT) mod 24;
     n := Random(MAXINT) mod 60;
     z := Random(MAXINT) mod 60;

     Result := EncodeDate(y, m, d) + EncodeTime( h, n, z, Random(1000));
end;


procedure TIndexTestD4.InMemoryTableWithIndexes;
var
  tbl: TACRTable;
  i:   Integer;
  s:   String;
begin
  tbl := TACRTable.Create(nil);
  tbl.InMemory := True;
  tbl.TableName := 'test';
  try
   tbl.FieldDefs.Clear;
   tbl.FieldDefs.Add('int', ftInteger,0,False);
   tbl.FieldDefs.Add('string', ftString, 500,False);
   tbl.IndexDefs.Clear;
   tbl.IndexDefs.Add('idx1','int',[]);
   tbl.IndexDefs.Add('idx2','int;string',[ixCaseInsensitive]);
   tbl.IndexDefs.Add('idx3','string',[ixUnique,ixCaseInsensitive]);
   if (tbl.Exists) then
    tbl.DeleteTable;
   tbl.CreateTable;
  except
   WriteToErrorLog('InMemoryTableWithIndexes - create table failed');
  end;

  try
   tbl.IndexDefs.Clear;
   tbl.Open;
   if (tbl.IndexDefs.Count <> 3) then
    WriteToErrorLog('InMemoryTableWithIndexes - wrong number of indexes');
   tbl.Close;
  except
   WriteToErrorLog('InMemoryTableWithIndexes - open error');
  end;

  try
   tbl.IndexDefs.Clear;
   tbl.Open;
   tbl.Insert;
   tbl.FieldByName('string').AsString := 'aaa';
   tbl.Post;
   tbl.Insert;
   tbl.FieldByName('string').AsString := 'ccc';
   tbl.Post;
   tbl.Insert;
   tbl.FieldByName('string').AsString := 'bbb';
   tbl.Post;
   tbl.AddIndex('idx4','string',[ixUnique],'string','string');
   tbl.Close;
   tbl.IndexDefs.Clear;
   tbl.Open;
   if (tbl.IndexDefs.Count <> 4) then
    WriteToErrorLog('InMemoryTableWithIndexes - wrong number of indexes');
   tbl.IndexName := 'idx4';
   tbl.First;
   if (tbl.FieldByName('string').AsString <> 'ccc') then
    WriteToErrorLog('InMemoryTableWithIndexes - wrong string desc index order: First');
   tbl.Last;
   if (tbl.FieldByName('string').AsString <> 'aaa') then
    WriteToErrorLog('InMemoryTableWithIndexes - wrong string desc index order: Last');
   tbl.Prior;
   if (tbl.FieldByName('string').AsString <> 'bbb') then
    WriteToErrorLog('InMemoryTableWithIndexes - wrong string desc index order: Prior');
   tbl.Next;
   if (tbl.FieldByName('string').AsString <> 'aaa') then
    WriteToErrorLog('InMemoryTableWithIndexes - wrong string desc index order: Next');
   tbl.Prior;
   tbl.Delete;
   if (tbl.FieldByName('string').AsString <> 'aaa') then
    WriteToErrorLog('InMemoryTableWithIndexes - delete - leaf');
   tbl.Delete;
   if (tbl.FieldByName('string').AsString <> 'ccc') then
    WriteToErrorLog('InMemoryTableWithIndexes - delete - leaf2');


   tbl.Close;
   tbl.IndexName := '';
   tbl.EmptyTable;
   tbl.Open;
   for i:=0 to 100 do
    begin
     tbl.Insert;
     tbl.FieldByName('string').AsString := IntToStr(i);
     tbl.Post;
    end;

   tbl.AddIndex('idx5','string',[ixUnique]);
   tbl.IndexName := 'idx5';
   tbl.First;
   if (tbl.FieldByName('string').AsString <> '0') then
    WriteToErrorLog('InMemoryTableWithIndexes - Node with leaf: First');
   tbl.Next;
   if (tbl.FieldByName('string').AsString <> '1') then
    WriteToErrorLog('InMemoryTableWithIndexes - Node with leaf: Next');
   tbl.Last;
   if (tbl.FieldByName('string').AsString <> '99') then
    WriteToErrorLog('InMemoryTableWithIndexes - Node with leaf: Last');
   tbl.Prior;
   if (tbl.FieldByName('string').AsString <> '98') then
    WriteToErrorLog('InMemoryTableWithIndexes - Node with leaf: Prior');

   // full cross
   tbl.First;
   while not tbl.Eof do
    tbl.Next;
   if (tbl.RecNo <> tbl.RecordCount) then
    WriteToErrorLog('InMemoryTableWithIndexes - RecNo <> RecCount');
   tbl.Last;
   while not tbl.Bof do
    tbl.Prior;
   if (tbl.RecNo <> 1) then
    WriteToErrorLog('InMemoryTableWithIndexes - RecNo <> 1');

   tbl.First;
   tbl.Edit;
   tbl.FieldByName('string').AsString := '999';
   tbl.Post;
   if (tbl.FieldByName('string').AsString <> '999') then
    WriteToErrorLog('InMemoryTableWithIndexes - Edit #1');
   tbl.Prior;
   tbl.Next;
   if (tbl.FieldByName('string').AsString <> '999') then
    WriteToErrorLog('InMemoryTableWithIndexes - Edit #2');
   tbl.First;
   tbl.Last;
   if (tbl.FieldByName('string').AsString <> '999') then
    WriteToErrorLog('InMemoryTableWithIndexes - Edit #3');
   tbl.Delete;

   tbl.Last;
   tbl.Delete;
   if (tbl.FieldByName('string').AsString <> '98') then
    WriteToErrorLog('InMemoryTableWithIndexes - Delete last');
   while (not tbl.Eof) do
    begin
      s := tbl.FieldByName('string').AsString;
      tbl.Delete;
      if (not tbl.Eof) then
       if (tbl.FieldByName('string').AsString > s) then
        WriteToErrorLog('InMemoryTableWithIndexes - Delete loop');
    end;

   tbl.DeleteIndex('idx5');
   tbl.IndexName := 'idx4';
   if (tbl.IndexDefs.Count <> 4) then
    WriteToErrorLog('InMemoryTableWithIndexes - wrong number of indexes: delete index');

   tbl.Close;
  except
   WriteToErrorLog('InMemoryTableWithIndexes - exception');
  end;

  try
   tbl.Close;
   tbl.DeleteTable;
  except
   WriteToErrorLog('InMemoryTableWithIndexes - delete table failed');
  end;
  tbl.Free;
end;


procedure TIndexTestD4.TemporaryTableWithIndexes;
var
  tbl: TACRTable;
  i:   Integer;
begin
  tbl := TACRTable.Create(nil);
  tbl.Temporary := True;
  tbl.TableName := 'test';
  try
   tbl.FieldDefs.Clear;
   tbl.FieldDefs.Add('int', ftInteger,0,False);
   tbl.FieldDefs.Add('string', ftString, 500,False);
   tbl.IndexDefs.Clear;
   tbl.IndexDefs.Add('idx1','int',[]);
   tbl.IndexDefs.Add('idx2','int;string',[ixCaseInsensitive]);
   tbl.IndexDefs.Add('idx3','string',[ixUnique,ixCaseInsensitive]);
   if (tbl.Exists) then
    tbl.DeleteTable;
   tbl.CreateTable;
  except
   WriteToErrorLog('TemporaryTableWithIndexes - create table failed');
  end;

  try
   tbl.IndexDefs.Clear;
   tbl.Open;
   if (tbl.IndexDefs.Count <> 3) then
    WriteToErrorLog('TemporaryTableWithIndexes - wrong number of indexes');
   tbl.Close;
  except
   WriteToErrorLog('TemporaryTableWithIndexes - open error');
  end;

  try
   tbl.IndexDefs.Clear;
   tbl.Open;
   tbl.Insert;
   tbl.FieldByName('string').AsString := 'aaa';
   tbl.Post;
   tbl.Insert;
   tbl.FieldByName('string').AsString := 'ccc';
   tbl.Post;
   tbl.Insert;
   tbl.FieldByName('string').AsString := 'bbb';
   tbl.Post;
   tbl.AddIndex('idx4','string',[ixUnique],'string','string');
   tbl.Close;
   tbl.IndexDefs.Clear;
   tbl.Open;
   if (tbl.IndexDefs.Count <> 4) then
    WriteToErrorLog('TemporaryTableWithIndexes - wrong number of indexes');
   tbl.IndexName := 'idx4';
   tbl.First;
   if (tbl.FieldByName('string').AsString <> 'ccc') then
    WriteToErrorLog('TemporaryTableWithIndexes - wrong string desc index order: First');
   tbl.Last;
   if (tbl.FieldByName('string').AsString <> 'aaa') then
    WriteToErrorLog('TemporaryTableWithIndexes - wrong string desc index order: Last');
   tbl.Prior;
   if (tbl.FieldByName('string').AsString <> 'bbb') then
    WriteToErrorLog('TemporaryTableWithIndexes - wrong string desc index order: Prior');
   tbl.Next;
   if (tbl.FieldByName('string').AsString <> 'aaa') then
    WriteToErrorLog('TemporaryTableWithIndexes - wrong string desc index order: Next');

   tbl.Close;
   tbl.IndexName := '';
   tbl.EmptyTable;
   tbl.Open;
   for i:=0 to 100 do
    begin
     tbl.Insert;
     tbl.FieldByName('string').AsString := IntToStr(i);
     tbl.Post;
    end;

   tbl.AddIndex('idx5','string',[ixUnique]);
   tbl.IndexName := 'idx5';
   tbl.First;
   if (tbl.FieldByName('string').AsString <> '0') then
    WriteToErrorLog('TemporaryTableWithIndexes - Node with leaf: First');
   tbl.Next;
   if (tbl.FieldByName('string').AsString <> '1') then
    WriteToErrorLog('TemporaryTableWithIndexes - Node with leaf: Next');
   tbl.Last;
   if (tbl.FieldByName('string').AsString <> '99') then
    WriteToErrorLog('TemporaryTableWithIndexes - Node with leaf: Last');
   tbl.Prior;
   if (tbl.FieldByName('string').AsString <> '98') then
    WriteToErrorLog('TemporaryTableWithIndexes - Node with leaf: Prior');
   tbl.RecNo := tbl.RecordCount;
   if (tbl.FieldByName('string').AsString <> '99') then
    WriteToErrorLog('TemporaryTableWithIndexes - RecNo or RecordCount failed');

   // full cross
   tbl.First;
   while not tbl.Eof do
    tbl.Next;
   if (tbl.RecNo <> tbl.RecordCount) then
    WriteToErrorLog('TemporaryTableWithIndexes - RecNo <> RecCount');
   tbl.Last;
   while not tbl.Bof do
    tbl.Prior;
   if (tbl.RecNo <> 1) then
    WriteToErrorLog('TemporaryTableWithIndexes - RecNo <> 1');

   tbl.DeleteIndex('idx5');
   tbl.IndexName := 'idx4';
   if (tbl.IndexDefs.Count <> 4) then
    WriteToErrorLog('TemporaryTableWithIndexes - wrong number of indexes: delete index');

   tbl.Close;
  except
   WriteToErrorLog('TemporaryTableWithIndexes - exception');
  end;

  try
   tbl.Close;
   tbl.DeleteTable;
  except
   WriteToErrorLog('TemporaryTableWithIndexes - delete table failed');
  end;
  tbl.Free;
end;

procedure TIndexTestD4.CreateTables;
begin
   ACRTable.FieldDefs.Clear;
   ACRTable.FieldDefs.Add('ID', ftAutoInc, 0, false);
   ACRTable.FieldDefs.Add('fInteger', ftInteger, 0, false);
   ACRTable.FieldDefs.Add('fString', ftString, 100, False);
   ACRTable.FieldDefs.Add('fDate', ftDateTime, 0, False);
   ACRTable.FieldDefs.Add('Notes',ftMemo,0,False);
   ACRTable.FieldDefs.Add('fGraphic',ftGraphic,0,False);
   ACRTable.IndexDefs.Clear;
   ACRTable.IndexDefs.Add('ID_key','ID',[ixPrimary,ixUnique]);
   ACRTable.IndexDefs.Add('String_key','fString;fInteger',[ixCaseInsensitive]);
   ACRTable.IndexDefs.Add('Integer_key','fInteger',[ixDescending]);
   ACRTable.IndexDefs.Add('Date_key','fDate',[ixCaseInsensitive]);
   if (ACRTable.Exists) then
    ACRTable.DeleteTable;
   ACRTable.CreateTable;
end;


procedure TIndexTestD4.InsertRecord(tbl: TDataset; RecNo: Integer);
var
  aInt: Integer;
  s: String;
  aDate: TDateTime;
begin
   aInt := 1000;
   s := 'TeSt'+IntToStr(Random(aInt))+IntTostr(RecNo);
   aDate := Now;

//   aaStartTime;
   tbl.Insert;
   tbl.FieldByName('fInteger').AsInteger := aInt;
   tbl.FieldByName('fString').AsString := s;
   tbl.FieldByName('fDate').AsDateTime := aDate;
   tbl.Post;
//aaStopTime;
end;

procedure TIndexTestD4.EditRecord(tbl: TDataset; RecNo: Integer);
var
  aInt: Integer;
  s: String;
begin
   aInt := 1000;
   s := 'TeSt'+IntToStr(Random(aInt))+IntTostr(RecNo);

//   aaStartTime;
   tbl.Edit;
   tbl.FieldByName('fString').AsString := s;
   tbl.Post;
//   aaStopTime;
end;


procedure TIndexTestD4.Insert1(InMemory: Boolean; Temporary: Boolean);
var
  i, RecCount: Integer;
begin
 RecCount := 1000;
 ACRTable := TACRTable.Create(nil);
 try
   ACRTable.TableName := 'test';
   if (InMemory) then
     ACRTable.InMemory := True
   else
     ACRTable.InMemory := False;
   if (Temporary) then
     ACRTable.Temporary := True
   else
     ACRTable.Temporary := False;

   CreateTables;
   ACRTable.Open;

//   aaInitTime;
   for i := 0 to RecCount-1 do
    begin
     InsertRecord(ACRTable, i);
//     InsertRecord(Table, i);
    end;
//   ShowMessage(IntToStr(aaGetTime));

 finally
   ACRTable.Free;
 end;
end;


procedure TIndexTestD4.InsertEdit1(InMemory: Boolean);
var
  i, RecCount: Integer;
begin
 RecCount := 1000;
 ACRTable := TACRTable.Create(nil);
 try
   ACRTable.TableName := 'test';
   if (InMemory) then
     ACRTable.InMemory := True
   else
     ACRTable.InMemory := False;

   CreateTables;
   ACRTable.Open;

//   aaInitTime;
   for i := 0 to RecCount-1 do
    begin
     InsertRecord(ACRTable, i);
//     InsertRecord(Table, i);
    end;
//   ShowMessage(IntToStr(aaGetTime));
   ACRTable.First;
   for i := 0 to RecCount-1 do
    begin
     EditRecord(ACRTable, i);
     ACRTable.Next;
//     EditRecord(Table, i);
    end;

 finally
   ACRTable.Free;
 end;
end;


procedure TIndexTestD4.Inserts1;
begin
  InsertEdit1(True);
  Insert1(True, False);
  Insert1(False, True);
end;


procedure TIndexTestD4.AddInvalidIndex(InMemory: Boolean; Temporary: Boolean);
var
  TestStr: String;
begin
 TestStr := 'AddInvalidIndex-';
 ACRTable := TACRTable.Create(nil);
 try
   ACRTable.TableName := 'test';
   if (InMemory) then
    begin
      TestStr := TestStr + 'memory: ';
      ACRTable.InMemory := True
    end
   else
     ACRTable.InMemory := False;
   if (Temporary) then
    begin
      TestStr := TestStr + 'temporary: ';
      ACRTable.Temporary := True
    end
   else
     ACRTable.Temporary := False;

   ACRTable.FieldDefs.Clear;
   ACRTable.FieldDefs.Add('ID', ftAutoInc, 0, false);
   ACRTable.FieldDefs.Add('fInteger', ftInteger, 0, false);
   ACRTable.FieldDefs.Add('fString', ftString, 100, False);
   ACRTable.FieldDefs.Add('fDate', ftDateTime, 0, False);
   ACRTable.FieldDefs.Add('Notes',ftMemo,0,False);
   ACRTable.FieldDefs.Add('fGraphic',ftGraphic,0,False);
   ACRTable.IndexDefs.Clear;
   ACRTable.IndexDefs.Add('idx1','ID',[ixPrimary,ixUnique]);
   if (ACRTable.Exists) then
    ACRTable.DeleteTable;
   ACRTable.CreateTable;
   try
    ACRTable.AddIndex('idx1', 'ID', []);
    WriteToErrorLog(TestStr+'invalid index accepted #1');
   except
   end;
   try
    ACRTable.AddIndex('idx3', '', []);
    WriteToErrorLog(TestStr+'invalid index accepted #2');
   except
   end;
   try
    ACRTable.AddIndex('', 'ID', []);
    WriteToErrorLog(TestStr+'invalid index accepted #3');
   except
   end;
   try
    ACRTable.AddIndex('idx4', 'non existing field', []);
    WriteToErrorLog(TestStr+'invalid index accepted #4');
   except
   end;
 finally
   ACRTable.Free;
 end;
end;


procedure TIndexTestD4.CreateTableWithInvalidIndex(InMemory: Boolean; Temporary: Boolean);
var
  TestStr: String;
begin
 TestStr := 'CreateTableWithInvalidIndex-';
 ACRTable := TACRTable.Create(nil);
 try
   ACRTable.TableName := 'test';
   if (InMemory) then
    begin
      TestStr := TestStr + 'memory: ';
      ACRTable.InMemory := True
    end
   else
     ACRTable.InMemory := False;
   if (Temporary) then
    begin
      TestStr := TestStr + 'temporary: ';
      ACRTable.Temporary := True
    end
   else
     ACRTable.Temporary := False;

   ACRTable.FieldDefs.Clear;
   ACRTable.FieldDefs.Add('ID', ftAutoInc, 0, false);

   try
    ACRTable.IndexDefs.Clear;
    ACRTable.IndexDefs.Add('idx1','ID',[ixPrimary,ixUnique]);
    ACRTable.IndexDefs.Add('idx1','ID',[]);
    ACRTable.CreateTable;
    WriteToErrorLog(TestStr+'invalid index accepted #1');
   except
   end;
   try
    ACRTable.IndexDefs.Clear;
    ACRTable.IndexDefs.Add('idx3', '', []);
    ACRTable.CreateTable;
    WriteToErrorLog(TestStr+'invalid index accepted #2');
   except
   end;
   try
    ACRTable.IndexDefs.Clear;
    ACRTable.IndexDefs.Add('', 'ID', []);
    ACRTable.CreateTable;
    WriteToErrorLog(TestStr+'invalid index accepted #3');
   except
   end;
   try
    ACRTable.IndexDefs.Clear;
    ACRTable.IndexDefs.Add('idx4', 'non existing field', []);
    ACRTable.CreateTable;
    WriteToErrorLog(TestStr+'invalid index accepted #4');
   except
   end;
 finally
   ACRTable.Free;
 end;
end;


procedure TIndexTestD4.TwoTableComponentsWithIndexes;
var
  ACRTable1, ACRTable2: TACRTable;
begin
  ACRTable1 := TACRTable.Create(nil);
  ACRTable2 := TACRTable.Create(nil);
  try
    ACRTable1.TableName := 'Test';
    ACRTable1.InMemory := True;
    ACRTable1.FieldDefs.Clear;
    ACRTable1.FieldDefs.Add('fString', ftString, 100, False);
    ACRTable1.IndexDefs.Clear;
    ACRTable1.CreateTable;
    ACRTable1.Open;

    ACRTable2.TableName := 'test';
    ACRTable2.InMemory := True;
    ACRTable2.Open;

    ACRTable1.AddIndex('idx1', 'fString', [ixDescending]);
    ACRTable2.IndexName := 'idx1';
    if (ACRTable2.IndexDefs.Count <> 1) then
     WriteToErrorLog('TIndexTestD4.TwoTableComponentsWithIndexes - #1');

  finally
    ACRTable1.Free;
    ACRTable2.Free;
  end;
end;


procedure TIndexTestD4.CreateAllFiledsTables;
begin
   // Accuracer
   ACRTable.FieldDefs.Clear;
   ACRTable.FieldDefs.Add('id', ftAutoInc, 0, False);
   ACRTable.FieldDefs.Add('fString', ftString, 100, False);
   ACRTable.FieldDefs.Add('fSmallint', ftSmallint, 0, False);
   ACRTable.FieldDefs.Add('fInteger', ftInteger, 0, False);
   ACRTable.FieldDefs.Add('fWord', ftWord, 0, False);
   ACRTable.FieldDefs.Add('fBoolean', ftBoolean, 0, False);
   ACRTable.FieldDefs.Add('fFloat', ftFloat, 0, False);
   ACRTable.FieldDefs.Add('fCurrency', ftCurrency, 0, False);
   ACRTable.FieldDefs.Add('fDate', ftDate, 0, False);
   ACRTable.FieldDefs.Add('fTime', ftTime, 0, False);
   ACRTable.FieldDefs.Add('fDateTime', ftDateTime, 0, False);
   ACRTable.FieldDefs.Add('fFixedChar', ftFixedChar, 50, False);

   ACRTable.IndexDefs.Clear;
   ACRTable.IndexDefs.Add('idxString1','fString',[ixDescending]);
   ACRTable.IndexDefs.Add('idxString2','fString',[ixCaseInsensitive]);
   ACRTable.IndexDefs.Add('idxSmallint','fSmallint',[ixCaseInsensitive]);
   ACRTable.IndexDefs.Add('idxInteger','fInteger',[]);
   ACRTable.IndexDefs.Add('idxWord','fWord',[]);
   ACRTable.IndexDefs.Add('idxBoolean','fBoolean',[]);
   ACRTable.IndexDefs.Add('idxFloat','fFloat',[]);
   ACRTable.IndexDefs.Add('idxCurrency','fCurrency',[]);
   ACRTable.IndexDefs.Add('idxDate','fDate',[]);
   ACRTable.IndexDefs.Add('idxTime','fTime',[]);
   ACRTable.IndexDefs.Add('idxDateTime','fDateTime',[]);
   ACRTable.IndexDefs.Add('idxFixedChar','fFixedChar',[ixDescending]);
   if (ACRTable.Exists) then
    ACRTable.DeleteTable;
   ACRTable.CreateTable;

   // Paradox
   Table.FieldDefs.Clear;
   Table.FieldDefs.Add('id', ftAutoInc, 0, False);
   Table.FieldDefs.Add('fString', ftString, 100, False);
   Table.FieldDefs.Add('fSmallint', ftSmallint, 0, False);
   Table.FieldDefs.Add('fInteger', ftInteger, 0, False);
   Table.FieldDefs.Add('fWord', ftWord, 0, False);
   Table.FieldDefs.Add('fBoolean', ftBoolean, 0, False);
   Table.FieldDefs.Add('fFloat', ftFloat, 0, False);
   Table.FieldDefs.Add('fCurrency', ftCurrency, 0, False);
   Table.FieldDefs.Add('fDate', ftDate, 0, False);
   Table.FieldDefs.Add('fTime', ftTime, 0, False);
   Table.FieldDefs.Add('fDateTime', ftDateTime, 0, False);
   Table.FieldDefs.Add('fFixedChar', ftFixedChar, 50, False);

   Table.IndexDefs.Clear;
   Table.IndexDefs.Add('idx','id',[ixPrimary]);
   Table.IndexDefs.Add('idxString1','fString',[ixDescending]);
   Table.IndexDefs.Add('idxString2','fString',[ixCaseInsensitive]);
   Table.IndexDefs.Add('idxSmallint','fSmallint',[ixCaseInsensitive]);
   Table.IndexDefs.Add('idxWord','fWord',[ixCaseInsensitive]);
   Table.IndexDefs.Add('idxInteger','fInteger',[ixCaseInsensitive]);
   Table.IndexDefs.Add('idxBoolean','fBoolean',[ixCaseInsensitive]);
   Table.IndexDefs.Add('idxFloat','fFloat',[ixCaseInsensitive]);
   Table.IndexDefs.Add('idxCurrency','fCurrency',[ixCaseInsensitive]);
   Table.IndexDefs.Add('idxDate','fDate',[ixCaseInsensitive]);
   Table.IndexDefs.Add('idxTime','fTime',[ixCaseInsensitive]);
   Table.IndexDefs.Add('idxDateTime','fDateTime',[ixCaseInsensitive]);
   Table.IndexDefs.Add('idxFixedChar','fFixedChar',[ixDescending]);
   
   if (Table.Exists) then
    Table.DeleteTable;
   Table.CreateTable;
end;


procedure TIndexTestD4.CompareTablesWithIndex(IndexName: String; CompareFieldName: String);
begin
   ACRTable.IndexName := IndexName;
   Table.IndexName := IndexName;
   CompareTables(IndexName, ACRTable, Table, CompareFieldName);
end;


procedure TIndexTestD4.CompareTables(Caption: String; Table1, Table2: TDataset; CompareFieldName: String);
var
  i:          Integer;
  bError:     Boolean;
begin
 if (Table1.BOF <> Table2.BOF) then
  WriteToErrorLog(Caption+' failed #1, BOF = '
    +IntToStr(Word(Table1.BOF))+', BDE BOF = '+IntToStr(Word(Table2.BOF)));
 if (Table1.EOF <> Table2.EOF) then
  WriteToErrorLog(Caption+' failed #2, EOF = '
    +IntToStr(Word(Table1.EOF))+', BDE EOF = '+IntToStr(Word(Table2.EOF)));
 if (Table1.RecordCount <> Table2.RecordCount) then
  WriteToErrorLog(Caption+' failed #3, record count = '
    +IntToStr(Table1.RecordCount)+', BDE record count = '+IntToStr(Table2.RecordCount));
 if (Table1.FieldDefs.Count <> Table2.FieldDefs.Count) then
  WriteToErrorLog(Caption+' failed #4, fielddefs count = '
    +IntToStr(Table1.FieldDefs.Count)+', BDE fielddefs count = '+IntToStr(Table2.FieldDefs.Count));
 if (Table1.FieldCount <> Table2.FieldCount) then
  WriteToErrorLog(Caption+' failed #5, field count = '
    +IntToStr(Table1.FieldCount)+', BDE field count = '+IntToStr(Table2.FieldCount))
 else
  begin
   for i := 0 to Table1.FieldDefs.Count - 1 do
    begin
     if (Table1.FieldDefs[i].Name <> Table2.FieldDefs[i].Name) then
      WriteToErrorLog(Caption+' failed #6, field name = ' +
        Table1.FieldDefs[i].Name + ', BDE field name = '+Table2.FieldDefs[i].Name);


     if (Table1.FieldDefs[i].DataType <> Table2.FieldDefs[i].DataType) then
      if (not (Table1.FieldDefs[i].DataType = ftFixedChar) and
              (Table1.FieldDefs[i].DataType = ftString)) then
      WriteToErrorLog(Caption+' failed #7, field type = ' +
        IntToStr(Integer(Table1.FieldDefs[i].DataType)) + ', BDE field type = '+
        IntToStr(Integer(Table2.FieldDefs[i].DataType)));

     if (Table1.FieldDefs[i].Size <> Table2.FieldDefs[i].Size) then
      WriteToErrorLog(Caption+' failed #8, field size = ' +
        IntToStr(Integer(Table1.FieldDefs[i].Size)) + ', BDE field size = '+
        IntToStr(Integer(Table2.FieldDefs[i].Size)));
{
     if (Table1.FieldDefs[i].Required <> Table2.FieldDefs[i].Required) then
      WriteToErrorLog(Caption+' failed #9, field required = ' +
        IntToStr(Integer(Table1.FieldDefs[i].Required)) + ', BDE field required = '+
        IntToStr(Integer(Table2.FieldDefs[i].Required)));
}
    end;
  end;
 Table1.First;
 Table2.First;
 bError := False;
 while (not Table2.Eof) do
  begin
    if (Table1.FieldByName(CompareFieldName).IsNull <> Table2.FieldByName(CompareFieldName).IsNull) then
     begin
       WriteToErrorLog(Caption+' failed #xx, ACR null flag = ' +
         IntToStr(Word(Table1.FieldByName(CompareFieldName).IsNull)) + ', BDE null flag = '+
         IntToStr(Word(Table2.FieldByName(CompareFieldName).IsNull)));
       bError := True;
     end
    else
     begin
      if (not Table1.FieldByName(CompareFieldName).IsNull) then
       if  (Table1.FieldByName(CompareFieldName).AsString <>
            Table2.FieldByName(CompareFieldName).AsString) then
        begin
         WriteToErrorLog(Caption+' failed #10, field  value = ' +
           Table1.FieldByName(CompareFieldName).AsString + ', BDE field value = '+
           Table2.FieldByName(CompareFieldName).AsString);
         bError := True;
        end;
     end;
   if (bError) then
    break;
   Table1.Next;
   Table2.Next;
  end;
 if (Table1.EOF <> Table2.EOF) then
  WriteToErrorLog(Caption+' failed #12, EOF = '
    +IntToStr(Word(Table1.EOF))+', BDE EOF = '+IntToStr(Word(Table2.EOF)));
end;


procedure TIndexTestD4.GenerateAllFieldsRecord(var rec: TTestRecord);
begin
  rec.vString := 's'+GenerateString(10+Random(90));
  rec.vSmallint := Random(abs(Low(SmallInt))+High(Smallint))-abs(Low(SmallInt));
  if ((Random(MaxInt) mod 2) = 0) then
    rec.vInteger := Random(MaxInt)
  else
    rec.vInteger := -Random(MaxInt);
  rec.vWord := Random(abs(Low(Word))+High(Word))-abs(Low(Word));
  rec.vBoolean := Boolean(Random(2));
  rec.vFloat := Random(High(Integer))+
                1/(1+Random(High(Word)));

  if ((Random(MaxInt) mod 2) = 0) then
   rec.vCurrency := Random(High(Integer))+1/(1+Random(High(Integer)))
  else
   rec.vCurrency := -(Random(High(Integer))+1/(1+Random(High(Integer))));
  rec.vDate := GenerateRandomDateTime;
  rec.vTime := GenerateRandomDateTime;
  rec.vDateTime := GenerateRandomDateTime;
  rec.vFixedChar := 's'+GenerateString(Random(50));
end;


procedure TIndexTestD4.InsertAllFieldsRecord(rec: TTestRecord; tbl: TDataset);
begin
  tbl.Insert;

  tbl.FieldByName('fString').AsString := rec.vString;
  tbl.FieldByName('fSmallInt').Value := rec.vSmallInt;
  tbl.FieldByName('fInteger').Value := rec.vInteger;
  tbl.FieldByName('fWord').Value := rec.vWord;
  tbl.FieldByName('fBoolean').Value := rec.vBoolean;
  tbl.FieldByName('fFloat').Value := rec.vFloat;
  tbl.FieldByName('fCurrency').Value := rec.vCurrency;
  tbl.FieldByName('fDate').Value := rec.vDate;
  tbl.FieldByName('fTime').Value := rec.vTime;
  tbl.FieldByName('fDateTime').Value := rec.vDateTime;
  tbl.FieldByName('fFixedChar').Value := rec.vFixedChar;

  tbl.Post;
end;


procedure TIndexTestD4.CheckIndexOrder1(InMemory: Boolean; Temporary: Boolean);
var
  i, RecCount: Integer;
  rec: TTestRecord;

begin
 RecCount := 1000;
 ACRTable := TACRTable.Create(nil);
 Table := TTable.Create(nil);
 try
   Table.DatabaseName := TempDir;
   Table.TableName := 'test';
   ACRTable.TableName := 'test';
   if (InMemory) then
     ACRTable.InMemory := True
   else
     ACRTable.InMemory := False;
   if (Temporary) then
     ACRTable.Temporary := True
   else
     ACRTable.Temporary := False;

   CreateAllFiledsTables;
   ACRTable.Open;
   Table.Open;

   // insert nulls
   ACRTable.Insert;
   ACRTable.Post;
   Table.Insert;
   Table.Post;

//   aaInitTime;
   for i := 0 to RecCount-1 do
    begin
     GenerateAllFieldsRecord(rec);
     InsertAllFieldsRecord(rec, Table);
     InsertAllFieldsRecord(rec, ACRTable);
    end;
//   ShowMessage(IntToStr(aaGetTime));

   CompareTablesWithIndex('idxString1','fString');
   CompareTablesWithIndex('idxString2','fString');
   CompareTablesWithIndex('idxSmallint','fSmallInt');
   CompareTablesWithIndex('idxInteger','fInteger');
   CompareTablesWithIndex('idxWord','fWord');
   CompareTablesWithIndex('idxBoolean','fBoolean');
   CompareTablesWithIndex('idxFloat','fFloat');
   CompareTablesWithIndex('idxCurrency','fCurrency');
   CompareTablesWithIndex('idxDate','fDate');
   CompareTablesWithIndex('idxTime','fTime');
   CompareTablesWithIndex('idxDateTime','fDateTime');
   CompareTablesWithIndex('idxFixedChar','fFixedChar');

 finally
   ACRTable.Free;
   Table.Free;
 end;
end;


procedure TIndexTestD4.CheckIndexOrder;
begin
  CheckIndexOrder1(True, False);
  CheckIndexOrder1(False, True);
end;


procedure TIndexTestD4.InvalidIndexParamsCheck;
begin
  AddInvalidIndex(True, False);
  AddInvalidIndex(False, True);
  CreateTableWithInvalidIndex(True, False);
  CreateTableWithInvalidIndex(False, True);
end;


procedure TIndexTestD4.TestShort;
begin
  CheckAction(InMemoryTableWithIndexes, 'InMemoryTableWithIndexes');
  CheckAction(TemporaryTableWithIndexes, 'TemporaryTableWithIndexes');
  CheckAction(TwoTableComponentsWithIndexes, 'TwoTableComponentsWithIndexes');
  CheckAction(Inserts1, 'Inserts1');
  CheckAction(CheckIndexOrder, 'CheckIndexOrder');

end;

procedure TIndexTestD4.TestExceptions;
begin
  CheckAction(InvalidIndexParamsCheck, 'InvalidIndexParamsCheck');
end;


{$IFNDEF D6H}
initialization
  IndexTest := TIndexTestD4.Create(UnitTestList);

finalization
  IndexTest.Free;

{$ENDIF}

end.

