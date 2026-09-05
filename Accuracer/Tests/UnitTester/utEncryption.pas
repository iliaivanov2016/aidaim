unit utEncryption;

interface

{$I UTConfig.Inc}

uses uTestList, SysUtils, Db,
Classes,
{$IFDEF D6H}
Variants,
{$ENDIF}
ACRDiskEngine,
ACRBaseEngine,
ACRCompression,
ACRCrypto,
ACRMain, 
{$IFDEF ACR5H}
     ACRComMain,
{$ENDIF}
ACRClient,
ACRServer,
ACRPage,
ACRConst,
ACRTypes,
ACRMemory
;

type

  TInitVectorArray = array [0..ACR_MAX_VECTOR] of Byte;

  TUnitTestEncryption = class(TUnitTest)
   private
    ACRDB:    TACRDatabase;
    ACRTable: TACRTable;
    TestRecordCount: Integer;

    procedure TestEncryptDecryptBuffer(Caption: String);
    procedure TestRandomBuffer(Caption: String);
    procedure TestStreamEncryptionWithConstantPassword(Caption: String);
    procedure TestEncryptedDB(Caption: String);
    procedure TestEncryptedDBWithIndexedTable(Caption: String);
    procedure TestIVEncryptionInCSMode(bExceptions: Boolean; Caption: String);
   public
    procedure MainTest;
    procedure MainTestExceptions;
    procedure TestShort; override;
    procedure TestExceptions; override;
  end;

var
  UnitTestEncryption: TUnitTestEncryption;
var
  DefaultTestIV: TInitVectorArray
    = (118, 237, 111, 97, 210, 22, 89, 48, 203, 72, 179, 88, 132, 67, 77,
199, 152, 65, 81, 51, 137, 125, 222, 114, 92, 84, 173, 63, 128, 134, 46,
253);
  DefaultTestIV2: TInitVectorArray
    = (218, 27, 101, 197, 0, 22, 89, 48, 203, 72, 179, 88, 132, 67, 77,
199, 152, 65, 81, 51, 137, 125, 222, 114, 92, 84, 173, 63, 128, 134, 46,
253);


implementation


procedure TUnitTestEncryption.TestEncryptDecryptBuffer(Caption: String);
var buf: PChar;
    encBuf: PChar;
    newBuf: PChar;
    size: Integer;
    info:   TACRCryptoInfo;
    i: Integer;

 procedure RunTest;
 var n,m,i: Integer;
 begin
{$IFDEF ACR5H}
  for n := 1 to ACR_Cipher_Blowfish do
{$ELSE}
  for n := 1 to ACR_Cipher_Des_Triple_24 do
{$ENDIF}
   for m := 0 to ACR_Cipher_Mode_OFB do
    begin
      info.CryptoAlgorithm := n;
      info.CryptoMode := m;
      for i := 0 to size-1 do
       PByte(buf + i)^ := Random(MaxInt) mod 256;
      Move(buf^,encBuf^,size);
      ACREncryptBuffer(info,encbuf,size);
      if (ACRCountCRC(0,Buf,Size) = ACRCountCRC(0,encBuf,Size)) then
       WriteToErrorLog('encrypt buffer failed, alg = '+IntToStr(n)+', mode = '+IntToStr(m)+', password = '+info.Password);
      Move(encbuf^,newBuf^,size);
      ACRDecryptBuffer(info,newBuf,size);
      for i := 0 to size-1 do
       if (PByte(buf + i)^ <> PByte(newBuf + i)^) then
        begin
         WriteToErrorLog('decrypt buffer failed, byte# '+IntToStr(i)+', alg = '+IntToStr(n)+', mode = '+IntToStr(m)+', password = '+info.Password);
         break;
        end;
    end;
 end;

begin
 info.KeyInfo.KeySize := (ACR_MAX_KEY+1)*8;
 for i := 0 to ACR_MAX_KEY do
  info.KeyInfo.Key[i] := Random(MaxInt) mod 256;
 for i := 0 to ACR_MAX_VECTOR do
  info.InitVector[i] := Random(MaxInt) mod 256;
 size := 4025;
 buf := MemoryManager.AllocMem(size);
 encBuf := MemoryManager.AllocMem(size);
 newBuf := MemoryManager.AllocMem(size);
 try
{$IFDEF ACR5H}
  info.Password := '';
  info.UseInitVector := False;
  RunTest;
  info.UseInitVector := True;
//  RunTest;
{$ELSE}
  info.Password := '';
  info.UseInitVector := False;
  RunTest;
  info.UseInitVector := True;
  RunTest;
{$ENDIF}

