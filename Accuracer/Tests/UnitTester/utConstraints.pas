unit utConstraints;

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
  TUnitTestConstraints = class(TUnitTest)
   public
    procedure TestShort; override;
    procedure TestExceptions; override;
   private
    procedure DropTable(Table: TACRTable);
    function CreateTableWithoutConstraints: TACRTable;
    function CreateTableWithConstraintNotNull: TACRTable;
    function CreateTableWithConstraintCheck: TACRTable;
    function CreateTableWithConstraintPK: TACRTable;
    function CreateTableWithConstraintPKMultiple: TACRTable;
    function CreateTableWithConstraintUnique: TACRTable;
   public
    procedure InternalTestWithoutConstraints;
    procedure InternalTestNotNull;
    procedure InternalTestCheck;
    procedure InternalTestPK;
    procedure InternalTestPKMultiple;
    procedure InternalTestUnique;
  end;

var
  UnitTestConstraints: TUnitTestConstraints;


implementation


{ TUnitTestConstraints }

procedure TUnitTestConstraints.TestShort;
begin
  CheckAction(InternalTestWithoutConstraints, 'Test without constraints');
end;


procedure TUnitTestConstraints.TestExceptions;
begin
  CheckAction(InternalTestNotNull, 'Test constraint NotNull');
  CheckAction(InternalTestCheck, 'Test constraint Check (Min Max)');
  CheckAction(InternalTestPK, 'Test constraint PK');
  CheckAction(InternalTestPKMultiple, 'Test constraint PK_Multiple');
  CheckAction(InternalTestUnique, 'Test constraint Unique');
end;



procedure TUnitTestConstraints.DropTable(Table: TACRTable);
begin
  UnitTestList.WriteToProcessLog('Drop Table');
  Table.Close;
  if (Table.Exists) then
   Table.DeleteTable(True);
  Table.Free;
  UnitTestList.WriteToProcessLog('Ok.');
end;



function TUnitTestConstraints.CreateTableWithoutConstraints: TACRTable;
begin
  UnitTestList.WriteToProcessLog('Create Table Without Constraints');

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
    DefaultValue.AsSmallint := 1234 ;
    //Required := true;
  end;
  if (Result.Exists) then
    Result.DeleteTable;
  Result.CreateTable;

  UnitTestList.WriteToProcessLog('Ok.');
end;


function TUnitTestConstraints.CreateTableWithConstraintNotNull: TACRTable;
begin
  UnitTestList.WriteToProcessLog('Create Table With Constraint NotNull');

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
    Required := true;
  end;
  if (Result.Exists) then
    Result.DeleteTable;
  Result.CreateTable;

  UnitTestList.WriteToProcessLog('Ok.');
end;




function TUnitTestConstraints.CreateTableWithConstraintCheck: TACRTable;
begin
  UnitTestList.WriteToProcessLog('Create Table With Constraint Check (Min=10 Max=20 for Field1');

  Result := TACRTable.Create(nil);
  Result.TableName := 'test';
  Result.InMemory := True;

  // Fill Defs
  Result.AdvFieldDefs.Clear;
  with Result.AdvFieldDefs.AddFieldDef do begin
    Name := 'Field1';
    DataType := aftInteger;
    MinValue.AsInteger := 10;
    MaxValue.AsInteger := 20;
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


function TUnitTestConstraints.CreateTableWithConstraintPK: TACRTable;
begin
  UnitTestList.WriteToProcessLog('Create Table With Constraint PK');

  Result := TACRTable.Create(nil);
  Result.TableName := 'test';
  Result.InMemory := True;

  // Fill Defs
  Result.AdvFieldDefs.Clear;
  with Result.AdvFieldDefs.AddFieldDef do begin
    Name := 'id';
    DataType := aftInteger;
  end;
  with Result.AdvFieldDefs.AddFieldDef do begin
    Name := 'Field2';
    DataType := aftSmallint;
  end;

  Result.IndexDefs.Add('PK', 'id', [ixPrimary]);

  if (Result.Exists) then
    Result.DeleteTable;

  Result.CreateTable;

  UnitTestList.WriteToProcessLog('Ok.');
