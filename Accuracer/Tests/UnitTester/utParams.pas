unit utParams;

interface

{$I UTConfig.Inc}


uses SysUtils, Classes, DB,
{$IFDEF MSWINDOWS}
      DBTables,
      Controls, 
{$ENDIF}
      DBClient,
     SqlTimSt,
     uTestList,
     ACRMain, 
{$IFDEF ACR5H}
     ACRComMain,
{$ENDIF}
     ACRTypes, ACRConst, ACRClient, ACRServer
     ;

type

   TValueRecord = Record
     vChar:               String;
     vString:             String;

     vWideChar:           WideString;
     vWideString:         WideString;

     vShortint:           Shortint;
     vSmallint:           Smallint;
     vInteger:            Integer;
     vLargeint:           Largeint;
     vByte:               Byte;
     vWord:               Word;
     vCardinal:           Cardinal;

     vSingle:             Single;
     vDouble:             Double;
     vExtended:           Extended;

     vBoolean:            Boolean;

     vCurrency:           Currency;

     vDate:               TDate;
     vTime:               TTime;
     vDateTime:           TDateTime;
     vTimeStamp:          TSQLTimeStamp;

     //vBytes:              array [0..9] of Byte;
     //vVarBytes:           array [0..9] of Byte;

     vBlob:               String;
     vGraphic:            String;
     vMemo:               String;
     vFormattedMemo:      String;
     vWideMemo:           WideString;
   end;

var
  ValueRecord: TValueRecord;

type
  TUnitTestParams = class(TUnitTest)
   private
    function CreateACRTable: TACRTable;
    procedure DropACRTable(Table: TACRTable);
    procedure FillValueRecord(var vr: TValueRecord);
    procedure FillParams(var vr: TValueRecord; q: TACRQuery);
    procedure TestNameVariants;
    procedure CheckResult(t: TACRTable; vr:TValueRecord);
    procedure InternalTestPreparedParams(
                      RemoteDB: Boolean;
                      InMemory: Boolean;
                      Live:     Boolean
              );
   public
    procedure TestShort; override;
   public
    procedure TestParams;
    procedure TestPreparedParams;
  end;

var
  UnitTestParams: TUnitTestParams;


implementation

{ TUnitTestParams }


procedure TUnitTestParams.TestShort;
begin
  CheckAction(TestPreparedParams, 'Test Prepared Params');
  CheckAction(TestParams, 'Test Params');
  CheckAction(TestNameVariants,'Test name variants');
end;


function TUnitTestParams.CreateACRTable: TACRTable;
begin
  Result := TACRTable.Create(nil);
  with Result do begin

    TableName := 'test';
    InMemory := True;


    AdvFieldDefs.Clear;

    AdvFieldDefs.Add('vChar', aftChar, 100, False);

    AdvFieldDefs.Add('vString', aftString, 100, False);

    AdvFieldDefs.Add('vWideChar', aftWideChar, 100, False);
    AdvFieldDefs.Add('vWideString', aftWideString, 100, False);

    AdvFieldDefs.Add('vShortint', aftShortint, 0, False);
    AdvFieldDefs.Add('vSmallint', aftSmallint, 0, False);
    AdvFieldDefs.Add('vInteger', aftInteger, 0, False);
    AdvFieldDefs.Add('vLargeint', aftLargeint, 0, False);
    AdvFieldDefs.Add('vByte', aftByte, 0, False);
    AdvFieldDefs.Add('vWord', aftWord, 0, False);
    AdvFieldDefs.Add('vCardinal', aftCardinal, 0, False);

    AdvFieldDefs.Add('vAutoInc', aftAutoInc, 0, False);
    AdvFieldDefs.Add('vAutoIncShortint', aftAutoIncShortint, 0, False);
    AdvFieldDefs.Add('vAutoIncSmallint', aftAutoIncSmallint, 0, False);
    AdvFieldDefs.Add('vAutoIncInteger', aftAutoIncInteger, 0, False);
    AdvFieldDefs.Add('vAutoIncLargeint', aftAutoIncLargeint, 0, False);
    AdvFieldDefs.Add('vAutoIncByte', aftAutoIncByte, 0, False);
    AdvFieldDefs.Add('vAutoIncWord', aftAutoIncWord, 0, False);
    AdvFieldDefs.Add('vAutoIncCardinal', aftAutoIncCardinal, 0, False);

    AdvFieldDefs.Add('vSingle', aftSingle, 0, False);
    AdvFieldDefs.Add('vDouble', aftDouble, 0, False);
    AdvFieldDefs.Add('vExtended', aftExtended, 0, False);

    AdvFieldDefs.Add('vBoolean', aftBoolean, 0, False);

    AdvFieldDefs.Add('vCurrency', aftCurrency, 0, False);

    AdvFieldDefs.Add('vDate', aftDate, 0, False);
    AdvFieldDefs.Add('vTime', aftTime, 0, False);
    AdvFieldDefs.Add('vDateTime', aftDateTime, 0, False);
    AdvFieldDefs.Add('vTimeStamp', aftTimeStamp, 0, False);

