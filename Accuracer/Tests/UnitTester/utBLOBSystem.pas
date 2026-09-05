unit utBLOBSystem;

interface

{$I UTConfig.Inc}

uses uTestList, SysUtils, DB,
{$IFDEF D6H}
Variants,
{$ENDIF}
Classes,
    ACRMain, ACRCompression,
{$IFDEF ACR5H}
    ACRComMain,
{$ENDIF}
    ACRDiskEngine,
    ACRTypes, ACRConst, ACRCrypto, ACRDecUtil, ACRMemory;

type
  TUnitTestBLOBSystem = class(TUnitTest)
   private
    TestSize:             Int64;
    BLOBStreamBlockSize:  Integer;
    function CompareBuffers(Buffer1,Buffer2: PChar; BufferSize: Integer): Boolean;
    function CompareStreams(Stream1,Stream2: TStream): Boolean;
    procedure InternalTestCompressedBLOBStream(
        CompressionAlgorithm: TACRCompressionAlgorithm;
        CompressionMode:      Byte
        );
    procedure InternalTestBLOBFields(
        CompressionAlgorithm: TACRCompressionAlgorithm;
        CompressionMode:      Byte;
        InMemoryMode:         Boolean;
        TemporaryMode:        Boolean
                                    );
    procedure TestStream(TestName: String; ms: TStream; ams: TACRStream);
   public
    procedure TestMemoryStream;
    procedure TestFileStream;
    procedure TestTemporaryStream;
    procedure TestCompressedBLOBStream;
    procedure TestBLOBFields;
    procedure DoTestRewriteSameDataSameSize(
                bMemory, bTemporary: Boolean;
                bufSize: Integer);
    procedure TestRewriteSameDataSameSize;

    procedure TestShort; override;
    procedure TestLong; override;
  end;

var
  UnitTestBLOBSystem: TUnitTestBLOBSystem;

const TestStrLength = 32768;
const TestSmallStrLength = 3000;

implementation

function GenerateString(
                       len : Integer // serial length
                       ) : String; // returns serial
var i,x : integer;
    s : string;
    c : char;
begin
 s := '';

 for i := 1 to len do
  begin
   x := Random(101);
   if ((x mod 2) =  0) then
    c := chr(65+(Random(260000000) mod 26))
   else
    c := chr(48+(Random(100000000) mod 10));

   s := s + c;
  end; //len
 result := s;
end; // GenerateString



function TUnitTestBLOBSystem.CompareBuffers(Buffer1,Buffer2: PChar; BufferSize: Integer): Boolean;
var i: Integer;
begin
 Result := False;
 for i := 0 to BufferSize-1 do
  if (PByte(Buffer1 + i)^ <> PByte(Buffer2 + i)^) then
   Exit;
 Result := True;
end; // CompareBuffers


function TUnitTestBLOBSystem.CompareStreams(Stream1,Stream2: TStream): Boolean;
var buf1, buf2:   PChar;
    BufferSize:   Integer;
    ReadSize:     Integer;
begin
 Result := False;
 if (Stream1.Size = Stream2.Size) then
  begin
   if (Stream1.Size = 0) then
    Result := True
   else
    begin
     BufferSize := DefaultMemoryBlockSize;
     buf1 := AllocMem(BufferSize);
     buf2 := AllocMem(BufferSize);
     try
      Stream1.Position := 0;
      Stream2.Position := 0;
      Result := True;
      while (Stream1.Position < Stream1.Size) do
       begin
        if (Stream1.Size - Stream1.Position < BufferSize) then
         ReadSize := Stream1.Size - Stream1.Position
        else
         ReadSize := BufferSize;
        Stream1.ReadBuffer(buf1^,ReadSize);
        Stream2.ReadBuffer(buf2^,ReadSize);
        if (not CompareBuffers(buf1,buf2,ReadSize)) then
         begin
          Result := False;
          break;
         end;
       end;
     finally
      FreeMem(buf1);
      FreeMem(buf2);
     end;
    end;
  end;
end; // CompareStreams


procedure TUnitTestBLOBSystem.TestMemoryStream;
var
    ms:       TMemoryStream;
    ams:      TACRMemoryStream;
begin
 ms := TMemoryStream.Create;
 ams := TACRMemoryStream.Create;
 if (ams.BlockSize <> DefaultMemoryBlockSize) then
  WriteToErrorLog('Test memory stream' + ' - Error in memory stream - invalid block size = '+
    IntToStr(ams.BlockSize));
 try
  TestStream('Test memory stream',ms,ams);
 finally
  ms.Free;
  ams.Free;
 end;
end;


procedure TUnitTestBLOBSystem.TestFileStream;
var
//    fs:       TFileStream;
    fs:       TMemoryStream;
    afs:      TACRFileStream;
