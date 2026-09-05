unit utBasicComponentsTest;

interface

{$I UTConfig.Inc}

uses uTestList, SysUtils, DB,
{$IFDEF MSWINDOWS}
Dialogs,
{$ENDIF}
{$IFDEF ACR5H}
     ACRComMain,
{$ENDIF}
     ACRMain;

type
  TBasicComponentsTest = class(TUnitTest)
   public
    procedure CreateDeleteInMemoryTable;
    procedure Create2InMemoryTables;
    procedure OpenCloseInMemoryTable;

    procedure TestShort; override;
    procedure TestExceptions; override;
  end;

var
  BasicComponentsTest: TBasicComponentsTest;

implementation

procedure TBasicComponentsTest.CreateDeleteInMemoryTable;
var
  tbl1: TACRTable;
begin
  tbl1 := TACRTable.Create(nil);
  tbl1.InMemory := True;
  tbl1.TableName := 'test1';
  try
   tbl1.FieldDefs.Clear;
   tbl1.FieldDefs.Add('int', ftInteger,0,False);
   tbl1.FieldDefs.Add('string', ftString,20,False);
   tbl1.CreateTable;
  except
   WriteToErrorLog('CreateDeleteInMemoryTable - create table failed');
  end;
  try
   tbl1.DeleteTable;
  except
   WriteToErrorLog('CreateDeleteInMemoryTable - delete table failed');
  end;
  tbl1.Free;
end;


procedure TBasicComponentsTest.Create2InMemoryTables;
var
  tbl1,tbl2: TACRTable;
begin
  tbl1 := TACRTable.Create(nil);
  tbl2 := TACRTable.Create(nil);
  tbl1.InMemory := True;
  tbl2.InMemory := True;
  tbl1.TableName := 'test1';
  tbl2.TableName := 'test2';
  try
   tbl1.FieldDefs.Clear;
   tbl2.FieldDefs.Clear;
   tbl1.FieldDefs.Add('int', ftInteger,0,False);
   tbl2.FieldDefs.Add('int', ftInteger,0,False);
   tbl1.FieldDefs.Add('string', ftString,20,False);
   tbl2.FieldDefs.Add('string', ftString,20,False);
   tbl1.CreateTable;
   tbl2.CreateTable;
  except
   WriteToErrorLog('Create2InMemoryTables - create table failed');
  end;
  try
   tbl1.DeleteTable;
   tbl2.DeleteTable;
  except
   WriteToErrorLog('Create2InMemoryTables - delete table failed');
  end;
  tbl1.Free;
  tbl2.Free;
end;




procedure TBasicComponentsTest.OpenCloseInMemoryTable;
var
  tbl: TACRTable;
begin
  tbl := TACRTable.Create(nil);
  tbl.InMemory := True;
  tbl.TableName := 'test';

  try
   tbl.FieldDefs.Clear;
   tbl.FieldDefs.Add('int', ftInteger,0,False);
   tbl.FieldDefs.Add('string', ftString,20,False);
   if (Tbl.Exists) then
    tbl.DeleteTable;
   tbl.CreateTable;
  except
   WriteToErrorLog('OpenCloseInMemoryTable - create table failed');
  end;

  try
   tbl.Open;
  except
   WriteToErrorLog('OpenCloseInMemoryTable - open table failed');
  end;

  try
   tbl.Close;
  except
   WriteToErrorLog('OpenCloseInMemoryTable - close table failed');
  end;

  try
   tbl.Open;
   tbl.Close;
  except
   WriteToErrorLog('OpenCloseInMemoryTable - reopen table failed');
  end;

  try
   tbl.DeleteTable;
  except
   WriteToErrorLog('OpenCloseInMemoryTable - delete table failed');
  end;
  try
   tbl.Close;
  except
   WriteToErrorLog('OpenCloseInMemoryTable - close after delete table failed');
  end;

  // now open will create in-memory table
  {
  try
   tbl.Open;
   WriteToErrorLog('OpenCloseInMemoryTable - deleted table can be open');
  except
  end;
  }
  tbl.Free;
end;

procedure TBasicComponentsTest.TestShort;
begin
  CheckAction(CreateDeleteInMemoryTable, 'CreateDeleteInMemoryTable');
  CheckAction(Create2InMemoryTables, 'Create2InMemoryTables');
end;

procedure TBasicComponentsTest.TestExceptions;
begin
  CheckAction(OpenCloseInMemoryTable, 'OpenCloseInMemoryTable');
end;

initialization
  BasicComponentsTest := TBasicComponentsTest.Create(UnitTestList);

finalization
  BasicComponentsTest.Free;

end.