//vBytes
//vVarBytes

    AdvFieldDefs.Add('vBlob', aftBlob, 0, False);
    AdvFieldDefs.Add('vGraphic', aftGraphic, 0, False);
    AdvFieldDefs.Add('vMemo', aftMemo, 0, False);
    AdvFieldDefs.Add('vFormattedMemo', aftFormattedMemo, 0, False);
    AdvFieldDefs.Add('vWideMemo', aftWideMemo, 0, False);

    if (Exists) then DeleteTable;
    Result.CreateTable;

  end;
end;


procedure TUnitTestParams.DropACRTable(Table: TACRTable);
begin
  Table.Close;
  Table.DeleteTable;
  Table.Free;
end;


procedure TUnitTestParams.FillValueRecord(var vr: TValueRecord);
begin
  with vr do begin
     vChar                := 'vChar' + IntToStr(Random(1000));

     vString              := 'vString' + IntToStr(Random(1000));

     vWideChar            := 'vWideChar' + IntToStr(Random(1000));
     vWideString          := 'vWideString' + IntToStr(Random(1000));

     vShortint            := Random(127);
     vSmallint            := Random(127);
     vInteger             := Random(1000);
     vLargeint            := Random(1000);
     vByte                := Random(255);
     vWord                := Random(65535);
     vCardinal            := Random(65535);

     vSingle              := Random(1000);
     vDouble              := Random(1000);
     vExtended            := Random(1000);

     vBoolean             := Boolean(Random(1));

     vCurrency            := Random(1000);

     vDate                := date;
     vTime                := time;
     vDateTime            := now;
     vTimeStamp           := DateTimeToSQLTimeStamp(vDateTime);

     //vBytes               := array [0..9] of Byte;
     //vVarBytes            := array [0..9] of Byte;

     vBlob                := 'vBlob'#0#0 + IntToStr(Random(1000));
     vGraphic             := 'vGraphic'#0#0 + IntToStr(Random(1000));
     vMemo                := 'vMemo_' + IntToStr(Random(1000));
     vFormattedMemo       := 'vFormattedMemo_' + IntToStr(Random(1000));
     vWideMemo            := 'vWideMemo_' + IntToStr(Random(1000));
  end;
end;


procedure TUnitTestParams.FillParams(var vr: TValueRecord; q: TACRQuery);
begin
  q.ParamByName('vChar').AsString := vr.vChar;
  q.ParamByName('vString').AsString := vr.vString;
  q.ParamByName('vWideChar').AsString := vr.vWideChar;
  q.ParamByName('vWideString').AsString := vr.vWideString;

  q.ParamByName('vShortint').AsInteger := vr.vShortint;
  q.ParamByName('vSmallint').AsInteger := vr.vSmallint;
  q.ParamByName('vInteger').AsInteger := vr.vInteger;
  q.ParamByName('vLargeint').AsInteger := vr.vLargeint;
  q.ParamByName('vByte').AsInteger := vr.vByte;
  q.ParamByName('vWord').AsInteger := vr.vWord;
  q.ParamByName('vCardinal').AsInteger := vr.vCardinal;

  q.ParamByName('vSingle').AsFloat := vr.vSingle;
  q.ParamByName('vDouble').AsFloat := vr.vDouble;
  q.ParamByName('vExtended').AsFloat := vr.vExtended;

  q.ParamByName('vBoolean').AsBoolean := vr.vBoolean;
  q.ParamByName('vCurrency').AsCurrency := vr.vCurrency;

  q.ParamByName('vDate').AsDate := vr.vDate;
  q.ParamByName('vTime').AsTime := vr.vTime;
  q.ParamByName('vDateTime').AsDateTime := vr.vDateTime;
  q.ParamByName('vTimeStamp').AsSQLTimeStamp := vr.vTimeStamp;

  q.ParamByName('vBlob').AsBlob := vr.vBlob;
  q.ParamByName('vGraphic').AsBlob := vr.vGraphic;
  q.ParamByName('vMemo').AsMemo := vr.vMemo;
  q.ParamByName('vFormattedMemo').AsMemo := vr.vFormattedMemo;
