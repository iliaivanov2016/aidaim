unit utDiskDatabase;

interface

{$I UTConfig.inc}
{$I ACRVer.inc}

uses
      Windows, Controls,
      SysUtils, Variants, 
     uTestList, db,
     ACRMain, 
{$IFDEF ACR5H}
     ACRComMain,
{$ENDIF}
     ACRConverts, ACRCompression
     ,ACRDiskEngine, ACRPage, ACRTypes, ACRConst, ACRLocalEngine, ACRBaseEngine, ACRBase
     ;

type
  TUnitTestDiskDatabase = class(TUnitTest)
   private
    procedure Test1;
    procedure Test2;
{$IFDEF ACR5H}
{$IFNDEF RELEASE_BUILD}
{$IFNDEF DEBUG_MEMCHECK}
    procedure TestZeroPages;
{$ENDIF}
{$ENDIF}
{$ENDIF}
    procedure TestUnicodeDatabaseFileName;
    procedure TestSQLCreateDropDatabase;
   public
    procedure TestShort; override;
    procedure TestExceptions; override;
  end;

var
  UnitTestDiskDatabase: TUnitTestDiskDatabase;


implementation


{ TUnitTestDiskDatabase }

procedure TUnitTestDiskDatabase.Test1;
var
  db:     TACRDatabase;
  table:  TACRTable;
  maxconnections: Integer;
  pagesize:       integer;
  encmode:        byte;
  encalg:         byte;

  procedure SaveOptions;
  begin
    maxconnections := db.Options.MaxSessionCount;
    pagesize := db.Options.PageSize;
    encmode := Byte(db.CryptoParams.CryptoMode);
    encalg := Byte(db.CryptoParams.CryptoAlgorithm);
  end;

  procedure CheckOptions;
  begin
    if (maxconnections <> db.Options.MaxSessionCount) then
     UnitTestDiskDatabase.WriteToErrorLog('maxconnections differs');
    if (pagesize <> db.Options.PageSize) then
     UnitTestDiskDatabase.WriteToErrorLog('pagesize differs');
    if (encmode <> Byte(db.CryptoParams.CryptoMode)) then
     UnitTestDiskDatabase.WriteToErrorLog('cryptomode differs');
    if (encalg <> Byte(db.CryptoParams.CryptoAlgorithm)) then
     UnitTestDiskDatabase.WriteToErrorLog('cryptoalgorithm differs');
  end;
begin
  WriteToProcessLog('UnitTestDiskDatabase - test short started');

  db := TACRDatabase.Create(nil);
  db.DatabaseFileName := 'temp\test.adb';
  db.DatabaseName := 'test';
  db.CreateDatabase;
  db.Open;
  db.Free;

  db := TACRDatabase.Create(nil);
  db.DatabaseFileName := 'temp\test.adb';
  db.DatabaseName := 'test';
  db.RenameDatabase('temp\test2.adb');
  db.Free;

  if (not FileExists('temp\test2.adb')) then
    WriteToErrorLog('Rename database error #1');
  if (FileExists('temp\test.adb')) then
    WriteToErrorLog('Rename database error #2');

  db := TACRDatabase.Create(nil);
  db.DatabaseFileName := 'temp\test2.adb';
  db.DatabaseName := 'test';
  if (not db.Exists) then
    WriteToErrorLog('Exists database error');
  db.Free;

  db := TACRDatabase.Create(nil);
  db.DatabaseFileName := 'temp\test2.adb';
  db.DatabaseName := 'test';
  db.DeleteDatabase;
  if (FileExists(db.DatabaseFileName)) then
    WriteToErrorLog('Delete database error');
  db.Free;

  db := TACRDatabase.Create(nil);
  db.DatabaseFileName := 'temp\test2.adb';
  db.DatabaseName := 'test';
  db.CreateDatabase;
  db.Exclusive := True;

  SaveOptions;
  db.CompactDatabase;
  if (not db.RepairDatabase) then
    WriteToErrorLog('Repair database error');

  CheckOptions;
  db.Open;
  CheckOptions;
  db.Close;


  db.CryptoParams.CryptoAlgorithm := craRijndael_256;
  db.CryptoParams.CryptoMode := acmCFB;
  db.Options.PageSize := 512;
  db.Options.MaxSessionCount := 100;
  SaveOptions;
  db.ChangeDatabaseSettings(db.Options,db.CryptoParams);
  db.Open;
  CheckOptions;
  db.FlushFileBuffers;
  db.Close;

  db.DeleteDatabase;
  if (FileExists(db.DatabaseFileName)) then
    WriteToErrorLog('Delete database error 2');
  db.Free;

  WriteToProcessLog('UnitTestDiskDatabase - test short finished');
end;