{$IFDEF ACR5H}
  info.UseInitVector := False;
  info.Password := 'Password!';
  RunTest;
  info.UseInitVector := True;
//  RunTest;
{$ELSE}
  info.UseInitVector := False;
  info.Password := 'Password!';
  RunTest;
  info.UseInitVector := True;
  RunTest;
{$ENDIF}


 finally
  MemoryManager.FreeAndNilMem(buf);
  MemoryManager.FreeAndNilMem(newBuf);
  MemoryManager.FreeAndNilMem(encBuf);
 end;
end;

procedure TUnitTestEncryption.TestRandomBuffer(Caption: String);
var buf1,buf2:  pchar;
    size:       integer;
begin
 size := ACR_MAX_CONTROL_BLOCK+1;
 buf1 := MemoryManager.AllocMem(size);
 buf2 := MemoryManager.AllocMem(size);
 try
  ACRGenerateRandomBuffer(buf1,size);
  ACRGenerateRandomBuffer(buf2,size);
  if (ACRCountCRC(0,buf1,size) = ACRCountCRC(0,buf2,size)) then
   WriteToErrorLog(Caption + ' failed. ');
 finally
  MemoryManager.FreeAndNilMem(buf1);
  MemoryManager.FreeAndNilMem(buf2);
 end;
end;

procedure TUnitTestEncryption.TestStreamEncryptionWithConstantPassword(Caption: String);
var crc1, crc2: Cardinal;
    size:       integer;
    s:          String;
    buf1:       PChar;
    ms:         TACRMemoryStream;
begin
 size := 1024;
 buf1 := MemoryManager.AllocMem(size);
 ms := TACRMemoryStream.Create;
 try
  ACRGenerateRandomBuffer(buf1,size);
  ms.WriteBuffer(buf1^,size);
  crc1 := ACRCountCRC(0,buf1,size);
  ACREncryptStreamToString(ms,s);
  ms.Size := 0;
  ACRDecryptStringToStream(ms,s);
  crc2 := ACRCountCRC(0,ms.Buffer,ms.size);
  if (crc1 <> crc2) then
   WriteToErrorLog(Caption + ' failed. ');
 finally
  MemoryManager.FreeAndNilMem(buf1);
  ms.Free;
 end;
end;

