unit utConvertDateTime;

interface

{$I UTConfig.Inc}

uses
{$IFDEF MSWINDOWS}
      Controls,
{$ENDIF}
      SysUtils,
     uTestList,
{$IFDEF ACR5H}
     ACRComMain,
{$ENDIF}
     ACRTypes, ACRConverts;

type
  TUnitTestConvertDateTime = class(TUnitTest)
   private
    procedure Test1;
   public
    procedure TestShort; override;
  end;

var
  UnitTestConvertDateTime: TUnitTestConvertDateTime;


implementation


{ TUnitTestConvertDateTime }

procedure TUnitTestConvertDateTime.Test1;
var
  ADate: TACRDate;
  BDate: TDate;
  ATime: TACRTime;
  BTime: TTime;
  ADateTime: TACRDateTime;
  BDateTime: TDateTime;
  s: String;
begin
  ADate := -33;
  BDate := ACRDateToDate(ADate);
  //BDate := Date;
  s := FormatDateTime('dd.mm.yyyy', BDate);
  WriteToProcessLog('s=''' + s + '''');

  BDateTime := now;
  ADateTime := DateTimeToACRDateTime(BDateTime);
  BDateTime := ACRDateTimeToDateTime(ADateTime);

  ATime := 13*60*60*1000;
  BTime := ACRTimeToTime(Atime);

  s := FormatDateTime('hh:nn:ss', BTime);
  WriteToProcessLog('time=''' + s + '''');
end;

procedure TUnitTestConvertDateTime.TestShort;
begin
  CheckAction(Test1, 'Test 1');
end;

initialization
  UnitTestConvertDateTime := TUnitTestConvertDateTime.Create(UnitTestList);

finalization
  UnitTestConvertDateTime.Free;


end.