begin
// fs := TFileStream.Create(UnitTestList.TempDir + '\test_fs.dat',fmCreate);
 //
 fs := TMemoryStream.Create;
 afs := TACRFileStream.Create(UnitTestList.TempDir + '\test_afs.dat',fmCreate);
 if (afs.BlockSize <> DefaultFileBlockSize) then
  WriteToErrorLog('Test file stream' + ' - Error in file stream - invalid block size = '+
    IntToStr(afs.BlockSize));
 try
  TestStream('Test file stream',fs,afs);
 finally
  fs.Free;
  afs.Free;
//  DeleteFile(UnitTestList.TempDir + '\test_fs.dat');
  DeleteFile(UnitTestList.TempDir + '\test_afs.dat');
 end;
end;


procedure TUnitTestBLOBSystem.TestTemporaryStream;
var
    ts:       TMemoryStream;
    ats:      TACRTemporaryStream;
begin
 ts := TMemoryStream.Create;
 ats := TACRTemporaryStream.Create;
 if (ats.BlockSize <> DefaultTemporaryBlockSize) then
  WriteToErrorLog('Test temporary stream' + ' - Error in temporary stream - invalid block size = '+
    IntToStr(ats.BlockSize));
 try
  TestStream('Test temporary stream',ts,ats);
 finally
  ts.Free;
  ats.Free;
 end;
end;


procedure TUnitTestBLOBSystem.TestStream(TestName: String; ms: TStream; ams: TACRStream);
var
    buf,buf2: PChar;
    Offset,i: Integer;