//  q.ParamByName('vWideMemo').AsBlob := vr.vWideMemo;
  q.ParamByName('vWideMemo').SetBlobData(PWideChar(@vr.vWideMemo[1]),Length(vr.vWideMemo) * 2+2);

end;


procedure TUnitTestParams.CheckResult(t: TACRTable; vr: TValueRecord);
begin
  t.Open;
  t.First;
  if t.RecordCount = 1 then
   begin
     if t.FieldByName('vChar').AsString <> vr.vChar then WriteToErrorLog('vChar');
     if t.FieldByName('vString').AsString <> vr.vString then WriteToErrorLog('vString');
     if t.FieldByName('vWideChar').AsString <> vr.vWideChar then WriteToErrorLog('vWideChar');
     if t.FieldByName('vWideString').AsString <> vr.vWideString then WriteToErrorLog('vWideString');

     if t.FieldByName('vShortint').AsInteger <> vr.vShortint then WriteToErrorLog('vShortint');
     if t.FieldByName('vSmallint').AsInteger <> vr.vSmallint then WriteToErrorLog('vSmallint');
     if t.FieldByName('vInteger').AsInteger <> vr.vInteger then WriteToErrorLog('vInteger');
     if t.FieldByName('vLargeint').AsInteger <> vr.vLargeint then WriteToErrorLog('vLargeint');
     if t.FieldByName('vByte').AsInteger <> vr.vByte then WriteToErrorLog('vByte');
     if t.FieldByName('vWord').AsInteger <> vr.vWord then WriteToErrorLog('vWord');
     if Cardinal(t.FieldByName('vCardinal').AsInteger) <> vr.vCardinal then WriteToErrorLog('vCardinal');

     if t.FieldByName('vSingle').AsFloat <> vr.vSingle then WriteToErrorLog('vSingle');
     if t.FieldByName('vDouble').AsFloat <> vr.vDouble then WriteToErrorLog('vDouble');
     if t.FieldByName('vExtended').AsFloat <> vr.vExtended then WriteToErrorLog('vExtended');

     if t.FieldByName('vBoolean').AsBoolean <> vr.vBoolean then WriteToErrorLog('vBoolean');
     if t.FieldByName('vCurrency').AsCurrency <> vr.vCurrency then WriteToErrorLog('vCurrency');

     if t.FieldByName('vDate').AsDateTime <> vr.vDate then WriteToErrorLog('vDate');
     if t.FieldByName('vTime').AsDateTime <> vr.vTime then WriteToErrorLog('vTime');
     if t.FieldByName('vDateTime').AsDateTime <> vr.vDateTime then WriteToErrorLog('vDateTime');

     if SQLTimeStampToStr('dd.mm.yyyy hh:hh:ss', t.FieldByName('vTimeStamp').AsSQLTimeStamp) <>
        SQLTimeStampToStr('dd.mm.yyyy hh:hh:ss', vr.vTimeStamp) then WriteToErrorLog('vTimeStamp');

     if t.FieldByName('vBlob').AsString <> vr.vBlob then WriteToErrorLog('vBlob');
     if t.FieldByName('vGraphic').AsString <> vr.vGraphic then WriteToErrorLog('vGraphic');
     if t.FieldByName('vMemo').AsString <> vr.vMemo then WriteToErrorLog('vMemo');
     if t.FieldByName('vFormattedMemo').AsString <> vr.vFormattedMemo then WriteToErrorLog('vFormattedMemo');
//     if t.FieldByName('vWideMemo').AsString <> vr.vWideMemo then WriteToErrorLog('vWideMemo');
//     if (t.GetWideMemoField(t.FieldByName('vWideMemo'))
//         <> vr.vWideMemo) then WriteToErrorLog('vWideMemo');
   end
  else
   WriteToErrorLog('RecordCount <> 1');