end;


function TUnitTestConstraints.CreateTableWithConstraintPKMultiple: TACRTable;
begin
  UnitTestList.WriteToProcessLog('Create Table With Constraint PK Multiple');

  Result := TACRTable.Create(nil);
  Result.TableName := 'test';
  Result.InMemory := True;

  // Fill Defs
  Result.AdvFieldDefs.Clear;
  with Result.AdvFieldDefs.AddFieldDef do begin
    Name := 'id';
    DataType := aftInteger;
  end;
  with Result.AdvFieldDefs.AddFieldDef do begin
    Name := 'num';
    DataType := aftInteger;
  end;

  Result.IndexDefs.Add('PK_Multiple', 'id;num', [ixPrimary]);

  if (Result.Exists) then
    Result.DeleteTable;

  Result.CreateTable;

  UnitTestList.WriteToProcessLog('Ok.');
end;



function TUnitTestConstraints.CreateTableWithConstraintUnique: TACRTable;
begin
  UnitTestList.WriteToProcessLog('Create Table With Constraint PK');

  Result := TACRTable.Create(nil);
  Result.TableName := 'test';
  Result.InMemory := True;

  // Fill Defs
  Result.AdvFieldDefs.Clear;
  with Result.AdvFieldDefs.AddFieldDef do begin
    Name := 'id';
    DataType := aftInteger;
  end;
  with Result.AdvFieldDefs.AddFieldDef do begin
    Name := 'Field2';
    DataType := aftSmallint;
  end;

  Result.IndexDefs.Add('PK', 'id', [ixUnique]);

  if (Result.Exists) then
    Result.DeleteTable;

  Result.CreateTable;

  UnitTestList.WriteToProcessLog('Ok.');
end;




procedure TUnitTestConstraints.InternalTestWithoutConstraints;
var
  t: TACRTable;
begin
  t := CreateTableWithoutConstraints;
  try
    t.Open;
    t.Insert;
    t.Fields[0].AsInteger := Random(MaxInt);
    // Field[1] is not set no Exception...
    t.Post;
  finally
    DropTable(t);
  end;
end;



procedure TUnitTestConstraints.InternalTestNotNull;
var
  t: TACRTable;
begin
  t := CreateTableWithConstraintNotNull;
  try
    t.Open;
    try
     t.Insert;
     t.Fields[0].AsInteger := Random(MaxInt);
     // Field[1] is not set. Waiting Exception...
     t.Post;
     raise Exception.Create('Constraints Not Null failed.');
    except
      on e: Exception do
       UnitTestList.WriteToProcessLog('Constraints Not Null worked. Message: ' + e.Message);
    end;
  finally
    DropTable(t);
  end;
end;



procedure TUnitTestConstraints.InternalTestCheck;
var
  t: TACRTable;
begin
  t := CreateTableWithConstraintCheck;
  try
    t.Open;

    
    // Value < min
    try
     t.Insert;
     t.Fields[0].AsInteger := 5;
     t.Post;
     raise Exception.Create('Constraints Check value=5 (min=10 max=20 ) failed');
    except
      on e: Exception do
       begin
        t.Cancel;
        UnitTestList.WriteToProcessLog('Constraints Check value=5 (min=10 max=20 ) worked: ' + e.Message);
       end;
    end;


    // Value > max
    try
     t.Insert;
     t.Fields[0].AsInteger := 30;
     t.Post;
     raise Exception.Create('Constraints Check value=30 (min=10 max=20 ) failed');
    except
      on e: Exception do
       begin
        t.Cancel;
        UnitTestList.WriteToProcessLog('Constraints Check value=30 (min=10 max=20 ) worked: ' + e.Message);
       end;
    end;


    // Value is correct
    try
     t.Insert;
     t.Fields[0].AsInteger := 15;
     t.Post;
     UnitTestList.WriteToProcessLog('Constraints Check value=15 (min=10 max=20 ) worked.');
    except
      on e: Exception do
       raise Exception.Create('Constraints Check value=15 (min=10 max=20) failed.: ' + e.Message);
    end;


    // Value is correct
    try
     t.Insert;
     t.Fields[0].AsInteger := 10;
     t.Post;
     UnitTestList.WriteToProcessLog('Constraints Check value=10 (min=10 max=20 ) worked.');
    except
      on e: Exception do
       raise Exception.Create('Constraints Check value=10 (min=10 max=20) failed.: ' + e.Message);
    end;


  finally
    DropTable(t);
  end;