begin
 WriteToProcessLog(TestName + ' - start');
 buf := AllocMem(TestSize);
 buf2 := AllocMem(TestSize);
 for i := 0 to TestSize - 1 do
  PByte(buf +  i)^ := Random(255);
 WriteToProcessLog(TestName + ' - streams created. ams.BlockSize = ' +
  IntToStr(ams.BlockSize));
 try
  ms.Size := TestSize;
  ams.Size := TestSize;
  if (ms.Size <> TestSize) then
   WriteToErrorLog(TestName + ' - Error setting ms.size, ms.Size = '+IntToStr(ms.Size) +
   ', TestSize = ' + IntToStr(TestSize));
  if (ams.Size <> TestSize) then
   WriteToErrorLog(TestName + ' - Error setting amn.size, ams.Size = '+IntToStr(ams.Size) +
   ', TestSize = ' + IntToStr(TestSize));
  WriteToProcessLog(TestName + ' - sizes are set');

  Offset := DefaultMemoryBlockSize - 1;
  ms.Position := Offset;
  ams.Position := Offset;
  if (ms.Position <> Offset) then
   WriteToErrorLog(TestName + ' - Error setting ms.Position, ms.Position = '+IntToStr(ms.Position) +
   ', Offset = ' + IntToStr(Offset));
  if (ams.Position <> Offset) then
   WriteToErrorLog(TestName + ' - Error setting ams.Position, ams.Position = '+IntToStr(ams.Position) +
   ', Offset = ' + IntToStr(Offset));
  WriteToProcessLog(TestName + ' - positions are set');

  i := ms.Write(buf^,TestSize);
  if (i <> TestSize) then
   WriteToErrorLog(TestName + ' - Error writing data to ms, i = ' + IntToStr(i) +
   ', TestSize = ' + IntToStr(TestSize));
  if (ms.Size <> Offset + TestSize) then
   WriteToErrorLog(TestName + ' - Error writing data to ms, ms.Size = ' + IntToStr(ms.Size) +
   ', Offset + TestSize = ' + IntToStr(Offset + TestSize));
  i := ams.Write(buf^,TestSize);
  if (i <> TestSize) then
   WriteToErrorLog(TestName + ' - Error writing data to ams, i = ' + IntToStr(i) +
   ', TestSize = ' + IntToStr(TestSize));
  if (ams.Size <> Offset + TestSize) then
   WriteToErrorLog(TestName + ' - Error writing data to ams, ams.Size = ' + IntToStr(ams.Size) +
   ', Offset + TestSize = ' + IntToStr(Offset + TestSize));
  WriteToProcessLog(TestName + ' - write complete');

  ms.Position := Offset;
  ams.Position := Offset;
  if (ms.Position <> Offset) then
   WriteToErrorLog(TestName + ' - Error setting ms.Position, ms.Position = '+IntToStr(ms.Position) +
   ', Offset = ' + IntToStr(Offset));
  if (ams.Position <> Offset) then
   WriteToErrorLog(TestName + ' - Error setting ams.Position, ams.Position = '+IntToStr(ams.Position) +
   ', Offset = ' + IntToStr(Offset));
  WriteToProcessLog(TestName + ' - positions2 are set');

  i := ms.Read(buf2^,TestSize);
  if (i <> TestSize) then
   WriteToErrorLog(TestName + ' - Error reading data to ms, i = ' + IntToStr(i) +
   ', TestSize = ' + IntToStr(TestSize));
  if (ms.Size <> Offset + TestSize) then
   WriteToErrorLog(TestName + ' - Error reading data to ms, ms.Size = ' + IntToStr(ms.Size) +
   ', Offset + TestSize = ' + IntToStr(Offset + TestSize));
  for i := 0 to TestSize - 1 do
   if (PByte(buf +  i)^ <> PByte(buf2 + i)^) then
     begin
      WriteToErrorLog('Error comparing data from ms, i = '+IntToStr(i));
      break;
     end;

  i := ams.Read(buf2^,TestSize);
  if (i <> TestSize) then
   WriteToErrorLog(TestName + ' - Error reading data to ams, i = ' + IntToStr(i) +
   ', TestSize = ' + IntToStr(TestSize));
  if (ams.Size <> Offset + TestSize) then
   WriteToErrorLog(TestName + ' - Error reading data to ams, ams.Size = ' + IntToStr(ams.Size) +
   ', Offset + TestSize = ' + IntToStr(Offset + TestSize));
  for i := 0 to TestSize - 1 do
   if (PByte(buf +  i)^ <> PByte(buf2 + i)^) then
     begin
      WriteToErrorLog(TestName + ' - Error comparing data from ams, i = '+IntToStr(i));
      break;
     end;
  WriteToProcessLog(TestName + ' - read complete');
  if (ams.Position <> ms.Position) then
   WriteToErrorLog(TestName + ' - Error#1 comparing positions of ms and ams, ms.Position = '
    + IntToStr(ams.Position) + ', ams.Position ' + IntToStr(ams.Position));

  TestSize := TestSize * 2 + 1;
  ms.Size := TestSize;
  ams.Size := TestSize;
  if (ms.Size <> TestSize) then
   WriteToErrorLog(TestName + ' - Error#2 setting ms.size, ms.Size = '+IntToStr(ms.Size) +
   ', TestSize = ' + IntToStr(TestSize));
  if (ams.Size <> TestSize) then
   WriteToErrorLog(TestName + ' - Error#2 setting amn.size, ams.Size = '+IntToStr(ams.Size) +
   ', TestSize = ' + IntToStr(TestSize));
  if (ams.Position <> ms.Position) then
   WriteToErrorLog(TestName + ' - Error#2 comparing positions of ms and ams, ms.Position = '
    + IntToStr(ams.Position) + ', ams.Position ' + IntToStr(ams.Position));
  WriteToProcessLog(TestName + ' - sizes are set#2');

  Offset := TestSize;
  ms.Position := Offset;
  ams.Position := Offset;
  if (ms.Position <> Offset) then
   WriteToErrorLog(TestName + ' - Error#2 setting ms.Position, ms.Position = '+IntToStr(ms.Position) +
   ', Offset = ' + IntToStr(Offset));
  if (ams.Position <> Offset) then
   WriteToErrorLog(TestName + ' - Error#2 setting ams.Position, ams.Position = '+IntToStr(ams.Position) +
   ', Offset = ' + IntToStr(Offset));
  WriteToProcessLog(TestName + ' - positions are set2');

  if (ams.Position <> ms.Position) then
   WriteToErrorLog(TestName + ' - Error#3 comparing positions of ms and ams, ms.Position = '
    + IntToStr(ams.Position) + ', ams.Position ' + IntToStr(ams.Position));

  ams.LoadFromStream(TACRStream(ms));

  if (not CompareStreams(ms,ams)) then
   WriteToErrorLog(TestName + ' - Error comparing streams #1');

  ms.Size := 0;
  ms.Position := 0; 
  ams.SaveToStream(TACRStream(ms));

  if (not CompareStreams(ms,ams)) then
   WriteToErrorLog(TestName + ' - Error comparing streams #2');

 finally
  FreeMem(buf);
  FreeMem(buf2);
 end;
 WriteToProcessLog(TestName + ' - finish');
end; // TestMemoryStream


procedure TUnitTestBLOBSystem.InternalTestCompressedBLOBStream(
        CompressionAlgorithm: TACRCompressionAlgorithm;
        CompressionMode:      Byte
        );
var ms,ms1,ms2:   TACRMemoryStream;
    cs:           TACRCompressedBLOBStream;
    bdsc:         TACRBLOBDescriptor;
    i:            Integer;
    buf,buf2,buf3:PChar;
    BufferSize:   Integer;
    BufferSize2:  Integer;
