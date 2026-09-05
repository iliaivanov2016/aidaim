unit utStoredProcedures;

interface

{$I UTConfig.Inc}

{DEFINE DO_NOT_DELETE_DB}

uses SysUtils, DateUtils, Classes, DB, Variants,
{$IFNDEF D6H}
     DBTables,
{$ELSE}
 {$IFDEF MSWINDOWS}
     DBTables,
 {$ENDIF}
{$ENDIF}
     DBClient,
     uTestList,
     ACRMain,
{$IFDEF ACR5H}
     ACRComMain,
{$ENDIF}
     ACRClient,
     ACRServer,
     ACRConst,
     ACRTypes,
     ACRExcept,
     ACRBaseEngine,
     ACRBase,
     ACRMemEngine,
     ACRDiskEngine,
     ACRLocalEngine,
     ACRSQLProcessor,
     ACRExpressions,
     ACRVariant,
     ACRRelationalALgebra
     ;

type
  TUnitTestStoredProcedures = class(TUnitTest)
   private
    db:         TACRDatabase;
    q:          TACRQuery;
    t:          TACRTable;
    srv:        TACRServer;
    procList:   TACRWideStringList;
    procNames:  TACRWideStringList;
    capt:       String;
    sqlScript:  WideString;
   protected
    procedure RunSQLTest(Live: Boolean);
    procedure RunTableTest;
    procedure CreateDB(UseSQL, DiskMode, CSMode: Boolean);
    procedure DeleteDB(UseSQL, DiskMode, CSMode: Boolean);
    procedure RunMainTest(UseSQL, DiskMode, CSMode: Boolean);
    procedure MainTest;
    procedure InternalTest_Jacque_Lafitte_Bugs(InMmemory: Boolean);
    procedure Test_Jacque_Lafitte_Bugs;
   public
    procedure TestShort; override;
    procedure TestExceptions; override;
  end;

var UnitTestStoredProcedures: TUnitTestStoredProcedures;

const

 NumFunctions = 11;
 StoredFunctionNames: array [0..NumFunctions-1] of WideString = (

                         'DivideByTwo'
                        ,'Execute1'
                        ,'GetEvenOdd'
                        ,'GetEvenOdd1'
                        ,'GetFmtVersion'
                        ,'GetStringConstant'
                        ,'GetVersion'
                        ,'GetVersionText'
                        ,'InsertRecordToTelTable'
                        ,'MyYear'
                        ,'MyYearDiff'
                       );


implementation



{ TUnitTestStoredProcedures }

procedure TUnitTestStoredProcedures.CreateDB(UseSQL, DiskMode, CSMode: Boolean);
var sr:         TSearchRec;
    proc:       TACRWideStringList;
    proc1:      TACRWideStringList;
    proc2:      TACRWideStringList;
    procPath:   String;
    s:          String;
    i,k:        Integer;
    ws:         WideString;
