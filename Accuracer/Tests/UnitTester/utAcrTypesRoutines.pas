unit utAcrTypesRoutines;

interface

{$I UTConfig.Inc}

uses uTestList,
     ACRConverts,
     ACRTypes,
     ACRTypesRoutines,
     ACRVariant,
{$IFDEF ACR5H}
     ACRComMain,
{$ENDIF}
     ACRMemory
     ;

implementation

uses Math, SysUtils;

type
  TUnitTestAcrTypesRoutines = class(TUnitTest)
   public
    procedure TestShort; override;
    procedure TestExceptions; override;
   public
    procedure InternalTestAllocMemAndSetValues;
  end;

var
  UnitTestAcrTypesRoutines: TUnitTestAcrTypesRoutines;


{ TUnitTestAcrTypesRoutines }


procedure TUnitTestAcrTypesRoutines.TestShort;
begin
  CheckAction(InternalTestAllocMemAndSetValues, 'Test AllocMem And SetValues functions');
end;


procedure TUnitTestAcrTypesRoutines.TestExceptions;
begin
end;



procedure TUnitTestAcrTypesRoutines.InternalTestAllocMemAndSetValues;
var
  Size: Integer;
  s1, s2: string;
  i1, i2: Integer;
  dt1, dt2: TACRDateTime;
  n: TDateTime;
  p: Pointer;
begin
  s1 := 'abc';
  AllocMemAndSetData(bftVarchar, s1, p, Size);
  try
    s2 := String(PChar(p));
    if s2 <> 'abc' then
      raise Exception.Create('Set String error');
  finally
    MemoryManager.FreeAndNilMem(p);
  end;
  WriteToProcessLog('String ok.');

  i1 := 12345;
  AllocMemAndSetData(bftSignedInt32, i1, p, Size);
  try
    i2 := pInteger(p)^;
    if i2 <> 12345 then
      raise Exception.Create('Set Integer error');
  finally
    MemoryManager.FreeAndNilMem(p);
  end;
  WriteToProcessLog('Integer ok.');

  n := now;
  dt1 := DateTimeToACRDateTime(n);
  AllocMemAndSetData(bftDateTime, dt1, p, Size);
  try
    dt2 := PACRDateTime(p)^;
    if abs(ACRDateTimeToDateTime(dt2) - n) > 0.00001 then
      raise Exception.Create('Set DateTime error');
  finally
    MemoryManager.FreeAndNilMem(p);
  end;
  WriteToProcessLog('DateTime ok.');


end;

initialization
  UnitTestAcrTypesRoutines := TUnitTestAcrTypesRoutines.Create(UnitTestList);

finalization
  UnitTestAcrTypesRoutines.Free;

end.
