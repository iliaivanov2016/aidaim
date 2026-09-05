unit utTemporaryTableEngine;

interface

{$I ACRVer.inc}
{$I UTConfig.Inc}

uses uTestList,
     SysUtils,
     DB,
    ACRMain,
{$IFDEF ACR5H}
     ACRComMain,
{$ENDIF}
    ACRPage,
    ACRTypes,
    ACRTempEngine,
    ACRCompression,
    ACRConst,
{$IFDEF D6H}
Variants,
{$ENDIF}
    ACRMemory
    ;

type
  TUnitTestTemporaryTableEngine = class(TUnitTest)
   private
    ACRTable: TACRTable;
    procedure TestCreateTable;
    procedure TestOpenTable;
    procedure TestCloseTable;
    procedure TestInsertRecord;
    procedure TestAddRecord;
    procedure TestNavigateTable;
    procedure TestEmptyTable;
    procedure TestDeleteTable;
    procedure RunTestTempStream(bufSize: Int64);
    procedure RunTestTempStreamSize(StreamSize: Int64);
//    procedure RunTestPageManager;
    procedure TestTempStream;
   public
    procedure MainTest;
    procedure TestShort; override;
  end;

var
  UnitTestTemporaryTableEngine: TUnitTestTemporaryTableEngine;


implementation