begin
 WriteToProcessLog('Test compressed BLOB stream - internal test start. CompAlg = '+
  IntToStr(Byte(CompressionAlgorithm))+', CompMode = '+IntToStr(CompressionMode));
 ms := TACRMemoryStream.Create;
 ms1 := TACRMemoryStream.Create;
 ms2 := TACRMemoryStream.Create;

 BufferSize := TestSize;
 BufferSize2 := BufferSize div 10;
 buf := AllocMem(BufferSize);
 buf2 := AllocMem(BufferSize2);
 buf3 := AllocMem(BufferSize2);
 for i := 0 to BufferSize - 1 do
  PByte(buf +  i)^ := Random(5);
 for i := 0 to BufferSize2 - 1 do
  PByte(buf2 +  i)^ := Random(5);

 // header
 i := ms1.Write(buf2^,BufferSize2);
 if (i <> BufferSize2) then
   WriteToErrorLog('Test compressed BLOB stream - Error writing data to ms1, i = ' + IntToStr(i) +
   ', BufferSize2 = ' + IntToStr(BufferSize2));
 // buffer
 i := ms.Write(buf^,BufferSize);
 if (i <> BufferSize) then
   WriteToErrorLog('Test compressed BLOB stream - Error writing data to ms, i = ' + IntToStr(i) +
   ', BufferSize = ' + IntToStr(BufferSize));

 bdsc.BlockSize := BLOBStreamBlockSize;
 bdsc.StartPosition := BufferSize2;
 bdsc.CompressionAlgorithm := Byte(CompressionAlgorithm);
 bdsc.CompressionMode := CompressionMode;
 cs := TACRCompressedBLOBStream.Create(ms1,bdsc,True);
 if (cs.BlockSize <> bdsc.BlockSize) then
   WriteToErrorLog('Test compressed BLOB stream - error creating compressed stream. BlockSize = '+
    IntToStr(cs.BlockSize) + ', bdsc.BlockSize = ' + IntToStr(bdsc.BlockSize));
 WriteToProcessLog('blob stream created');

 try

   cs.LoadFromStream(ms);
   if (not CompareStreams(cs,ms)) then
     WriteToErrorLog('Test compressed BLOB stream - Error comparing streams #1');
   WriteToProcessLog('blob stream loaded');

   cs.SaveToStream(ms2);
   if (not CompareStreams(ms2,ms)) then
     WriteToErrorLog('Test compressed BLOB stream - Error comparing streams #2');
   WriteToProcessLog('blob stream saved');

   bdsc := cs.BLOBDescriptor;
   cs.Free;
   WriteToProcessLog('blob stream closed');

   cs := TACRCompressedBLOBStream.Create(ms1,bdsc,False);
   WriteToProcessLog('blob stream opened');

   ms2.Size := 0;
   cs.SaveToStream(ms2);
   if (not CompareStreams(ms2,cs)) then
     WriteToErrorLog('Test compressed BLOB stream - Error comparing streams #3');
   WriteToProcessLog('blob stream saved#2');

   ms1.Position := 0;
   i := ms1.Read(buf3^,BufferSize2);
   if (i <> BufferSize2) then
    WriteToErrorLog('Error reading data from ms1, i = ' + IntToStr(i) +
    ', BufferSize2 = ' + IntToStr(BufferSize2));

   if (not CompareBuffers(buf2,buf3,BufferSize2)) then
     WriteToErrorLog('Test compressed BLOB stream - header corrupted');

 finally
  cs.Free;
  ms.Free;
  ms1.Free;
  ms2.Free;
  FreeMem(buf);
  FreeMem(buf2);
  FreeMem(buf3);
 end;
 WriteToProcessLog('Test compressed BLOB stream - internal test finish. CompAlg = '+
  IntToStr(Byte(CompressionAlgorithm))+', CompMode = '+IntToStr(CompressionMode));
end; // InternalTestCompressedBLOBStream


procedure TUnitTestBLOBSystem.InternalTestBLOBFields(
        CompressionAlgorithm: TACRCompressionAlgorithm;
        CompressionMode:      Byte;
        InMemoryMode:         Boolean;
        TemporaryMode:        Boolean
                                    );
var ms,ms1:          TACRMemoryStream;
    bs:             TStream;
    i:              Integer;
    buf:            PChar;
    s,s1:           String;
    BufferSize:     Integer;
    ACRTable:       TACRTable;
    ACRdb:          TACRDatabase;
    AdvFieldDef:    TACRAdvFieldDef;