begin
 proc := TACRWideStringList.Create();
 proc1:= TACRWideStringList.Create();
 proc2:= TACRWideStringList.Create();
 try
   procList := TACRWideStringList.Create();
   procNames := TACRWideStringList.Create();
   db := TACRDatabase.Create(nil);
   q := TACRQuery.Create(nil);
   t := TACRTable.Create(nil);
   srv := TACRServer.Create(nil);
   procPath := SQLDir+'Stored_Procedures\';
   if (FindFirst(procPath+'*.sql',faAnyFile,sr) = 0) then
    repeat
     proc.Clear;
     proc.LoadFromFile(procPath+sr.Name);
     procList.Add(proc.Text);
     procNames.Add(Copy(sr.Name,1,Length(sr.Name)-4));
    until (FindNext(sr) <> 0);
   FindClose(sr);
   db.InMemory := not DiskMode;
   db.DatabaseName := 'DB_StoredProcedures';
   t.DatabaseName := db.DatabaseName;
   // to have existing memory database
   q.InMemory := True;
   // create db
   if (UseSQL) then
    begin
     if (DiskMode) then
      begin
       db.DatabaseFileName := TempDir+'db_stored_procedures.adb';
       q.SQL.Text := 'CREATE DATABASE FILE "'+db.DatabaseFileName+'"';
      end
     else
       q.SQL.Text := 'CREATE DATABASE MEMORY "'+db.DatabaseName+'"';
     q.ExecSQL;
     db.Open;
    end
   else
    begin
     if (DiskMode) then
      db.DatabaseFileName := TempDir+'db_stored_procedures.adb';
     db.CreateDatabase;
     db.Open;
    end;
   q.InMemory := db.InMemory;
   q.DatabaseName := db.DatabaseName;
   if (CSMode) then
    begin
     db.Close;
     db.LocalDatabase := False;
     db.ConnectionParams.DatabaseName := 'db_remote_stored_procedures';
     srv.UseConfigFile := False;
     srv.DatabaseNames.Clear;
     srv.DatabaseFileNames.Clear;
     srv.DatabaseNames.Add(db.ConnectionParams.DatabaseName);
     srv.DatabaseFileNames.Add(db.DatabaseFileName);
     srv.Active := true;
     db.Open;
    end;
   if (UseSQL) then
    begin
     WriteToProcessLog(capt+'creating database...');
     q.SQL.LoadFromFile(SQLDir+'stored_procedures_db.sql');
     q.ExecSQL;
     WriteToProcessLog(capt+'creating database...OK');
     WriteToProcessLog(capt+'creating procedures...');
     for i := 0 to procList.Count-1 do
      begin
       q.SQL.Text := procList[i];
       q.ExecSQL;
       WriteToProcessLog(capt+'Stored Procedure #'+IntToStr(i)+' - '+procNames[i]+' created!');
      end;
     WriteToProcessLog(capt+'creating procedures...OK');
    end
   else
    begin
     WriteToProcessLog(capt+'creating database...');
     // customers
     t.TableName := 'customers';
     t.ClearDefinitions;
     t.AdvFieldDefs.Add('ID',aftAutoInc);
     t.AdvFieldDefs.Add('Name',aftWideChar,50);
     t.AdvFieldDefs.Add('Mail',aftWideChar,50);
     t.IndexDefs.Add('PK','ID',[ixPrimary]);
     t.CreateTable;
     t.Open;
     // 1
     t.InsertRecord([Null,'Mark Johnson','mark_johnson@aol.com']);
     // 2
     t.InsertRecord([Null,'Alex Stone','alex.stone@aol.com']);
     // 3
     t.InsertRecord([Null,'Ann Swensson','ann.swenson@yahoo.com']);
     t.Close;
     // products
     t.TableName := 'products';
     t.ClearDefinitions;
     t.AdvFieldDefs.Add('ID',aftAutoInc);
     t.AdvFieldDefs.Add('Name',aftWideChar,30);
     t.AdvFieldDefs.Add('Version',aftDouble,0);
     t.IndexDefs.Add('PK','ID',[ixPrimary]);
     t.CreateTable;
     t.Open;
     t.InsertRecord([Null,'EasyTable',6.40]);          // 1
     t.InsertRecord([Null,'Single File System',2.70]); // 2
     t.InsertRecord([Null,'SQLMemTable',4.20]);        // 3
     t.InsertRecord([Null,'Accuracer',5.10]);          // 4
     t.InsertRecord([Null,'CryptoPressStream',2.00]);  // 5
     t.InsertRecord([Null,'MsgCommunicator',4.10]);    // 6
     t.Close;
     // orders
     t.TableName := 'orders';
     t.ClearDefinitions;
     t.AdvFieldDefs.Add('ID',aftAutoInc);
     t.AdvFieldDefs.Add('CustomerID',aftInteger);
     t.AdvFieldDefs.Add('ProductID',aftInteger);
     t.AdvFieldDefs.Add('Date',aftDateTime,0);
     t.AdvFieldDefs.Add('Price',aftDouble,0);
     t.AdvFieldDefs.Add('Qty',aftByte,0);
     t.IndexDefs.Add('PK','ID',[ixPrimary]);
     t.CreateTable;
     t.Open;
     t.InsertRecord([Null,1,1,EncodeDateTime(2009,12,23,15,46,35,234),50.0,2]);
     t.InsertRecord([Null,2,2,EncodeDateTime(2009,12,25,14,0,0,0),300.0,1]);
     t.InsertRecord([Null,2,4,EncodeDateTime(2009,12,25,14,0,0,0),600.0,1]);
     t.InsertRecord([Null,3,5,EncodeDateTime(2010,1,15,11,0,0,0),250.0,1]);
     t.InsertRecord([Null,3,4,EncodeDateTime(2010,1,15,11,0,0,0),350.0,1]);
     t.Close;
     WriteToProcessLog(capt+'creating database...OK');
     WriteToProcessLog(capt+'creating procedures...');
     for i := 0 to procList.Count-1 do
      begin
       db.CreateStoredFunction(procList[i]);
       WriteToProcessLog(capt+'Stored Procedure #'+IntToStr(i)+' - '+procNames[i]+' created!');
      end;
     WriteToProcessLog(capt+'creating procedures...OK');
    end; // create without SQL
   WriteToProcessLog(capt+'checking procedures...OK');
   // sort by creation order
   db.GetStoredFunctions(proc1,proc2,True);
   if (proc1.Count <> proc2.Count) then
    begin
     WriteToErrorLog(capt+'error checking procedures list - invalid count = '+IntToStr(proc1.Count)+', '+IntToStr(proc2.Count));
    end
   else
    begin
     if (proc1.Count <> NumFunctions) then
      WriteToErrorLog(capt+'error checking procedures list - invalid count = '+IntToStr(proc1.Count)+', '+IntToStr(NumFunctions))
     else
      begin
       for i := 0 to NumFunctions-1 do
        begin
          if (proc1[i] <> StoredFunctionNames[i]) then
           WriteToErrorLog(capt+'error checking names, i = '+IntToStr(i)+#9+'proc1[i] = '+proc1[i]+#9+StoredFunctionNames[i]);
          k := Pos(proc1[i],proc2[i]);
          if (k = 0) then
           WriteToErrorLog(capt+'error checking names, i = '+IntToStr(i)+#9+'proc1[i] = '+proc1[i]+#9+proc2[i]);
        end;
      end;
    end;
   sqlScript := db.ExportDatabaseToSQL();
   WriteToProcessLog('Export database to SQL: ');
   WriteToProcessLog(sqlScript);
   for i := 0 to proc1.Count-1 do
    begin
     k := Pos(proc1[i],sqlScript);
     if (k = 0) then
      WriteToErrorLog(capt+'export error: function "'+proc1[i]+'" not found!');
    end;
   // delete stored functions
   for i := 0 to proc1.Count-1 do
    begin
     if (db.FindStoredFunction(proc1[i]) <> proc2[i]) then
      WriteToErrorLog('Function "'+proc1[i]+'" does not exist');
     if (UseSQL) then
      begin
       q.SQL.Text := 'DROP PROCEDURE '+proc1[i];
       q.ExecSQL;
      end
     else
      db.DropStoredFunction(proc1[i]);
     if (db.FindStoredFunction(proc1[i]) <> '') then
      WriteToErrorLog('Function "'+proc1[i]+'" was not deleted');
    end;
   // drop all database
   if (not CSMode) then
    begin
      db.Close;
      db.DeleteDatabase;
      db.CreateDatabase;
      db.Open;
    end;
   // recreate from SQL script
   q.SQL.Text := sqlScript;
   q.ExecSQL;
   q.SQL.Clear;
   for i := 0 to proc1.Count-1 do
    begin
     ws := db.FindStoredFunction(proc1[i]);
     if (ws <> proc2[i]) then
      WriteToErrorLog('Function "'+proc1[i]+'" does not exist');
    end;
   // drop all database
   if (not CSMode) and (DiskMode) then
    begin
       db.Close;
       db.Exclusive := True;
       db.RepairDatabase(True);
       db.Open;
       for i := 0 to proc1.Count-1 do
        begin
         ws := db.FindStoredFunction(proc1[i]);
         if (ws <> proc2[i]) then
          WriteToErrorLog('Function "'+proc1[i]+'" does not exist');
        end;
       db.Close;
       db.RepairDatabase(False);
       db.Open;
       for i := 0 to proc1.Count-1 do
        begin
         ws := db.FindStoredFunction(proc1[i]);
         if (ws <> proc2[i]) then
          WriteToErrorLog('Function "'+proc1[i]+'" does not exist');
        end;
    end;
 finally
   proc.Free;
   proc1.Free;
   proc2.Free;
 end;
end; // CreateDB


procedure TUnitTestStoredProcedures.DeleteDB(UseSQL, DiskMode, CSMode: Boolean);
begin
 procList.Free;
 procNames.Free;
 db.Close;
 if (not DiskMode) then
  db.DeleteDatabase;
 srv.Free;
 q.Free;
 t.Free;
 if (CSMode) then
  begin
    db.LocalDatabase := True;
    Sleep(16);
  end;
{$IFNDEF DO_NOT_DELETE_DB}
 db.DeleteDatabase;
 Sleep(16);
{$ENDIF}
 db.Free;
end;

procedure TUnitTestStoredProcedures.MainTest;
begin
  RunMainTest(True,False,False);
//exit;
  // local mode - disk, SQL
  RunMainTest(True,True,False);
  // local mode - disk, no SQL
  RunMainTest(False,True,False);

  // local mode - memory, SQL
  RunMainTest(True,False,False);
  // local mode - memory, no SQL
  RunMainTest(False,False,False);
//exit;
{$IFNDEF NO_NETWORK}
  // remote mode - disk, no SQL
{ TODO -oLeo : implement it in client-server }
//  RunMainTest(False,True,True);
  // remote mode - disk, SQL
  RunMainTest(True,True,True);
  // remote mode - memory, no SQL
{ TODO -oLeo : implement it in client-server }
//  RunMainTest(False,False,True);
  // remote mode - memory, SQL
  RunMainTest(True,False,True);
{$ENDIF}
end; // MainTest


procedure TUnitTestStoredProcedures.InternalTest_Jacque_Lafitte_Bugs(InMmemory: Boolean);
var capt,s:           String;
    q:                TACRQuery;
    db:               TACRDatabase;
    tempStringList:   TStringList;
    i:                Integer;
begin
  if (InMmemory) then
   capt := 'Test_Jacque_Lafitte_Bugs (MEMORY) - '
  else
   capt := 'Test_Jacque_Lafitte_Bugs (DISK) - ';
  db := TACRDatabase.Create(nil);
  q := TACRQuery.Create(nil);
  try
    if (InMmemory) then
    begin
      db.InMemory := True;
      db.DatabaseName := capt;
      db.CreateDatabase;
      db.Open;
      q.InMemory := True;
    end
    else
    begin
      db.InMemory := False;
      db.DatabaseName := capt;
      db.DatabaseFileName := TempDir+'test_jacque_lafittle_stored_functions_bugs.adb';
      db.CreateDatabase;
      db.Open;
      q.InMemory := False;
    end;
    q.DatabaseName := db.DatabaseName;
    q.SQL.LoadFromFile(SQLDir+'test_jacque_lafittle_03_01_2011.sql');
    q.ExecSQL;

    // Error: 16
    q.SQL.Clear;
    q.SQL.Add('select FInteger, GetCountryAge(FString, FDateTime, 2010, ''years'') As Bug2, Cast(''This string should be truncated'', Char(4)) As Bug3 from T1 ORDER BY FINTEGER');
    q.Open;

    if (q.RecordCount <> 5) then
     WriteToErrorLog(capt+'Error #1 '+IntToStr(q.RecordCount))
    else
    begin
     if (q.Fields[0].AsInteger <> 1) then
      WriteToErrorLog(capt+'Error #2 '+q.Fields[0].AsString)
     else
     if (q.Fields[1].AsString <> 'France (-1 years)') then
      WriteToErrorLog(capt+'Error #3 '+q.Fields[1].AsString)
     else
     if (q.Fields[2].AsString <> 'This') then
      WriteToErrorLog(capt+'Error #4 '+q.Fields[2].AsString);
     q.Next;
     if (q.Fields[0].AsInteger <> 2) then
      WriteToErrorLog(capt+'Error #5 '+q.Fields[0].AsString)
     else
     if (q.Fields[1].AsString <> 'England (-1 years)') then
      WriteToErrorLog(capt+'Error #6 '+q.Fields[1].AsString)
     else
     if (q.Fields[2].AsString <> 'This') then
      WriteToErrorLog(capt+'Error #7 '+q.Fields[2].AsString);
     q.Next;
     if (q.Fields[0].AsInteger <> 3) then
      WriteToErrorLog(capt+'Error #8 '+q.Fields[0].AsString)
     else
     if (q.Fields[1].AsString <> 'Russia (-1 years)') then
      WriteToErrorLog(capt+'Error #9 '+q.Fields[1].AsString)
     else
     if (q.Fields[2].AsString <> 'This') then
      WriteToErrorLog(capt+'Error #10 '+q.Fields[2].AsString);
     q.Next;
     if (q.Fields[0].AsInteger <> 4) then
      WriteToErrorLog(capt+'Error #11 '+q.Fields[0].AsString)
     else
     if (q.Fields[1].AsString <> 'Estonia (-1 years)') then
      WriteToErrorLog(capt+'Error #12 '+q.Fields[1].AsString)
     else
     if (q.Fields[2].AsString <> 'This') then
      WriteToErrorLog(capt+'Error #13 '+q.Fields[2].AsString);
     q.Next;
     if (q.Fields[0].AsInteger <> 5) then
      WriteToErrorLog(capt+'Error #14 '+q.Fields[0].AsString)
     else
     if (q.Fields[1].AsString <> 'Portugal (-1 years)') then
      WriteToErrorLog(capt+'Error #15 '+q.Fields[1].AsString)
     else
     if (q.Fields[2].AsString <> 'This') then
      WriteToErrorLog(capt+'Error #16 '+q.Fields[2].AsString);
     q.Next;
    end;

    q.Close;

    tempStringList := TStringList.Create();
    try
      db.GetStoredFunctions(tempStringList, nil, False);
      for i := 0 to tempStringList.Count - 1 do
      begin
        q.SQL.Text := 'drop function ' + tempStringList.Strings[i];
        q.ExecSQL;
      end;
    finally
      tempStringList.Free;
    end;
    
  finally
    q.Free;
    db.Close;
    db.DeleteDatabase;
    db.Free;
  end;
end;

procedure TUnitTestStoredProcedures.Test_Jacque_Lafitte_Bugs;
begin
  InternalTest_Jacque_Lafitte_Bugs(False);
  InternalTest_Jacque_Lafitte_Bugs(True);
end;


procedure TUnitTestStoredProcedures.RunMainTest(UseSQL, DiskMode, CSMode: Boolean);
begin
 if (CSMode) then
  capt := 'REMOTE '
 else
  capt := 'LOCAL ';
 if (UseSQL) then
  capt := capt + ' WITH SQL '
 else
  capt := capt + ' WITHOUT SQL ';
 if (DiskMode) then
  capt := capt + 'DISK DATABASE - '
 else
  capt := capt + 'MEMORY DATABASE - ';
 CreateDB(UseSQL,DiskMode,CSMode);
 try
   WriteToProcessLog(capt+'db created');

   if (UseSQL) then
    RunSQLTest(False)
   else
    RunTableTest;

   db.FlushFileBuffers;
   db.ClearCache;
   db.Close;
   db.Open;

   capt := capt + ' REOPEN - ';
   if (UseSQL) then
    RunSQLTest(True)
   else
    RunTableTest;

   WriteToProcessLog(capt+'test complete');
 finally
   DeleteDB(UseSQL,DiskMode,CSMode);
   WriteToProcessLog(capt+'db celeted');
 end;
end;


procedure TUnitTestStoredProcedures.RunSQLTest(Live: Boolean);
var TestNo:    Integer;
    fName,s,df:   String;

function GetErrorText(ErrNo: Integer): String;
begin
  Result := 'SQL Test #'+IntToStr(TestNo)
            +#9+'Error #'+IntToStr(ErrNo)
            +#9+#13#10+'SQL:'
            +#13#10+q.SQL.Text;
end;

begin
(*
// products
     t.InsertRecord([Null,'EasyTable',6.40]);          // 1
     t.InsertRecord([Null,'Single File System',2.70]); // 2
     t.InsertRecord([Null,'SQLMemTable',4.20]);        // 3
     t.InsertRecord([Null,'Accuracer',5.10]);          // 4
     t.InsertRecord([Null,'CryptoPressStream',2.00]);  // 5
     t.InsertRecord([Null,'MsgCommunicator',4.10]);    // 6

*)
  WriteToProcessLog(capt+'Starting SQL test...');
  q.RequestLive := Live;

  // Test# 12
  TestNo := 12;
  q.SQL.Text :=         'EXECUTE PROCEDURE InsertRecordToTelTable("a","1234");'
                +#13#10+'EXECUTE PROCEDURE InsertRecordToTelTable("b","68795");'
                +#13#10+'EXECUTE PROCEDURE InsertRecordToTelTable("a","12345");'
                ;
  q.ExecSQL;
  q.SQL.Text := 'select * from TelTable ORDER BY 1';
  q.Open;
  if (q.RecordCount <> 2) then
    WriteToErrorLog(GetErrorText(1)+IntToStr(q.RecordCount))
  else
  if (q.FieldCount <> 2) then
    WriteToErrorLog(GetErrorText(2)+IntToStr(q.FieldCount))
  else
  begin
   if (q.Fields[0].AsString <> 'a') then
    WriteToErrorLog(GetErrorText(3)+q.Fields[0].AsString);
   if (q.Fields[1].AsString <> '1234') then
    WriteToErrorLog(GetErrorText(4)+q.Fields[1].AsString);
   q.Next;
   if (q.Fields[0].AsString <> 'b') then
    WriteToErrorLog(GetErrorText(5)+q.Fields[0].AsString);
   if (q.Fields[1].AsString <> '68795') then
    WriteToErrorLog(GetErrorText(6)+q.Fields[1].AsString);
   q.Next;
   if (not q.Eof) then
    WriteToErrorLog(GetErrorText(7));
  end;

  // Test# 11
  TestNo := 11;
  q.SQL.Text :=         'DROP TABLE T1 CASCADE;'
                +#13#10+'CREATE TABLE T1 (FString STRING (30),FInteger INTEGER,FDateTime DATETIME);'
                +#13#10+'INSERT INTO T1 VALUES ("France",1,TODATE("12/30/2009 14:53:43:828","M/D/YYYY H24:N:S:Z"));'
                +#13#10+'INSERT INTO T1 VALUES ("England",2,TODATE("12/30/2010 14:53:43:828","M/D/YYYY H24:N:S:Z"));'
                +#13#10+'INSERT INTO T1 VALUES ("Russia",3,TODATE("12/30/2010 14:53:43:828","M/D/YYYY H24:N:S:Z"));'
                +#13#10+'INSERT INTO T1 VALUES ("Estonia",4,TODATE("12/30/2010 14:53:43:828","M/D/YYYY H24:N:S:Z"));'
                +#13#10+'INSERT INTO T1 VALUES ("Portugal",5,TODATE("12/30/2010 14:53:43:828","M/D/YYYY H24:N:S:Z"));'
                ;
  q.ExecSQL;
  WriteToProcessLog(capt+'SQL test #'+IntToStr(TestNo)+' table created');
  q.SQL.Text :=         'Create Function GetDateFromYear(INValue:Integer):DateTime;'
                +#13#10+'var'
                +#13#10+'tempDate:String;'
                +#13#10+'Begin'
                +#13#10+'Result := Null;'
                +#13#10+'If INValue Is Not Null Then'
                +#13#10+'Begin'
                +#13#10+'tempDate := "31-12-" + Cast(INValue, String);'
                +#13#10+'Result := ToDate(tempDate, "dd-mm-yyyy");'
                +#13#10+'End;'
                +#13#10+'End;'

                +#13#10+'Create Function GetAgeFromYear(INBirthDate:DateTime; INYear:Integer; INLocYears:String):String;'
                +#13#10+'var'
                +#13#10+'tempDate:DateTime;'
                +#13#10+'Begin'
                +#13#10+'Result := Null;'
                +#13#10+'tempDate := GetDateFromYear(INYear);'
                +#13#10+'If (INBirthDate Is Not Null) And (tempDate Is Not Null) Then'
                +#13#10+'Begin'
                +#13#10+'Result := Cast(DateDiff(YEAR, INBirthDate, tempDate), String) + " " + INLocYears;'
                +#13#10+'End;'
                +#13#10+'End;'

                +#13#10+'Create Function GetCountryAge(INCountryName:String; INBirthDate:DateTime; INYear:Integer; INLocYears:String):String;'
                +#13#10+'var'
                +#13#10+'tempAge:String;'
                +#13#10+'tempString:String;'
                +#13#10+'Begin'
                +#13#10+'tempAge := Null;'
                +#13#10+'tempString := Null;'
                +#13#10+'tempAge := GetAgeFromYear(INBirthDate, INYear, INLocYears);'
                +#13#10+'If (INCountryName Is Not Null) and (Length(INCountryName) > 0) Then tempString := INCountryName;'
                +#13#10+'If tempAge Is Not Null Then'
                +#13#10+'Begin'
                +#13#10+'If (tempString Is Not Null) and (Length(tempString) > 0) Then'
                +#13#10+'tempString := tempString + " (" + tempAge + ")"'
                +#13#10+'Else'
                +#13#10+'tempString := tempAge;'
                +#13#10+'End;'
                +#13#10+'Result := tempString;'
                +#13#10+'End;'
            ;
  q.ExecSQL;
  WriteToProcessLog(capt+'SQL test #'+IntToStr(TestNo)+' age functions created');

  q.SQL.Text := 'select TOP 1 FInteger, GetCountryAge(FString, FDateTime, 2010, "years") As Bug2, FString from T1 ORDER BY 1';
  q.Open;
  if (q.RecordCount <> 1) then
    WriteToErrorLog(GetErrorText(4)+IntToStr(q.RecordCount))
  else
  if (q.FieldCount <> 3) then
    WriteToErrorLog(GetErrorText(5)+IntToStr(q.FieldCount))
  else
  begin
   if (q.Fields[0].AsInteger <> 1) then
    WriteToErrorLog(GetErrorText(6)+q.Fields[0].AsString);
   s := 'France (1 years)';
   if (q.Fields[1].AsString <> s) then
    WriteToErrorLog(GetErrorText(7)+q.Fields[0].AsString+#9+q.Fields[1].AsString+#9+q.Fields[2].AsString);
   q.Next;
   if (not q.Eof) then
    WriteToErrorLog(GetErrorText(8));
  end;

  q.SQL.Text :=
            'create function MyFunction1(INDate:DateTime):String;' + #13#10 +
            'var' + #13#10 +
            'tString:String;' + #13#10 +
            'begin' + #13#10 +
            'tString := ''Today is '' + Cast((Now), String);' + #13#10 +
            'Result := tString;' + #13#10 +
            'end;'
            ;
  q.ExecSQL;
  WriteToProcessLog(capt+'SQL test #'+IntToStr(TestNo)+' function MyFunction1 created');

  q.SQL.Text := 'select TOP 1 FInteger, Now as CurDate, MyFunction1(CurDate) As Bug1 from T1 order by 1;';
  q.Open;
  if (q.RecordCount <> 1) then
    WriteToErrorLog(GetErrorText(0)+IntToStr(q.RecordCount))
  else
  if (q.FieldCount <> 3) then
    WriteToErrorLog(GetErrorText(1)+IntToStr(q.FieldCount))
  else
  begin
   if (q.Fields[0].AsInteger <> 1) then
    WriteToErrorLog(GetErrorText(2)+q.Fields[0].AsString);
   s := DateTimeToStr(q.Fields[1].AsDateTime);
   if (q.Fields[2].AsString <> 'Today is '+s) then
    WriteToErrorLog(GetErrorText(2)+q.Fields[2].AsString+#9+q.Fields[1].AsString);
   q.Next;
   if (not q.Eof) then
    WriteToErrorLog(GetErrorText(3));
  end;

  if (not q.InMemory) then
  begin
    db.Close;
    db.Open;
  end;

  q.SQL.Text := 'DROP FUNCTION GetCountryAge';
  q.ExecSQL;

  q.SQL.Text := 'DROP FUNCTION GetAgeFromYear';
  q.ExecSQL;

  q.SQL.Text := 'DROP FUNCTION GetDateFromYear';
  q.ExecSQL;

  q.SQL.Text := 'DROP TABLE T1 CASCADE; DROP FUNCTION MyFunction1;';
  q.ExecSQL;
  WriteToProcessLog(capt+'SQL test #'+IntToStr(TestNo)+' finished');

  // Test# 11


  // Test# 10
  TestNo := 10;
  q.SQL.Text := 'SELECT TOP 1 MyYearDiff(TODATE("25.05.1910","DD.MM.YYYY"),TODATE("28.01.2010","DD.MM.YYYY")) FROM TABLES;';
  q.Open;
  if (q.RecordCount <> 1) then
  WriteToErrorLog(GetErrorText(0)+IntToStr(q.RecordCount))
  else
  if (q.FieldCount <> 1) then
  WriteToErrorLog(GetErrorText(1)+IntToStr(q.FieldCount))
  else
  begin
   if (q.Fields[0].AsInteger <> 100) then
    WriteToErrorLog(GetErrorText(2)+q.Fields[0].AsString);
   q.Next;
   if (not q.Eof) then
    WriteToErrorLog(GetErrorText(3));
  end;
  WriteToProcessLog(capt+'SQL test #'+IntToStr(TestNo)+' finished');
  // Test# 10

  // Test# 9
  TestNo := 9;
  q.SQL.Text := 'SELECT TOP 1 MyYear(TODATE("25.05.1910","DD.MM.YYYY")) FROM TABLES;';
  q.Open;
  if (q.RecordCount <> 1) then
  WriteToErrorLog(GetErrorText(0)+IntToStr(q.RecordCount))
  else
  if (q.FieldCount <> 1) then
  WriteToErrorLog(GetErrorText(1)+IntToStr(q.FieldCount))
  else
  begin
   if (q.Fields[0].AsInteger <> 1910) then
    WriteToErrorLog(GetErrorText(2)+q.Fields[0].AsString);
   q.Next;
   if (not q.Eof) then
    WriteToErrorLog(GetErrorText(3));
  end;
  WriteToProcessLog(capt+'SQL test #'+IntToStr(TestNo)+' finished');
  // Test# 9

  // Test# 8
  TestNo := 8;
  q.SQL.Text := 'SELECT TOP 1 MyYear(NOW) as y1, EXTRACT(YEAR FROM NOW) as y2 FROM TABLES;';
  q.Open;
  if (q.RecordCount <> 1) then
  WriteToErrorLog(GetErrorText(0)+IntToStr(q.RecordCount))
  else
  if (q.FieldCount <> 2) then
  WriteToErrorLog(GetErrorText(1)+IntToStr(q.FieldCount))
  else
  begin
   if (q.Fields[0].AsInteger <> q.Fields[1].AsInteger) then
    WriteToErrorLog(GetErrorText(2)+q.Fields[0].AsString+#9+q.Fields[1].AsString);
   q.Next;
   if (not q.Eof) then
    WriteToErrorLog(GetErrorText(3));
  end;
  WriteToProcessLog(capt+'SQL test #'+IntToStr(TestNo)+' finished');
  // Test# 8

  // Test# 7
  TestNo := 7;
  q.SQL.Text := 'SELECT TOP 1 DivideByTwo(7) as div2 FROM TABLES;';
  q.Open;
  if (q.RecordCount <> 1) then
  WriteToErrorLog(GetErrorText(0)+IntToStr(q.RecordCount))
  else
  begin
   if (q.Fields[0].AsInteger <> 3) then
    WriteToErrorLog(GetErrorText(1)+IntToStr(q.RecNo)+#9+q.Fields[0].AsString);
   q.Next;
   if (not q.Eof) then
    WriteToErrorLog(GetErrorText(2));
  end;
  WriteToProcessLog(capt+'SQL test #'+IntToStr(TestNo)+' finished');
  // Test# 7

  // Test# 6
  TestNo := 6;
  q.SQL.Text := 'SELECT GetEvenOdd1(ID) as even_odd FROM products ORDER BY ID;';
  q.Open;
  if (q.RecordCount <> 6) then
  WriteToErrorLog(GetErrorText(0)+IntToStr(q.RecordCount))
  else
  begin
   if (q.Fields[0].AsString <> 'Odd') then
    WriteToErrorLog(GetErrorText(1)+IntToStr(q.RecNo)+#9+q.Fields[0].AsString);
   q.Next;
   if (q.Fields[0].AsString <> 'Even') then
    WriteToErrorLog(GetErrorText(2)+IntToStr(q.RecNo)+#9+q.Fields[0].AsString);
   q.Next;
   if (q.Fields[0].AsString <> 'Odd') then
    WriteToErrorLog(GetErrorText(3)+IntToStr(q.RecNo)+#9+q.Fields[0].AsString);
   q.Next;
   if (q.Fields[0].AsString <> 'Even') then
    WriteToErrorLog(GetErrorText(4)+IntToStr(q.RecNo)+#9+q.Fields[0].AsString);
   q.Next;
   if (q.Fields[0].AsString <> 'Odd') then
    WriteToErrorLog(GetErrorText(5)+IntToStr(q.RecNo)+#9+q.Fields[0].AsString);
   q.Next;
   if (q.Fields[0].AsString <> 'Even') then
    WriteToErrorLog(GetErrorText(6)+IntToStr(q.RecNo)+#9+q.Fields[0].AsString);
   q.Next;
   if (not q.Eof) then
    WriteToErrorLog(GetErrorText(7));
  end;
  WriteToProcessLog(capt+'SQL test #'+IntToStr(TestNo)+' finished');
  // Test# 6

  // Test# 5
  TestNo := 5;
  q.SQL.Text := 'SELECT GetEvenOdd(ID) as even_odd FROM products ORDER BY ID;';
  q.Open;
  if (q.RecordCount <> 6) then
  WriteToErrorLog(GetErrorText(0)+IntToStr(q.RecordCount))
  else
  begin
   if (q.Fields[0].AsString <> 'Odd') then
    WriteToErrorLog(GetErrorText(1)+IntToStr(q.RecNo)+#9+q.Fields[0].AsString);
   q.Next;
   if (q.Fields[0].AsString <> 'Even') then
    WriteToErrorLog(GetErrorText(2)+IntToStr(q.RecNo)+#9+q.Fields[0].AsString);
   q.Next;
   if (q.Fields[0].AsString <> 'Odd') then
    WriteToErrorLog(GetErrorText(3)+IntToStr(q.RecNo)+#9+q.Fields[0].AsString);
   q.Next;
   if (q.Fields[0].AsString <> 'Even') then
    WriteToErrorLog(GetErrorText(4)+IntToStr(q.RecNo)+#9+q.Fields[0].AsString);
   q.Next;
   if (q.Fields[0].AsString <> 'Odd') then
    WriteToErrorLog(GetErrorText(5)+IntToStr(q.RecNo)+#9+q.Fields[0].AsString);
   q.Next;
   if (q.Fields[0].AsString <> 'Even') then
    WriteToErrorLog(GetErrorText(6)+IntToStr(q.RecNo)+#9+q.Fields[0].AsString);
   q.Next;
   if (not q.Eof) then
    WriteToErrorLog(GetErrorText(7));
  end;
  WriteToProcessLog(capt+'SQL test #'+IntToStr(TestNo)+' finished');
  // Test# 5

  // Test# 4
  TestNo := 4;
  fName := 'TempExecute';
  s :=          'CREATE FUNCTION '+fName+': INTEGER;'
       +#13#10+'BEGIN'
       +#13#10+'RESULT := 1;'
       +#13#10+'END;';
  q.SQL.Text := s;
  q.ExecSQL;

//  q.SQL.Text := 'SELECT Name FROM products WHERE ID = 1 ';
  q.SQL.Text := 'SELECT Name FROM products WHERE ID = '+fName;
  q.Open;
  if (q.RecordCount <> 1) then
  WriteToErrorLog(GetErrorText(0)+IntToStr(q.RecordCount))
  else
  if (q.Fields[0].AsString <> 'EasyTable') then
    WriteToErrorLog(GetErrorText(1)+q.Fields[0].AsString);
  q.Close;


  s :=          'CREATE FUNCTION '+fName+': INTEGER;'
       +#13#10+'BEGIN'
       +#13#10+'RESULT := 4;'
       +#13#10+'END;';

  q.SQL.Text := 'ALTER FUNCTION '+fName+' MODIFY '+AnsiQuotedStr(s,'"');
  q.ExecSQL;

  q.SQL.Text := 'SELECT Name FROM products WHERE ID = '+fName;
  q.Open;
  if (q.RecordCount <> 1) then
  WriteToErrorLog(GetErrorText(2)+IntToStr(q.RecordCount))
  else
  if (q.Fields[0].AsString <> 'Accuracer') then
    WriteToErrorLog(GetErrorText(3)+q.Fields[0].AsString);
  q.Close;

  q.SQL.Text := 'ALTER FUNCTION '+fName+' RENAME TO DUMMY_FUNCTION_TO DROP';
  q.ExecSQL;

  q.SQL.Text := 'DROP FUNCTION DUMMY_FUNCTION_TO DROP';
  q.ExecSQL;

  if (db.FindStoredFunction(fName) <> '') then
  WriteToErrorLog(GetErrorText(4));
  if (db.FindStoredFunction('DUMMY_FUNCTION_TO DROP') <> '') then
  WriteToErrorLog(GetErrorText(5));
  WriteToProcessLog(capt+'SQL test #'+IntToStr(TestNo)+' finished');
  // Test# 4

  // Test# 3
  TestNo := 3;
  q.SQL.Text := 'EXECUTE FUNCTION Execute1(1,"Demo value!");';
  q.ExecSQL;
  q.SQL.Text := 'SELECT * FROM TestExecute1;';
  q.Open;
  if (q.RecordCount <> 1) then
  WriteToErrorLog(GetErrorText(2)+'RecordCount = '+IntToStr(q.RecordCount))
  else
  begin
   if (q.Fields[0].AsInteger <> 1) then
    WriteToErrorLog(GetErrorText(2)+'Field0 = '+q.Fields[0].AsString);
   if (q.Fields[1].AsString <> 'Demo value!') then
    WriteToErrorLog(GetErrorText(3)+'Field1 = '+q.Fields[1].AsString);
  end;
  q.Close;
  WriteToProcessLog(capt+'SQL test #'+IntToStr(TestNo)+' finished');
  // Test# 3

  // Test# 2
  TestNo := 2;
  //Version
  q.SQL.Text := 'SELECT GetVersionText(Version) as full_name FROM products ORDER BY ID;';
  q.Open;
  if (q.RecordCount <> 6) then
  WriteToErrorLog(GetErrorText(1)+'RecCount = '+IntToStr(q.RecordCount));
  if (q.FieldCount <> 1) then
  WriteToErrorLog(GetErrorText(2)+'FieldCount = '+IntToStr(q.FieldCount));
  if (q.FieldDefs[0].Name <> 'full_name') then
  WriteToErrorLog(GetErrorText(3)+'FieldName = '+q.FieldDefs[0].Name);

  if (q.Fields[0].AsString <> 'version 6.4') then
  WriteToErrorLog(GetErrorText(4)+'Fields[0] = '+q.Fields[0].AsString);
  q.Next;

  if (q.Fields[0].AsString <> 'version 2.7') then
  WriteToErrorLog(GetErrorText(5)+'Fields[0] = '+q.Fields[0].AsString);
  q.Next;

  if (q.Fields[0].AsString <> 'version 4.2') then
  WriteToErrorLog(GetErrorText(6)+'Fields[0] = '+q.Fields[0].AsString);
  q.Next;

  if (q.Fields[0].AsString <> 'version 5.1') then
  WriteToErrorLog(GetErrorText(7)+'Fields[0] = '+q.Fields[0].AsString);
  q.Next;

  if (q.Fields[0].AsString <> 'version 2') then
  WriteToErrorLog(GetErrorText(8)+'Fields[0] = '+q.Fields[0].AsString);
  q.Next;

  if (q.Fields[0].AsString <> 'version 4.1') then
  WriteToErrorLog(GetErrorText(9)+'Fields[0] = '+q.Fields[0].AsString);
  q.Next;
  if (not q.Eof) then
  WriteToErrorLog(GetErrorText(10));
  q.Close;
  WriteToProcessLog(capt+'SQL test #'+IntToStr(TestNo)+' finished');
  // Test# 2

  // Test# 1
  TestNo := 1;
  q.SQL.Text := 'SELECT GetStringConstant+CAST(Version as CHAR) as full_name FROM products ORDER BY ID';
  q.Open;
  if (q.RecordCount <> 6) then
  WriteToErrorLog(GetErrorText(1)+'RecCount = '+IntToStr(q.RecordCount));
  if (q.FieldCount <> 1) then
  WriteToErrorLog(GetErrorText(2)+'FieldCount = '+IntToStr(q.FieldCount));
  if (q.FieldDefs[0].Name <> 'full_name') then
  WriteToErrorLog(GetErrorText(3)+'FieldName = '+q.FieldDefs[0].Name);

  if (q.Fields[0].AsString <> 'version 6.4') then
  WriteToErrorLog(GetErrorText(4)+'Fields[0] = '+q.Fields[0].AsString);
  q.Next;

  if (q.Fields[0].AsString <> 'version 2.7') then
  WriteToErrorLog(GetErrorText(5)+'Fields[0] = '+q.Fields[0].AsString);
  q.Next;

  if (q.Fields[0].AsString <> 'version 4.2') then
  WriteToErrorLog(GetErrorText(6)+'Fields[0] = '+q.Fields[0].AsString);
  q.Next;

  if (q.Fields[0].AsString <> 'version 5.1') then
  WriteToErrorLog(GetErrorText(7)+'Fields[0] = '+q.Fields[0].AsString);
  q.Next;

  if (q.Fields[0].AsString <> 'version 2') then
  WriteToErrorLog(GetErrorText(8)+'Fields[0] = '+q.Fields[0].AsString);
  q.Next;

  if (q.Fields[0].AsString <> 'version 4.1') then
  WriteToErrorLog(GetErrorText(9)+'Fields[0] = '+q.Fields[0].AsString);
  q.Next;
  if (not q.Eof) then
  WriteToErrorLog(GetErrorText(10));
  WriteToProcessLog(capt+'SQL test #'+IntToStr(TestNo)+' finished');
  // Test# 1




 q.Close;
{ TODO :
q.Close;
// without it does not work in memory mode }

 WriteToProcessLog(capt+'SQL test finished');
end;

procedure TUnitTestStoredProcedures.RunTableTest;
var TestNo: Integer;
    Params: TACRSQLParams;
    Param:  TACRSQLParam;
    ResultValue: TACRVariant;

function GetErrorText(ErrNo: Integer): String;
begin
  Result := 'Table Test #'+IntToStr(TestNo)
            +#9+'Error #'+IntToStr(ErrNo);
end;
begin
 Params := TACRSQLParams.Create;
 ResultValue := TACRSQLParam.Create();
 try
   // Test# 1
   TestNo := 1;
   Params.Clear;
   Param := Params.AddCreated;
   Param.Name := 'P1';
   Param.AsInteger := 2;
   Param := Params.AddCreated;
   Param.Name := 'P2';
   Param.AsString := 'Table Insert!';
   // call function
   db.ExecuteStoredFunction('Execute1',ResultValue,Params);
   if (not ResultValue.IsNull) then
    WriteToErrorLog(GetErrorText(0));
   // check data
   t.TableName := 'TestExecute1';
   if (not t.Exists) then
    WriteToErrorLog(GetErrorText(1))
   else
    begin
     t.Open;
     if (t.RecordCount <> 1) then
      WriteToErrorLog(GetErrorText(2)+'RecordCount = '+IntToStr(t.RecordCount))
     else
      begin
       if (t.Fields[0].AsInteger <> 2) then
        WriteToErrorLog(GetErrorText(2)+'Field0 = '+t.Fields[0].AsString);
       if (t.Fields[1].AsString <> 'Table Insert!') then
        WriteToErrorLog(GetErrorText(3)+'Field1 = '+t.Fields[1].AsString);
      end;
     t.Close;
    end;
   WriteToProcessLog(capt+'Table test #'+IntToStr(TestNo)+' finished');
   // Test# 1
 finally
   Params.Free;
   ResultValue.Free;
 end;
end;

procedure TUnitTestStoredProcedures.TestExceptions;
begin
;
end;


procedure TUnitTestStoredProcedures.TestShort;
begin
  CheckAction(Test_Jacque_Lafitte_Bugs,'Test Jacque Lafitte''s Bugs');
  CheckAction(MainTest,'Main Test for stored procedures');
end;


initialization
  UnitTestStoredProcedures := TUnitTestStoredProcedures.Create(UnitTestList);

finalization
  UnitTestStoredProcedures.Free;


end.
