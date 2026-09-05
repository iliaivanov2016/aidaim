unit utDatabaseOptions;

interface

{$I UTConfig.inc}
{$I ACRVer.inc}

uses uTestList, SysUtils, DB, Classes,
{$IFDEF D6H}
     Variants,
{$ENDIF}
{$IFDEF ACR5H}
     ACRComMain,
{$ENDIF}
     ACRMain;

type
  TUnitTestDatabaseOptions = class(TUnitTest)
   private
    db:           TACRDatabase;
    table:        TACRTable;
    procedure ParamTesting;
    procedure TestMaxSessionCount;
    procedure TestPageSize;
    procedure TestExtentPageCount;
    procedure TestRandomSearchRetryCount;
   public
    procedure MainTest;
    procedure MainTestExceptions;
    procedure TestShort; override;
    procedure TestExceptions; override;
  end;

var
  UnitTestDatabaseOptions: TUnitTestDatabaseOptions;

implementation

uses Math;

procedure TUnitTestDatabaseOptions.MainTest;
begin
 db := TACRDatabase.Create(nil);
 db.DatabaseFileName := 'temp\test.adb';
 db.DatabaseName := 'test_db';
 try
  CheckAction(TestMaxSessionCount, 'TestMaxSessionCount');
  CheckAction(TestPageSize, 'TestPageSize');
  CheckAction(TestExtentPageCount, 'TestExtentPageCount');
  CheckAction(TestRandomSearchRetryCount, 'TestRandomSearchRetryCount');
 finally
  db.Close;
  db.DeleteDatabase;
  db.Free;
 end;
end;

procedure TUnitTestDatabaseOptions.MainTestExceptions;
begin
{
  db := TACRDatabase.Create(nil);
  db.DatabaseFileName := 'temp\test.adb';
  db.DatabaseName := 'test';
  db.CreateDatabase;
  db.Open;
  WriteToProcessLog('UnitTestDiskTableEngine - test exceptions started');
 try
  CheckAction(TestX, 'TestX');
 finally
  db.Close;
  db.Free;
 end;
  WriteToProcessLog('UnitTestDiskTableEngine - test exceptions finished');
}
end;

procedure TUnitTestDatabaseOptions.ParamTesting;
begin
  if db.Exists then
   begin
    if db.Connected then
      db.Close;
    db.DeleteDatabase;
   end;
  try
   db.CreateDatabase;
   db.Open;
{
  table := TACRTable.Create(nil);
  table.TableName := 'test_table';
  table.DatabaseName := db.DatabaseName;
  table.InMemory := False;
  table.FieldDefs.Add('id',ftAutoInc);
  table.CreateTable;
//  table.Open;
//  table.Close;
  table.Free;
}
  except
   WriteToErrorLog('Error: Cannot create database with options:'+#10+#13
                    +'MaxSessionCount='+IntToStr(db.Options.MaxSessionCount)+#10+#13
                    +'PageSize='+IntToStr(db.Options.PageSize)+#10+#13
                    +'ExtentPageCount='+IntToStr(db.Options.ExtentPageCount)
                    );
   if db.Exists then
    begin
     if db.Connected then
       db.Close;
     db.DeleteDatabase;
    end;
   raise;
  end;
   db.Close;
   db.Open;
end;

procedure TUnitTestDatabaseOptions.TestMaxSessionCount;
const
  DefaultValue = 1000;
  MinValue = 1;
  MaxValue =  1000;// 2147483647;
//            583746577 - OK!
//            160296784 - OK in 16 sec!!!
  Steps = 10;
var
  MaxSessionCount :   Int64;
  i :                 Integer;
begin
 try
  // Test < MinValue
  MaxSessionCount := MinValue - 1;
  db.Options.MaxSessionCount := MaxSessionCount;
  ParamTesting;
  if db.Options.MaxSessionCount = MinValue then
    WriteToProcessLog('MaxSessionCount cannot be set under MinValue='
                      +IntToStr(MinValue)+' - OK!')
  else
    WriteToErrorLog('Error: MaxSessionCount has been set to less value than the minimal boundary is:'+#10+#13
                    +' db.Option.MaxSessionCount='+IntToStr(db.Options.MaxSessionCount)
                    +' while MinValue='+IntToStr(MinValue));
  // Test from MinValue to MaxValue including both these values in Steps steps
  for i:= 1 to Steps do
   begin
    MaxSessionCount := Trunc(Exp((i-1)*(Ln(MaxValue) / Steps + 1)));
    if MaxSessionCount > MaxValue then
      MaxSessionCount := MaxValue;
    db.Options.MaxSessionCount :=  MaxSessionCount;
    ParamTesting;
    if MaxSessionCount = db.Options.MaxSessionCount then
      WriteToProcessLog('Step'+IntToStr(i)+': MaxSessionCount='
                         +IntToStr(MaxSessionCount)+' - OK!')
    else
      WriteToErrorLog('Error on step'+IntToStr(i)+':'+#10+#13
                      +' db.Option.MaxSessionCount='+IntToStr(db.Options.MaxSessionCount)
                      +' while it has been set to '+IntToStr(MaxSessionCount));
    if MaxSessionCount = MaxValue then break;
   end;
  // Test > MaxValue
{
  MaxSessionCount := Int64(MaxValue) + 1;
  db.Options.MaxSessionCount := MaxSessionCount;
  ParamTesting;
  if db.Options.MaxSessionCount = MaxValue then
    WriteToProcessLog('MaxSessionCount cannot be set over MaxValue='
                      +IntToStr(MaxValue)+' - OK!')
  else
    WriteToErrorLog('Error: MaxSessionCount has been set to more value than the maximal boundary is:'+#10+#13
                    +' db.Option.MaxSessionCount='+IntToStr(db.Options.MaxSessionCount)
                    +' while MaxValue='+IntToStr(MaxValue));
}
 finally
  db.Options.MaxSessionCount := DefaultValue;
 end;