begin
 WriteToProcessLog('Test BLOB fields - internal test start. CompAlg = '+
  IntToStr(Byte(CompressionAlgorithm))+', CompMode = '+IntToStr(CompressionMode));
 if (TemporaryMode) then
  WriteToProcessLog('Test BLOB fields - temporary mode')
 else
 if (InMemoryMode) then
  WriteToProcessLog('Test BLOB fields - InMemory mode')
 else
  WriteToProcessLog('Test BLOB fields - disk mode');
 ms := TACRMemoryStream.Create;

 BufferSize := TestSize;
 buf := AllocMem(BufferSize);
 for i := 0 to BufferSize - 1 do
  PByte(buf +  i)^ := Random(5)+60;
 if (ms.Write(Buf^,BufferSize) <> BufferSize) then
  WriteToErrorLog('Test BLOB fields - error writing to memory stream');
 ACRTable := TACRTable.Create(nil);
 ACRdb := TACRDatabase.Create(nil);
 try
  ACRTable.TableName := 'test';
  if (InMemoryMode) then
   ACRTable.InMemory := True
  else
   ACRTable.InMemory := False;
  if (TemporaryMode) then
   ACRTable.Temporary := True
  else
   ACRTable.Temporary := False;
  if (not InMemoryMode) and (not TemporaryMode) then
    begin
     ACRdb.DatabaseName := 'testDB';
     ACRdb.DatabaseFileName := TempDir+'testDB.adb';
     if (ACRdb.Exists) then
      ACRdb.DeleteDatabase;
     ACRdb.CreateDatabase;
     ACRdb.Open;
     ACRTable.DatabaseName := ACRdb.DatabaseName;
    end;

  ACRTable.FieldDefs.Clear;
  ACRTable.AdvFieldDefs.Clear;
  AdvFieldDef := ACRTable.AdvFieldDefs.AddFieldDef;
  AdvFieldDef.Name := 'Memo';
  AdvFieldDef.DataType := aftMemo;
  AdvFieldDef.BLOBCompressionAlgorithm := TCompressionAlgorithm(CompressionAlgorithm);
  AdvFieldDef.BLOBCompressionMode := CompressionMode;
  AdvFieldDef.BLOBBlockSize := BLOBStreamBlockSize;


  // varchar test

  if (not InMemoryMode) and (not TemporaryMode) then
   begin
    AdvFieldDef := ACRTable.AdvFieldDefs.AddFieldDef;
    AdvFieldDef.Name := 'Memo1';
    AdvFieldDef.DataType := aftString;
    AdvFieldDef.Size := TestStrLength;
    AdvFieldDef.BLOBCompressionAlgorithm := TCompressionAlgorithm(CompressionAlgorithm);
    AdvFieldDef.BLOBCompressionMode := CompressionMode;

    AdvFieldDef := ACRTable.AdvFieldDefs.AddFieldDef;
    AdvFieldDef.Name := 'Memo2';
    AdvFieldDef.DataType := aftMemo;
    AdvFieldDef.BLOBCompressionAlgorithm := TCompressionAlgorithm(CompressionAlgorithm);
    AdvFieldDef.BLOBCompressionMode := CompressionMode;
    AdvFieldDef.BLOBBlockSize := BLOBStreamBlockSize;
   end;


  if (ACRTable.Exists) then
    ACRTable.DeleteTable;
  ACRTable.CreateTable;
  WriteToProcessLog('Test BLOB and varchar fields - table created');
  ACRTable.Open;
  WriteToProcessLog('Test BLOB fields - table opened');
  ACRTable.Insert;

  if (not InMemoryMode) and (not TemporaryMode) then
   begin
    s := GenerateString(TestStrLength);
    ACRTable.FieldByName('Memo1').AsString := s;
    s1 := GenerateString(TestSmallStrLength);
    ACRTable.FieldByName('Memo2').AsString := s1;
   end;

  ACRTable.Post;

  if (not InMemoryMode) and (not TemporaryMode) then
   begin
     if (ACRTable.FieldByName('Memo1').AsString <> s) then
      WriteToErrorLog('varchar error: Memo1 = '+ACRTable.FieldByName('Memo1').AsString+
        ' , s = '+s);

     if (ACRTable.FieldByName('Memo2').AsString <> s1) then
      WriteToErrorLog('blob error: Memo2 = '+ACRTable.FieldByName('Memo2').AsString+
        ' , s1 = '+s1);
   end;

  ACRTable.Insert;
  bs := ACRTable.CreateBlobStream(ACRTable.FieldByName('memo'),bmWrite);
  bs.CopyFrom(ms,0);

  ms1 := TACRMemoryStream.Create;
  try
   TACRStream(bs).SaveToStream(ms1);
   if (not CompareStreams(bs,ms1)) then
    WriteToErrorLog('Test BLOB fields - Error comparing streams #6');
  finally
   ms1.Free;
  end;


  bs.Free;
  ACRTable.Post;

  bs := ACRTable.CreateBlobStream(ACRTable.FieldByName('memo'),bmRead);
  if (not CompareStreams(bs,ms)) then
   WriteToErrorLog('Test BLOB fields - Error comparing streams #1');
  bs.Free;
  if (TemporaryMode) then
   WriteToProcessLog('Test BLOB fields temporary - edit skipped')
  else
   begin
    ACRTable.Edit;
    bs := ACRTable.CreateBlobStream(ACRTable.FieldByName('memo'),bmReadWrite);
    if (not CompareStreams(bs,ms)) then
     WriteToErrorLog('Test BLOB fields - Error comparing streams #2');
    bs.Free;
    ACRTable.Post;
    bs := ACRTable.CreateBlobStream(ACRTable.FieldByName('memo'),bmRead);
    if (not CompareStreams(bs,ms)) then
     WriteToErrorLog('Test BLOB fields - Error comparing streams #3');
    bs.Free;

    ms.Size := 0;
    ACRTable.Edit;
    bs := ACRTable.CreateBlobStream(ACRTable.FieldByName('memo'),bmWrite);
    if (not CompareStreams(bs,ms)) then
     WriteToErrorLog('Test BLOB fields - Error comparing streams #4');
    bs.Free;
    ACRTable.Post;
    bs := ACRTable.CreateBlobStream(ACRTable.FieldByName('memo'),bmRead);
    if (not CompareStreams(bs,ms)) then
     WriteToErrorLog('Test BLOB fields - Error comparing streams #5');
    bs.Free;
   end;

  if (TemporaryMode) then
   WriteToProcessLog('Test BLOB fields temporary - delete skipped')
  else
   begin
    i := ACRTable.RecordCount;
    ACRTable.Delete;
    if (ACRTable.RecordCount <> i-1) then
     WriteToErrorLog('Test BLOB fields - error deleting record, RecordCount = '+
      IntToStr(ACRTable.RecordCount)+', old RecordCount = '+IntToStr(i));
   end;

 finally
  ACRTable.Free;
  if (not InMemoryMode) and (not TemporaryMode) then
    begin
      ACRdb.Close;
      ACRdb.DeleteDatabase;
    end;
  ACRdb.Free;
  ms.Free;
  FreeMem(buf);
 end;
 if (TemporaryMode) then
  WriteToProcessLog('Test BLOB fields - temporary mode')
 else
 if (InMemoryMode) then
  WriteToProcessLog('Test BLOB fields - InMemory mode')
 else
  WriteToProcessLog('Test BLOB fields - disk mode');
 WriteToProcessLog('Test BLOB fields - internal test finish. CompAlg = '+
  IntToStr(Byte(CompressionAlgorithm))+', CompMode = '+IntToStr(CompressionMode));