procedure TUnitTestEncryption.TestEncryptedDB(Caption: String);
begin
 ACRDB := TACRDatabase.Create(nil);
 try
  ACRDB.DatabaseName := 'TestDB';
  ACRDB.DatabaseFileName := TempDir + 'cryptodb.adb';
  if (ACRDB.Exists) then
   ACRDB.DeleteDatabase;

  ACRDB.CryptoParams.Password := 'password';

  ACRDB.CreateDatabase;
  if (ACRDB.IsDatabaseEncrypted) then
   WriteToErrorLog('Error - database is not encrypted #1');
  if (not ACRDB.IsCryptoParamsValid) then
   WriteToErrorLog('Error - invalid crypto params on none-encrypted database #1');
  ACRDB.Open;

  if (ACRDB.IsDatabaseEncrypted) then
   WriteToErrorLog('Error - database is not encrypted #2');
  if (not ACRDB.IsCryptoParamsValid) then
   WriteToErrorLog('Error - invalid crypto params on none-encrypted database #3');
  ACRDB.Close;
  ACRDB.DeleteDatabase;

  ACRDB.CryptoParams.CryptoAlgorithm := craRijndael_256;
  ACRDB.CreateDatabase;
  if (not ACRDB.IsDatabaseEncrypted) then
   WriteToErrorLog('Error - database is encrypted #1');
  if (not ACRDB.IsDatabaseEncryptedByPassword) then
   WriteToErrorLog('Error - database is encrypted by password #1');
  if (not ACRDB.IsCryptoParamsValid) then
   WriteToErrorLog('Error - invalid crypto params on encrypted by password database #1');
  ACRDB.Open;
  if (not ACRDB.IsDatabaseEncrypted) then
   WriteToErrorLog('Error - database is encrypted #2');
  if (not ACRDB.IsDatabaseEncryptedByPassword) then
   WriteToErrorLog('Error - database is encrypted by password #2');
  if (not ACRDB.IsCryptoParamsValid) then
   WriteToErrorLog('Error - invalid crypto params on encrypted by password database #2');
  ACRDB.CryptoParams.MakeRandomKey(32);
  if (ACRDB.IsCryptoParamsValid) then
   WriteToErrorLog('Error - valid crypto params (key) on encrypted by password database #2');
  ACRDB.CryptoParams.Password := 'dummy password';
  if (ACRDB.IsCryptoParamsValid) then
   WriteToErrorLog('Error - valid crypto params (dummy password) on encrypted by password database #2');
  ACRDB.Close;
  if (ACRDB.IsCryptoParamsValid) then
   WriteToErrorLog('Error - valid crypto params (dummy password) on encrypted by password database #3');
  ACRDB.DeleteDatabase;

  ACRDB.CryptoParams.MakeRandomKey(32);
  ACRDB.CreateDatabase;
  if (not ACRDB.IsDatabaseEncrypted) then
   WriteToErrorLog('Error - database is encrypted #3');
  if (ACRDB.IsDatabaseEncryptedByPassword) then
   WriteToErrorLog('Error - database is encrypted by key #1');
  ACRDB.Open;
  if (not ACRDB.IsDatabaseEncrypted) then
   WriteToErrorLog('Error - database is encrypted #4');
  if (ACRDB.IsDatabaseEncryptedByPassword) then
   WriteToErrorLog('Error - database is encrypted by key #2');
  ACRDB.CryptoParams.MakeRandomKey(32);
  if (ACRDB.IsCryptoParamsValid) then
   WriteToErrorLog('Error - valid crypto params (dummy key) on encrypted by key database #2');
  ACRDB.CryptoParams.Password := 'dummy password';
  if (ACRDB.IsCryptoParamsValid) then
   WriteToErrorLog('Error - valid crypto params (dummy password) on encrypted by key database #2');
  ACRDB.Close;
  if (ACRDB.IsCryptoParamsValid) then
   WriteToErrorLog('Error - valid crypto params (dummy password) on encrypted by key database #3');
  ACRDB.DeleteDatabase;

  ACRDB.CryptoParams.Password := '12345';
  ACRDB.CryptoParams.CryptoAlgorithm := craRijndael_256;
  ACRDB.CryptoParams.CryptoMode := acmCTS;
  ACRDB.CryptoParams.UseInitVector := False;
  ACRDB.CreateDatabase;

  if (not ACRDB.IsDatabaseEncrypted) then
   WriteToErrorLog('Error - database is encrypted #10');
  if (not ACRDB.IsDatabaseEncryptedByPassword) then
   WriteToErrorLog('Error - database is encrypted by password #11');
  if (not ACRDB.IsCryptoParamsValid) then
   WriteToErrorLog('Error - invalid crypto params on encrypted by password database #12');
  ACRDB.Open;
  if (not ACRDB.IsDatabaseEncrypted) then
   WriteToErrorLog('Error - database is encrypted #13');
  if (not ACRDB.IsDatabaseEncryptedByPassword) then
   WriteToErrorLog('Error - database is encrypted by password #14');
  if (not ACRDB.IsCryptoParamsValid) then
   WriteToErrorLog('Error - invalid crypto params on encrypted by password database #15');

  ACRDB.CryptoParams.Password := '1234';
  if (ACRDB.IsCryptoParamsValid) then
   WriteToErrorLog('Error - valid crypto params on encrypted by password database #16');

 finally
  ACRDB.Close;
  ACRDB.DeleteDatabase;
  ACRDB.Free;
 end;
end;

procedure TUnitTestEncryption.TestEncryptedDBWithIndexedTable(Caption: String);
var i: Integer;
begin

 ACRDB := TACRDatabase.Create(nil);
 ACRTable := TACRTable.Create(nil);
 try
  ACRDB.DatabaseName := 'TestDB';
  ACRDB.DatabaseFileName := TempDir + 'cryptodb.adb';
  ACRTable.DatabaseName := ACRDB.DatabaseName;
  ACRTable.TableName := 'test';
  if (ACRDB.Exists) then
   ACRDB.DeleteDatabase;
  ACRDB.CryptoParams.CryptoAlgorithm := craRijndael_256;
  // database encrypted with default password
  ACRDB.CreateDatabase;
  ACRDB.Open;

  ACRTable.FieldDefs.Clear;
  ACRTable.FieldDefs.Add('ID',ftAutoInc);
  ACRTable.FieldDefs.Add('name',ftString,500);
  ACRTable.FieldDefs.Add('name2',ftFixedChar,50);
  ACRTable.IndexDefs.Clear;
  ACRTable.IndexDefs.Add('index1','name',[ixUnique]);
  ACRTable.CreateTable;
  ACRTable.Open;

  for i := 1 to TestRecordCount do
   begin
    ACRTable.Insert;
    ACRTable.FieldByName('name').AsString := 'name_'+IntToStr(i);
    ACRTable.FieldByName('name2').AsString := 'name2_'+IntToStr(i);
    ACRTable.Post;
   end;

 finally
  ACRDB.Close;
  ACRDB.DeleteDatabase;
  ACRDB.Free;
  ACRTable.Free;
 end;