procedure TUnitTestTemporaryTableEngine.TestCreateTable;
begin
  ACRTable.FieldDefs.Clear;
  ACRTable.FieldDefs.Add('Field1',ftInteger,0,False);
  ACRTable.FieldDefs.Add('Field2',ftString,500,False);
  ACRTable.FieldDefs.Add('Field3',ftDateTime,0,False);
  ACRTable.FieldDefs.Add('Field4',ftDate,0,False);
  ACRTable.FieldDefs.Add('Field5',ftTime,0,False);
  ACRTable.FieldDefs.Add('Field6',ftLargeInt,0,False);
  ACRTable.FieldDefs.Add('Field7',ftBoolean,0,False);
{$IFDEF D5H}
  ACRTable.FieldDefs.Add('Field8',ftWideString,100,False);
{$ELSE}
  ACRTable.FieldDefs.Add('Field8',ftString,100,False);
{$ENDIF}
  ACRTable.FieldDefs.Add('Field9',ftSmallInt,0,False);
  ACRTable.FieldDefs.Add('Field10',ftWord,0,False);
  ACRTable.FieldDefs.Add('Field11',ftFloat,0,False);
  ACRTable.FieldDefs.Add('Field12',ftCurrency,0,False);
  UnitTestList.WriteToProcessLog('FieldDefs filled');
  try
   ACRTable.CreateTable;
   UnitTestList.WriteToProcessLog('Table created');
  except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('Error creating table' + #9 + 'Error:'#13#10 + e.Message);
     end;
  end;
end;


procedure TUnitTestTemporaryTableEngine.TestOpenTable;
begin
  try
   ACRTable.Open;
   UnitTestList.WriteToProcessLog('Table opened');
  except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('Error opening table' + #9 + 'Error:'#13#10 + e.Message);
     end;
  end;
end;


procedure TUnitTestTemporaryTableEngine.TestInsertRecord;
begin
  try
   ACRTable.Insert;
   ACRTable.Fields[0].AsInteger := Random(MaxInt);
   ACRTable.Fields[1].AsString := 'sfs drsp swer80w4 r0w4 r0w rw0ers';
   ACRTable.Fields[2].AsDateTime := Now;
   ACRTable.Fields[3].AsDateTime := Now;
   ACRTable.Fields[4].AsDateTime := Now;
   TLargeIntField(ACRTable.Fields[5]).AsLargeInt := 2121432424483243;
   ACRTable.Fields[6].AsBoolean := True;
   ACRTable.Fields[7].AsString := 'rsts rsers  483243';
   ACRTable.Fields[8].AsInteger := -12747;
   ACRTable.Fields[9].AsInteger := 34659;
   ACRTable.Fields[10].AsFloat := 4455043.430943;
   ACRTable.Fields[11].AsCurrency:= 98530.36;
   ACRTable.Post;
   UnitTestList.WriteToProcessLog('Table update complete');
  except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('Error updating table' + #9 + 'Error:'#13#10 + e.Message);
     end;
  end;
end;


procedure TUnitTestTemporaryTableEngine.TestAddRecord;
begin
  try
   ACRTable.AppendRecord([Random(MaxInt),'add sfs drsp swer80w4 r0w4 r0w rw0ers',
   Now,Now,Now,Null,False,'sdfsfo',4342,6546,2412334.49,323.5]);
   UnitTestList.WriteToProcessLog('Table append record complete');
  except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('Error appending record' + #9 + 'Error:'#13#10 + e.Message);
     end;
  end;
end;



procedure TUnitTestTemporaryTableEngine.TestNavigateTable;
var Bookmark:   TBookmark;
    Bookmark2:  TBookmark;
begin
  try
   ACRTable.First;
   UnitTestList.WriteToProcessLog('First record, RecNo = ' + IntToStr(ACRTable.RecNo));
   if (not ACRTable.Bof) then
    UnitTestList.WriteToErrorLog('BOF not set at first record');
   if (ACRTable.Eof) then
    UnitTestList.WriteToErrorLog('EOF is set at first record');
   if (ACRTable.RecNo <> 1) then
    UnitTestList.WriteToErrorLog('Invalid RecNo = '+ IntToStr(ACRTable.RecNo) +' at first record');
   UnitTestList.WriteToProcessLog('First complete');

   ACRTable.Last;
   UnitTestList.WriteToProcessLog('Last record, RecNo = ' + IntToStr(ACRTable.RecNo));
   if (ACRTable.Bof) then
    UnitTestList.WriteToErrorLog('BOF is set at last record');
   if (not ACRTable.Eof) then
    UnitTestList.WriteToErrorLog('EOF is not set at last record');
   if (ACRTable.RecNo <> ACRTable.RecordCount) then
    UnitTestList.WriteToErrorLog('Invalid RecNo = '+ IntToStr(ACRTable.RecNo) +' at last record');
   UnitTestList.WriteToProcessLog('Last complete');

   ACRTable.RecNo := ACRTable.RecordCount div 2;
   if (ACRTable.RecNo <> ACRTable.RecordCount div 2) then
    UnitTestList.WriteToErrorLog('Invalid RecNo = '+ IntToStr(ACRTable.RecNo) +' at middle record');
   UnitTestList.WriteToProcessLog('Middle complete');

   Bookmark := ACRTable.GetBookmark;
   UnitTestList.WriteToProcessLog('Get bookmark complete');

   ACRTable.Prior;
   if (ACRTable.RecNo <> (ACRTable.RecordCount div 2) - 1) then
    UnitTestList.WriteToErrorLog('Invalid RecNo = '+ IntToStr(ACRTable.RecNo) +' at middle record - 1');
   UnitTestList.WriteToProcessLog('Prior ok complete');

   ACRTable.GotoBookmark(Bookmark);
   if (ACRTable.RecNo <> (ACRTable.RecordCount div 2)) then
    UnitTestList.WriteToErrorLog('Invalid RecNo = '+ IntToStr(ACRTable.RecNo) +' at middle record #2');
   UnitTestList.WriteToProcessLog('Goto bookmark complete');

   ACRTable.Next;
   if (ACRTable.RecNo <> (ACRTable.RecordCount div 2) + 1) then
    UnitTestList.WriteToErrorLog('Invalid RecNo = '+ IntToStr(ACRTable.RecNo) +' at middle record + 1');
   UnitTestList.WriteToProcessLog('Next complete');

   Bookmark2 := ACRTable.GetBookmark;
   UnitTestList.WriteToProcessLog('Get bookmark2 complete');

   if (ACRTable.CompareBookmarks(Bookmark,Bookmark2) <> -1) then
    UnitTestList.WriteToErrorLog('Compare bookmark failed #1');

   if (ACRTable.CompareBookmarks(Bookmark,Bookmark) <> 0) then
    UnitTestList.WriteToErrorLog('Compare bookmark failed #2');

   if (ACRTable.CompareBookmarks(Bookmark2,Bookmark) <> 1) then
    UnitTestList.WriteToErrorLog('Compare bookmark failed #3');

   ACRTable.FreeBookmark(Bookmark);
   UnitTestList.WriteToProcessLog('Bookmark free complete');

   ACRTable.FreeBookmark(Bookmark2);
   UnitTestList.WriteToProcessLog('Bookmark2 free complete');

   UnitTestList.WriteToProcessLog('Table navigate complete');
  except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('Error navigating table' + #9 + 'Error:'#13#10 + e.Message);
     end;
  end;
end;


procedure TUnitTestTemporaryTableEngine.TestCloseTable;
begin
  try
   ACRTable.Close;
   if (ACRTable.Exists) then
    WriteToErrorLog('TUnitTestTemporaryTableEngine - table was not deleted on close');
   UnitTestList.WriteToProcessLog('Table closed');
  except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('Error closing table' + #9 + 'Error:'#13#10 + e.Message);
     end;
  end;
end;


procedure TUnitTestTemporaryTableEngine.TestEmptyTable;
begin
  try
   TestCloseTable;
   ACRTable.EmptyTable;
   UnitTestList.WriteToProcessLog('Table is empty #1');
   TestOpenTable;
   if (ACRTable.RecordCount <> 0) then
    UnitTestList.WriteToErrorLog('RecordCount is not zero = ' +
      IntToStr(ACRTable.RecordCount));
   TestInsertRecord;
   TestCloseTable;
   ACRTable.EmptyTable;
   UnitTestList.WriteToProcessLog('Table is empty #2');
  except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('Error emptying table' + #9 + 'Error:'#13#10 + e.Message);
     end;
  end;
end;


procedure TUnitTestTemporaryTableEngine.TestDeleteTable;
begin
  try
   ACRTable.Close;
   if (ACRTable.Exists) then
    UnitTestList.WriteToErrorLog('Table was not deleted')
   else
   UnitTestList.WriteToProcessLog('Table deleted');
  except
    on e: Exception do
     begin
      UnitTestList.WriteToErrorLog('Error deleting table' + #9 + 'Error:'#13#10 + e.Message);
     end;
  end;
end;


procedure TUnitTestTemporaryTableEngine.MainTest;
begin
 ACRTable := TACRTable.Create(nil);
 ACRTable.TableName := 'test';
 ACRTable.Temporary := True;
 try
//  CheckAction(RunTestPageManager, 'Test temporary page manager');

  CheckAction(TestCreateTable, 'Test create table');
  CheckAction(TestOpenTable, 'Test open table');
//  CheckAction(TestCloseTable, 'Test close table');
//  CheckAction(TestOpenTable, 'Test open2 table');
  CheckAction(TestInsertRecord, 'Test insert record #1');
  CheckAction(TestInsertRecord, 'Test insert record #2');
  CheckAction(TestInsertRecord, 'Test insert record #3');
  CheckAction(TestInsertRecord, 'Test insert record #4');
  CheckAction(TestInsertRecord, 'Test insert record #5');
  CheckAction(TestInsertRecord, 'Test insert record #6');
  CheckAction(TestInsertRecord, 'Test insert record #7');
  CheckAction(TestInsertRecord, 'Test insert record #8');
  CheckAction(TestAddRecord, 'Test add record ');
  CheckAction(TestNavigateTable, 'Test navigate table');
  CheckAction(TestCloseTable, 'Test close2 table');
  CheckAction(TestTempStream, 'Test temporary streams');

//  CheckAction(TestEmptyTable, 'Test empty table');
//  CheckAction(TestDeleteTable, 'Test delete table');
 finally
  ACRTable.Free;
 end;
end;


procedure TUnitTestTemporaryTableEngine.TestShort;
begin
 CheckAction(MainTest, 'Main test of Temporary table engine');
end;


procedure TUnitTestTemporaryTableEngine.TestTempStream;
var oldLimit, oldBlockSize:  Int64;

procedure RunTest;
begin
   WriteToProcessLog('Testing temp stream - general functions ..');
   RunTestTempStream(100);
   RunTestTempStream(DefaultTemporaryBlockSize-1);
   RunTestTempStream(DefaultTemporaryBlockSize);
   RunTestTempStream(DefaultTemporaryBlockSize+1);
   RunTestTempStream(DefaultTemporaryBlockSize-1);
   RunTestTempStream(DefaultTemporaryBlockSize);
   RunTestTempStream(DefaultTemporaryBlockSize+1);
   DefaultTemporaryLimit := DefaultTemporaryBlockSize;
   RunTestTempStream(DefaultTemporaryBlockSize-1);
   RunTestTempStream(DefaultTemporaryBlockSize);
   RunTestTempStream(DefaultTemporaryBlockSize+1);
   RunTestTempStream(DefaultTemporaryBlockSize*10);

   WriteToProcessLog('Testing set Size...');
   RunTestTempStreamSize(0);
   RunTestTempStreamSize(DefaultTemporaryBlockSize-1);
   RunTestTempStreamSize(DefaultTemporaryBlockSize);
   RunTestTempStreamSize(DefaultTemporaryBlockSize+1);
   RunTestTempStreamSize(DefaultTemporaryBlockSize*2);
   RunTestTempStreamSize(DefaultTemporaryBlockSize*3+1);
   RunTestTempStreamSize(DefaultTemporaryBlockSize*4-1);
   RunTestTempStreamSize(DefaultTemporaryBlockSize*3+1);
   RunTestTempStreamSize(DefaultTemporaryBlockSize*3);
   RunTestTempStreamSize(DefaultTemporaryBlockSize*3-1);
   RunTestTempStreamSize(1);
   RunTestTempStreamSize(0);
end;

begin
 oldLimit := DefaultTemporaryLimit;
 oldBlockSize := DefaultTemporaryBlockSize;
 try
   DefaultTemporaryBlockSize := 4096;
   ACR_ENCRYPTED_DB_USED := False;
   DefaultTemporaryLimit := 0;
   RunTest;
   DefaultTemporaryLimit := DefaultTemporaryBlockSize;
   RunTest;
   DefaultTemporaryLimit := 1024*1024;
   RunTest;
   ACR_ENCRYPTED_DB_USED := True;
   DefaultTemporaryLimit := 0;
   RunTest;
   DefaultTemporaryLimit := DefaultTemporaryBlockSize;
   RunTest;
   DefaultTemporaryLimit := 1024*1024;
   RunTest;
 finally
  DefaultTemporaryLimit := oldLimit;
  DefaultTemporaryBlockSize := oldBlockSize;
 end;
end;

procedure TUnitTestTemporaryTableEngine.RunTestTempStream(bufSize: Int64);
var tst:      TACRTemporaryStream;
    buf:      PAnsiChar;
    b:        Byte;
    Caption:  String;

procedure Check;
var    i,n:      Integer;
begin
 if (tst.Size <> bufSize) then
  WriteToErrorLog(Caption+'Error - invalid stream size = '+IntToStr(tst.Size));
 if (tst.Position <> bufSize) then
  WriteToErrorLog(Caption+'Error - invalid stream position = '+IntToStr(tst.Position));
 tst.Position := 0;
 if (tst.Position <> 0) then
  WriteToErrorLog(Caption+'Error - invalid stream position #2 = '+IntToStr(tst.Position));
 FillChar(buf^,bufSize,$00);
 n := tst.Read(buf^,bufSize);
 if (n <> bufSize) then
  WriteToErrorLog(Caption+'Error - read failed: n = '+IntToStr(n));
 for i := 0 to bufSize-1 do
  begin
   b := pByte(buf+i)^;
   if (b <> $FF) then
    begin
      WriteToErrorLog(Caption+'Error - invalid byte, i = '+IntToStr(i)+', b = '+IntToHex(b,2));
      break;
    end;
   tst.Position := i;
   if (tst.Position <> i) then
    begin
      WriteToErrorLog(Caption+'Error - invalid stream position #3 = '+IntToStr(tst.Position));
      break;
    end;
   b := 1; 
   n := tst.Read(b,1);
   if (n <> 1) then
    begin
      WriteToErrorLog(Caption+'Error - read failed #2: n = '+IntToStr(n));
      break;
    end;
   if (b <> $FF) then
    begin
      WriteToErrorLog(Caption+'Error - invalid byte #2, i = '+IntToStr(i)+', b = '+IntToHex(b,2));
      break;
    end;
  end;
end; // Check


var i1,n1,n2: Integer;

begin
 WriteToProcessLog('starting test bufSize = '+IntToStr(bufSize)+' ...');
 Caption := 'Temp stream main test'
            +#13#10+'bufSize = '+IntToStr(bufSize)
            +#13#10+'Encrypted = '+BoolToStr(ACR_ENCRYPTED_DB_USED,True)
            +#13#10+'Block size = '+IntToStr(DefaultTemporaryBlockSize)
            +#13#10+'Memory limit = '+IntToStr(DefaultTemporaryLimit)
            +#13#10;
 buf := MemoryManager.GetMem(bufSize);
 tst := TACRTemporaryStream.Create;
 try
   FillChar(buf^,bufSize,$FF);
   tst.WriteBuffer(buf^,bufSize);
   Check;

   tst.Size := 0;
   tst.Position := 0;
   if (tst.Size <> 0) then
      WriteToErrorLog(Caption+'Error - invalid stream size 0 = '+IntToStr(tst.Size));
   if (tst.Position <> 0) then
      WriteToErrorLog(Caption+'Error - invalid stream position 0 = '+IntToStr(tst.Position));
   n1 := bufSize-1;
   for i1 := 0 to n1 do
    begin
     b := $FF;
     n2 := tst.Write(b,1);
     if (n2 <> 1) then
      begin
        WriteToErrorLog(Caption+'Error - write failed #2: n2 = '+IntToStr(n2));
        break;
      end;
     if (tst.Position <> i1+1) then
      begin
        WriteToErrorLog(Caption+'Error - invalid position after write = '+IntToStr(tst.Position));
        break;
      end;
    end;
    Check;
 finally
   MemoryManager.FreeAndNilMem(buf);
   WriteToProcessLog('starting test bufSize = '+IntToStr(bufSize)+' ... Complete.');
   tst.Free;
 end;
end;

procedure TUnitTestTemporaryTableEngine.RunTestTempStreamSize(StreamSize: Int64);
var tst:      TACRTemporaryStream;
    Caption:  String;

procedure Check;
var b:    Byte;
    n:    Int64;
    k:    Integer;
begin
 if (tst.Size <> StreamSize) then
    WriteToErrorLog(Caption+'Error - invalid stream size 0 = '+IntToStr(tst.Size));
 n := 0;
 tst.Position := 0;
 while (n < StreamSize) do
  begin
   k := tst.Read(b,1);
   if (k <> 1) then
    begin
     WriteToErrorLog(Caption+'Error - cannot read byte #'+IntTostr(n)+', k = '+IntToStr(k));
     break;
    end;
   Inc(n);
   if (tst.Position <> n) then
    begin
     WriteToErrorLog(Caption+'Error - invalid Position = '+IntTostr(tst.Position)+', n = '+IntToStr(n));
     break;
    end;
  end;
end;

begin
 WriteToProcessLog('starting test set Size = '+IntToStr(StreamSize)+' ... ');
 Caption := 'Temp stream set Size test'
            +#13#10+'StreamSize = '+IntToStr(StreamSize)
            +#13#10+'Encrypted = '+BoolToStr(ACR_ENCRYPTED_DB_USED,True)
            +#13#10+'Block size = '+IntToStr(DefaultTemporaryBlockSize)
            +#13#10+'Memory limit = '+IntToStr(DefaultTemporaryLimit)
            +#13#10;
 tst := TACRTemporaryStream.Create;
 try
   tst.Size := StreamSize;
   Check;
 finally
   WriteToProcessLog('starting test set Size = '+IntToStr(StreamSize)+' ... Complete.');
   tst.Free;
 end;
end; // RunTestTempStreamSize
{
procedure TUnitTestTemporaryTableEngine.RunTestPageManager;
const b1 = $FF;
const b2 = $72;
var pm:           TACRTemporaryPageManager;
    buf1,buf2:    PAnsiChar;
    Caption:      String;
    page1,page2:  TACRPage;
    i,bufSize:    Integer;

begin
 WriteToProcessLog('starting test TempPageManager... ');
 Caption := 'Temp stream set Size test';
 ACRTempPageManagerMaxMemoryPageCount := 1;
 pm := TACRTemporaryPageManager.Create;
 bufSize := pm.PageDataSize;
 buf1 := MemoryManager.GetMem(bufSize);
 buf2 := MemoryManager.GetMem(bufSize);
 try
   FillChar(buf1^,bufSize,b1);
   FillChar(buf2^,bufSize,b2);
   page1 := pm.AddPage(0);
   page2 := pm.AddPage(0);
   Move(buf1^,page1.PageData^,bufSize);
   Move(buf2^,page2.PageData^,bufSize);
   pm.PutPage(page1);
   pm.PutPage(page2);
   pm.ApplyChanges(0);
   
   page1 := pm.GetPage(0,0);
   page2 := pm.GetPage(0,1);
   for i := 0 to bufSize - 1 do
    if (pByte(page1.PageData+i)^ <> b1) then
     begin
      WriteToErrorLog(Caption+' error #1 - i = '+IntToStr(i)+', byte = '+IntToHex(pByte(page1.PageData+i)^,2));
      break;
     end
    else
    if (pByte(page2.PageData+i)^ <> b2) then
     begin
      WriteToErrorLog(Caption+' error #2 - i = '+IntToStr(i)+', byte = '+IntToHex(pByte(page2.PageData+i)^,2));
      break;
     end;
   pm.PutPage(page1);
   pm.PutPage(page2);
   pm.RemovePage(0,0);
   pm.RemovePage(0,1);
   pm.ApplyChanges(0);
 finally
   pm.Free;
   MemoryManager.FreeAndNilMem(buf1);
   MemoryManager.FreeAndNilMem(buf2);
   WriteToProcessLog('starting test TempPageManager... Complete.');
 end;
end; // RunTestPageManager

}
initialization
  UnitTestTemporaryTableEngine := TUnitTestTemporaryTableEngine.Create(UnitTestList);

finalization
  UnitTestTemporaryTableEngine.Free;
end.