end; // InternalTestBLOBFields


procedure TUnitTestBLOBSystem.TestCompressedBLOBStream;
var i: Integer;
begin
 WriteToProcessLog('Test compressed BLOB stream - start');

 WriteToProcessLog('testing with CompressionAlgorithm = acaNone...');
 InternalTestCompressedBLOBStream(acaNone,0);
 WriteToProcessLog('testing with CompressionAlgorithm = acaNone... Complete');

 WriteToProcessLog('testing with CompressionAlgorithm = acaZLIB...');
 for i := 1 to 9 do
  InternalTestCompressedBLOBStream(acaZLIB,i);
 WriteToProcessLog('testing with CompressionAlgorithm = acaZLIB... Complete');

 WriteToProcessLog('testing with CompressionAlgorithm = acaBZIP...');
 for i := 1 to 9 do
  InternalTestCompressedBLOBStream(acaBZIP,i);
 WriteToProcessLog('testing with CompressionAlgorithm = acaBZIP... Complete');

 WriteToProcessLog('testing with CompressionAlgorithm = acaPPM...');
 for i := 1 to 9 do
  InternalTestCompressedBLOBStream(acaPPM,i);
 WriteToProcessLog('testing with CompressionAlgorithm = acaPPM... Complete');

 WriteToProcessLog('Test compressed BLOB stream - finish');
end; // TestCompressedBLOBStream


