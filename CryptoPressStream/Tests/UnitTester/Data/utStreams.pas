unit utStreams;

interface

{$I CPSVer.Inc}

uses uTestList, SysUtils,
Classes,
CPSMain, CPSDebug, CPSConst, CPSCrypto, CPSMemory;

const TestBlockSize: Integer = 1024; // Bytes
const TestCachedBlocks = 2;

type
  TUnitTestStreams = class(TUnitTest)
   private
    FCPSManager: TCPSManager;
   protected
    function CompareBuffers(Buffer1,Buffer2: PAnsiChar; BufferSize: Integer): Boolean;
    function CompareStreams(Stream1,Stream2: TStream): Boolean;
    procedure TestStream(Stream: TStream; Caption: AnsiString);
    procedure TestCryptoPressStream;
    procedure TestCryptoPressMemoryStream;
    procedure TestCryptoPressFileStream;
   public
    procedure TestShort; override;
  end;

var
  UnitTestStreams: TUnitTestStreams;


implementation



function TUnitTestStreams.CompareBuffers(Buffer1,Buffer2: PAnsiChar; BufferSize: Integer): Boolean;
var i: Integer;
begin
 Result := False;
 for i := 0 to BufferSize-1 do
  if (PByte(Buffer1 + i)^ <> PByte(Buffer2 + i)^) then
   Exit;
 Result := True;
end; // CompareBuffers


function TUnitTestStreams.CompareStreams(Stream1,Stream2: TStream): Boolean;
var buf1, buf2:     PAnsiChar;
    BufferSize,x:   Integer;
    ReadSize:       Integer;
    oldPos,oldPos1: Int64;
begin
 Result := False;
 oldPos := Stream1.Position;
 oldPos1 := Stream2.Position;
 if (Stream1.Position <> Stream2.Position) then
  UnitTestList.WriteToErrorLog('CompareStreams failed: positions not equal #1')
 else
  try
   if (Stream1.Size <> Stream2.Size) then
    begin
     UnitTestList.WriteToErrorLog('CompareStreams failed: sizes not equal #3');
    end
   else
    begin
     if (Stream1.Size = 0) then
      Result := True
     else
      begin
       BufferSize := TestBlockSize;
       buf1 := MemoryManager.GetMem(BufferSize);
       buf2 := MemoryManager.GetMem(BufferSize);
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
          x := Stream1.Read(buf1^,ReadSize);
          if (x <> ReadSize) then
           begin
            Result := False;
            UnitTestList.WriteToErrorLog('CompareStreams failed: stream1 read failed #5');
            break;
           end;
          x := Stream2.Read(buf2^,ReadSize);
          if (x <> ReadSize) then
           begin
            Result := False;
            UnitTestList.WriteToErrorLog('CompareStreams failed: stream2 read failed #6');
            break;
           end;
          if (not CompareBuffers(buf1,buf2,ReadSize)) then
           begin
            Result := False;
            UnitTestList.WriteToErrorLog('CompareStreams failed: data not equal #4');
            break;
           end;
         end;
       finally
        MemoryManager.FreeAndNilMem(buf1);
        MemoryManager.FreeAndNilMem(buf2);
       end;
      end;
    end;
  finally
   Stream1.Position := oldPos;
   Stream2.Position := oldPos1;
   if (Stream1.Position <> Stream2.Position) then
    UnitTestList.WriteToErrorLog('CompareStreams failed: positions not equal #2');
  end;
end; // CompareStreams