end;

procedure TUnitTestEncryption.MainTest;
begin
{$IFNDEF NO_NETWORK}
 TestIVEncryptionInCSMode(False,'Encryption with IV in CS mode - no exceptions');
{$ENDIF} 
 TestStreamEncryptionWithConstantPassword('Stream Encryption with constant password');
 TestEncryptedDB('Testing encrypted database ');
 TestEncryptDecryptBuffer('Testing Buffer Encryption / Decryption ');
 TestRandomBuffer('Testing Random Buffer ');
 TestEncryptedDBWithIndexedTable('Testing encrypted database with indexed table ');
end;


procedure TUnitTestEncryption.TestShort;
begin
 TestRecordCount := 100;
 CheckAction(MainTest, 'Main test of Encryption');
end;


procedure TUnitTestEncryption.TestIVEncryptionInCSMode(bExceptions: Boolean; Caption: String);
var db:   TACRDatabase;
    srv:  TACRServer;
    q:    TACRQuery;
    t:    TACRTable;
begin
  // create local DB
  db := TACRDatabase.Create(nil);
  srv := TACRServer.Create(nil);
  q := TACRQuery.Create(nil);
  t := TACRTable.Create(nil);
  try
    db.LocalDatabase := True;
    db.DatabaseFileName := TempDir + 'enc_iv_cs.adb';
    if (db.Exists) then
      db.DeleteDatabase;
    db.CryptoParams.CryptoAlgorithm := craRijndael_256;
    db.CryptoParams.Password := 'Test!223$#@4@123';
    db.CryptoParams.SetInitVector(@DefaultTestIV[0]{$IFDEF ACR5H},Length(DefaultTestIV){$ENDIF});
    db.CryptoParams.UseInitVector := True;
    db.CreateDatabase;
    db.Open;
    WriteToProcessLog('encrypted db with IV created');
    t.DatabaseName := db.DatabaseName;
    q.DatabaseName := db.DatabaseName;
    // create tables
    q.SQL.Text := 'CREATE TABLE Dept(ID AutoInc,Name Char(20), PRIMARY KEY(id)); '+#13#10
                 +'CREATE TABLE Emp(ID AutoInc, DeptID Integer, FirstName Char(20), LastName Char(20), PRIMARY KEY(id));'+#13#10
                 +'CREATE INDEX IdxDeptName ON Dept(Name);'+#13#10
                 +'CREATE INDEX IdxDeptID ON Emp(DeptID);'+#13#10
                 +'ALTER TABLE Emp ADD FOREIGN KEY FK_1(DeptID) References Dept ON DELETE CASCADE ON UPDATE CASCADE;'+#13#10
                 +'INSERT INTO Dept(Name) VALUES ("Support Team");'+#13#10
                 +'INSERT INTO Dept(Name) VALUES ("Development Department");'+#13#10
                 +'INSERT INTO Dept(Name) VALUES ("Sales Department");'+#13#10
                 +'INSERT INTO Emp(DeptID,FirstName,LastName) VALUES (1,"Ray","Lahoy");'+#13#10
                 +'INSERT INTO Emp(DeptID,FirstName,LastName) VALUES (2,"Leo","Martin");'+#13#10
                 +'INSERT INTO Emp(DeptID,FirstName,LastName) VALUES (3,"Ella","Perelman");'+#13#10
                 +'INSERT INTO Emp(DeptID,FirstName,LastName) VALUES (3,"John","Smith");'+#13#10
                 ;
    q.ExecSQL;
    WriteToProcessLog('tables created');
    db.Close;

    srv.UseConfigFile := False;
    srv.DatabaseNames.Clear;
    srv.DatabaseFileNames.Clear;
    srv.DatabaseNames.Add('TestIV');
    srv.DatabaseFileNames.Add(db.DatabaseFileName);
    srv.CryptoParams.Assign(db.CryptoParams);
    srv.CryptoParams.Password := 'Test!Connection33$^3219@';
    srv.ServerID := 0;
    srv.Active := True;

    db.LocalDatabase := False;
    db.ConnectionParams.CryptoParams.Assign(db.CryptoParams);
    db.ConnectionParams.RemoteHost := ACRDefaultHost;
    db.ConnectionParams.RemotePort := ACRDefaultServerPort;
    db.ConnectionParams.DatabaseName := 'TestIV';
    db.ConnectionParams.CryptoParams.Password := srv.CryptoParams.Password;
    db.ConnectionParams.ServerID := 0;
    db.ConnectionParams.NetworkSettings.ConnectRetryCount := 10;
    db.ConnectionParams.NetworkSettings.ConnectDelay := 16;

    sleep(100);

    if (not db.IsCryptoParamsValid) then
     WriteToErrorLog(Caption + ' - CryptoParams are not valid in remote database')
    else
     begin
      db.Open;
      q.SQL.Text := 'SELECT dept.ID as deptID,dept.Name as Department,'
                    +'emp.ID as EmpID, emp.FirstName, emp.LastName FROM emp INNER JOIN dept ON (emp.DeptID = dept.ID) ORDER BY deptID,LastName,FirstName';
      q.Open;
      if (q.RecordCount <> 4) then
       WriteToErrorLog(Caption + ' - invalid q.Recordcount = '+IntToStr(q.RecordCount))
      else
       begin
        q.First;
        if (q.Fields[0].AsInteger <> 1) then
         WriteToErrorLog(Caption + ' - RecNo = '+IntToStr(q.RecNo)
          +', invalid field value #0: '+q.Fields[0].AsString);
        if (q.Fields[1].AsString <> 'Support Team') then
         WriteToErrorLog(Caption + ' - RecNo = '+IntToStr(q.RecNo)
          +', invalid field value #1: '+q.Fields[1].AsString);
        if (q.Fields[2].AsInteger <> 1) then
         WriteToErrorLog(Caption + ' - RecNo = '+IntToStr(q.RecNo)
          +', invalid field value #2: '+q.Fields[2].AsString);
        if (q.Fields[3].AsString <> 'Ray') then
         WriteToErrorLog(Caption + ' - RecNo = '+IntToStr(q.RecNo)
          +', invalid field value #3: '+q.Fields[3].AsString);
        if (q.Fields[4].AsString <> 'Lahoy') then
         WriteToErrorLog(Caption + ' - RecNo = '+IntToStr(q.RecNo)
          +', invalid field value #4: '+q.Fields[4].AsString);
          q.Next;
       end;
     end;
    db.Close;
    sleep(100);
    if (bExceptions) then
     begin
      db.ConnectionParams.CryptoParams.SetInitVector(@DefaultTestIV2[0]{$IFDEF ACR5H},Length(DefaultTestIV2){$ENDIF});
      try
        db.Open;
        WriteToErrorLog(Caption+' - ERROR: Invalid IV in ConnectionParams successfully connected to server!');
        db.Close;
      except
        WriteToProcessLog(Caption+' - OK: Invalid IV in ConnectionParams connect failed as expected!');
      end;

       db.ConnectionParams.CryptoParams.SetInitVector(@DefaultTestIV[0]{$IFDEF ACR5H},Length(DefaultTestIV){$ENDIF});
       db.CryptoParams.SetInitVector(@DefaultTestIV2[0]{$IFDEF ACR5H},Length(DefaultTestIV2){$ENDIF});
       if (db.IsCryptoParamsValid) then
        WriteToErrorLog(Caption+' - ERROR: IsCryptoParamsValid does not detected invalid IV in CryptoParams');
       try
        db.Open;
        WriteToErrorLog(Caption+' - ERROR: Invalid IV in CryptoParams successfully connected to server!');
        db.Close;
       except
        WriteToProcessLog(Caption+' - OK: Invalid IV in CryptoParams connect failed as expected!');
       end;
       db.CryptoParams.SetInitVector(@DefaultTestIV[0]{$IFDEF ACR5H},Length(DefaultTestIV){$ENDIF});
       try
         db.Open;
         WriteToProcessLog(Caption+' - OK: Correct IV settings connected');
       except
        on e: Exception do
         WriteToErrorLog(Caption+' - ERROR: Correct IV settings failed to connect:'+#13#10+e.Message)
        else
         WriteToErrorLog(Caption+' - ERROR: Correct IV settings failed to connect: - UNKNOWN ERROR');
       end;
     end; // test exceptions

  finally
    q.Free;
    t.Free;
    db.Free;
    sleep(100);
    srv.Free;
  end;
end;

procedure TUnitTestEncryption.TestExceptions;
begin
  CheckAction(MainTestExceptions,'Test encryption with exception');
end;

procedure TUnitTestEncryption.MainTestExceptions;
begin
{$IFNDEF NO_NETWORK}
  TestIVEncryptionInCSMode(True,'Encryption with IV in CS mode - no exceptions');
{$ENDIF}  
end;

initialization
  UnitTestEncryption := TUnitTestEncryption.Create(UnitTestList);

finalization
  UnitTestEncryption.Free;
end.