procedure TUnitTestBLOBSystem.TestBLOBFields;
var i: Integer;
begin
 WriteToProcessLog('Test BLOB Fields - start');


 WriteToProcessLog('testing with CompressionAlgorithm = acaNone, disk mode...');
 InternalTestBLOBFields(acaNone,0,False,False);
 WriteToProcessLog('testing with CompressionAlgorithm = acaNone... Complete');

 WriteToProcessLog('testing with CompressionAlgorithm = acaZLIB, disk mode...');
 for i := 1 to 9 do
  InternalTestBLOBFields(acaZLIB,i,False,False);
 WriteToProcessLog('testing with CompressionAlgorithm = acaZLIB... Complete');

 WriteToProcessLog('testing with CompressionAlgorithm = acaBZIP, disk mode...');
 for i := 1 to 9 do
  InternalTestBLOBFields(acaBZIP,i,False,False);
 WriteToProcessLog('testing with CompressionAlgorithm = acaBZIP... Complete');

 WriteToProcessLog('testing with CompressionAlgorithm = acaPPM, disk mode...');


 for i := 1 to 9 do
  InternalTestBLOBFields(acaPPM,i,False,False);
 WriteToProcessLog('testing with CompressionAlgorithm = acaPPM... Complete');


 WriteToProcessLog('testing with CompressionAlgorithm = acaNone, InMemory mode...');
 InternalTestBLOBFields(acaNone,0,True,False);
 WriteToProcessLog('testing with CompressionAlgorithm = acaNone... Complete');

 WriteToProcessLog('testing with CompressionAlgorithm = acaZLIB, InMemory mode...');
 for i := 1 to 9 do
  InternalTestBLOBFields(acaZLIB,i,True,False);
 WriteToProcessLog('testing with CompressionAlgorithm = acaZLIB... Complete');

 WriteToProcessLog('testing with CompressionAlgorithm = acaBZIP, InMemory mode...');
 for i := 1 to 9 do
  InternalTestBLOBFields(acaBZIP,i,True,False);
 WriteToProcessLog('testing with CompressionAlgorithm = acaBZIP... Complete');

 WriteToProcessLog('testing with CompressionAlgorithm = acaPPM, InMemory mode...');
 for i := 1 to 9 do
  InternalTestBLOBFields(acaPPM,i,True,False);
 WriteToProcessLog('testing with CompressionAlgorithm = acaPPM... Complete');


 WriteToProcessLog('testing with CompressionAlgorithm = acaNone, Temporary mode...');
 InternalTestBLOBFields(acaNone,0,False,True);
 WriteToProcessLog('testing with CompressionAlgorithm = acaNone... Complete');

 WriteToProcessLog('testing with CompressionAlgorithm = acaZLIB, Temporary mode...');
 for i := 1 to 9 do
  InternalTestBLOBFields(acaZLIB,i,False,True);
 WriteToProcessLog('testing with CompressionAlgorithm = acaZLIB... Complete');

 WriteToProcessLog('testing with CompressionAlgorithm = acaBZIP, Temporary mode...');
 for i := 1 to 9 do
  InternalTestBLOBFields(acaBZIP,i,False,True);
 WriteToProcessLog('testing with CompressionAlgorithm = acaBZIP... Complete');

 WriteToProcessLog('testing with CompressionAlgorithm = acaPPM, Temporary mode...');
 for i := 1 to 9 do
  InternalTestBLOBFields(acaPPM,i,False,True);
 WriteToProcessLog('testing with CompressionAlgorithm = acaPPM... Complete');

 WriteToProcessLog('Test BLOB Fields - finish');
end; // TestBLOBFields


procedure TUnitTestBLOBSystem.TestRewriteSameDataSameSize;
var bufSize: Integer;

procedure RunTest(bMemory, bTemporary: Boolean);
begin
  // exact fit in 1 page fully
  bufSize := ACRDefaultPageSize - sizeOf(TACRDiskPageHeader) - sizeOf(TACRDataItem) - SizeOf(Word);
  DoTestRewriteSameDataSameSize(bMemory, bTemporary, bufSize);
  // small buffer
  bufSize := bufSize div 10;
  DoTestRewriteSameDataSameSize(bMemory, bTemporary, bufSize);
  // large buffer - 2 pages
  bufSize := ACRDefaultPageSize;
  DoTestRewriteSameDataSameSize(bMemory, bTemporary, bufSize);
  // large buffer - 2 pages fit fully
  bufSize := 2*(ACRDefaultPageSize - sizeOf(TACRDiskPageHeader) - sizeOf(TACRDataItem) - SizeOf(Word));
  DoTestRewriteSameDataSameSize(bMemory, bTemporary, bufSize);
end;

begin
  // disk
  RunTest(false,false);
  // memory
  RunTest(true,false);
  // temporary
  RunTest(false,true);
end;

procedure TUnitTestBLOBSystem.DoTestRewriteSameDataSameSize(
                bMemory, bTemporary: Boolean;
                bufSize: Integer);
var Capt:       String;
    db:         TACRDatabase;
    t:          TACRTable;
    buf0,buf1:  PAnsiChar;
    bs:         TACRBLOBStream;
    fs1,fs2:    Int64;
    fh:         THandle;
    crc1,crc2:  Cardinal;