end;


procedure TUnitTestParams.InternalTestPreparedParams(
                      RemoteDB: Boolean;
                      InMemory: Boolean;
                      Live:     Boolean
              );

var Caption:  String;
    aq:        TACRQuery;
    bq:        TQuery;
    db:        TACRDatabase;
    srv:       TACRServer;

 procedure CreateDB;
 begin
  // create local DB
  db := TACRDatabase.Create(nil);
  db.DatabaseFileName := TempDir+'server_param_db.adb';
  db.DatabaseName := 'LocalParamsDB';
  if (db.Exists) then
   db.DeleteDatabase;
  db.CreateDatabase;
  db.Open;
  aq.DatabaseName := db.DatabaseName;
  if (RemoteDB) then
   begin
    // client-server
    db.Close;
    srv := TACRServer.Create(nil);
    srv.DatabaseNames.Clear;
    srv.DatabaseFileNames.Clear;
    srv.DatabaseNames.Add('RemoteParamsDB');
    srv.DatabaseFileNames.Add(db.DatabaseFileName);
    srv.UseConfigFile := False;
    srv.LocalHost := db.ConnectionParams.RemoteHost;
    srv.Active := True;
    db.LocalDatabase := False;
    db.ConnectionParams.DatabaseName := srv.DatabaseNames.Strings[0];
    db.Open;
   end
 end; // CreateDB

 procedure DestroyDB;
 begin
  db.Close;
  if (RemoteDB) then
   begin
    // client-server
    srv.Free;
    Sleep(100);
    db.LocalDatabase := True;
   end;
  db.DeleteDatabase;
  db.Free;
 end; // DestroyDB