procedure TUnitTestDiskDatabase.Test2;
var
  db1, db2: TACRDatabase;
  FHandle:  Integer;
begin
  WriteToProcessLog('UnitTestDiskDatabase - test exceptions started');

  db1 := TACRDatabase.Create(nil);
  db1.DatabaseFileName := 'temp\test.adb';
  db1.DatabaseName := 'test1';
  db2 := TACRDatabase.Create(nil);
  db2.DatabaseFileName := 'temp\test.adb';
  db2.DatabaseName := 'test2';

  db1.CreateDatabase;

//  db1.Exclusive := False;
  db1.Open;
  try
   db2.Open;
  except
   WriteToErrorLog('2 databases open error');
  end;

  db1.Close;
  db2.Close;

  try
   db1.FlushFileBuffers;
   WriteToErrorLog('flush file buffers on closed database');
  except
   WriteToProcessLog('flush file buffers ok');
  end;

  db1.Exclusive := True;
  db1.Open;
  FHandle := FileOpen(db1.DatabaseFileName,fmOpenRead);
  if (FHandle <> -1) then
   begin
    FileClose(FHandle);
    WriteToErrorLog('Exclusive open database error');
   end
  else
   WriteToProcessLog('Exclusive open database ok');

  db1.Free;
  db2.Free;
  WriteToProcessLog('UnitTestDiskDatabase - test exceptions finished');
end;


{$IFDEF ACR5H}
{$IFNDEF RELEASE_BUILD}
{$IFNDEF DEBUG_MEMCHECK}
procedure TUnitTestDiskDatabase.TestZeroPages;
var capt:   String;
    i,pc:   Integer;
    db:     TACRDatabase;
    t:      TACRTable;
    page:   TACRPage;
    dbData: TACRDiskDatabaseData;
    pm:     TACRDiskPageManager;