begin
 Capt := 'TestRewriteSameDataSameSize, bufSize = '+IntToStr(bufSize)+': ';
 if not (bMemory or bTemporary) then
  db := TACRDatabase.Create(nil);
 t := TACRTable.Create(nil);
 buf0 := MemoryManager.AllocMem(bufSize);
 buf1 := MemoryManager.GetMem(bufSize);
 FillChar(buf1^,bufSize,$FF);
 try
   if (bMemory) then
    t.InMemory := True
   else
   if (bTemporary) then
    t.Temporary := True
   else
    begin
     // disk mode
     db.DatabaseFileName := IncludeTrailingBackslash(TempDir)+'test_blob_size.adb';
     if (db.Exists) then
      db.DeleteDatabase;
     db.CreateDatabase;
     db.Open;
     t.DatabaseName := db.DatabaseName;
    end; // disk
   t.TableName := 'test';
   t.FieldDefs.Add('id',ftAutoInc);
   t.FieldDefs.Add('data',ftBlob);
   t.CreateTable;
   t.Open;
   t.Insert;
   bs := TACRBlobStream.Create(TBLOBField(t.Fields[1]),bmWrite);
   bs.WriteBuffer(buf1^,bufSize);
   bs.Free;
   t.Post;

   bs := TACRBlobStream.Create(TBLOBField(t.Fields[1]),bmRead);
   crc1 := ACRCountCRC(0,buf1,bufSize);
   FillChar(buf1^,bufSize,$00);
   bs.ReadBuffer(buf1^,bufSize);
   crc2 := ACRCountCRC(0,buf1,bufSize);
   if (crc1 <> crc2) then
    WriteToErrorLog(Capt+'write $FF error - read bytes differs from $FF');
   bs.Free;
   t.Close;
   if not (bMemory or bTemporary) then
    db.Close;

   if (bMemory or bTemporary) then
    begin
     fs1 := 0;
    end
   else
    begin
     fh := SysUtils.FileOpen(db.DatabaseFileName,fmOpenRead);
     fs1 := SysUtils.FileSeek(fh,0,soFromEnd);
     SysUtils.FileClose(fh);
    end;
   // temporary cannot edit records
   if (not bTemporary) then
    begin
     if not (bMemory or bTemporary) then
       db.Open;
     t.Open;
     t.Edit;
     bs := TACRBlobStream.Create(TBLOBField(t.Fields[1]),bmWrite);
     bs.WriteBuffer(buf0^,bufSize);
     bs.Free;
     t.Post;
     bs := TACRBlobStream.Create(TBLOBField(t.Fields[1]),bmRead);
     crc1 := ACRCountCRC(0,buf0,bufSize);
     FillChar(buf0^,bufSize,$FF);
     bs.ReadBuffer(buf0^,bufSize);
     crc2 := ACRCountCRC(0,buf0,bufSize);
     if (crc1 <> crc2) then
      WriteToErrorLog(Capt+'write $00 error - read bytes differs from $FF');
     bs.Free;
     t.Close;
     if not (bMemory or bTemporary) then
       db.Close;

     if (bMemory or bTemporary) then
      begin
       fs1 := 0;
      end
     else
      begin
       fh := SysUtils.FileOpen(db.DatabaseFileName,fmOpenRead);
       fs2 := SysUtils.FileSeek(fh,0,soFromEnd);
       SysUtils.FileClose(fh);

       if (fs1 <> fs2) then
        WriteToErrorLog(Capt + 'File sizes different: '+#13#10+'fs1 = '+IntToStr(fs1)+#13#10+'fs2 = '+IntToStr(fs2));
      end;
    end;
 finally
   if (bMemory) then
    begin
     t.Close;
     t.DeleteTable(True);
    end;
   t.Free;
   if not (bMemory or bTemporary) then
    begin
     db.Close;
     db.DeleteDatabase;
     db.Free;
    end;
   MemoryManager.FreeAndNilMem(buf0);
   MemoryManager.FreeAndNilMem(buf1);
 end;

end;

procedure TUnitTestBLOBSystem.TestShort;
begin
 TestSize := 10 * 1024;
 BLOBStreamBlockSize := 10 * 1024;
 CheckAction(TestRewriteSameDataSameSize, 'Test rewrite same data - same size');
 CheckAction(TestBLOBFields, 'Test BLOB Fields');
 CheckAction(TestMemoryStream, 'Test memory stream');
 CheckAction(TestFileStream, 'Test file stream');
 CheckAction(TestTemporaryStream, 'Test temporary stream');
 CheckAction(TestCompressedBLOBStream, 'Test compressed BLOB stream');
end;

procedure TUnitTestBLOBSystem.TestLong;
begin
 TestSize := 10 * 1024 * 1024;
 BLOBStreamBlockSize := 1024 * 1024;
 CheckAction(TestBLOBFields, 'Test BLOB Fields');
 CheckAction(TestTemporaryStream, 'Test temporary stream');
 CheckAction(TestMemoryStream, 'Test memory stream');
 CheckAction(TestFileStream, 'Test file stream');
 CheckAction(TestCompressedBLOBStream, 'Test compressed BLOB stream');
end;

initialization
  UnitTestBLOBSystem := TUnitTestBLOBSystem.Create(UnitTestList);

finalization
  UnitTestBLOBSystem.Free;
end.