end;

procedure TUnitTestDatabaseOptions.TestPageSize;
const
  MinValue = 128;//40+12;
  MaxValue = 65535;
  DefaultValue = 100;
  Steps = 10;
var
  PageSize :   Integer;
  i :          Integer;
begin
 try
  // Test < MinValue
  PageSize := MinValue - 1;
  db.Options.PageSize := PageSize;
  ParamTesting;
  if db.Options.PageSize = MinValue then
    WriteToProcessLog('PageSize cannot be set under MinValue='
                      +IntToStr(MinValue)+' - OK!')
  else
    WriteToErrorLog('Error: PageSize has been set to less value than the minimal boundary is:'+#10+#13
                    +' db.Option.PageSize='+IntToStr(db.Options.PageSize)
                    +' while MinValue='+IntToStr(MinValue));
  // Test from MinValue to MaxValue including both these values in Steps steps
  for i:= 1 to Steps do
   begin
    PageSize :=  MinValue + ((MaxValue-MinValue) div (Steps-1) + 1) * (i-1);
    if PageSize > MaxValue then
      PageSize := MaxValue;
    db.Options.PageSize :=  PageSize;
    ParamTesting;
    if PageSize = db.Options.PageSize then
      WriteToProcessLog('Step'+IntToStr(i)+': PageSize='
                         +IntToStr(PageSize)+' - OK!')
    else
      WriteToErrorLog('Error on step'+IntToStr(i)+':'+#10+#13
                      +' db.Option.PageSize='+IntToStr(db.Options.PageSize)
                      +' while it has been set to '+IntToStr(PageSize));
   end;
  // Test > MaxValue
  PageSize := MaxValue + 1;
  db.Options.PageSize := PageSize;
  ParamTesting;
  if db.Options.PageSize = MaxValue then
    WriteToProcessLog('PageSize cannot be set over MaxValue='
                      +IntToStr(MaxValue)+' - OK!')
  else
    WriteToErrorLog('Error: PageSize has been set to more value than the maximal boundary is:'+#10+#13
                    +' db.Option.PageSize='+IntToStr(db.Options.PageSize)
                    +' while MaxValue='+IntToStr(MaxValue));
 finally
  db.Options.PageSize := DefaultValue;
 end;
end;

procedure TUnitTestDatabaseOptions.TestExtentPageCount;
const
  DefaultValue = 8;
  MinValue = 4;
{$IFDEF ACR5H}
  MaxValue = 256;
{$ELSE}
  MaxValue = 100;
{$ENDIF}
  Steps = 10;
var
  ExtentPageCount :   Integer;
  i :                 Integer;
begin
 try
  // Test < MinValue
  ExtentPageCount := MinValue - 1;
  db.Options.ExtentPageCount := ExtentPageCount;
  ParamTesting;
  if db.Options.ExtentPageCount = MinValue then
    WriteToProcessLog('ExtentPageCount cannot be set under MinValue='
                      +IntToStr(MinValue)+' - OK!')
  else
    WriteToErrorLog('Error: ExtentPageCount has been set to less value than the minimal boundary is:'+#10+#13
                    +' db.Option.ExtentPageCount='+IntToStr(db.Options.ExtentPageCount)
                    +' while MinValue='+IntToStr(MinValue));
  // Test from MinValue to MaxValue including both these values in Steps steps
  for i:= 1 to Steps do
   begin
    ExtentPageCount :=  MinValue + ((MaxValue-MinValue) div (Steps-1) + 1) * (i-1);
    if ExtentPageCount > MaxValue then
      ExtentPageCount := MaxValue;
    db.Options.ExtentPageCount :=  ExtentPageCount;
    ParamTesting;
    if ExtentPageCount = db.Options.ExtentPageCount then
      WriteToProcessLog('Step'+IntToStr(i)+': ExtentPageCount='
                         +IntToStr(ExtentPageCount)+' - OK!')
    else
      WriteToErrorLog('Error on step'+IntToStr(i)+':'+#10+#13
                      +' db.Option.ExtentPageCount='+IntToStr(db.Options.ExtentPageCount)
                      +' while it has been set to '+IntToStr(ExtentPageCount));
   end;
  // Test > MaxValue
  ExtentPageCount := MaxValue + 1;
  db.Options.ExtentPageCount := ExtentPageCount;
  ParamTesting;
  if db.Options.ExtentPageCount = MaxValue then
    WriteToProcessLog('ExtentPageCount cannot be set over MaxValue='
                      +IntToStr(MaxValue)+' - OK!')
  else
    WriteToErrorLog('Error: ExtentPageCount has been set to more value than the maximal boundary is:'+#10+#13
                    +' db.Option.ExtentPageCount='+IntToStr(db.Options.ExtentPageCount)
                    +' while MaxValue='+IntToStr(MaxValue));
 finally
  db.Options.ExtentPageCount := DefaultValue;
 end;