begin
 aq := TACRQuery.Create(nil);
 bq := TQuery.Create(nil);
 if (not InMemory) or RemoteDB then
  CreateDB;
 try
   aq.InMemory := InMemory;
   aq.SQL.Text := 'DROP TABLE test';
   aq.ExecSQL;

   aq.SQL.Text := 'CREATE TABLE test(id Autoinc, str Char(25));'+#13#10+
                  'CREATE INDEX idx_id ON test(id);'+#13#10+
                 'INSERT INTO test(str) VALUES("test1");'+#13#10+
                 'INSERT INTO test(str) VALUES("test2");'+#13#10;
   aq.ExecSQL;
   aq.RequestLive := False;
   bq.RequestLive := False;

   SysUtils.DeleteFile(IncludeTrailingBackslash(Self.TempDir)+'test.db');
   bq.DatabaseName := Self.TempDir;
   bq.SQL.Text := 'CREATE TABLE test(id Autoinc, str Char(25))';
   bq.ExecSQL;
   bq.SQL.Text := 'CREATE INDEX idx_id ON test(id)';
   bq.ExecSQL;
   bq.SQL.Text := 'INSERT INTO test(str) VALUES("test1")';
   bq.ExecSQL;
   bq.SQL.Text := 'INSERT INTO test(str) VALUES("test2")';
   bq.ExecSQL;

   // parametrized INSERT
   aq.SQL.Text := 'INSERT INTO test(str) VALUES(:p_str)';
   aq.Prepared := True;
   aq.Params[0].Value := 'test333';
   aq.ExecSQL;
   aq.Params[0].Value := 'test4';
   aq.ExecSQL;
   aq.Params[0].Value := 'test5';
   aq.ExecSQL;

   bq.SQL.Text := 'INSERT INTO test(str) VALUES(:p_str)';
   bq.Prepared := True;
   bq.Params[0].Value := 'test333';
   bq.ExecSQL;
   bq.Params[0].Value := 'test4';
   bq.ExecSQL;
   bq.Params[0].Value := 'test5';
   bq.ExecSQL;

   aq.SQL.Text := 'SELECT * FROM test ORDER BY ID';
   aq.Open;
   bq.SQL.Text := 'SELECT * FROM test ORDER BY ID';
   bq.Open;
   CheckQuery(bq,aq,Caption+' - DDL INSERT #0');

   // parametrized UPDATE
   aq.SQL.Text := 'UPDATE TEST SET str = :p_str WHERE id = 3';
   aq.Prepared := True;
   aq.Params[0].Value := 'test33';
   aq.ExecSQL;
   aq.Params[0].Value := 'test3';
   aq.ExecSQL;

   bq.SQL.Text := 'UPDATE TEST SET str = :p_str WHERE id = 3';
   bq.Prepared := True;
   bq.Params[0].Value := 'test33';
   bq.ExecSQL;
   bq.Params[0].Value := 'test3';
   bq.ExecSQL;

   aq.SQL.Text := 'SELECT * FROM test ORDER BY ID';
   aq.Open;
   bq.SQL.Text := 'SELECT * FROM test ORDER BY ID';
   bq.Open;
   CheckQuery(bq,aq,Caption+' - DDL UPDATE #1');

   // parametrized DELETE
   aq.SQL.Text := 'DELETE FROM TEST WHERE id = :p_id';
   aq.Prepared := True;
   aq.Params[0].AsInteger := 4;
   aq.ExecSQL;
   aq.Params[0].AsInteger := 5;
   aq.ExecSQL;

   bq.SQL.Text := 'DELETE FROM TEST WHERE id = :p_id';
   bq.Prepared := True;
   bq.Params[0].AsInteger := 4;
   bq.ExecSQL;
   bq.Params[0].AsInteger := 5;
   bq.ExecSQL;

   aq.SQL.Text := 'SELECT * FROM test ORDER BY ID';
   aq.Open;
   bq.SQL.Text := 'SELECT * FROM test ORDER BY ID';
   bq.Open;
   CheckQuery(bq,aq,Caption+' - DDL DELETE #2');

   aq.RequestLive := Live;
   bq.RequestLive := Live;

   aq.SQL.Text := 'SELECT * FROM test ORDER BY ID';
   aq.Open;

   bq.SQL.Text := 'SELECT * FROM test';
   bq.Open;

   CheckQuery(bq,aq,Caption+' - #0');
   aq.Close;
   bq.Close;

   aq.SQL.Text := 'SELECT * FROM test WHERE str = :p_str';
   aq.Prepared := True;
   aq.Params[0].Value := 'test1';
   aq.Open;

   bq.SQL.Text := 'SELECT * FROM test WHERE str = :p_str';
   bq.Prepared := True;
   bq.Params[0].Value := 'test1';
   bq.Open;

   CheckQuery(bq,aq,Caption+' - #1');

   aq.Close;
   bq.Close;
   
   // reopen with same parameters
   aq.Open;
   bq.Open;
   CheckQuery(bq,aq,Caption+' - #1');
   aq.Close;
   bq.Close;

   // reopened with another param value
   aq.Params[0].Value := 'test2';
   bq.Params[0].Value := 'test2';
   aq.Open;
   bq.Open;

   CheckQuery(bq,aq,Caption+' - #2');

   // 2 parameters: field list and WHERE
   aq.SQL.Text := 'SELECT (id * :p_id) as expr FROM test WHERE str = :p_str';
   aq.Prepared := True;
   aq.Params[0].asInteger := 10;
   aq.Params[1].Value := 'test1';
   aq.Open;

   bq.RequestLive := False;
   bq.SQL.Text := 'SELECT (id * 10) as expr FROM test WHERE str = "test1"';
   bq.Open;

   CheckQuery(bq,aq,Caption+' - #3');

   aq.Close;
   bq.Close;

   aq.Params[1].Value := 'test2';
   bq.SQL.Text := 'SELECT (id * 10) as expr FROM test WHERE str = "test2"';
   aq.Open;
   bq.Open;

   CheckQuery(bq,aq,Caption+' - #4');

   aq.Close;
   bq.Close;

   aq.Params[0].AsInteger := 100;
   aq.Params[1].Value := 'test2';
   bq.SQL.Text := 'SELECT (id * 100) as expr FROM test WHERE str = "test2"';
   aq.Open;
   bq.Open;

   CheckQuery(bq,aq,Caption+' - #5');

   aq.Close;
   bq.Close;

   if (not Live) then
    begin
     // 2 records
     aq.SQL.Text := 'SELECT * FROM test WHERE id > :p_id ORDER BY str desc';
     aq.Prepared := True;
     aq.Params[0].AsInteger := 0;
     aq.Open;
     bq.SQL.Text := 'SELECT * FROM test WHERE id > :p_id ORDER BY str desc';
     bq.Prepared := True;
     bq.Params[0].AsInteger := 0;
     bq.Open;
     CheckQuery(bq,aq,Caption+' - #6');
     aq.Close;
     bq.Close;
     // 1 record
     bq.Params[0].AsInteger := 1;
     aq.Params[0].AsInteger := 1;
     aq.Open;
     bq.Open;
     CheckQuery(bq,aq,Caption+' - #7');
     aq.Close;
     bq.Close;
    end;

 finally
   aq.SQL.Text := 'DROP TABLE test';
   aq.ExecSQL;
   aq.Free;
   bq.SQL.Text := 'DROP TABLE test';
   bq.ExecSQL;
   bq.Free;

   if (not InMemory) or RemoteDB then
    DestroyDB;
 end;