end;


procedure TUnitTestConstraints.InternalTestPK;
var
  t: TACRTable;
begin
  t := CreateTableWithConstraintPK;
  try
    t.Open;
    try

     t.Insert;
     t.Fields[0].AsInteger := 1;
     t.Post;

     t.Insert;
     t.Fields[0].AsInteger := 1;
     t.Post;

     raise Exception.Create('Constraints PK failed.');
    except
      on e: Exception do
       UnitTestList.WriteToProcessLog('Constraints PK worked. Message: ' + e.Message);
    end;
  finally
    DropTable(t);
  end;
end;


procedure TUnitTestConstraints.InternalTestPKMultiple;
var
  t: TACRTable;
begin
  t := CreateTableWithConstraintPKMultiple;
  try
    t.Open;
    // Check null
    try
     t.Insert;
     try
      t.Fields[0].AsInteger := 1;
      t.Post;
     except
      t.Cancel;
      raise;
     end;
     WriteToErrorLog('Error: #1 Constraints PK_Multiple failed.');
    except
      on e: Exception do
       UnitTestList.WriteToProcessLog('Constraints PK_Multiple worked. Message: ' + e.Message);
    end;

    // Check update
    try
     t.Insert;
     try
      t.Fields[0].AsInteger := 1;
      t.Fields[1].AsInteger := 1;
      t.Post;
     except
      t.Cancel;
      raise;
     end;

     t.Edit;
     try
      t.Fields[0].AsInteger := 1;
      t.Fields[1].AsInteger := 1;
      t.Post;
     except
      t.Cancel;
      raise;
     end;
    except
     on e: Exception do
      UnitTestList.WriteToErrorLog('#2 Constraints PK_Multiple UPDATE Error: ' + e.Message);
    end;

    // Insert Duplicate
    try
     t.Insert;
     try
      t.Fields[0].AsInteger := 1;
      t.Fields[1].AsInteger := 1;
      t.Post;
     except
      t.Cancel;
      raise;
     end;
     
     WriteToErrorLog('Error: #3 Constraints PK_Multiple failed.');
    except
      on e: Exception do
       UnitTestList.WriteToProcessLog('Constraints PK_Multiple worked. Message: ' + e.Message);
    end;

  finally
    DropTable(t);
  end;
end;




procedure TUnitTestConstraints.InternalTestUnique;
var
  t: TACRTable;
begin
  t := CreateTableWithConstraintUnique;
  try
    t.Open;
    try

     t.Insert;
     t.Fields[0].AsInteger := 1;
     t.Post;

     t.Insert;
     t.Fields[0].AsInteger := 1;
     t.Post;

     WriteToErrorLog('Constraints Unique failed.');
    except
      on e: Exception do
       UnitTestList.WriteToProcessLog('Insert: Constraints Unique worked. Message: ' + e.Message);
    end;

    try

     t.Insert;
     t.Fields[0].AsInteger := 2;
     t.Post;

     t.Edit;
     t.Fields[0].AsInteger := 1;
     t.Post;

     WriteToErrorLog('Edit Constraints Unique failed.');
    except
      on e: Exception do
       UnitTestList.WriteToProcessLog('Edit: Constraints Unique worked. Message: ' + e.Message);
    end;

    try

     t.Edit;
     t.Fields[0].AsInteger := 3;
     t.Post;
     UnitTestList.WriteToProcessLog('Edit#2: Constraints Unique worked. Message: ');

    except
      on e: Exception do
        WriteToErrorLog('Edit#2 Constraints Unique failed.');
    end;

  finally
    DropTable(t);
  end;
end;






initialization
  UnitTestConstraints := TUnitTestConstraints.Create(UnitTestList);

finalization
  UnitTestConstraints.Free;

end.