end;

procedure TUnitTestDatabaseOptions.TestRandomSearchRetryCount;
const
  DefaultValue = 10;
  MinValue = 1;
  MaxValue = 100;
  Steps = 10;
var
  RandomSearchRetryCount :   Integer;
  i :                 Integer;
begin
 try
  // Test < MinValue
  RandomSearchRetryCount := MinValue - 1;
  db.Options.RandomSearchRetryCount := RandomSearchRetryCount;
  ParamTesting;
  if db.Options.RandomSearchRetryCount = MinValue then
    WriteToProcessLog('RandomSearchRetryCount cannot be set under MinValue='
                      +IntToStr(MinValue)+' - OK!')
  else
    WriteToErrorLog('Error: RandomSearchRetryCount has been set to less value than the minimal boundary is:'+#10+#13
                    +' db.Option.RandomSearchRetryCount='+IntToStr(db.Options.RandomSearchRetryCount)
                    +' while MinValue='+IntToStr(MinValue));
  // Test from MinValue to MaxValue including both these values in Steps steps
  for i:= 1 to Steps do
   begin
    RandomSearchRetryCount :=  MinValue + ((MaxValue-MinValue) div (Steps-1) + 1) * (i-1);
    if RandomSearchRetryCount > MaxValue then
      RandomSearchRetryCount := MaxValue;
    db.Options.RandomSearchRetryCount :=  RandomSearchRetryCount;
    ParamTesting;
    if RandomSearchRetryCount = db.Options.RandomSearchRetryCount then
      WriteToProcessLog('Step'+IntToStr(i)+': RandomSearchRetryCount='
                         +IntToStr(RandomSearchRetryCount)+' - OK!')
    else
      WriteToErrorLog('Error on step'+IntToStr(i)+':'+#10+#13
                      +' db.Option.RandomSearchRetryCount='+IntToStr(db.Options.RandomSearchRetryCount)
                      +' while it has been set to '+IntToStr(RandomSearchRetryCount));
   end;
  // Test > MaxValue
  RandomSearchRetryCount := MaxValue + 1;
  db.Options.RandomSearchRetryCount := RandomSearchRetryCount;
  ParamTesting;
  if db.Options.RandomSearchRetryCount = MaxValue then
    WriteToProcessLog('RandomSearchRetryCount cannot be set over MaxValue='
                      +IntToStr(MaxValue)+' - OK!')
  else
    WriteToErrorLog('Error: RandomSearchRetryCount has been set to more value than the maximal boundary is:'+#10+#13
                    +' db.Option.RandomSearchRetryCount='+IntToStr(db.Options.RandomSearchRetryCount)
                    +' while MaxValue='+IntToStr(MaxValue));
 finally
  db.Options.RandomSearchRetryCount := DefaultValue;
 end;
end;

{
procedure TUnitTestDatabaseOption.TestX;
begin
  table1.Exclusive := False;
  table1.Open;
  WriteToProcessLog('table1 is opened in non-exclusive mode');
  table2.TableName := 'table1';
  table2.Exclusive := False;
  try
   table2.Open;
   WriteToProcessLog('table2 is opened too');
  except
   WriteToErrorLog('2 tables open error');
  end;
  table1.Close;
  WriteToProcessLog('table1 is closed');
  table2.Close;
  WriteToProcessLog('table2 is closed, too');

  table1.Exclusive := True;
  table1.Open;
  WriteToProcessLog('table1 is opened in exclusive mode');
  try
   WriteToProcessLog('Try to open second table in non-exclusive mode...');
   table2.Open;
   WriteToErrorLog('Exclusive open table error: table2 is opened in non-exclusive mode');
   table2.Close;
  except
   WriteToProcessLog('... OK: non-exclusive opening blocked');
  end;
  table2.Exclusive := True;
  try
   WriteToProcessLog('Try to open second table in exclusive mode...');
   table2.Open;
   WriteToErrorLog('Exclusive open table error: table2 is opened in exclusive mode too');
   table2.Close;
  except
   WriteToProcessLog('... OK: exclusive opening blocked');
  end;
  table1.Close;
end;
}

procedure TUnitTestDatabaseOptions.TestShort;
begin
  CheckAction(MainTest, 'Main test of database Options');
end;

procedure TUnitTestDatabaseOptions.TestExceptions;
begin
  CheckAction(MainTestExceptions, 'Main exceptions test of database Options');
end;

initialization
  UnitTestDatabaseOptions := TUnitTestDatabaseOptions.Create(UnitTestList);

finalization
  UnitTestDatabaseOptions.Free;

end.