begin
 capt := 'TestZeroPages - ';
 db := TACRDatabase.Create(nil);
 t := TACRTable.Create(nil);
 try
   db.DatabaseFileName := TempDir+'\test_zero_pages.adb';
   db.CreateDatabase;
   db.Open;
   t.DatabaseName := db.DatabaseName;
   t.TableName := 'test';
   t.ClearDefinitions;
   t.AdvFieldDefs.Add('id',aftAutoInc);
   t.AdvFieldDefs.Add('str',aftChar,1000);
   t.AdvFieldDefs.Add('notes',aftMemo,0);
   t.IndexDefs.Add('PK','id',[ixPrimary]);
   t.IndexDefs.Add('Index1','str',[]);
   t.CreateTable;
   db.CreateStoredFunction('CREATE FUNCTION Test: INTEGER; BEGIN RESULT := 1; END;');
   db.ClearCache;
   db.Close;
   db.Open;
   t.Open;
   t.InsertRecord([Null,'aaa','1325u3[0use rlsjdrflsd jfse0 ru23408u24r']);
   t.InsertRecord([Null,'aaa1','fsngsrdklfnjseo fnw3ioprji32 ruw3j0frjw340pfjwfjkwkfi-34r ir034']);
   t.InsertRecord([Null,'aaa2','sdfdsfsdfsd']);
   t.InsertRecord([Null,'aaa3','']);
   t.InsertRecord([Null,'aaa4','w40r4u3r0jwefmsepfj sdl.fjs p u340u34r wjh3erfpwejf w0e']);
   t.Close;
   try
     dbData := TACRDiskDatabaseData(TACRLocalSession(db.Handle).DatabaseData);
     if (dbData = nil) then
       WriteToErrorLog(capt+'Failed - no database data')
     else
      begin
       pm := TACRDiskPageManager(dbData.PageManager);
       if (pm = nil) then
        begin
         WriteToErrorLog(capt+'Failed - no database page manager');
         exit;
        end;
       pm.Cache.FUpdatedPages.SetSize(0);
       pc := pm.GetTotalPageCount;
       for i := 0 to pc -1 do
        begin
         page := pm.GetPage(FSM_SESSION_ID,i,dbstFreeSpaceManager,0,True,True);
         FillChar(page.PageBuffer^,page.PageSize,$00);
        end;
       pm.ApplyChanges(1,dbstFreeSpaceManager);
      end;
     WriteToErrorLog(capt+'Failed - no exception');
   except
    on e: Exception do
     begin
      WriteToProcessLog(capt+'OK: '+#13#10+e.Message);
      pm.CancelChanges;
     end;
   end;
  db.Close;
  db.DeleteDatabase;
 finally
   t.Free;
   db.Free;
 end;
end; // TestZeroPages
{$ENDIF}
{$ENDIF}
{$ENDIF}


procedure TUnitTestDiskDatabase.TestShort;
begin
  CheckAction(TestSQLCreateDropDatabase,'DiskDatabase create / drop database');
  CheckAction(TestUnicodeDatabaseFileName, 'DiskDatabase Unicode Database File Name');
  CheckAction(Test1, 'DiskDatabase Test 1');
end;


procedure TUnitTestDiskDatabase.TestExceptions;
begin
{$IFDEF ACR5H}
{$IFNDEF RELEASE_BUILD}
{$IFNDEF DEBUG_MEMCHECK}
  CheckAction(TestZeroPages, 'TestZeroPages');
{$ENDIF}
{$ENDIF}
{$ENDIF}
  CheckAction(Test2, 'DiskDatabase Test 2');
end;

procedure TUnitTestDiskDatabase.TestUnicodeDatabaseFileName;
var ws,dbFile,bkFile:  WideString;
    db:  TACRDatabase;
    s:   AnsiString;
begin
  SetLength(ws,4);
  ws[1] := #$8DC4;
  ws[2] := #$87C4;
  ws[3] := #$BEC5;
  ws[4] := #$A1C5;
  dbFile := WideString(TempDir)+ws;
  bkFile := dbFile+Widestring('1.abk');
  Windows.DeleteFileW(PWideChar(@dbFile[1]));
  Windows.DeleteFileW(PWideChar(@bkFile[1]));
  db := TACRDatabase.Create(nil);
  try
    db.DatabaseFileNameUnicode := dbFile;
    if (db.Exists) then
     WriteToErrorLog('database exists, but it was not created yet');
    db.CreateDatabase;
    try
    if (not db.Exists) then
     WriteToErrorLog('database does not exist, but it was already created');
     db.Open;
     db.Close;
     if (not db.IsAccuracerDatabaseFile) then
      WriteToErrorLog('not an accuracer database file');
     db.Backup('',bkFile);
     if (not ACRFileExists('',bkFile)) then
      WriteToErrorLog('backup file does not exist');
     db.DeleteDatabase;
     if (db.Exists) then
      WriteToErrorLog('database does not deleted');
     db.Restore('',bkFile);
     if (not db.Exists) then
      WriteToErrorLog('database does not restored');
     db.Open;
     db.Close;
     db.Exclusive := True;
     db.RepairDatabase(s,False);
     if (not db.Exists) then
      WriteToErrorLog('database does not repaired');
     if (db.DatabaseFileNameUnicode <> dbFile) then
      WriteToErrorLog('unicode database name lost #1');
     db.RepairDatabase(s,True);
     db.Open;
     db.Close;
     if (db.DatabaseFileNameUnicode <> dbFile) then
      WriteToErrorLog('unicode database name lost #2');
    finally
      Windows.DeleteFileW(PWideChar(@bkFile[1]));
      db.DeleteDatabase;
      if (db.Exists) then
       WriteToErrorLog('database exists, but it was already deleted');
    end;
  finally
    db.Free;
  end;

end;

procedure TUnitTestDiskDatabase.TestSQLCreateDropDatabase;
var db:       TACRDatabase;
    q:        TACRQuery;
    capt:     String;
    fileName: AnsiString;
begin
 capt := 'TUnitTestDiskDatabase.TestSQLCreateDropDatabase - ';
 db := TACRDatabase.Create(nil);
 q := TACRQuery.Create(nil);
 try
   q.InMemory := True;
   fileName := TempDir+'sql_create_db.adb';
   q.SQL.Text := 'CREATE DATABASE FILE '+
                 AnsiQuotedStr(fileName,'"')
                 +' PAGESIZE 8192 MAXSESSIONSCOUNT 10';
   q.ExecSQL;
   db.DatabaseFileNameAnsi := fileName;
   if (db.Exists) then
    begin
     WriteToProcessLog(capt+'database file created');
     db.Open;
     db.Close;
     if (db.Options.PageSize <> 8192) then
      WriteToErrorLog(capt+'database file has invalid PageSize = '+IntToStr(db.Options.PageSize));
     if (db.Options.MaxSessionCount <> 10) then
      WriteToErrorLog(capt+'database file has invalid MaxSessionsCount = '+IntToStr(db.Options.MaxSessionCount));
    end
   else
    WriteToErrorLog(capt+'database file NOT created!');
   q.SQL.Text := 'DROP DATABASE FILE '+
                 AnsiQuotedStr(fileName,'"');
   q.ExecSQL;
   db.DatabaseFileNameAnsi := fileName;
   if (not db.Exists) then
    WriteToProcessLog(capt+'database file deleted')
   else
    WriteToErrorLog(capt+'database file NOT deleted!');
 finally
   q.Free;
   db.Free;
 end;
end;

initialization
  UnitTestDiskDatabase := TUnitTestDiskDatabase.Create(UnitTestList);

finalization
  UnitTestDiskDatabase.Free;


end.
