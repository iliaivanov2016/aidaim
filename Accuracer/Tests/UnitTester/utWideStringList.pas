unit utWideStringList;

interface

{$I UTConfig.Inc}

uses
      uTestList,
      SysUtils, Classes,

      ACRTypes,
    ACRConst;

type
  TUnitTestWideStringList = class(TUnitTest)
   protected
    procedure CompareStringLists(capt: String; sla: TACRWideStringList; slb: TStringList);
   public
    procedure TestShort; override;
    procedure TestExceptions; override;
   public
    procedure InternalTestWideStringList;
  end;

var
  UnitTestWideStringList: TUnitTestWideStringList;


implementation


{ TUnitTestWideStringList }

procedure TUnitTestWideStringList.CompareStringLists(capt: String; sla: TACRWideStringList; slb: TStringList);
var i:      Integer;
    sa,sb:  String;
    bOK:    Boolean;
begin
 bOK := True;
 if (sla.Count <> slb.Count) then
  begin
   WriteToErrorLog(capt + ' - Error #0, sla.Count = '+IntToStr(sla.Count)+', slb.count = '+IntTostr(slb.Count));
   bOK := False;
  end
 else
  begin
   for i := 0 to sla.Count-1 do
    begin
     sa := sla.Strings[i];
     sb := slb.Strings[i];
     if (sa <> sb) then
      begin
       WriteToErrorLog(capt + ' - Error #1, i = '+IntToStr(i)+', sa = "'+sa+'", sb = "'+sb+'"');
       bOK := False;
      end;
    end;
  end;
 if (bOK) then
  WriteToProcessLog(capt + ' - OK!');
end;


procedure TUnitTestWideStringList.TestShort;
begin
  CheckAction(InternalTestWideStringList, 'WideStringList test');
end;


procedure TUnitTestWideStringList.TestExceptions;
begin
end;


procedure TUnitTestWideStringList.InternalTestWideStringList;
const TestCount: Integer = 100;
var sla:      TACRWideStringList;
    slb:      TStringList;
    i:        Integer;
    capt,s:   String;
begin
  capt := 'InternalTestWideStringList - ';
  sla := TACRWideStringList.Create;
  slb := TStringList.Create;
  try
    for i := 1 to TestCount do
     begin
      s := 'Test_'+StringReplace(Format('%11d',[i]),' ','0',[rfReplaceAll]);
      sla.Add(s);
      slb.Add(s);
     end;
    CompareStringLists(capt+'After Add',sla,slb);
    sla.Delete(0);
    slb.Delete(0);
    CompareStringLists(capt+'After Delete from Start',sla,slb);
    i := TestCount div 2;
    s := 'Test_'+StringReplace(Format('%11d',[i]),' ','0',[rfReplaceAll]);
    sla.Remove(s);
    slb.Delete(slb.IndexOf(s));
    CompareStringLists(capt+'After Remove from middle',sla,slb);
    i := sla.Count-1;
    sla.Delete(i);
    slb.Delete(i);
    CompareStringLists(capt+'After Delete from End',sla,slb);
  finally
    sla.Free;
    slb.Free;
  end;
end;

initialization
  UnitTestWideStringList := TUnitTestWideStringList.Create(UnitTestList);

finalization
  UnitTestWideStringList.Free;

end.