procedure TUnitTestStreams.TestStream(Stream: TStream; Caption: AnsiString);
var etStream: TMemoryStream;

 procedure TestSize(bufSize: Integer);
 var buf: PAnsiChar;
 begin
  Stream.Size := bufSize;
  if (Stream.Size <> bufSize) then
   UnitTestList.WriteToErrorLog(Caption + 'error#1: invalid size');
  Stream.Position := 0;
  if (Stream.Position <> 0) then
   UnitTestList.WriteToErrorLog(Caption + 'error#2: invalid position');
  if (bufsize > 0) then
   buf := MemoryManager.GetMem(bufSize);
  try
    if (Stream.Read(buf^,bufSize) <> bufSize) then
     UnitTestList.WriteToErrorLog(Caption + 'error#3: invalid size - read failed');
  finally
   if (bufsize > 0) then
    MemoryManager.FreeAndNilMem(buf);
  end;
  Stream.Position := bufSize;
  if (Stream.Position <> bufSize) then
   UnitTestList.WriteToErrorLog(Caption + 'error#4: invalid position');
 end;

 procedure TestWrite(Size: Integer; Encrypted: Boolean; TestFromCurrentPosition: Boolean = False);
 var
     buf:   PAnsiChar;
     buf1:  PAnsiChar;
     i,n,l: Integer;
     k:     Byte;
     cr:    TCPSCryptoParams;
     pos:   Int64;
 begin
  buf := MemoryManager.AllocMem(Size);
  buf1 := MemoryManager.AllocMem(Size);
  try
    n := Size div 10;
    if n = 0 then
     n := Size div 5;
    if n = 0 then
     n := Size div 2;
    if n = 0 then
     n := Size;
    i := 0;
    while i < size do
     begin
      k := random(256);
      if (Size - i < n) then
       l := Size - i
      else
       l := n;
      FillChar(PAnsiChar(buf + i)^,l,k);
      Inc(i,l);
     end;
    if (Encrypted) then
     begin
      cr.Password := 'test';
      cr.CryptoAlgorithm := CPS_Cipher_Rijndael_256;
      cr.CryptoMode := CPS_Cipher_Mode_CTS;
      cr.UseInitVector := False;
      CPSEncryptBuffer(cr,buf,Size);
     end;
    pos := Stream.Position;
    if (TestFromCurrentPosition) then
     if (Stream.Position <> etStream.Position) then
      UnitTestList.WriteToErrorLog(Caption+'error#7 write failed');

    i := Stream.Write(buf^,Size);
    l := etStream.Write(buf^,Size);
    if (i <> l) then
     UnitTestList.WriteToErrorLog(Caption+'error#5 write failed');
    if (TestFromCurrentPosition) then
     begin
      if (Stream.Size <> etStream.Size) then
       UnitTestList.WriteToErrorLog(Caption+'error#10 write failed');
      Stream.Position := pos;
      etStream.Position := pos;
      i := Stream.Read(buf^,Size);
      l := etStream.Read(buf1^,Size);
      if (i <> l) then
       UnitTestList.WriteToErrorLog(Caption+'error#8 write failed');
      if (not CompareBuffers(buf,buf1,Size)) then
       UnitTestList.WriteToErrorLog(Caption+'error#9 write failed');
     end
    else
     if (not CompareStreams(Stream,etStream)) then
      UnitTestList.WriteToErrorLog(Caption+'error#6 write failed - streams not equal');
  finally
    MemoryManager.FreeAndNilMem(buf);
    MemoryManager.FreeAndNilMem(buf1);
  end;

 end;

begin
  UnitTestList.WriteToProcessLog(Caption + 'started');
  TestSize(TestBlockSize - 1);
  TestSize(TestBlockSize);
  TestSize(TestBlockSize+1);
  TestSize(TestBlockSize*10+1);
  TestSize(TestBlockSize*10);
  TestSize(TestBlockSize*10-1);
  TestSize(TestBlockSize*5+1);
  TestSize(TestBlockSize*5-1);
  TestSize(1);
  TestSize(0);
  etStream := TMemoryStream.Create;
  try
    Stream.Size := 0;
    etStream.Size := 0;
    TestWrite(TestBlockSize - 1,False);
    TestWrite(1,False);
    TestWrite(1,False);
    Stream.Size := 0;
    etStream.Size := 0;
    TestWrite(TestBlockSize*10 - 1,False);
    Stream.Size := 0;
    etStream.Size := 0;
    TestWrite(TestBlockSize*10,False);

    Stream.Size := 0;
    etStream.Size := 0;
    TestWrite(TestBlockSize*10 + 1,False);
    Stream.Position := 0;
    etStream.Position := 0;
    TestWrite(TestBlockSize,True);

    Stream.Size := 0;
    etStream.Size := 0;
    TestWrite(TestBlockSize*10 + 1,False);
    Stream.Position := 0;
    etStream.Position := 0;
    TestWrite(TestBlockSize*10,True);

    Stream.Size := 0;
    etStream.Size := 0;
    TestWrite(TestBlockSize*10 + 1,False);
    Stream.Position := 0;
    etStream.Position := 0;
    TestWrite(TestBlockSize*10+1,True);

    Stream.Size := 0;
    etStream.Size := 0;
    TestWrite(TestBlockSize*10 + 1,False);
    Stream.Position := 0;
    etStream.Position := 0;
    TestWrite(TestBlockSize*11,True);
    Stream.Position := 10;
    etStream.Position := 10;
    TestWrite(TestBlockSize*11-20,True);


    Stream.Position := Stream.Size * 2;
    etStream.Position := etStream.Size * 2;
    TestWrite(TestBlockSize,False,True);

    Stream.Position := Stream.Size * 2 - 1;
    etStream.Position := etStream.Size * 2 - 1;
    TestWrite(TestBlockSize,True,True);

    Stream.Position := Stream.Position - 10;
    etStream.Position := etStream.Position - 10;
    TestWrite(5,True,True);


  finally
    etStream.Free;
  end;
  UnitTestList.WriteToProcessLog(Caption + 'finished');
