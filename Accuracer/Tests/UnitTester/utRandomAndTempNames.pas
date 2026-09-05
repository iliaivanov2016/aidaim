unit utRandomAndTempNames;

interface

{$I UTConfig.Inc}

uses uTestList, SysUtils, Db,
Classes,
{$IFDEF D6H}
Variants,
{$ENDIF}
ACRDiskEngine,
ACRCrypto,
ACRMain, 
ACRLocalEngine,

{$IFDEF ACR5H}
     ACRComMain,
{$ENDIF}

ACRPage,
ACRConst,
ACRBaseEngine,
ACRTypes,
ACRMemory
;

const TestShortCount = 10000;

type
  TUnitTestRandomAndTempNames = class(TUnitTest)
   private
    TestCount:        Integer;

    procedure TestTempName(Caption: String);
   public
    procedure MainTest;
    procedure TestShort; override;
  end;

var
  UnitTestRandomAndTempNames: TUnitTestRandomAndTempNames;


implementation


procedure TUnitTestRandomAndTempNames.TestTempName(Caption: String);
var i,j: Integer;
    sl:  array of String;
begin
 SetLength(sl,TestCount);
 for i := 1 to TestCount do
  begin
   sl[i-1] := GetTemporaryName('test');
   for j := 0 to i-2 do
    if (sl[j] = sl[i-1]) then
     WriteToErrorLog(Caption + '- error, temp names equals, name = '+sl[j]);
  end;
 sl := nil;
end;




procedure TUnitTestRandomAndTempNames.MainTest;
begin
 TestTempName('Testing GetTemporaryName ');
end;


procedure TUnitTestRandomAndTempNames.TestShort;
begin
 TestCount := TestShortCount;
 CheckAction(MainTest, 'Main test of RandomAndTempNames');
end;


initialization
  UnitTestRandomAndTempNames := TUnitTestRandomAndTempNames.Create(UnitTestList);

finalization
  UnitTestRandomAndTempNames.Free;
end.