end; // InternalTestPreparedParams


procedure TUnitTestParams.TestParams;
var
 q: TACRQuery;
 t: TACRTable;
 ms: TStringStream;
begin
 t := CreateACRTable;
 try
   q := TACRQuery.Create(nil);
   try
     q.DatabaseName := t.DatabaseName;
     q.InMemory := t.InMemory;

     WriteToProcessLog('Test Insert');
     FillValueRecord(ValueRecord);
 q.SQL.Text := 'insert into test (' +
'vChar, vString, vWideChar, vWideString, vShortint, vSmallint, vInteger, vLargeint, vByte, '+
'vWord, vCardinal, '+
'vSingle, vDouble, vExtended, vBoolean, '+
'vCurrency, vDate, vTime, vDateTime, vTimeStamp, vBlob, vGraphic, vMemo, vFormattedMemo, vWideMemo '+
' ) values (' +
':vChar, :vString, :vWideChar, :vWideString, :vShortint, :vSmallint, :vInteger, :vLargeint, :vByte, '+
':vWord, :vCardinal,'+
':vSingle, :vDouble, :vExtended, :vBoolean, '+
':vCurrency, :vDate, :vTime, :vDateTime, :vTimeStamp, :vBlob, :vGraphic, :vMemo, :vFormattedMemo, :vWideMemo '+
')';
     FillParams(ValueRecord, q);
     q.ExecSQL;
     CheckResult(t, ValueRecord);


     WriteToProcessLog('Test Update');
     FillValueRecord(ValueRecord);
 q.SQL.Text := 'update test set ' +
'vChar=:vChar, vString=:vString, vWideChar=:vWideChar, vWideString=:vWideString, vShortint=:vShortint, ' +
'vSmallint=:vSmallint, vInteger=:vInteger, vLargeint=:vLargeint, vByte=:vByte, ' +
'vWord=:vWord, vCardinal=:vCardinal,' +
'vSingle=:vSingle, vDouble=:vDouble, vExtended=:vExtended, vBoolean=:vBoolean, ' +
'vCurrency=:vCurrency, vDate=:vDate, vTime=:vTime, vDateTime=:vDateTime, vTimeStamp=:vTimeStamp, ' +
'vBlob=:vBlob, vGraphic=:vGraphic, vMemo=:vMemo, vFormattedMemo=:vFormattedMemo, vWideMemo=:vWideMemo ';
     FillParams(ValueRecord, q);
     q.ExecSQL;
     CheckResult(t, ValueRecord);


     WriteToProcessLog('Test Select');
 q.SQL.Text := 'select * from test where ' +
'vChar=:vChar, vString=:vString, vWideChar=:vWideChar, vWideString=:vWideString, vShortint=:vShortint, ' +
'vSmallint=:vSmallint, vInteger=:vInteger, vLargeint=:vLargeint, vByte=:vByte, ' +
'vWord=:vWord, vCardinal=:vCardinal,' +
'vSingle=:vSingle, vDouble=:vDouble, vExtended=:vExtended, vBoolean=:vBoolean, ' +
'vCurrency=:vCurrency, vDate=:vDate, vTime=:vTime, vDateTime=:vDateTime, vTimeStamp=:vTimeStamp, ' +
'vBlob=:vBlob, vGraphic=:vGraphic, vMemo=:vMemo, vFormattedMemo=:vFormattedMemo, vWideMemo=:vWideMemo ';
     FillParams(ValueRecord, q);
     q.Open;
     if q.RecordCount <> 1 then
       WriteToErrorLog('Select with params Error');
     q.Close;


     WriteToProcessLog('Test Delete');
 q.SQL.Text := 'delete from test where ' +
