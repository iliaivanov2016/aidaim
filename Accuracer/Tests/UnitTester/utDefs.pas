unit utDefs;

interface

{$I UTConfig.Inc}

uses uTestList,
     ACRBase,
     ACRTypes,
     ACRMain,
{$IFDEF ACR5H}
     ACRComMain,
{$ENDIF}
     DB
     ;

type
  TUnitTestDefs = class(TUnitTest)
   public
    procedure TestShort; override;
    //procedure TestExceptions; override;
    procedure TestTACRFieldDefs;
    procedure TestTACRSequenceDefs;
  end;

var
  UnitTestDefs: TUnitTestDefs;

implementation

uses SysUtils;


procedure TUnitTestDefs.TestShort;
begin
  CheckAction(TestTACRFieldDefs, 'Test TACRFieldDefs');
  CheckAction(TestTACRSequenceDefs, 'Test TACRSequenceDefs');
end;


{ TUnitTestDefs }

{function TUnitTestDefs.CeateTable: TACRTable;
begin

end;

procedure TUnitTestDefs.DropTable;
begin

end;
}



procedure TUnitTestDefs.TestTACRFieldDefs;
var fds: TACRFieldDefs;
    fd:  TACRFieldDef;
    i: Integer;
begin
  fds := TACRFieldDefs.Create;
  try
    fds.AddCreated;
    fds[0].SetFieldDefDataType(aftInteger);
    fds[0].Name := 'Field0';
    fds[0].ObjectID := 123;
    fds.AddCreated.Assign(fds[0]);
    fds.Delete(0);  // Delete
    fds.AddCreated;
    fd := fds.GetFieldDefByName('Field0');
    fd.Assign(fds[0]);
    i:=fds.GetDefNumberByObjectId(123);
    fds[i].Assign(fds[0]);
    if fds.GetDefNumberByObjectId(3333) <> -1 then
      raise Exception.Create('GetDefNumberByObjectId error');
  finally
    fds.Free;
  end;
end;


procedure TUnitTestDefs.TestTACRSequenceDefs;
var ds: TACRSequenceDefs;
    d:  TACRSequenceDef;
    i: TACRSequenceValue;
begin
  ds := TACRSequenceDefs.Create;
  try
    ds.AddCreated;
    with ds.AddCreated do begin
      Name := 'sq1';
      ObjectID := 13;
      DataType := bftSignedInt32;
      Increment := 10;
      LastValue := 1;
    end;
    ds.AddCreated;
    d := ds.GetSequenceDefByName('sq1');
    i := d.GetNextVal + d.GetNextVal;
    if i <> 32 then
      raise Exception.Create('GetNextVal error');
  finally
    ds.Free;
  end;
end;

initialization
  UnitTestDefs := TUnitTestDefs.Create(UnitTestList);

finalization
  UnitTestDefs.Free;

end.