end; // TestStream


procedure TUnitTestStreams.TestCryptoPressStream;
const s_sgn = 'START_';
const f_sgn = '_FINISH';
var
    Capt:     AnsiString;
    fs:       TCPSFileStream;
    cs:       TCPSCryptoPressStream;
    hdr:      PAnsiChar;
    hdr1:     PAnsiChar;
    hdrSize:  Integer;
    FileNo:   Integer;

 procedure Test;
 begin
  fs := TCPSFileStream.Create(UnitTestList.TempDir+'test_'+IntToStr(FileNo),fmCreate);
  hdrSize:= 55;
  hdr := MemoryManager.GetMem(hdrSize);
  hdr1 := MemoryManager.GetMem(hdrSize);
  try
    CPSGenerateRandomBuffer(hdr,hdrSize);
    Move(s_sgn,hdr^,Length(s_sgn));
    Move(f_sgn,PAnsiChar(hdr+hdrSize - Length(f_sgn))^,Length(f_sgn));
    fs.WriteBuffer(hdr^,hdrSize);
    cs := FCPSManager.CreateCryptoPressStream(fs,True,False,hdr,hdrSize);
    TestStream(cs,Capt);
    cs.LoadHeader(hdr1);
    if (not CompareBuffers(hdr1,hdr,hdrSize)) then
     WriteToErrorLog(Capt + 'invalid cs header');
    fs.Position := 0;
    fs.ReadBuffer(hdr1^,hdrSize);
    if (not CompareBuffers(hdr1,hdr,hdrSize)) then
     WriteToErrorLog(Capt + 'invalid fs header');
    cs.Free;
    fs.Position := 0;
    cs := FCPSManager.CreateCryptoPressStream(fs,False,True);
    TestStream(cs,Capt);
    cs.LoadHeader(hdr1);
    if (not CompareBuffers(hdr1,hdr,hdrSize)) then
     WriteToErrorLog(Capt + 'invalid cs header');
    fs.Position := 0;
    fs.ReadBuffer(hdr1^,hdrSize);
    if (not CompareBuffers(hdr1,hdr,hdrSize)) then
     WriteToErrorLog(Capt + 'invalid fs header');
  finally
    MemoryManager.FreeAndNilMem(hdr);
    MemoryManager.FreeAndNilMem(hdr1);
  end;
  Inc(FileNo);
 end;

begin
 FileNo := 1;

 FCPSManager.BlockSize := TestBlockSize;
 FCPSManager.NumCachedBlocks := TestCachedBlocks;
 Capt := 'TCPSCryptoPressStream test: no compression, no encryption - ';
 FCPSManager.CompressionAlgorithm := caNone;
 FCPSManager.CryptoParams.CryptoAlgorithm := craNone;
 Test;

 FCPSManager.BlockSize := TestBlockSize;
 FCPSManager.NumCachedBlocks := TestCachedBlocks;
 Capt := 'TCPSCryptoPressStream test: no compression, encryption - ';
 FCPSManager.CompressionAlgorithm := caNone;
 FCPSManager.CryptoParams.CryptoAlgorithm := craRijndael_256;
 FCPSManager.CryptoParams.Password := 'The Password!!!@!@#';
 Test;

 FCPSManager.BlockSize := TestBlockSize;
 FCPSManager.NumCachedBlocks := TestCachedBlocks;
 Capt := 'TCPSCryptoPressStream test: compression, no encryption - ';
 FCPSManager.CompressionAlgorithm := caZLIB;
 FCPSManager.CompressionMode := 1;
 FCPSManager.CryptoParams.CryptoAlgorithm := craNone;
 Test;

 FCPSManager.BlockSize := TestBlockSize;
 FCPSManager.NumCachedBlocks := TestCachedBlocks;
 Capt := 'TCPSCryptoPressStream test: compression, encryption - ';
 FCPSManager.CompressionAlgorithm := caZLIB;
 FCPSManager.CompressionMode := 1;
 FCPSManager.CryptoParams.CryptoAlgorithm := craRijndael_256;
 FCPSManager.CryptoParams.Password := 'The Password!!!@!@#';
 Test;