'vChar=:vChar, vString=:vString, vWideChar=:vWideChar, vWideString=:vWideString, vShortint=:vShortint, ' +
'vSmallint=:vSmallint, vInteger=:vInteger, vLargeint=:vLargeint, vByte=:vByte, ' +
'vWord=:vWord, vCardinal=:vCardinal,' +
'vSingle=:vSingle, vDouble=:vDouble, vExtended=:vExtended, vBoolean=:vBoolean, ' +
'vCurrency=:vCurrency, vDate=:vDate, vTime=:vTime, vDateTime=:vDateTime, vTimeStamp=:vTimeStamp, ' +
'vBlob=:vBlob, vGraphic=:vGraphic, vMemo=:vMemo, vFormattedMemo=:vFormattedMemo, vWideMemo=:vWideMemo ';
     FillParams(ValueRecord, q);
     q.ExecSQL;
     if q.RowsAffected <> 1 then
       WriteToErrorLog('Delete with params Error');


   finally
     q.Free;
   end;
 finally
   DropACRTable(t);
 end;

end;

procedure TUnitTestParams.TestNameVariants;
var ACRQuery1: TACRQuery;
begin
 ACRQuery1 := TACRQuery.Create(nil);
 try
   ACRQuery1.InMemory := True;
   ACRQuery1.SQL.Text := 'CREATE TABLE TEST (ID1 INTEGER, ID2 INTEGER, ID3 INTEGER, ID4 INTEGER);';
   ACRQuery1.ExecSQL;
   ACRQuery1.SQL.Text := 'INSERT INTO TEST VALUES (:P_STR1,:"P STR2",:`P STR3`,:''P STR4'')';
   ACRQuery1.ParamByName('P_STR1').AsInteger := 1;
   ACRQuery1.ParamByName('P STR2').AsInteger := 2;
   ACRQuery1.ParamByName('P STR3').AsInteger := 3;
   ACRQuery1.ParamByName('P STR4').AsInteger := 4;
   ACRQuery1.ExecSQL;
   ACRQuery1.SQL.Text := 'SELECT * FROM TEST';
   ACRQuery1.Open;
   if (ACRQuery1.Fields[0].AsInteger <> 1) or
      (ACRQuery1.Fields[1].AsInteger <> 2) or
      (ACRQuery1.Fields[2].AsInteger <> 3) or
      (ACRQuery1.Fields[3].AsInteger <> 4)  then
       WriteToErrorLog('TUnitTestParams.TestNameVariants error - invalid field values');
   ACRQuery1.SQL.Text := 'DROP TABLE TEST;';
   ACRQuery1.ExecSQL;
 finally
   ACRQuery1.Free;
 end;
end;

procedure TUnitTestParams.TestPreparedParams;
begin
 // local
 InternalTestPreparedParams(False,False,False);
 WriteToProcessLog('TUnitTestParams.TestPreparedParams - Local, Disk, ReadOnly');
 InternalTestPreparedParams(False,False,True);
 WriteToProcessLog('TUnitTestParams.TestPreparedParams - Local, Disk, Live');
 InternalTestPreparedParams(False,True,False);
 WriteToProcessLog('TUnitTestParams.TestPreparedParams - Local, Memory, ReadOnly');
 InternalTestPreparedParams(False,True,True);
 WriteToProcessLog('TUnitTestParams.TestPreparedParams - Local, Memory, Live');
 // remote
{$IFNDEF NO_NETWORK}
 InternalTestPreparedParams(True,False,False);
 WriteToProcessLog('TUnitTestParams.TestPreparedParams - Remote, Disk, ReadOnly');
 InternalTestPreparedParams(True,False,True);
 WriteToProcessLog('TUnitTestParams.TestPreparedParams - Remote, Disk, Live');
 InternalTestPreparedParams(True,True,False);
 WriteToProcessLog('TUnitTestParams.TestPreparedParams - Remote, Memory, ReadOnly');
 InternalTestPreparedParams(True,True,True);
 WriteToProcessLog('TUnitTestParams.TestPreparedParams - Remote, Memory, Live');
{$ENDIF}
end;

initialization
  UnitTestParams := TUnitTestParams.Create(UnitTestList);

finalization
  UnitTestParams.Free;

end.

