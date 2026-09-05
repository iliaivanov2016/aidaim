unit utDefaultValue;

interface

{$I UTConfig.Inc}

uses uTestList,
     ACRBase,
     ACRTypes,
     ACRMain,
{$IFDEF ACR5H}
  ACRComMain,
{$ENDIF}
     DB,
     SysUtils
     ;

type
  TUnitTestDefaultValue = class(TUnitTest)
   public
    procedure TestShort; override;
    procedure TestExceptions; override;
   private
    procedure DropTable(Table: TACRTable);
    function CreateTableWithoutDefaultValue: TACRTable;
    function CreateTableWithDefaultValueConst: TACRTable;
    function CreateTableWithDefaultValueConstAndBadConstraint: TACRTable;
    function CreateTableWithDefaultValueSequence: TACRTable;
    function CreateTableWithAutoinc: TACRTable;
   public
    procedure InternalTestWithoutDefaultValue;
    procedure InternalTestDefaultValueConst;
    procedure InternalTestDefaultValueSequence;
    procedure InternalTestAutoinc;
    procedure InternalTestDefaultValueAndBadConstraint;
  end;

var
  UnitTestDefaultValue: TUnitTestDefaultValue;

implementation

uses Math;

{ TUnitTestDefaultValue }


procedure TUnitTestDefaultValue.TestShort;
begin
  CheckAction(InternalTestWithoutDefaultValue, 'Test No DefaultValue');
  CheckAction(InternalTestDefaultValueConst, 'Test DefaultValue Const');
  CheckAction(InternalTestDefaultValueSequence, 'Test DefaultValue Sequence');
  CheckAction(InternalTestAutoinc, 'Test Autoinc');
end;


procedure TUnitTestDefaultValue.TestExceptions;
begin
  CheckAction(InternalTestDefaultValueAndBadConstraint, 'Test Constraint incompatiblre with default value');
end;

procedure TUnitTestDefaultValue.DropTable(Table: TACRTable);
begin
  UnitTestList.WriteToProcessLog('Drop Table');
  Table.Close;
  if (Table.Exists) then
   Table.DeleteTable(True);
  Table.Free;
  UnitTestList.WriteToProcessLog('Ok.');
end;


function TUnitTestDefaultValue.CreateTableWithoutDefaultValue: TACRTable;
begin
  UnitTestList.WriteToProcessLog('Create Table Without DefaultValues');

  Result := TACRTable.Create(nil);
  Result.TableName := 'test';
  Result.InMemory := True;

  // Fill Defs
  Result.AdvFieldDefs.Clear;
  with Result.AdvFieldDefs.AddFieldDef do begin
    Name := 'Field1';
    DataType := aftInteger;
  end;
  with Result.AdvFieldDefs.AddFieldDef do begin
    Name := 'Field2';
    DataType := aftSmallint;
    //DefaultValue.AsSmallint := 1234 ;
  end;
  if (Result.Exists) then
    Result.DeleteTable;
  Result.CreateTable;

  UnitTestList.WriteToProcessLog('Ok.');
end;

function TUnitTestDefaultValue.CreateTableWithAutoinc: TACRTable;
begin
  UnitTestList.WriteToProcessLog('Create Table With Autoinc');

  Result := TACRTable.Create(nil);
  Result.TableName := 'test';
  Result.InMemory := True;

  // Fill Defs
  Result.AdvFieldDefs.Clear;
  with Result.AdvFieldDefs.AddFieldDef do begin
    Name := 'Field1';
    DataType := aftAutoInc;
    //DefaultValue.AsSmallint := 1234 ;
  end;
  with Result.AdvFieldDefs.AddFieldDef do begin
    Name := 'Field2';
    DataType := aftSmallint;
  end;
  if (Result.Exists) then
    Result.DeleteTable;
  Result.CreateTable;

  UnitTestList.WriteToProcessLog('Ok.');
end;


function TUnitTestDefaultValue.CreateTableWithDefaultValueConst: TACRTable;
begin
  UnitTestList.WriteToProcessLog('Create Table With Const DefaultValue');

  Result := TACRTable.Create(nil);
  Result.TableName := 'test';
  Result.InMemory := True;

  // Fill Defs
  Result.AdvFieldDefs.Clear;
  with Result.AdvFieldDefs.AddFieldDef do begin
    Name := 'Field1';
    DataType := aftInteger;
    //DefaultValueType := dvtConst;
    DefaultValue.AsInteger := 12345;
  end;
  with Result.AdvFieldDefs.AddFieldDef do begin
    Name := 'Field2';
    DataType := aftSmallint;
  end;
  if (Result.Exists) then
    Result.DeleteTable;
  Result.CreateTable;

  UnitTestList.WriteToProcessLog('Ok.');
end;