end; // TestCryptoPressStream

procedure TUnitTestStreams.TestCryptoPressMemoryStream;
const Header = 'The Header!';
var
    Capt:     AnsiString;
    ms:       TCPSCryptoPressMemoryStream;
    ms1:      TMemoryStream;
    buf:      PAnsiChar;
    buf1:     PAnsiChar;
begin
 Capt := 'TCPSCryptoPressMemoryStream test: ';
 buf := MemoryManager.GetMem(TestBlockSize);
 try
   CPSGenerateRandomBuffer(buf,TestBlockSize);
   ms1 := TMemoryStream.Create;
   ms := TCPSCryptoPressMemoryStream.Create;
   try
     ms.WriteBuffer(buf^,TestBlockSize);
     ms1.WriteBuffer(buf^,TestBlockSize);
     if (not CompareStreams(ms,ms1)) then
      UnitTestList.WriteToErrorLog(Capt + '#1 streams are not equal');
     ms.Size := 0;
   finally
     ms.Free;
     ms1.Free;
   end;
   ms1 := TMemoryStream.Create;
   FCPSManager.CryptoParams.Password := 'test';
   FCPSManager.CryptoParams.CryptoAlgorithm := craNone;
   ms := TCPSCryptoPressMemoryStream.Create(FCPSManager.CryptoParams.GetCryptoParams,
                                            caZLIB,9,FCPSManager.BlockSize,
                                            PAnsiChar(Header),Length(Header),FCPSManager,UnitTestList.TempDir);

   try
     ms1.WriteBuffer(buf^,TestBlockSize);
     ms.CopyFrom(ms1,0);
     ms.Position := 0;
     ms1.Position := 0;
     if (not CompareStreams(ms,ms1)) then
      UnitTestList.WriteToErrorLog(Capt + '#2 streams are not equal');
     ms.Size := 0;
     ms1.Position := 0;
     ms.LoadFromStream(ms1);
     ms.Position := 0;
     ms1.Position := 0;
     if (not CompareStreams(ms,ms1)) then
      UnitTestList.WriteToErrorLog(Capt + '#3 streams are not equal');
     FCPSManager.CryptoParams.CryptoAlgorithm := craRijndael_256;
     ms.ChangeParameters(caPPM,3,FCPSManager.CryptoParams.GetCryptoParams);
     if (ms.CompressionAlgorithm <> caPPM) then
      UnitTestList.WriteToErrorLog(Capt + '#5 change parameters failed');
     if (ms.CompressionMode <> 3) then
      UnitTestList.WriteToErrorLog(Capt + '#6 change parameters failed');
     if (ms.CryptoParams.CryptoAlgorithm <> Byte(craRijndael_256)) then
      UnitTestList.WriteToErrorLog(Capt + '#7 change parameters failed');
     if (not ms.Encrypted) then
      UnitTestList.WriteToErrorLog(Capt + '#8 change parameters failed');
     if (not CompareStreams(ms,ms1)) then
      UnitTestList.WriteToErrorLog(Capt + '#4 streams are not equal');
     buf1 := MemoryManager.GetMem(Length(Header));
     ms.LoadHeader(buf1);
     if (not CompareBuffers(buf1,PAnsiChar(Header),Length(Header))) then
      UnitTestList.WriteToErrorLog(Capt + '#9 invalid header');
     MemoryManager.FreeAndNilMem(buf1); 
   finally
     ms.Free;
     ms1.Free;
   end;
 finally
   MemoryManager.FreeAndNilMem(buf);
 end;
end; // TestCryptoPressMemoryStream


procedure TUnitTestStreams.TestCryptoPressFileStream;
const Header = 'The Header!';
var 
    Capt:     AnsiString;
    fs:       TCPSCryptoPressFileStream;
    ms1:      TMemoryStream;
    buf:      PAnsiChar;
    buf1:     PAnsiChar;