function TUnitTestDefaultValue.CreateTableWithDefaultValueConstAndBadConstraint: TACRTable;
begin
  UnitTestList.WriteToProcessLog('Create Table With Const DefaultValue and noncompatible Constraint');

  Result := TACRTable.Create(nil);
  Result.TableName := 'test';
  Result.InMemory := True;

  // Fill Defs
  Result.AdvFieldDefs.Clear;
  with Result.AdvFieldDefs.AddFieldDef do begin
    Name := 'Field1';
    DataType := aftInteger;
    //DefaultValueType := dvtConst;
    DefaultValue.AsInteger := 12345;
    MaxValue.AsInteger := 10;
  end;
  with Result.AdvFieldDefs.AddFieldDef do begin
    Name := 'Field2';
    DataType := aftSmallint;
  end;
  if (Result.Exists) then
    Result.DeleteTable;
  Result.CreateTable;

  UnitTestList.WriteToProcessLog('Ok.');
end;


function TUnitTestDefaultValue.CreateTableWithDefaultValueSequence: TACRTable;
begin
  UnitTestList.WriteToProcessLog('Create Table With Default Value Sequence');

  Result := TACRTable.Create(nil);
  Result.TableName := 'test';
  Result.InMemory := True;

  //Result.Fields[0].AsVariant.
  // Fill Defs
  Result.AdvFieldDefs.Clear;
  with Result.AdvFieldDefs.AddFieldDef do begin
    Name := 'Field1';
    DataType := aftAutoIncSmallint;
    //DefaultValueType := dvtSequence;
    //SequenceName := 'Sequence_1';
  end;
  with Result.AdvFieldDefs.AddFieldDef do begin
    Name := 'Field2';
    DataType := aftSmallint;
  end;
  if (Result.Exists) then
    Result.DeleteTable;
  Result.CreateTable;

  UnitTestList.WriteToProcessLog('Ok.');
end;


procedure TUnitTestDefaultValue.InternalTestWithoutDefaultValue;
var
  t: TACRTable;
begin
  t := CreateTableWithoutDefaultValue;
  try
    t.Open;

    // Insert Record with Null
    t.Insert;
    t.Fields[1].AsInteger := 123;
    t.Post;

    // Check Null
    t.First;
    if (not t.Fields[0].IsNull) then
      raise Exception.Create('Inserted ''Null'' not found.');

    UnitTestList.WriteToProcessLog('No Default value worked properly.');
  finally
    DropTable(t);
  end;
end;



procedure TUnitTestDefaultValue.InternalTestDefaultValueConst;
var
  t: TACRTable;
begin
  t := CreateTableWithDefaultValueConst;
  try
    t.Open;

    // Insert Record with Null
    t.Insert;
    t.Fields[1].AsInteger := 123;
    t.Post;

    // Check Default Value
    t.First;
    if (t.Fields[0].AsInteger <> 12345) then
      raise Exception.Create('Wanted ''12345'' Default Value');
    UnitTestList.WriteToProcessLog('Default Value Const worked properly.');
  finally
    DropTable(t);
  end;
end;


procedure TUnitTestDefaultValue.InternalTestDefaultValueSequence;
var
  t: TACRTable;
begin
  t := CreateTableWithDefaultValueSequence;
  try
    t.Open;

    // Insert Record without filling Sequence field
    t.Insert;
    t.Fields[1].AsInteger := 123;
    t.Post;

    t.Insert;
    t.Fields[1].AsInteger := 12;
    t.Post;

    // Check Sequence Field[0] = 2
    t.First;
    t.Next;
    if (t.Fields[0].AsInteger <> 2) then
      raise Exception.Create('Default Value = ''sequence'' not worked');

   UnitTestList.WriteToProcessLog('Default Value = ''sequence'' worked properly.');
  finally
    DropTable(t);
  end;
end;


procedure TUnitTestDefaultValue.InternalTestAutoinc;
var
  t: TACRTable;
begin
  t := CreateTableWithAutoinc;
  try
    t.Open;

    // Insert Record without filling Sequence field
    t.Insert;
    t.Fields[1].AsInteger := 123;
    t.Post;

    t.Insert;
    t.Fields[1].AsInteger := 12;
    t.Post;

    // Check Sequence Field[0] = 2
    t.First;
    t.Next;
    if (t.Fields[0].AsInteger <> 2) then
      raise Exception.Create('Default Value = ''Autoinc'' not worked');

   UnitTestList.WriteToProcessLog('Autoinc worked properly.');
  finally
    DropTable(t);
  end;
end;


procedure TUnitTestDefaultValue.InternalTestDefaultValueAndBadConstraint;
var
  t: TACRTable;
begin
  t := CreateTableWithDefaultValueConstAndBadConstraint;
  try
    t.Open;
    try
      // Insert Record with Null
      t.Insert;
      t.Fields[1].AsInteger := 123;
      t.Post;
      raise Exception.Create('Constraints with incompatible defult value not worked.');
    except
      on e: Exception do
       UnitTestList.WriteToProcessLog('Constraints with incompatible defult value worked. ErrorText: ' + e.Message);
    end;
  finally
    DropTable(t);
  end;
end;


initialization
  UnitTestDefaultValue := TUnitTestDefaultValue.Create(UnitTestList);

finalization
  UnitTestDefaultValue.Free;

end.