begin
 Capt := 'TCPSCryptoPressFileStream test: ';
 buf := MemoryManager.GetMem(TestBlockSize);
 try
   CPSGenerateRandomBuffer(buf,TestBlockSize);
   ms1 := TMemoryStream.Create;
   fs := TCPSCryptoPressFileStream.Create(UnitTestList.TempDir+'test_fs.dat',fmCreate);
   try
     fs.WriteBuffer(buf^,TestBlockSize);
     fs.FlushFileBuffers;
     ms1.WriteBuffer(buf^,TestBlockSize);
     if (not CompareStreams(fs,ms1)) then
      UnitTestList.WriteToErrorLog(Capt + '#1 streams are not equal');
     fs.Size := 0;
   finally
     fs.Free;
     ms1.Free;
   end;
   ms1 := TMemoryStream.Create;
   FCPSManager.CryptoParams.Password := 'test';
   FCPSManager.CryptoParams.CryptoAlgorithm := craNone;
   fs := TCPSCryptoPressFileStream.Create(
                                         'test_fs1.dat',fmCreate,
                                         FCPSManager.CryptoParams.GetCryptoParams,
                                            caZLIB,9,FCPSManager.BlockSize,
                                            PAnsiChar(Header),Length(Header),FCPSManager,UnitTestList.TempDir);

   try
     ms1.WriteBuffer(buf^,TestBlockSize);
     fs.CopyFrom(ms1,0);
     fs.Position := 0;
     ms1.Position := 0;
     if (not CompareStreams(fs,ms1)) then
      UnitTestList.WriteToErrorLog(Capt + '#2 streams are not equal');
     fs.Size := 0;
     ms1.Position := 0;
     fs.LoadFromStream(ms1);
     fs.Position := 0;
     ms1.Position := 0;
     if (not CompareStreams(fs,ms1)) then
      UnitTestList.WriteToErrorLog(Capt + '#3 streams are not equal');
     FCPSManager.CryptoParams.CryptoAlgorithm := craRijndael_256;
     if (fs.Mode <> fmCreate) then
      UnitTestList.WriteToErrorLog(Capt + '#9 invalid mode');
     fs.ChangeParameters(caPPM,3,FCPSManager.CryptoParams.GetCryptoParams);
     if (fs.CompressionAlgorithm <> caPPM) then
      UnitTestList.WriteToErrorLog(Capt + '#5 change parameters failed');
     if (fs.CompressionMode <> 3) then
      UnitTestList.WriteToErrorLog(Capt + '#6 change parameters failed');
     if (fs.CryptoParams.CryptoAlgorithm <> Byte(craRijndael_256)) then
      UnitTestList.WriteToErrorLog(Capt + '#7 change parameters failed');
     if (not fs.Encrypted) then
      UnitTestList.WriteToErrorLog(Capt + '#8 change parameters failed');
     if (not CompareStreams(fs,ms1)) then
      UnitTestList.WriteToErrorLog(Capt + '#4 streams are not equal');
     if (fs.FileName <> 'test_fs1.dat') then
      UnitTestList.WriteToErrorLog(Capt + '#10 invalid name');
     buf1 := MemoryManager.GetMem(Length(Header));
     fs.LoadHeader(buf1);
     if (not CompareBuffers(buf1,PAnsiChar(Header),Length(Header))) then
      UnitTestList.WriteToErrorLog(Capt + '#9 invalid header');
     MemoryManager.FreeAndNilMem(buf1);
   finally
     fs.Free;
     ms1.Free;
   end;
 finally
   MemoryManager.FreeAndNilMem(buf);
 end;
end; // TestCryptoPressFileStream

procedure TUnitTestStreams.TestShort;
begin
 FCPSManager := TCPSManager.Create(nil);
 try
   CheckAction(TestCryptoPressStream,'Test CryptoPressStream streams');
   CheckAction(TestCryptoPressMemoryStream,'Test CryptoPressStream memory streams');
   CheckAction(TestCryptoPressFileStream,'Test CryptoPressStream file streams');
 finally
   FCPSManager.Free;
 end;
end;

initialization
  UnitTestStreams := TUnitTestStreams.Create(UnitTestList);

finalization
  UnitTestStreams.Free;

end.
