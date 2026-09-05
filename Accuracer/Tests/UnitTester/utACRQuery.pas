unit utACRQuery;

interface

{$I UTConfig.Inc}
{$I ACRVer.Inc}
{$DEFINE TEST_CI}

uses SysUtils, Classes, DB,
{$IFNDEF D6H}
      DBTables,
{$ELSE}
 {$IFDEF MSWINDOWS}
      DBTables,
 {$ENDIF}
{$ENDIF}
      DBClient,
     uTestList,
{$IFDEF ACR5H}
     ACRComMain,
{$ENDIF}
     ACRMain,
     ACRExcept;

type
  TUnitTestACRQuery = class(TUnitTest)
   private
    function CreateACRTable: TACRTable;
    procedure DropACRTable(Table: TACRTable);
    function CreateTTable: TTable;
    procedure DropTTable(Table: TTable);
    procedure FillTable(var Table);
   public
    procedure TestShort; override;
    procedure TestExceptions; override;
   public
    procedure TestParams;
    procedure TestSomeQuery;
    procedure TestIndexesAndOrderBy;
    procedure TestTemporaryIndexes;
    procedure TestUpdateItselfAndRowsAffected;
    procedure TestQuery(SqlText: String);
    procedure TestNoResultQuery(SqlText: String);
    procedure TestWideStringFunctions;
    procedure TestLeftJoinAbsDiff;
    procedure TestLeftJoinDekart2Conditions;
    procedure TestDateFunctions;
    procedure TestDeleteUpdateWithVarcharBLOBAndForeignKeys;
    procedure TestBugBufferSizeExceededAlexFelton;
    procedure TestPrimaryIndex;
    procedure TestForeignKeySelfTable;

    // exceptions
    procedure TestInsertIntoNotExistingTable;
    procedure TestSQLErrorLineNumber;
    procedure TestSelectUnionInvalidFieldName;
    // end of exceptions

    procedure TestSelectUnionInvalidFieldCount;
    procedure TestCumSum;
    procedure TestCumProd;
    procedure TestGroupConcat;
    procedure TestDistinctBug;
    procedure TestReadOnlyDBSelect;
    procedure TestQuestionParameters;
    procedure TestExceptWithSubQuery;
    procedure TestCreateDefaultsTable_Brian_Pettit_bug;
    procedure TestLeftJoinOnConditionBug;
    procedure TestIsNullAndNullIfFunctions;
    procedure TestCorrelatedSubQueries;
    procedure TestRoundBug;
    procedure TestCaseAndCoalesce;
    procedure TestDateAddAndDateDiff;
    procedure TestBLOBAndMemo;
    procedure TestNotLike;
    procedure TestBrunner_18_11_2010;
    procedure TestSQLByRomanKorzh;
    procedure TestTrim;
    procedure TestBrunner_08_03_2010;
    procedure TestBrunner_13_12_2010;
    procedure TestExtract;
    procedure TestVclDb;
    procedure TestInnerJoinBugYabut_23_02_2011;
    procedure TestSimpleExpressions;
{$IFDEF TEST_CI}
    procedure TestCaseInsensitiveExpressions;
{$ENDIF}    
    procedure TestConstraint;
  end;

var
  UnitTestACRQuery: TUnitTestACRQuery;


implementation

{ TUnitTestACRQuery }


procedure TUnitTestACRQuery.TestShort;
begin
//  CheckAction(TestIsNullAndNullIfFunctions,'Test ISNULL function');
//CheckAction(TestConstraint,'Constraint');
//CheckAction(TestCaseInsensitiveExpressions,'Test Case Insensitive Expressions');
//  CheckAction(TestNotLike,'Test NOT LIKE');
//  CheckAction(TestCorrelatedSubQueries,'Test correlated Subqueries');
//  CheckAction(TestSimpleExpressions,'Test Simple Expressions');
//  CheckAction(TestVclDb,'Test TestVclDb');
//exit;
//  CheckAction(TestInnerJoinBugYabut_23_02_2011,'Test Inner Join Bug Yabut 23.02.2011');
//exit;
//  CheckAction(TestLeftJoinOnConditionBug,'Test "left join on" condition bug');
//  CheckAction(TestSQLByRomanKorzh,'TestSQLByRomanKorzh');
//exit;
//  CheckAction(TestBrunner_18_11_2010,'Test Brunner 18.11.2010');
//  CheckAction(TestCaseAndCoalesce,'Test CASE and COALESCE');
//exit;
  { TODO -oLeo : Should work in v.6 }
  //  CheckAction(TestLeftJoinDekart2Conditions, 'Left Join on Dekart join with 2 conditions');
//exit;

// MAIN TESTS:
  CheckAction(TestInnerJoinBugYabut_23_02_2011,'Test Inner Join Bug Yabut 23.02.2011');
  CheckAction(TestBrunner_13_12_2010,'Test Brunner 13.12.2010');
  CheckAction(TestBrunner_18_11_2010,'Test Brunner 18.11.2010');
  CheckAction(TestBrunner_08_03_2010,'Test Brunner 08.03.2010');
  CheckAction(TestNotLike,'Test NOT LIKE');
  CheckAction(TestBLOBAndMemo,'Test BLOB and Memo');
{$IFDEF ACR5H}
  CheckAction(TestConstraint,'Constraint');
{$IFDEF TEST_CI}
  CheckAction(TestCaseInsensitiveExpressions,'Test Case Insensitive Expressions');
{$ENDIF}
  CheckAction(TestSimpleExpressions,'Test Simple Expressions');
  CheckAction(TestVclDb,'Test TestVclDb');
  CheckAction(TestExtract,'Test EXTRACT');
  CheckAction(TestSQLByRomanKorzh,'TestSQLByRomanKorzh');
  CheckAction(TestTrim,'TestTrim');
  CheckAction(TestDateAddAndDateDiff,'Test DateAdd and DateDiff');
 {$IFDEF CORRELATED_SUBQUERIES}
  CheckAction(TestCorrelatedSubQueries,'Test correlated Subqueries');
 {$ENDIF}
  CheckAction(TestCaseAndCoalesce,'Test CASE and COALESCE');
  CheckAction(TestRoundBug,'Test Round Bug');
  CheckAction(TestIsNullAndNullIfFunctions,'Test ISNULL function');
  CheckAction(TestExceptWithSubQuery,'Test EXCEPT with sub-query');
  CheckAction(TestLeftJoinOnConditionBug,'Test "left join on" condition bug');
  CheckAction(TestCumSum,'Test CUMSUM');
  CheckAction(TestCumProd,'Test CUMPROD');
  CheckAction(TestGroupConcat,'Test GROUP_CONCAT');
  CheckAction(TestSelectUnionInvalidFieldCount,'Test Select Union Invalid Field Count');
{$ENDIF}
  CheckAction(TestQuestionParameters,'Test question parameters');
  CheckAction(TestReadOnlyDBSelect,'Test Read Only DB Select');
  CheckAction(TestDistinctBug,'Test DISTINCT Bug');
  CheckAction(TestForeignKeySelfTable,'Test foreign key self table');
  CheckAction(TestPrimaryIndex,'Test primary index - desc, no case');
  CheckAction(TestDeleteUpdateWithVarcharBLOBAndForeignKeys, 'Test Delete Update With Varchar, BLOB And ForeignKeys');

  CheckAction(TestBugBufferSizeExceededAlexFelton,'Test bug buffer size exceeded Alex Felton');

  CheckAction(TestLeftJoinAbsDiff, 'Left Join on Abs Diff');
  CheckAction(TestWideStringFunctions, 'Wide String Functions');

  CheckAction(TestParams, 'Test Params');

  CheckAction(TestSomeQuery, 'Test Queries');
  CheckAction(TestIndexesAndOrderBy, 'Test indexes and order by');
  CheckAction(TestTemporaryIndexes, 'Test Temporary indexes in disk Queries');
  CheckAction(TestUpdateItselfAndRowsAffected, 'Test UpdateItselfAndRowsAffected in disk Queries');
  CheckAction(TestDateFunctions,'Test DateFunctions');
  CheckAction(TestCreateDefaultsTable_Brian_Pettit_bug,'Test create Defaults table by Brian Pettit');
end;


procedure TUnitTestACRQuery.TestExceptions;
begin
 {$IFDEF ACR5H}
 CheckAction(TestSelectUnionInvalidFieldName,'Test Select Union Invalid Field Name');
{$ENDIF}
 CheckAction(TestSQLErrorLineNumber,'Test SQL error line number');
 CheckAction(TestInsertIntoNotExistingTable,'Test insert into not existing table');
end;


function TUnitTestACRQuery.CreateACRTable: TACRTable;
begin
  Result := TACRTable.Create(nil);
  with Result do begin

    TableName := 'test';
    InMemory := True;

    FieldDefs.Clear;
    FieldDefs.Add('Field1', ftInteger,0,False);
    FieldDefs.Add('Field2', ftString, 200,False);

    if (Exists) then DeleteTable;
    Result.CreateTable;

    FillTable(Result);
  end;
end;


function TUnitTestACRQuery.CreateTTable: TTable;
begin
  Result := TTable.Create(nil);
  with Result do begin

    TableName := 'test';
    TableType := ttParadox;
    DatabaseName := TempDir;
    //InMemory := True;

    FieldDefs.Clear;
    FieldDefs.Add('Field1', ftInteger,0,False);
    FieldDefs.Add('Field2', ftString, 200,False);

    if (Exists) then DeleteTable;
    Result.CreateTable;

    FillTable(Result);
  end;
end;



procedure TUnitTestACRQuery.FillTable(var Table);
begin

  with TTable(Table) do begin
    Open;

    Insert;
    Fields[0].AsInteger := 10;
    Fields[1].AsString := 'aaa';
    Post;
    Insert;
    Fields[0].AsInteger := 15;
    Fields[1].AsString := 'aab';
    Post;
    Insert;
    Fields[0].AsInteger := 16;
    Fields[1].AsString := 'aac';
    Post;
    Insert;
    Fields[0].AsInteger := -20;
    Fields[1].AsString := 'Aab';
    Post;
    Insert;
    Fields[0].AsInteger := -10;
    Fields[1].AsString := 'bab';
    Post;

    Close;
  end;
end;


procedure TUnitTestACRQuery.DropACRTable(Table: TACRTable);
begin
  Table.DeleteTable;
  Table.Free;
end;


procedure TUnitTestACRQuery.DropTTable(Table: TTable);
begin
  Table.DeleteTable;
  Table.Free;
end;


procedure TUnitTestACRQuery.TestParams;
var i:    Integer;
    aDB:  TACRDatabase;
    aq1:  TACRQuery;
begin
 aDB := TACRDatabase.Create(nil);
 aDB.DatabaseFileName := TempDir + 'test_sql_params.adb';
 aDB.DatabaseName := 'TestDB';
 aDB.DeleteDatabase;
 aDB.CreateDatabase;
 aDB.Open;
 aq1 := TACRQuery.Create(nil);
 try
  aq1.DatabaseName := ADB.DatabaseName;

  aq1.SQL.Clear;
  aq1.SQL.Add('CREATE TABLE Test (id AutoInc, str Varchar(100), `memo` memo);');
  aq1.ExecSQL;

  aq1.SQL.Clear;
//aq1.RequestLive := True;
  aq1.SQL.Text := 'INSERT INTO Test(str,`memo`) values (:P_STR,:P_MEMO);SELECT * FROM Test;';
  aq1.ParamByName('P_STR').AsString := 'Test 123';
  aq1.ParamByName('P_MEMO').AsString := 'Test 1234567890';
  aq1.Open;
//   aq1.ExecSQL;

  if (aq1.RecordCount <> 1) then
   WriteToErrorLog('TUnitTestACRQuery.TestParams - reccount <> 1');

  if (aq1.FieldByName('str').AsString <> 'Test 123') then
   WriteToErrorLog('TUnitTestACRQuery.TestParams - insert with string param failed!');

  if (aq1.FieldByName('memo').AsString <> 'Test 1234567890') then
   WriteToErrorLog('TUnitTestACRQuery.TestParams - insert with string param failed!');

  aq1.SQL.Clear;
  aq1.SQL.Text := 'UPDATE Test SET str = :P_STR, memo= :P_MEMO; SELECT * FROM Test;';
  aq1.ParamByName('P_STR').AsString := 'Test 456';
  aq1.ParamByName('P_MEMO').AsString := 'Test !1234567890';
  aq1.Open;

  if (aq1.RecordCount <> 1) then
   WriteToErrorLog('TUnitTestACRQuery.TestParams - reccount <> 1');

  if (aq1.FieldByName('str').AsString <> 'Test 456') then
   WriteToErrorLog('TUnitTestACRQuery.TestParams - update with string param failed!');

  if (aq1.FieldByName('memo').AsString <> 'Test !1234567890') then
   WriteToErrorLog('TUnitTestACRQuery.TestParams - update with memo param failed!');


  aq1.SQL.Clear;
  aq1.SQL.Text := 'INSERT INTO Test(str) values (:P_STR);SELECT * FROM Test;';
  aq1.ParamByName('P_STR').Clear;
  aq1.Open;

  aq1.Last;
  if (not aq1.FieldByName('str').IsNull) then
   WriteToErrorLog('TUnitTestACRQuery.TestParams - parameter = null was not inserted');

  if (aq1.RecordCount <> 2) then
   WriteToErrorLog('TUnitTestACRQuery.TestParams - reccount <> 2');

  aq1.SQL.Clear;
  aq1.SQL.Text := 'INSERT INTO Test(`memo`) values (:P_MEMO);INSERT INTO Test(`memo`) values (:P_MEMO1);SELECT `MEMO` FROM Test ORDER BY 1 DESC;';
  aq1.ParamByName('P_MEMO').Clear;
  aq1.ParamByName('P_MEMO1').AsMemo := '';
  aq1.Open;

  if (aq1.RecordCount <> 4) then
   WriteToErrorLog('TUnitTestACRQuery.TestParams - MEMO TEST reccount <> 4');

  aq1.Last;
  if (not aq1.FieldByName('memo').IsNull) then
   WriteToErrorLog('TUnitTestACRQuery.TestParams - parameter = null MEMO was not inserted #1');

  aq1.Prior;
  if (not aq1.FieldByName('memo').IsNull) then
   WriteToErrorLog('TUnitTestACRQuery.TestParams - parameter = null MEMO was not inserted #2');

  aq1.Close;
  aq1.SQL.Text := 'SELECT DISTINCT `Memo` FROM Test ORDER BY 1 DESC';
  aq1.Open;

  if (aq1.RecordCount <> 2) then
   WriteToErrorLog('TUnitTestACRQuery.TestParams - MEMO TEST reccount <> 2');
  aq1.Last;
  if (not aq1.FieldByName('memo').IsNull) then
   WriteToErrorLog('TUnitTestACRQuery.TestParams - parameter = null MEMO was not inserted #3');

  aq1.Close;
  aq1.SQL.Text := 'SELECT DISTINCT TOP 1 `Memo` FROM Test ORDER BY 1';
  aq1.Open;
  aq1.First;
  if (aq1.RecordCount <> 1) then
   WriteToErrorLog('TUnitTestACRQuery.TestParams - MEMO TEST DISTINCT TOP 1 reccount <> 1');
  if (not aq1.FieldByName('memo').IsNull) then
   WriteToErrorLog('TUnitTestACRQuery.TestParams - parameter = null MEMO was not inserted #4');

  aq1.SQL.Text := 'DROP TABLE Test';
  aq1.ExecSQL;

  aq1.SQL.Text := 'CREATE TABLE Test (id AutoInc, str Varchar(100), `memo` memo);';
  aq1.ExecSQL;

  aq1.SQL.Text := 'CREATE TABLE Test2 (id integer);';
  aq1.ExecSQL;

  aq1.SQL.Text := 'INSERT INTO test (str) VALUES(:P_STR); INSERT INTO Test2 VALUES(:P_ID);';
  aq1.Prepare;
  for i := 1 to 10 do
   begin
    aq1.ParamByName('P_STR').AsString := 'Test_'+IntToStr(i);
    aq1.ParamByName('P_ID').AsInteger := i;
    aq1.ExecSQL;
   end;
  aq1.UnPrepare;

  aq1.SQL.Text := 'SELECT * FROM Test ORDER BY id desc';
  aq1.Open;
  aq1.First;
  if (aq1.RecordCount <> 10) then
   WriteToErrorLog('TUnitTestACRQuery.TestParams - Error #1 RecCount <> 10');
  if (aq1.FieldValues['id'] <> 10) then
   WriteToErrorLog('TUnitTestACRQuery.TestParams - Error #2 id <> 10');
  aq1.Close;

  aq1.SQL.Text := 'SELECT test.str,test2.id FROM test INNER JOIN test2 ON (test.id = test2.id)'
                  +' WHERE (str = :P_STR)';
  aq1.Prepare;
  for i := 1 to 10 do
   begin
    aq1.Close;
    aq1.ParamByName('P_STR').AsString := 'Test_'+IntToStr(i);
    aq1.Open;
    if (aq1.RecordCount <> 1) then
     WriteToErrorLog('TUnitTestACRQuery.TestParams - Error #3 RecCount <> 1');
   end;
  aq1.Close; 
  aq1.UnPrepare;


 finally
  aq1.SQL.Text := 'DROP TABLE Test;DROP TABLE Test2;';
  aq1.ExecSQL;

  aq1.Free;
  aDB.Close;
  aDB.DeleteDatabase;
  aDB.Free;
 end;
end;


procedure TUnitTestACRQuery.TestSomeQuery;
var
  at: TACRTable;
  t:  TTable;
begin
  at := CreateACRTable;
  try
    t := CreateTTable;
    try
//for bug
      TestQuery('select * from test where Field2 = "aab"');

      TestQuery('select * from test order by Field1');

      TestQuery('select Field1 from test order by Field1');
      TestQuery('select ''1.0'' as a from test');
      TestQuery('select (1.0+1)*3 a from test');

      TestQuery('select * from test where Field1 = 10');

      //TestQuery('select 13 a from test');
      //TestQuery('select 13.2 a from test');

      TestQuery('select ''1'' a, Field1 from test where Field1 = 10 ' +
                'union ' +
                'select ''2'' a, Field1 from test where Field1 = 10');


      TestNoResultQuery('insert into test (Field1, Field2) values (13, ''qwerty'')');
      //TestNoResultQuery('insert into test select * from test where Field1 > 0');


//for bug
      TestNoResultQuery('update test set Field2=''ZZZ'' where Field1=10');

      TestNoResultQuery('update test set Field2=''ZZZ''');

      TestNoResultQuery('delete from test where Field1=10');

    finally
      DropTTable(t);
    end;
  finally
    DropACRTable(at);
  end;
end;

procedure TUnitTestACRQuery.TestIndexesAndOrderBy;
var
  aDB:  TACRDatabase;
  aq1:  TACRQuery;
  at1:  TACRTable;
  s:    string;
begin
 aDB := TACRDatabase.Create(nil);
 aDB.DatabaseFileName := TempDir + 'test_q_idx.adb';
 aDB.DatabaseName := 'TestDB';
 aDB.DeleteDatabase;
 aDB.CreateDatabase;
 aDB.Open;
 aq1 := TACRQuery.Create(nil);
 at1 := TACRTable.Create(nil);
 try
   aq1.DatabaseName := aDB.DatabaseName;
   at1.DatabaseName := aDB.DatabaseName;
   at1.TableName := 'TEST_INDEX';
   aq1.SQL.Clear;
   aq1.SQL.Add('CREATE TABLE TEST_INDEX(id AutoInc, name CHAR(50));');
   aq1.SQL.Add('INSERT INTO TEST_INDEX(name) VALUES ("aaa");');
   aq1.SQL.Add('INSERT INTO TEST_INDEX(name) VALUES ("BaA");');
   aq1.SQL.Add('INSERT INTO TEST_INDEX(name) VALUES ("aaA");');
   aq1.SQL.Add('INSERT INTO TEST_INDEX(name) VALUES ("BaA");');
   aq1.SQL.Add('DROP INDEX IF EXISTS TEST_INDEX.IDX_ID');
   aq1.SQL.Add('CREATE INDEX IDX_ID ON TEST_INDEX(id DESC, name ASC NOCASE);');
   aq1.SQL.Add('CREATE INDEX IF NOT EXISTS IDX_ID ON TEST_INDEX(id DESC, name ASC NOCASE);');
   aq1.SQL.Add('DROP INDEX TEST_INDEX.IDX_ID;');
   aq1.SQL.Add('CREATE INDEX IDX_ID ON TEST_INDEX(name ASC NOCASE);');
   aq1.SQL.Add('SELECT * FROM TEST_INDEX ORDER BY name NOCASE;');
   aq1.Open;
   aq1.First;
   if (aq1.RecordCount <> 4) then
    WriteToErrorLog('Test ACRQuery - indexes and order by error #0');
   s := aq1.FieldByName('name').AsString;
   if (s[1] <> 'a') then
    WriteToErrorLog('Test ACRQuery - indexes and order by error #1');
   aq1.Next;
   if (aq1.Eof) then
    WriteToErrorLog('Test ACRQuery - indexes and order by error #2');
   s := aq1.FieldByName('name').AsString;
   if (s[1] <> 'a') then
    WriteToErrorLog('Test ACRQuery - indexes and order by error #3');
   aq1.Next;
   if (aq1.Eof) then
    WriteToErrorLog('Test ACRQuery - indexes and order by error #4');
   s := aq1.FieldByName('name').AsString;
   if (s[1] <> 'B') then
    WriteToErrorLog('Test ACRQuery - indexes and order by error #5');
   aq1.Next;
   if (aq1.Eof) then
    WriteToErrorLog('Test ACRQuery - indexes and order by error #6');
   s := aq1.FieldByName('name').AsString;
   if (s[1] <> 'B') then
    WriteToErrorLog('Test ACRQuery - indexes and order by error #7');
   aq1.Next;
   if (not aq1.Eof) then
    WriteToErrorLog('Test ACRQuery - indexes and order by error #8');

   at1.TableName := 'TEST_INDEX';
   if (not at1.Exists) then
    WriteToErrorLog('Test ACRQuery - indexes and order by error #9');
   at1.Open;
   if (at1.IndexDefs.Count <> 1) then
    WriteToErrorLog('Test ACRQuery - indexes and order by error #10');
   at1.Close;

   aq1.SQL.Clear;
   aq1.SQL.Add('ALTER TABLE TEST_INDEX ADD (field1 integer);');
   aq1.ExecSQL;

   if (not at1.Exists) then
    WriteToErrorLog('Test ACRQuery - indexes and order by error #21');
   at1.Open;
   if (at1.IndexDefs.Count <> 1) then
    WriteToErrorLog('Test ACRQuery - indexes and order by error #22');
   at1.Close;


   aq1.SQL.Clear;
   aq1.SQL.Add('SELECT * FROM TEST_INDEX ORDER BY INDEX IDX_ID;');
   aq1.Open;
   if (aq1.RecordCount <> 4) then
    WriteToErrorLog('Test ACRQuery - indexes and order by error #11');
   s := aq1.FieldByName('name').AsString;
   if (s[1] <> 'a') then
    WriteToErrorLog('Test ACRQuery - indexes and order by error #12');
   aq1.Next;
   if (aq1.Eof) then
    WriteToErrorLog('Test ACRQuery - indexes and order by error #13');
   s := aq1.FieldByName('name').AsString;
   if (s[1] <> 'a') then
    WriteToErrorLog('Test ACRQuery - indexes and order by error #14');
   aq1.Next;
   if (aq1.Eof) then
    WriteToErrorLog('Test ACRQuery - indexes and order by error #15');
   s := aq1.FieldByName('name').AsString;
   if (s[1] <> 'B') then
    WriteToErrorLog('Test ACRQuery - indexes and order by error #16');
   aq1.Next;
   if (aq1.Eof) then
    WriteToErrorLog('Test ACRQuery - indexes and order by error #17');
   s := aq1.FieldByName('name').AsString;
   if (s[1] <> 'B') then
    WriteToErrorLog('Test ACRQuery - indexes and order by error #18');
   aq1.Next;
   if (not aq1.Eof) then
    WriteToErrorLog('Test ACRQuery - indexes and order by error #19');

   aq1.SQL.Clear;
   aq1.SQL.Add('SELECT * INTO Test_Index2 FROM TEST_INDEX;');
   aq1.SQL.Add('SELECT * FROM Test_Index2;');
   aq1.Open;
   if (aq1.RecordCount <> 4) then
    WriteToErrorLog('Test ACRQuery - indexes and order by error #20');


 finally
   aq1.SQL.Text := 'DROP TABLE TEST_INDEX;';
   aq1.ExecSQL;

   at1.Free;
   aq1.Free;
   aDB.Close;
   aDB.DeleteDatabase;
   aDB.Free;
 end;

end;


procedure TUnitTestACRQuery.TestTemporaryIndexes;
var
  aDB: TACRDatabase;
  aq1:  TACRQuery;
  aq2:  TACRQuery;
  aq3:  TACRQuery;
begin
 aDB := TACRDatabase.Create(nil);
 aDB.DatabaseFileName := TempDir + 'test_q.adb';
 aDB.DatabaseName := 'TestDB';
 aDB.DeleteDatabase;
 aDB.CreateDatabase;
 aDB.Open;
 aq1 := TACRQuery.Create(nil);
 aq2 := TACRQuery.Create(nil);
 aq3 := TACRQuery.Create(nil);
 try
  aq1.DatabaseName := aDB.DatabaseName;
  aq2.DatabaseName := aDB.DatabaseName;
  aq3.DatabaseName := aDB.DatabaseName;

  aq1.SQL.Text := 'select * from test1 order by num desc,id';
  aq2.SQL.Text := 'insert into test1 (num) values (1)';
  aq3.SQL.Text := 'drop table test1;'+
                  'create table test1 (id AutoInc, num Integer, str Varchar(20));';

  aq3.ExecSQL; //Creating Table
  aq3.Close;

  aq1.Open; //Select

  aq2.ExecSQL; //Insert
  aq2.Close;

  aq1.Close;
  aq1.Open;  //Select

 finally
   aq1.SQL.Text := 'drop table test1';
   aq1.ExecSQL;

   aq1.Free;
   aq2.Free;
   aq3.Free;
   aDB.Close;
   aDB.DeleteDatabase;
   aDB.Free;
 end;

end;


procedure TUnitTestACRQuery.TestUpdateItselfAndRowsAffected;
var
  aDB: TACRDatabase;
  aq1:  TACRQuery;

  procedure Test(InMemory: Boolean);
  begin
    if (InMemory) then
     aq1.InMemory := True
    else
     aq1.DatabaseName := aDB.DatabaseName;
    aq1.RequestLive := True;
    aq1.SQL.Clear;
    aq1.SQL.Add('create table test (num integer,num1 integer);');
    aq1.SQL.Add('insert into test (num,num1) values (1,1);');
    aq1.SQL.Add('insert into test (num,num1) values (2,2);');
    aq1.SQL.Add('insert into test (num,num1) values (1,1);');
    aq1.SQL.Add('insert into test (num,num1) values (2,2);');
    aq1.SQL.Add('insert into test (num,num1) values (2,2);');
    aq1.ExecSQL;

    aq1.SQL.Text := 'update test set num = 5 where num = 2';
    aq1.ExecSQL;
    if (aq1.RowsAffected <> 3) then
     WriteToErrorLog('TUnitTestACRQuery.TestUpdateItselfAndRowsAffected - RowsAffected <> 3 updating num = 5');

    aq1.SQL.Text := 'select * from test where num = 5';
    aq1.Open;  //Select
    if (aq1.RecordCount <> 3) then
     WriteToErrorLog('TUnitTestACRQuery.TestUpdateItselfAndRowsAffected - RecordCount <> 3 updating num = 5');
    aq1.Close;

    aq1.SQL.Text := 'update test set num1 = 5 where num = 1';
    aq1.ExecSQL;
    if (aq1.RowsAffected <> 2) then
     WriteToErrorLog('TUnitTestACRQuery.TestUpdateItselfAndRowsAffected - RowsAffected <> 2 updating num1 = 5');

    aq1.SQL.Text := 'select * from test where num1 = 5';
    aq1.Open;  //Select
    if (aq1.RecordCount <> 2) then
     WriteToErrorLog('TUnitTestACRQuery.TestUpdateItselfAndRowsAffected - RecordCount <> 2 updating num1 = 5');
    aq1.Edit;
    aq1.FieldByName('num1').AsInteger := 6;
    aq1.Post;
    if (aq1.FieldByName('num1').AsInteger <> 5) then
     WriteToErrorLog('TUnitTestACRQuery.TestUpdateItselfAndRowsAffected - RecordCount <> 2 select and edit num1 = 5 make invisible');
    aq1.Close;
    aq1.SQL.Text :=  'drop table test;';
    aq1.ExecSQL;
  end;

begin
 aDB := TACRDatabase.Create(nil);
 aDB.DatabaseFileName := TempDir + 'test_q.adb';
 aDB.DatabaseName := 'TestDB';
 aDB.DeleteDatabase;
 aDB.CreateDatabase;
 aDB.Open;
 aq1 := TACRQuery.Create(nil);
 try
   Test(False);
   Test(True);
 finally
   aq1.Free;
   aDB.Close;
   aDB.DeleteDatabase;
   aDB.Free;
 end;

end;

procedure TUnitTestACRQuery.TestQuery(SqlText: String);
var
  aq: TACRQuery;
  q:  TQuery;
begin
  WriteToProcessLog('Test Query: ' + SqlText);
  aq := TACRQuery.Create(nil);
  try
    aq.InMemory := true;

    q := TQuery.Create(nil);
    try
      q.DatabaseName := TempDir;

      aq.SQL.Text := SqlText;
      q.SQL.Text := SqlText;
      aq.Open;
      //aq.First;
      q.Open;

      CheckQuery(q, aq, '''' + SqlText + '''');

    finally
      q.Free;
    end;

  finally
    aq.Free;
  end;
  WriteToProcessLog('Test Query: ok.');
end;


procedure TUnitTestACRQuery.TestNoResultQuery(SqlText: String);
var
  aq: TACRQuery;
  q:  TQuery;
begin
  WriteToProcessLog('Test NoResultQuery: ' + SqlText);
  aq := TACRQuery.Create(nil);
  try
    aq.InMemory := true;

    q := TQuery.Create(nil);
    try
      q.DatabaseName := TempDir;

      aq.SQL.Text := SqlText;
      q.SQL.Text := SqlText;
      aq.ExecSQL;
      try
        q.ExecSQL;
      except
        on e: Exception do
          WriteToErrorLog('bde query error: ' + e.Message);
      end;

      if aq.RowsAffected <> q.RowsAffected then
        WriteToErrorLog('RowsAffected error: sql=''' + SqlText + ''' BDE = ' +
          IntToStr(q.RowsAffected) + '  ACR = ' + IntToStr(aq.RowsAffected));

      aq.SQL.Text := 'select * from test order by Field1';
      q.SQL.Text := 'select * from test order by Field1';
      aq.Open;
      q.Open;


      CheckQuery(q, aq, '''' + SqlText + '''');

    finally
      q.Free;
    end;

  finally
    aq.Free;
  end;
  WriteToProcessLog('Test NoResultQuery: ok.');
end;




procedure TUnitTestACRQuery.TestWideStringFunctions;
var q: TACRQuery;
begin
  q := TACRQuery.Create(nil);
  try
    q.InMemory := true;
    q.SQL.Text := 'DROP TABLE test; CREATE TABLE test(id AutoInc, name CHAR(50), surname CHAR(50)'
                  + ', w_name WIDECHAR(50), w_surname WIDECHAR(50));'+#13#10
                  +'INSERT INTO test(name,surname,w_name,w_surname) '
                  +'VALUES ("Leo","Martin","Leo","Martin");';
    q.ExecSQL;
    if (q.RowsAffected <> 1) then
     WriteToErrorLog('TestWideStringFunctions error: rows affected = '+IntToStr(q.RowsAffected));
    q.SQL.Text := 'SELECT (name+" "+surname) as fullname, (w_name+" "+w_surname) as w_fullname FROM test';
    q.Open;
    if (q.RecordCount <> 1) then
     WriteToErrorLog('TestWideStringFunctions error: record count = '+IntToStr(q.RecordCount));
    if (q.Fields[0].AsString <> 'Leo Martin') then
     WriteToErrorLog('TestWideStringFunctions error: fullname = '+q.Fields[0].AsString);
    if (q.Fields[1].AsString <> 'Leo Martin') then
     WriteToErrorLog('TestWideStringFunctions error: w_fullname = '+q.Fields[1].AsString);
    q.Close;

    q.SQL.Text := 'SELECT SUBSTRING(name,2,1),SUBSTRING(w_name,3,1) FROM test';
    q.Open;
    if (q.RecordCount <> 1) then
     WriteToErrorLog('TestWideStringFunctions error #1: RecordCount = '+IntToStr(q.RecordCount));
    if (q.Fields[0].AsString <> 'e') then
     WriteToErrorLog('TestWideStringFunctions error #2: Field#0 = '+q.Fields[0].AsString);
    if (q.Fields[1].AsString <> 'o') then
     WriteToErrorLog('TestWideStringFunctions error #3: Field#1 = '+q.Fields[1].AsString);
  finally
    q.SQL.Text := 'DROP TABLE test';
    q.ExecSQL;
    q.Free;
  end;
end;

procedure TUnitTestACRQuery.TestLeftJoinAbsDiff;
var q: TACRQuery;
begin
  q := TACRQuery.Create(nil);
  try
    q.InMemory := true;
    q.SQL.Text := 'DROP TABLE HPL; DROP TABLE AA;';
    q.ExecSQL;
    q.SQL.Text := 'CREATE TABLE HPL(id integer, f1 float, f2 float);'+#13#10+
                  'INSERT INTO HPL VALUES(1,1.0,1.5);'+#13#10+
                  'CREATE TABLE AA(id integer, mass integer);'+#13#10+
                  'INSERT INTO AA VALUES(1,40);'+#13#10+
                  'INSERT INTO AA VALUES(1,75);'+#13#10
                  ;
    q.ExecSQL;
    q.SQL.Text := 'SELECT HPL.f2 - HPL.f1 AS diff, ABS(diff) AS ABS_diff, AA.mass FROM HPL'+#13#10+
                  'LEFT JOIN AA ON (HPL.id = AA.id)'+#13#10+
                  'WHERE (AA.mass >= 70) AND (abs_diff > 0.3)'+#13#10+
                  'ORDER BY abs_diff DESC';
    q.Open;
    if (q.RecordCount <> 1) then
     WriteToErrorLog('TestLeftJoinAbsDiff error: record count = '+IntToStr(q.RecordCount));
    if (q.FieldByName('mass').AsInteger <> 75) then
     WriteToErrorLog('TestLeftJoinAbsDiff error: invalid mass = '+q.FieldByName('mass').AsString);
  finally
    q.SQL.Text := 'DROP TABLE HPL; DROP TABLE AA;';
    q.ExecSQL;
    q.Free;
  end;
end;

procedure TUnitTestACRQuery.TestLeftJoinDekart2Conditions;
var q: TACRQuery;
begin
  q := TACRQuery.Create(nil);
  try
    q.InMemory := true;
    q.SQL.Text := 'DROP TABLE moretest CASCADE; DROP TABLE testing2 CASCADE; DROP TABLE testing CASCADE;';
    q.ExecSQL;
    q.SQL.Text := 'CREATE TABLE moretest ('+#13#10+
        	'id  AUTOINC,	testing_id SIGNEDINT32,	testing2_id SIGNEDINT32, naming CHAR(25));'+#13#10+
          'INSERT INTO moretest VALUES (1,1,1,"asdfasd");'+#13#10+
          'CREATE TABLE testing (ID  AUTOINC ,	NAME CHAR (25));'+#13#10+
          'INSERT INTO testing VALUES (1,"DFGDFG");'+#13#10+
          'INSERT INTO testing VALUES (2,"VBCVB");'+#13#10+
          'CREATE TABLE testing2 (id  AUTOINC,	name CHAR (25));'+#13#10+
          'INSERT INTO testing2 VALUES (1,"yrre");'+#13#10+
          'INSERT INTO testing2 VALUES (2,"rtrt");'+#13#10;
    q.ExecSQL;
    q.SQL.Text := 'SELECT t.name as name,t2.name as name2,m.naming '+#13#10+
//                  'FROM testing t,testing2 t2'+#13#10+
                  'FROM testing t CROSS JOIN testing2 t2'+#13#10+
                  'LEFT JOIN moretest m ON m.testing_id=t.id AND m.testing2_id=t2.id'+#13#10+
                  'ORDER BY 1,2,3';
    q.Open;
    q.First;
    if (q.RecordCount <> 4) then
     WriteToErrorLog('TestLeftJoinDekart2Conditions error: record count = '+IntToStr(q.RecordCount));
    //#1
    if (q.FieldByName('name').AsString <> 'DFGDFG') then
     WriteToErrorLog('TestLeftJoinDekart2Conditions error: invalid name = '+q.FieldByName('name').AsString);
    if (q.FieldByName('name2').AsString <> 'rtrt') then
     WriteToErrorLog('TestLeftJoinDekart2Conditions error: invalid name2 = '+q.FieldByName('name2').AsString);
    if (q.FieldByName('naming').AsString <> '') then
     WriteToErrorLog('TestLeftJoinDekart2Conditions error: invalid naming = '+q.FieldByName('naming').AsString);
    q.Next;
    //#2
    if (q.FieldByName('name').AsString <> 'DFGDFG') then
     WriteToErrorLog('TestLeftJoinDekart2Conditions error: invalid name = '+q.FieldByName('name').AsString);
    if (q.FieldByName('name2').AsString <> 'yrre') then
     WriteToErrorLog('TestLeftJoinDekart2Conditions error: invalid name2 = '+q.FieldByName('name2').AsString);
    if (q.FieldByName('naming').AsString <> 'asdfasd') then
     WriteToErrorLog('TestLeftJoinDekart2Conditions error: invalid naming = '+q.FieldByName('naming').AsString);
    q.Next;
    //#3
    if (q.FieldByName('name').AsString <> 'VBCVB') then
     WriteToErrorLog('TestLeftJoinDekart2Conditions error: invalid name = '+q.FieldByName('name').AsString);
    if (q.FieldByName('name2').AsString <> 'rtrt') then
     WriteToErrorLog('TestLeftJoinDekart2Conditions error: invalid name2 = '+q.FieldByName('name2').AsString);
    if (q.FieldByName('naming').AsString <> '') then
     WriteToErrorLog('TestLeftJoinDekart2Conditions error: invalid naming = '+q.FieldByName('naming').AsString);
    q.Next;
    //#4
    if (q.FieldByName('name').AsString <> 'VBCVB') then
     WriteToErrorLog('TestLeftJoinDekart2Conditions error: invalid name = '+q.FieldByName('name').AsString);
    if (q.FieldByName('name2').AsString <> 'yrre') then
     WriteToErrorLog('TestLeftJoinDekart2Conditions error: invalid name2 = '+q.FieldByName('name2').AsString);
    if (q.FieldByName('naming').AsString <> '') then
     WriteToErrorLog('TestLeftJoinDekart2Conditions error: invalid naming = '+q.FieldByName('naming').AsString);
  finally
    q.SQL.Text := 'DROP TABLE moretest CASCADE; DROP TABLE testing2 CASCADE; DROP TABLE testing CASCADE;';
    q.ExecSQL;
    q.Free;
  end;
end;

procedure TUnitTestACRQuery.TestDateFunctions;
var q:    TACRQuery;
    capt: AnsiString;
begin
  capt := 'TUnitTestACRQuery.TestDateFunctions - ';
  WriteToProcessLog(capt+'starting...');
  q := TACRQuery.Create(nil);
  try
    q.InMemory := True;
    q.SQL.Text :=  'CREATE TABLE TestDT(ID AutoInc, dt DateTime, PRIMARY KEY PK(ID));'+#13#10
                  +'CREATE INDEX id1 ON TestDT(dt);';
    q.ExecSQL;
    q.SQL.Text :=  'INSERT INTO TestDT(dt) VALUES(TODATE("01/12/2009","MM/DD/YYYY"));'+#13#10
                  +'INSERT INTO TestDT(dt) VALUES(TODATE("31.12.2008","DD.MM.YYYY"));';
    q.ExecSQL;

    q.SQL.Text := 'SELECT * FROM TestDT WHERE dt = TODATE("01/12/2009","MM/DD/YYYY")';
    q.Open;
    if (q.RecordCount <> 1) then
     WriteToErrorLog(capt+'error #1 in SELECT #1');
    if (q.FieldValues['ID'] <> 1) then
     WriteToErrorLog(capt+'error #2 in SELECT #1');
    q.Close;
    WriteToProcessLog(capt+'SELECT #1 OK.');

    q.SQL.Text := 'SELECT * FROM TestDT '
                  +'WHERE TOSTRING(dt,"YYYY") = "2008" AND TOSTRING(dt,"MM") = "12"';
    q.Open;
    if (q.RecordCount <> 1) then
     WriteToErrorLog(capt+'error #1 in SELECT #2');
    if (q.FieldValues['ID'] <> 2) then
     WriteToErrorLog(capt+'error #2 in SELECT #2');
    q.Close;
    WriteToProcessLog(capt+'SELECT #2 OK.');

    q.SQL.Text := 'SELECT * FROM TestDT WHERE dt = TODATE("31.12.2008","DD.MM.YYYY")';
    q.Open;
    if (q.RecordCount <> 1) then
     WriteToErrorLog(capt+'error #1 in SELECT #3');
    if (q.FieldValues['ID'] <> 2) then
     WriteToErrorLog(capt+'error #2 in SELECT #3');
    q.Close;
    WriteToProcessLog(capt+'SELECT #3 OK.');

    q.SQL.Text := 'SELECT TOSTRING(dt,"DD"), TOSTRING(dt,"MM"), TOSTRING(dt,"YYYY") FROM TestDT ORDER BY 3';
    q.Open;
    if (q.RecordCount <> 2) then
     WriteToErrorLog(capt+'error #1 in SELECT #4');
    if (q.Fields[0].AsInteger <> 31) then
     WriteToErrorLog(capt+'error #2 in SELECT #4');
    if (q.Fields[1].AsInteger <> 12) then
     WriteToErrorLog(capt+'error #3 in SELECT #4');
    if (q.Fields[2].AsInteger <> 2008) then
     WriteToErrorLog(capt+'error #4 in SELECT #4');
    q.Next;
    if (q.Fields[0].AsInteger <> 12) then
     WriteToErrorLog(capt+'error #5 in SELECT #4');
    if (q.Fields[1].AsInteger <> 1) then
     WriteToErrorLog(capt+'error #6 in SELECT #4');
    if (q.Fields[2].AsInteger <> 2009) then
     WriteToErrorLog(capt+'error #7 in SELECT #4');
    q.Close;
    WriteToProcessLog(capt+'SELECT #4 OK.');


    q.SQL.Text := 'DROP TABLE testdt';
    q.ExecSQL;
  finally
    q.Free;
  end;
end;


procedure TUnitTestACRQuery.TestDeleteUpdateWithVarcharBLOBAndForeignKeys;
const Capt = 'TestDeleteUpdateWithVarcharBLOBAndForeignKeys - ';
var
  ACRDatabase1: TACRDatabase;
  ACRQuery1: TDataSet;
  sTemp: string;
begin
  sTemp := '';
  ACRDatabase1 := TACRDatabase.Create(nil);
  ACRQuery1 := TACRQuery.Create(nil);
  try
    ACRDatabase1.DatabaseFileName := TempDir+'acc48.adb';
    TACRQuery(ACRQuery1).DatabaseName := ACRDatabase1.DatabaseName;
    if (ACRDatabase1.Exists) then
     ACRDatabase1.DeleteDatabase;
    WriteToProcessLog(Capt+'Create database');
    ACRDatabase1.CreateDatabase;
    ACRDatabase1.Open;


    WriteToProcessLog(Capt+'Execute SQL script');
    TACRQuery(ACRQuery1).SQL.LoadFromFile(SQLDir+'d5pl0000.sql');
    TACRQuery(ACRQuery1).ExecSQL;
    ACRDatabase1.ClearCache;

    WriteToProcessLog(Capt+'Insert some data');
    TACRQuery(ACRQuery1).SQL.Text := 'INSERT INTO tsGeneralProperties (PropertyName, PropertyValue) VALUES (''Version'', ''506'')';
    TACRQuery(ACRQuery1).ExecSQL;
    ACRDatabase1.ClearCache;
    TACRQuery(ACRQuery1).SQL.Text := 'INSERT INTO tsGeneralProperties (PropertyName, PropertyValue) VALUES (''Edition'', ''4'')';
    TACRQuery(ACRQuery1).ExecSQL;
    ACRDatabase1.ClearCache;
    TACRQuery(ACRQuery1).SQL.Text := 'INSERT INTO tsGeneralProperties (PropertyName, PropertyValue) VALUES (''DatabaseType'', ''3'')';
    TACRQuery(ACRQuery1).ExecSQL;
    ACRDatabase1.ClearCache;

    WriteToProcessLog(Capt+'Close database');
    ACRDatabase1.Close;
    Sleep(1000);

    WriteToProcessLog(Capt+'Open database');
    ACRDatabase1.Open;

    WriteToProcessLog(Capt+'Execute some statements');
    TACRQuery(ACRQuery1).SQL.Text := 'SELECT PropertyValue FROM tsGeneralProperties WHERE PropertyName=''Edition''';
    TACRQuery(ACRQuery1).Open;
    sTemp := sTemp + ACRQuery1.FieldByName('PropertyValue').AsString;
    ACRQuery1.Close;
    ACRDatabase1.ClearCache;

    TACRQuery(ACRQuery1).SQL.Text := 'SELECT MAX(Patchlevel) FROM tsPatchlevel';
    TACRQuery(ACRQuery1).Open;
    sTemp := sTemp + IntToStr(ACRQuery1.Fields[0].AsInteger);
    ACRQuery1.Close;
    ACRDatabase1.ClearCache;

    TACRQuery(ACRQuery1).SQL.Text := 'SELECT PropertyValue FROM tsGeneralProperties WHERE PropertyName=''Version''';
    TACRQuery(ACRQuery1).Open;
    sTemp := sTemp + ACRQuery1.FieldByName('PropertyValue').AsString;
    ACRQuery1.Close;
    ACRDatabase1.ClearCache;

    TACRQuery(ACRQuery1).SQL.Text := 'SELECT PropertyValue FROM tsGeneralProperties WHERE PropertyName=''DatabaseType''';
    TACRQuery(ACRQuery1).Open;
    sTemp := sTemp + ACRQuery1.FieldByName('PropertyValue').AsString;
    ACRQuery1.Close;
    ACRDatabase1.ClearCache;

    WriteToProcessLog(Capt+'Execute critical statements');
    TACRQuery(ACRQuery1).SQL.Text := 'SELECT ID FROM tdUsers WHERE ActiveDirectorySID = ''S-1-5-21-73586283-507921405-854245398-1004''';
    TACRQuery(ACRQuery1).Open;
    sTemp := sTemp + IntToStr(ACRQuery1.FieldByName('ID').AsInteger);
    ACRQuery1.Close;
    ACRDatabase1.ClearCache;

    TACRQuery(ACRQuery1).SQL.Text := 'SELECT TOP 1 * FROM tdUsers';
    TACRQuery(ACRQuery1).Open;
    sTemp := sTemp + IntToStr(ACRQuery1.FieldByName('ID').AsInteger);
    ACRQuery1.Close;
    ACRDatabase1.ClearCache;

    TACRQuery(ACRQuery1).SQL.Text := 'SELECT TOP 5 ID, Name, Fullname, Inactive FROM tdUsers WHERE Name like ''Administrator%'' AND Deleted=False ORDER BY Name';
    TACRQuery(ACRQuery1).Open;
    sTemp := sTemp + IntToStr(ACRQuery1.FieldByName('ID').AsInteger) + ACRQuery1.FieldByName('Name').AsString + ACRQuery1.FieldByName('Fullname').AsString;
    ACRQuery1.Close;
    ACRDatabase1.ClearCache;

    TACRQuery(ACRQuery1).SQL.Text := 'DELETE FROM tsClients WHERE UserID=-1';
    TACRQuery(ACRQuery1).ExecSQL;
    ACRDatabase1.ClearCache;

    TACRQuery(ACRQuery1).SQL.Text := 'SELECT * FROM tdUsers WHERE ID=1';
    TACRQuery(ACRQuery1).Open;
    sTemp := sTemp + IntToStr(ACRQuery1.FieldByName('ID').AsInteger);
    ACRQuery1.Close;
    ACRDatabase1.ClearCache;

    TACRQuery(ACRQuery1).SQL.Text := 'UPDATE tdUsers SET BadPasswordCount=0 WHERE ID=1';
    TACRQuery(ACRQuery1).ExecSQL;
    ACRDatabase1.ClearCache;

    TACRQuery(ACRQuery1).SQL.Text := 'SELECT TOP 1 * FROM tdUsers';
    TACRQuery(ACRQuery1).Open;
    sTemp := sTemp + IntToStr(ACRQuery1.FieldByName('ID').AsInteger);
    ACRQuery1.Close;
    ACRDatabase1.ClearCache;

    WriteToProcessLog(Capt+sTemp);

    WriteToProcessLog(Capt+'finished');
    ACRDatabase1.Close;
  finally
    ACRQuery1.Free;
    ACRDatabase1.DeleteDatabase;
    ACRDatabase1.Free;
  end;
end;

procedure TUnitTestACRQuery.TestBugBufferSizeExceededAlexFelton;
var
    q: TACRQuery;
    capt: String;
begin
 capt := 'TUnitTestACRQuery.TestBugBufferSizeExceededAlexFelton - ';
 q := TACRQuery.Create(nil);
 try
   q.InMemory := True;
   q.SQL.Text := 'DROP TABLE CurContacts; DROP TABLE PrevContacts;';
   q.ExecSQL;
   WriteToProcessLog(capt+'loading database...');
   q.SQL.LoadFromFile(SQLDir+'bug_buffer_size_exceeded_alex_felton_db.SQL');
   q.ExecSQL;
   WriteToProcessLog(capt+'loading database...OK');
   q.SQL.Text := 'select count(*) as newcnt from CurContacts cur left outer join PrevContacts prev on (prev.Unique_ID = cur.Unique_ID) where prev.Unique_ID is null';
   q.Open;
   if (q.RecordCount <> 1) then
    WriteToErrorLog(capt+'invalid record count #1 = '+IntToStr(q.RecordCount))
   else
   if (q.Fields[0].AsInteger <> 0) then
    WriteToErrorLog(capt+'invalid record count #2 = '+IntToStr(q.Fields[0].AsInteger));
 finally
   q.SQL.Text := 'DROP TABLE CurContacts; DROP TABLE PrevContacts;';
   q.ExecSQL;
   q.Free;
 end;
end;

procedure TUnitTestACRQuery.TestPrimaryIndex;
var capt: String;
    q:    TACRQuery;
begin
 capt := 'TUnitTestACRQuery.TestPrimaryIndex - ';
 q := TACRQuery.Create(nil);
 try
   q.InMemory := True;
   q.SQL.Text := 'CREATE TABLE MEMORY TestPrimaryIndex(Code Integer,Name Char(50), RegDate Date, PRIMARY KEY (Code DESC,Name NOCASE))';
   q.ExecSQL;
   WriteToProcessLog(capt+'table created');
   q.SQL.Text := 'INSERT INTO MEMORY TestPrimaryIndex VALUES(15,"Test1",NOW)';
   q.ExecSQL;
   q.SQL.Text := 'INSERT INTO MEMORY TestPrimaryIndex VALUES(15,"test",NOW)';
   q.ExecSQL;
   q.SQL.Text := 'INSERT INTO MEMORY TestPrimaryIndex VALUES(5,"test",NOW)';
   q.ExecSQL;
   WriteToProcessLog(capt+'records inserted');
   q.RequestLive := True;
   q.SQL.Text := 'SELECT * FROM MEMORY TestPrimaryIndex ORDER BY Code DESC,Name NOCASE';
   q.Open;
   if (q.ReadOnly) then
    WriteToErrorLog(capt+'error #1');
   if (q.RecordCount <> 3) then
    WriteToErrorLog(capt+'error #2');
   if (q.FieldByName('name').AsString <> 'test') then
    WriteToErrorLog(capt+'error #3');
   if (q.FieldByName('code').AsInteger <> 15) then
    WriteToErrorLog(capt+'error #4');
   q.Next;
   if (q.FieldByName('name').AsString <> 'Test1') then
    WriteToErrorLog(capt+'error #5');
   if (q.FieldByName('code').AsInteger <> 15) then
    WriteToErrorLog(capt+'error #6');
   q.Next;
   if (q.FieldByName('name').AsString <> 'test') then
    WriteToErrorLog(capt+'error #7');
   if (q.FieldByName('code').AsInteger <> 5) then
    WriteToErrorLog(capt+'error #8');
   q.Next;
   if (not q.Eof) then
    WriteToErrorLog(capt+'error #9');
   WriteToProcessLog(capt+'test finished');
 finally
   q.SQL.Text := 'DROP TABLE MEMORY TestPrimaryIndex;';
   q.ExecSQL;
   q.Free;
 end;
end; // TestPrimaryIndex

procedure TUnitTestACRQuery.TestForeignKeySelfTable;
var capt: String;
    q:    TACRQuery;
begin
 capt := 'TUnitTestACRQuery.TestForeignKeySelfTable - ';
 q := TACRQuery.Create(nil);
 try
   q.InMemory := True;
   q.SQL.Text := 'CREATE TABLE MEMORY testFKSelfTable ('
+'[id] AUTOINC (AUTOINC INITIALVALUE 0 INCREMENT 1 NOMINVALUE MAXVALUE 2147483647 NOCYCLED) NOT NULL,'
+'[parent] INTEGER,'
+'PRIMARY KEY [PK_test] ([id] NOCASE)'
+'); ';
   q.ExecSQL;
   WriteToProcessLog(capt+'table created');
   q.SQL.Text := 'ALTER TABLE MEMORY testFKSelfTable ADD('
+'FOREIGN KEY Fk_TEST (parent) REFERENCES [testFKSelfTable] ON DELETE CASCADE ON UPDATE CASCADE); ';
   q.ExecSQL;
   WriteToProcessLog(capt+'foreign key created');
   q.SQL.Text := 'INSERT INTO MEMORY testFKSelfTable(parent) VALUES(NULL);'+
                 'INSERT INTO MEMORY testFKSelfTable(parent) VALUES(1);'+
                 'INSERT INTO MEMORY testFKSelfTable(parent) VALUES(2);';
   q.ExecSQL;
   WriteToProcessLog(capt+'records inserted');

   q.RequestLive := True;
   q.SQL.Text := 'SELECT * FROM MEMORY testFKSelfTable ORDER BY id NOCASE';
   q.Open;
   if (q.ForeignKeyDefs.Count <> 1) then
    WriteToErrorLog(capt+'error #1');
   if (q.ReadOnly) then
    WriteToErrorLog(capt+'error #2');
   if (q.Fields[0].AsInteger <> 1) then
    WriteToErrorLog(capt+'error #3');
   q.Next;
   if (q.Fields[0].AsInteger <> 2) then
    WriteToErrorLog(capt+'error #4');
   q.Next;
   if (q.Fields[0].AsInteger <> 3) then
    WriteToErrorLog(capt+'error #5');
   q.Next;
   if (not q.Eof) then
    WriteToErrorLog(capt+'error #6');
   q.SQL.Text := 'DELETE FROM MEMORY testFKSelfTable WHERE id = 1';
   q.ExecSQL;
   // RowsAffected does not include actions performed by foreign keys
   if (q.RowsAffected <> 1) then
    WriteToErrorLog(capt+'error #7');
   q.RequestLive := True;
   q.SQL.Text := 'SELECT * FROM MEMORY testFKSelfTable ORDER BY id NOCASE';
   q.Open;
   if (q.RecordCount <> 0) then
    WriteToErrorLog(capt+'error #8');
   if (not q.Eof) then
    WriteToErrorLog(capt+'error #9');
   q.Close;
   q.SQL.Text := 'ALTER TABLE MEMORY testFKSelfTable ADD(column1 integer NULL,'
                +'column2 integer NULL, column3 integer NULL)';
   q.ExecSQL;
   q.RequestLive := True;
   q.SQL.Text := 'SELECT * FROM MEMORY testFKSelfTable ORDER BY id NOCASE';
   q.Open;
   if (q.FieldCount <> 5) then
    WriteToErrorLog(capt+'error #10');
   if (q.FieldByName('column1') = nil) then
    WriteToErrorLog(capt+'error #11');
   if (q.FieldByName('column2') = nil) then
    WriteToErrorLog(capt+'error #12');
   if (q.FieldByName('column3') = nil) then
    WriteToErrorLog(capt+'error #13');
   q.Insert;
   q.Post;
   if (q.RecordCount <> 1) then
    WriteToErrorLog(capt+'error #14');
   WriteToProcessLog(capt+'test finished');
 finally
   q.SQL.Text := 'DROP TABLE MEMORY testFKSelfTable CASCADE;';
   q.ExecSQL;
   q.Free;
 end;
end; // TestForeignKeySelfTable


procedure TUnitTestACRQuery.TestInsertIntoNotExistingTable;
var
    q: TACRQuery;
    capt: String;
begin
 capt := 'TestInsertIntoNotExistingTable - ';
 q := TACRQuery.Create(nil);
 try
   q.InMemory := True;
   q.SQL.Text := 'DROP TABLE TestInsert; CREATE TABLE TestInsert(id AutoInc);';
   q.ExecSQL;
   try
     q.SQL.Text := 'INSERT INTO NotExistingTable SELECT * FROM TestInsert';
     q.ExecSQL;
     WriteToErrorLog(capt+'insert FAILED');
   except
     WriteToProcessLog(capt+'insert ok');
   end;

   q.SQL.Text := 'SELECT COUNT(*) FROM NotExistingTable';
   try
     q.Open;
     WriteToErrorLog(capt+'insert FAILED - table exists #2');
   except
     WriteToProcessLog(capt+'insert ok #2');
   end;
   q.SQL.Text := 'INSERT INTO TestInsert SELECT * FROM NotExistingTable';
   try
     q.ExecSQL;
     WriteToErrorLog(capt+'insert FAILED #3');
   except
     WriteToProcessLog(capt+'insert ok #3');
   end;
   q.SQL.Text := 'SELECT COUNT(*) FROM NotExistingTable';
   try
     q.Open;
     WriteToErrorLog(capt+'insert FAILED - table exists #4');
   except
     WriteToProcessLog(capt+'insert ok #4');
   end;
   
 finally
   q.SQL.Text := 'DROP TABLE TestInsert';
   q.ExecSQL;
   q.Free;
 end;
end; // TestInsertIntoNotExistingTable

procedure TUnitTestACRQuery.TestSQLErrorLineNumber;
var
    q: TACRQuery;
    capt: String;
    x: Integer;
begin
 capt := 'TestInsertIntoNotExistingTable - ';
 q := TACRQuery.Create(nil);
 try
   q.InMemory := True;
   q.SQL.Text := 'DROP TABLE TestSQLError; CREATE TABLE TestSQLError(id AutoInc);';
   q.ExecSQL;

   q.SQL.Text := 'UPDATE TestSQLError'+#13#10+'SELECT * FROM TestSQLError';
   try
     q.ExecSQL;
     WriteToErrorLog(capt+'Error - no exception!!!');
   except
    on e: EACRException do
     begin
      x := Pos('at line 2',e.Message);
      if (e.NativeError = 30220) and (x = 42) then
       WriteToProcessLog(capt+'Exception - OK'+#13#10+e.Message)
      else
       WriteToErrorLog(capt+'Invalid exception:'+#13#10+e.Message);
     end
    else
     WriteToErrorLog(capt+'Error - invalid exception class!!!');
   end;

 finally
   q.SQL.Text := 'DROP TABLE TestSQLError';
   q.ExecSQL;
   q.Free;
 end;
end; // TestSQLErrorLineNumber


procedure TUnitTestACRQuery.TestSelectUnionInvalidFieldName;
var
    q: TACRQuery;
    capt: String;
    b: Boolean;
begin
{




-- The following has a deliberate fault to highlite the problem
select UniqueId, 'Missing Surname' as Message
	from Students where LastName = ''
union
select UniqueId, 'Missing Forename' as Message
	from Students where xxxxFirstName = ''
;

}
 capt := 'TestSelectUnionInvalidFieldName - ';
 q := TACRQuery.Create(nil);
 try
   q.InMemory := True;
   q.SQL.Text := 'drop table students;'+
                 'create table Students (UniqueId integer, LastName varchar(50), FirstName varchar(50), UPN varchar(20));'+
                 'insert into Students values (1, ''Felton'', ''Alex'', ''X12345'');';
   q.ExecSQL;

   q.SQL.Text := 'select UniqueId, "Missing Surname" as Message'+#13#10+
                 'from Students where LastName = ""'+#13#10+
                 'union'+#13#10+
                 'select UniqueId, "Missing Forename" as Message'+#13#10+
                 'from Students where xxxxFirstName = ""';

   try
     q.ExecSQL;
     WriteToErrorLog(capt+'Error - no exception!!!');
   except
    on e: EACRException do
     begin
      b := (Pos('Field ''xxxxFirstName'' not found',e.Message) = 1) and
           (e.NativeError = 11764);
      if (b) then
       WriteToProcessLog(capt+'Exception - OK'+#13#10+e.Message)
      else
       WriteToErrorLog(capt+'Invalid exception:'+#13#10+e.Message);
     end
    else
     WriteToErrorLog(capt+'Error - invalid exception class!!!');
   end;

 finally
   q.SQL.Text := 'drop table students cascade';
   q.ExecSQL;
   q.Free;
 end;
end; // TestSelectUnionInvalidFieldName

procedure TUnitTestACRQuery.TestSelectUnionInvalidFieldCount;
var
    q: TACRQuery;
    capt: String;
    b: Boolean;
begin
{
drop table students;
create table Students (UniqueId integer, LastName varchar(50), FirstName varchar(50), UPN varchar(20));
insert into Students values (1, 'Felton', 'Alex', 'X12345');

-- this select returns 6 columns
select 'xxxx' as NewField, s.* from students s;
}
 capt := 'TestSelectUnionInvalidFieldCount - ';
 q := TACRQuery.Create(nil);
 try
   q.InMemory := True;
   q.SQL.Text := 'drop table students;'+
                 'create table Students (UniqueId integer, LastName varchar(50), FirstName varchar(50), UPN varchar(20));'+
                 'insert into Students values (1, ''Felton'', ''Alex'', ''X12345'');';
   q.ExecSQL;

   q.SQL.Text := 'select ''xxxx'' as NewField, s.* from students s';
   q.Open;
   if (q.FieldCount <> 5) then
     WriteToErrorLog(capt+'Error - invalid field count = '+IntToStr(q.FieldCount));
   WriteToProcessLog(capt+'finished')

 finally
   q.SQL.Text := 'drop table students cascade';
   q.ExecSQL;
   q.Free;
 end;
end; // TestSelectUnionInvalidFieldName


procedure TUnitTestACRQuery.TestCumSum;
var
    q: TACRQuery;
    capt: String;
    b: Boolean;
begin
 capt := 'TestCumSum - ';
 q := TACRQuery.Create(nil);
 try
   q.InMemory := True;
   q.SQL.Text := 'drop table test;'+
                 'create table test (num integer);'+
                 'insert into test values (1);'+
                 'insert into test values (10);'+
                 'insert into test values (25);'+
                 'insert into test values (100);'+
                 'insert into test values (1000);'
                 ;
   q.ExecSQL;

   q.SQL.Text := 'select num, CUMSUM(num) FROM test';
   q.Open;
   if (q.FieldCount <> 2) then
     WriteToErrorLog(capt+'Error - invalid field count = '+IntToStr(q.FieldCount));
   if (q.Fields[1].AsInteger <> 1) then
     WriteToErrorLog(capt+'Error #1');
   q.Next;
   if (q.Fields[1].AsInteger <> 11) then
     WriteToErrorLog(capt+'Error #2');
   q.Next;
   if (q.Fields[1].AsInteger <> 36) then
     WriteToErrorLog(capt+'Error #3');
   q.Next;
   if (q.Fields[1].AsInteger <> 136) then
     WriteToErrorLog(capt+'Error #4');
   q.Next;
   if (q.Fields[1].AsInteger <> 1136) then
     WriteToErrorLog(capt+'Error #5');
   q.Next;
   if (not q.Eof) then
     WriteToErrorLog(capt+'Error #6');

   WriteToProcessLog(capt+'finished')

 finally
   q.SQL.Text := 'drop table test cascade';
   q.ExecSQL;
   q.Free;
 end;
end; // TestCumSum


procedure TUnitTestACRQuery.TestCumProd;
var
    q: TACRQuery;
    capt: String;
    b: Boolean;
begin
 capt := 'TestCumProd - ';
 q := TACRQuery.Create(nil);
 try
   q.InMemory := True;
   q.SQL.Text := 'drop table test;'+
                 'create table test (num integer);'+
                 'insert into test values (3);'+
                 'insert into test values (2);'+
                 'insert into test values (5);'+
                 'insert into test values (7);'+
                 'insert into test values (10);'
                 ;
   q.ExecSQL;

   q.SQL.Text := 'select num, CUMPROD(num) FROM test';
   q.Open;
   if (q.FieldCount <> 2) then
     WriteToErrorLog(capt+'Error - invalid field count = '+IntToStr(q.FieldCount));
   if (q.Fields[1].AsInteger <> 3) then
     WriteToErrorLog(capt+'Error #1');
   q.Next;
   if (q.Fields[1].AsInteger <> 6) then
     WriteToErrorLog(capt+'Error #2');
   q.Next;
   if (q.Fields[1].AsInteger <> 30) then
     WriteToErrorLog(capt+'Error #3');
   q.Next;
   if (q.Fields[1].AsInteger <> 210) then
     WriteToErrorLog(capt+'Error #4');
   q.Next;
   if (q.Fields[1].AsInteger <> 2100) then
     WriteToErrorLog(capt+'Error #5');
   q.Next;
   if (not q.Eof) then
     WriteToErrorLog(capt+'Error #6');

   WriteToProcessLog(capt+'finished')

 finally
   q.SQL.Text := 'drop table test cascade';
   q.ExecSQL;
   q.Free;
 end;
end; // TestCumProd


procedure TUnitTestACRQuery.TestGroupConcat;
var
    q: TACRQuery;
    capt: String;
    b: Boolean;
begin
 capt := 'TestGroupConcat - ';
 q := TACRQuery.Create(nil);
 try
   q.InMemory := True;
   q.SQL.Text := 'drop table test;'+
                 'create table test (num integer,name char(20));'+
                 'insert into test values (1,"Leo");'+
                 'insert into test values (1,"Ray");'+
                 'insert into test values (2,"Ella");'+
                 'insert into test values (2,"John");'+
                 'insert into test values (3,"Net");'
                 ;
   q.ExecSQL;
   q.SQL.Text := 'select GROUP_CONCAT(name) FROM test';
   q.Open;
   if (q.FieldCount <> 1) then
     WriteToErrorLog(capt+'Error1 - invalid field count = '+IntToStr(q.FieldCount));
   if (q.RecordCount <> 1) then
     WriteToErrorLog(capt+'Error #1');
   if (q.Fields[0].AsString <> 'Ella,John,Leo,Net,Ray') then
     WriteToErrorLog(capt+'Error #2');
   q.Next;
   if (not q.Eof) then
     WriteToErrorLog(capt+'Error #3');

   q.SQL.Text := 'select GROUP_CONCAT(DESC name,";") FROM test';
   q.Open;
   if (q.FieldCount <> 1) then
     WriteToErrorLog(capt+'Error2 - invalid field count = '+IntToStr(q.FieldCount));
   if (q.RecordCount <> 1) then
     WriteToErrorLog(capt+'Error #4');
   if (q.Fields[0].AsString <> 'Ray;Net;Leo;John;Ella') then
     WriteToErrorLog(capt+'Error #5');
   q.Next;
   if (not q.Eof) then
     WriteToErrorLog(capt+'Error #6');

   q.SQL.Text := 'select num,GROUP_CONCAT(name,"; ") FROM test GROUP BY num ORDER BY num';
   q.Open;
   if (q.FieldCount <> 2) then
     WriteToErrorLog(capt+'Error3 - invalid field count = '+IntToStr(q.FieldCount));
   if (q.RecordCount <> 3) then
     WriteToErrorLog(capt+'Error #7');
   if (q.Fields[1].AsString <> 'Leo; Ray') then
     WriteToErrorLog(capt+'Error #8');
   q.Next;
   if (q.Fields[1].AsString <> 'Ella; John') then
     WriteToErrorLog(capt+'Error #9');
   q.Next;
   if (q.Fields[1].AsString <> 'Net') then
     WriteToErrorLog(capt+'Error #10');
   q.Next;
   if (not q.Eof) then
     WriteToErrorLog(capt+'Error #11');

   q.SQL.Text := 'select num,GROUP_CONCAT(DESC name,"; ") FROM test GROUP BY num ORDER BY num';
   q.Open;
   if (q.FieldCount <> 2) then
     WriteToErrorLog(capt+'Error4 - invalid field count = '+IntToStr(q.FieldCount));
   if (q.RecordCount <> 3) then
     WriteToErrorLog(capt+'Error #12');
   if (q.Fields[1].AsString <> 'Ray; Leo') then
     WriteToErrorLog(capt+'Error #13');
   q.Next;
   if (q.Fields[1].AsString <> 'John; Ella') then
     WriteToErrorLog(capt+'Error #14');
   q.Next;
   if (q.Fields[1].AsString <> 'Net') then
     WriteToErrorLog(capt+'Error #15');
   q.Next;
   if (not q.Eof) then
     WriteToErrorLog(capt+'Error #16');

   q.SQL.Text := 'insert into test values (3,"Net")';
   q.ExecSQL;


   q.SQL.Text := 'select num,GROUP_CONCAT(DISTINCT DESC name,"; ") FROM test GROUP BY num ORDER BY num';
   q.Open;
   if (q.FieldCount <> 2) then
     WriteToErrorLog(capt+'Error5 - invalid field count = '+IntToStr(q.FieldCount));
   if (q.RecordCount <> 3) then
     WriteToErrorLog(capt+'Error #17');
   if (q.Fields[1].AsString <> 'Ray; Leo') then
     WriteToErrorLog(capt+'Error #18');
   q.Next;
   if (q.Fields[1].AsString <> 'John; Ella') then
     WriteToErrorLog(capt+'Error #19');
   q.Next;
   if (q.Fields[1].AsString <> 'Net') then
     WriteToErrorLog(capt+'Error #20');
   q.Next;
   if (not q.Eof) then
     WriteToErrorLog(capt+'Error #21');

   q.SQL.Text := 'select num,num FROM test GROUP BY num ORDER BY num';
   q.Open;
   if (q.FieldCount <> 2) then
     WriteToErrorLog(capt+'Error #22');
   if (q.RecordCount <> 3) then
     WriteToErrorLog(capt+'Error #23');
   if (q.Fields[0].AsInteger <> 1) then
     WriteToErrorLog(capt+'Error #24');
   if (q.Fields[1].AsInteger <> 1) then
     WriteToErrorLog(capt+'Error #25');
   q.Next;
   if (q.Fields[0].AsInteger <> 2) then
     WriteToErrorLog(capt+'Error #26');
   if (q.Fields[1].AsInteger <> 2) then
     WriteToErrorLog(capt+'Error #27');
   q.Next;
   if (q.Fields[0].AsInteger <> 3) then
     WriteToErrorLog(capt+'Error #28');
   if (q.Fields[1].AsInteger <> 3) then
     WriteToErrorLog(capt+'Error #29');
   q.Next;
   if (not q.Eof) then
     WriteToErrorLog(capt+'Error #30');
   q.Close;

   WriteToProcessLog(capt+'finished')

 finally
   q.SQL.Text := 'drop table test cascade';
   q.ExecSQL;
   q.Free;
 end;
end; // TestGroupConcat


procedure TUnitTestACRQuery.TestDistinctBug;
var
    q: TACRQuery;
    capt: String;
    b:    Boolean;
    qb:   TQuery;
begin
 q := TACRQuery.Create(nil);
 qb := TQuery.Create(nil);
 try
   capt := 'TestDistinctBug - test #1. ';
   q.InMemory := True;
   qb.DatabaseName := TempDir;

   qb.SQL.Text := 'CREATE TABLE Test (Field1 CHAR(100), Field2 AutoInc)';
   qb.ExecSQL;
   qb.SQL.Text := 'INSERT INTO Test(Field1) VALUES (''aa'')';
   qb.ExecSQL;
   qb.SQL.Text := 'INSERT INTO Test(Field1) VALUES (''ab'')';
   qb.ExecSQL;
   qb.SQL.Text := 'INSERT INTO Test(Field1) VALUES (''abc'')';
   qb.ExecSQL;
   qb.SQL.Text := 'INSERT INTO Test(Field1) VALUES (''aac'')';
   qb.ExecSQL;

   q.InMemory := True;
{$IFDEF ACR5H}
   q.SQL.Text := 'DROP TABLE Test CASCADE;'
+#13#10+'CREATE TABLE Test (Field1 WIDESTRING (100),	Field2  AUTOINC);'
+#13#10+'INSERT INTO Test VALUES ("aa",NULL);'
+#13#10+'INSERT INTO Test VALUES ("ab",NULL);'
+#13#10+'INSERT INTO Test VALUES ("abc",NULL);'
+#13#10+'INSERT INTO Test VALUES ("aac",NULL);'
;
{$ELSE}
   q.SQL.Text := 'DROP TABLE Test CASCADE;'
+#13#10+'CREATE TABLE Test (Field1 WIDESTRING (100),	Field2  AUTOINC);'
+#13#10+'INSERT INTO Test(field1) VALUES ("aa");'
+#13#10+'INSERT INTO Test(field1) VALUES ("ab");'
+#13#10+'INSERT INTO Test(field1) VALUES ("abc");'
+#13#10+'INSERT INTO Test(field1) VALUES ("aac");'
;
{$ENDIF}
   q.ExecSQL;
   WriteToProcessLog(capt+'tables created');

   q.SQL.Text := 'select * from Test ORDER BY Field1 DESC';
   qb.SQL.Text := q.SQL.Text;
   q.Open;
   qb.Open;
   CheckQuery(qb,q,capt+q.SQL.Text);
   q.Close;
   qb.Close;

   q.SQL.Text := 'select Distinct Field1 from Test ORDER BY 1';
   qb.SQL.Text := q.SQL.Text;
   q.Open;
   qb.Open;
   CheckQuery(qb,q,capt+q.SQL.Text);
   WriteToProcessLog(capt+' complete');


   capt := 'TestDistinctBug - test #2. ';
   qb.SQL.Text := 'create table Classes (ClassId char(30), ClassName char(50))';
   qb.ExecSQL;
   qb.SQL.Text := 'insert into Classes values ("S1AR1", "S1AR1 Art")';
   qb.ExecSQL;
   qb.SQL.Text := 'insert into Classes values ("S1AR2", "S1AR2 Art")';
   qb.ExecSQL;
   qb.SQL.Text := 'insert into Classes values ("S1AR3", "S1AR3 Art")';
   qb.ExecSQL;
   qb.SQL.Text := 'insert into Classes values ("S1AR4", "S1AR4 Art")';
   qb.ExecSQL;
   qb.SQL.Text := 'insert into Classes values ("S1AR5", "S1AR5 Art")';
   qb.ExecSQL;
   qb.SQL.Text := 'insert into Classes values ("S1AR6", "S1AR6 Art")';
   qb.ExecSQL;
   qb.SQL.Text := 'insert into Classes values ("S1AR7", "S1AR7 Art")';
   qb.ExecSQL;
   qb.SQL.Text := 'insert into Classes values ("S1AR8", "S1AR8 Art")';
   qb.ExecSQL;

   q.SQL.Text := 'drop table Classes;'+
                 'create table Classes (ClassId char(30), ClassName char(50));'+
                 'insert into Classes values ("S1AR1", "S1AR1 Art");'+
                 'insert into Classes values ("S1AR2", "S1AR2 Art");'+
                 'insert into Classes values ("S1AR3", "S1AR3 Art");'+
                 'insert into Classes values ("S1AR4", "S1AR4 Art");'+
                 'insert into Classes values ("S1AR5", "S1AR5 Art");'+
                 'insert into Classes values ("S1AR6", "S1AR6 Art");'+
                 'insert into Classes values ("S1AR7", "S1AR7 Art");'+
                 'insert into Classes values ("S1AR8", "S1AR8 Art");'
                 ;
   q.ExecSQL;
   WriteToProcessLog(capt+'tables created');

   q.SQL.Text := 'select * from Classes ORDER BY ClassId';
   qb.SQL.Text := q.SQL.Text;
   q.Open;
   qb.Open;
   CheckQuery(qb,q,capt+q.SQL.Text);

   q.SQL.Text := 'select distinct * from Classes';
   qb.SQL.Text := q.SQL.Text;
   q.Open;
   qb.Open;
   CheckQuery(qb,q,capt+q.SQL.Text);

   q.SQL.Text := 'select distinct ClassId from Classes ORDER BY 1';
   qb.SQL.Text := q.SQL.Text;
   q.Open;
   qb.Open;
   CheckQuery(qb,q,capt+q.SQL.Text);

   q.SQL.Text := 'select distinct ClassName from Classes ORDER BY 1';
   qb.SQL.Text := q.SQL.Text;
   q.Open;
   qb.Open;
   CheckQuery(qb,q,capt+q.SQL.Text);

   q.SQL.Text := 'select distinct ClassName,ClassId from Classes ORDER BY 1,2';
   qb.SQL.Text := q.SQL.Text;
   q.Open;
   qb.Open;
   CheckQuery(qb,q,capt+q.SQL.Text);
   WriteToProcessLog(capt+' complete');

   WriteToProcessLog(capt+'finished')

 finally
   q.SQL.Text := 'drop table Classes cascade; drop table Test cascade;';
   q.ExecSQL;
   q.Free;
   qb.SQL.Text := 'drop table Classes';
   qb.ExecSQL;
   qb.SQL.Text := 'drop table Test';
   qb.ExecSQL;
   qb.Free;
 end;
end; // TestDistinctBug


procedure TUnitTestACRQuery.TestReadOnlyDBSelect;
var db: TACRDatabase;
    q:  TACRQuery;
    capt: String;
begin
 capt := 'TestReadOnlyDBSelect - ';
 db := TACRDatabase.Create(nil);
 q := TACRquery.Create(nil);
 try
   db.DatabaseFileName := TempDir+'test_index_readonly.adb';
   db.CreateDatabase;
   db.Open;
   q.DatabaseName := db.DatabaseName;
   q.SQL.Text := 'CREATE TABLE test (id AutoInc, name Char(50))';
   q.ExecSQL;
   q.SQL.Text := 'INSERT INTO test VALUES(NULL,"test 1");'
                +'INSERT INTO test VALUES(NULL,"test 2");';
   q.ExecSQL;
   db.Close;
   db.ReadOnly := True;
   db.Open;
   q.SQL.Text := 'SELECT * FROM test ORDER BY name';
   try
     q.Open;
   except
     on e: Exception do
      begin
       WriteToErrorLog(capt+'Error: '+#13#10+e.Message);
       raise;
      end;
   end;
   if (q.RecordCount <> 2) then
    WriteToErrorLog(capt+'invalid recCount = '+IntToStr(q.RecordCount));
   if (q.Fields[1].AsString <> 'test 1') then
    WriteToErrorLog(capt+'invalid name = '+q.Fields[1].AsString);
 finally
   q.Free;
   db.Close;
   db.DeleteDatabase;
   db.Free;
 end;
end; // ReadOnlyDBSelect

procedure TUnitTestACRQuery.TestQuestionParameters;
var q: TACRQuery;
    capt: AnsiString;
    i: Integer;
begin
 capt := 'TestQuestionParameters - ';
 q := TACRquery.Create(nil);
 try
   q.InMemory := True;
   q.SQL.Text := 'CREATE TABLE Parameters (f1 Integer, f2 Integer, f3 Integer, f4 Integer, f5 Integer, f6 Char(10), f7 Integer, f8 Char(10), f9 Memo);';
   q.ExecSQL;
   q.SQL.Text := 'insert into Parameters (F1, F2, F3, F4, F5, F6, F7, F8, F9) values (?, ?, ?, ?, ?, ?, ?, ?, ?)';
   q.Prepare;
   for i := 0 to 4 do
    q.Params[i].AsInteger := i;
   q.Params[5].AsString := 'test 1!';
   q.Params[6].AsInteger := 10;
   q.Params[7].AsString := 'test 2!';
   q.Params[8].AsString := 'test 2! 1234567890 test 2! 1234567890 test 2! 1234567890';
   q.ExecSQL;
   q.SQL.Text := 'SELECT * FROM Parameters';
   q.Open;
   if (q.RecordCount <> 1) then
    WriteToErrorLog('error #000');
   if (q.Fields[0].AsInteger <> 0) then
    WriteToErrorLog('error #0');
   if (q.Fields[1].AsInteger <> 1) then
    WriteToErrorLog('error #1');
   if (q.Fields[2].AsInteger <> 2) then
    WriteToErrorLog('error #2');
   if (q.Fields[3].AsInteger <> 3) then
    WriteToErrorLog('error #3');
   if (q.Fields[4].AsInteger <> 4) then
    WriteToErrorLog('error #4');
   if (q.Fields[5].AsString <> 'test 1!') then
    WriteToErrorLog('error #5');
   if (q.Fields[6].AsInteger <> 10) then
    WriteToErrorLog('error #6');
   if (q.Fields[7].AsString <> 'test 2!') then
    WriteToErrorLog('error #7');
   if (q.Fields[8].AsString <> 'test 2! 1234567890 test 2! 1234567890 test 2! 1234567890') then
    WriteToErrorLog('error #8');
 finally
   q.SQL.Text := 'DROP TABLE Parameters;';
   q.ExecSQL;
   q.Free;
 end;
end; // TestQuestionParameters


procedure TUnitTestACRQuery.TestExceptWithSubQuery;
var q: TACRQuery;
    capt: AnsiString;
    i: Integer;
begin
 capt := 'TestExceptWithSubQuery - ';
 q := TACRquery.Create(nil);
 try
   q.InMemory := True;
   WriteToProcessLog(capt+'creating tables...');
   q.SQL.Text :=        'CREATE TABLE t1 (int1 integer, str1 char(20));'
                +#13#10+'CREATE TABLE t2 (int1 integer);'
                +#13#10+'CREATE TABLE t3 (int1 integer, str1 char(20));'
                +#13#10+'INSERT INTO t1 VALUES(1, "aaa");'
                +#13#10+'INSERT INTO t1 VALUES(2, "bbb");'
                +#13#10+'INSERT INTO t1 VALUES(3, "ccc");'
                +#13#10+'INSERT INTO t2 VALUES(3);'
                +#13#10+'INSERT INTO t3 VALUES(3, "ccc");'
                ;
   q.ExecSQL;
   q.SQL.Text :=         'CREATE TABLE Test(id Integer, name Char(20), PRIMARY KEY (id));'
                 +#13#10+'INSERT INTO Test VALUES (1,"John");'
                 +#13#10+'INSERT INTO Test VALUES (2,"Mike");'
                 +#13#10+'INSERT INTO Test VALUES (3,"Bob");'
                 ;
   q.ExecSQL;
   WriteToProcessLog(capt+'tables created');

   // last error code: 55

    q.SQL.Text := 'SELECT * FROM (SELECT ID,Name FROM Test EXCEPT SELECT ID,Name FROM Test WHERE id = 1) as G order by g.Name';
    q.Open;
    if (q.RecordCount <> 2) then
      WriteToErrorLog(capt+'Error #56')
    else
    begin
      if (q.Fields[0].AsInteger <> 3) then
       WriteToErrorLog(capt+'Error #57 - '+q.Fields[0].AsString);
      if (q.Fields[1].AsString <> 'Bob') then
       WriteToErrorLog(capt+'Error #58 - '+q.Fields[1].AsString);
      q.Next;
      if (q.Fields[0].AsInteger <> 2) then
       WriteToErrorLog(capt+'Error #59 - '+q.Fields[0].AsString);
      if (q.Fields[1].AsString <> 'Mike') then
       WriteToErrorLog(capt+'Error #60 - '+q.Fields[1].AsString);
      q.Next;
      if (not q.Eof) then
        WriteToErrorLog(capt+'Error #61');
    end;
    q.SQL.Text := 'SELECT * FROM '
                + '(SELECT ID FROM Test EXCEPT (SELECT ID FROM Test WHERE id = 1) '
                + 'EXCEPT (SELECT ID FROM Test WHERE id >= 2)'
                + ') G';
    q.Open;
    if (q.RecordCount <> 0) then
      WriteToErrorLog(capt+'Error #62');


   q.SQL.Text :=         'SELECT * FROM t1 EXCEPT ('
                 +#13#10+'SELECT t2.int1, t3.str1 FROM t2 INNER JOIN t3 ON (t2.int1 = t3.int1)'
                 +#13#10+') ORDER BY 2 DESC';
   q.Open;
   if (q.RecordCount <> 2) then
    WriteToErrorLog(capt+'Error #1');
   if (q.Fields[0].AsInteger <> 2) then
    WriteToErrorLog(capt+'Error #2');
   if (q.Fields[1].AsString <> 'bbb') then
    WriteToErrorLog(capt+'Error #3');
   q.Next;
   if (q.Fields[0].AsInteger <> 1) then
    WriteToErrorLog(capt+'Error #4');
   if (q.Fields[1].AsString <> 'aaa') then
    WriteToErrorLog(capt+'Error #5');
   q.Next;
   if (not q.Eof) then
    WriteToErrorLog(capt+'Error #6');
   WriteToProcessLog(capt+'EXCEPT ok');
   q.SQL.Text :=         'SELECT * FROM t1 INTERSECT ('
                 +#13#10+'SELECT t2.int1, t3.str1 FROM t2 INNER JOIN t3 ON (t2.int1 = t3.int1)'
                 +#13#10+')';
   q.Open;
   if (q.RecordCount <> 1) then
    WriteToErrorLog(capt+'Error #7');
   if (q.Fields[0].AsInteger <> 3) then
    WriteToErrorLog(capt+'Error #8');
   if (q.Fields[1].AsString <> 'ccc') then
    WriteToErrorLog(capt+'Error #9');
   q.Next;
   if (not q.Eof) then
    WriteToErrorLog(capt+'Error #10');
   WriteToProcessLog(capt+'INTERSECT ok');
   q.SQL.Text :=         'SELECT * FROM t1 UNION ('
                 +#13#10+'SELECT t2.int1, t3.str1 FROM t2 INNER JOIN t3 ON (t2.int1 = t3.int1)'
                 +#13#10+') ORDER BY 2';
   q.Open;
   if (q.RecordCount <> 3) then
    WriteToErrorLog(capt+'Error #11');
   if (q.Fields[0].AsInteger <> 1) then
    WriteToErrorLog(capt+'Error #12');
   if (q.Fields[1].AsString <> 'aaa') then
    WriteToErrorLog(capt+'Error #13');
   q.Next;
   if (q.Fields[0].AsInteger <> 2) then
    WriteToErrorLog(capt+'Error #14');
   if (q.Fields[1].AsString <> 'bbb') then
    WriteToErrorLog(capt+'Error #15');
   q.Next;
   if (q.Fields[0].AsInteger <> 3) then
    WriteToErrorLog(capt+'Error #16');
   if (q.Fields[1].AsString <> 'ccc') then
    WriteToErrorLog(capt+'Error #17');
   q.Next;
   if (not q.Eof) then
    WriteToErrorLog(capt+'Error #18');
   WriteToProcessLog(capt+'UNION DISTINCT ok');
   q.SQL.Text :=         'SELECT * FROM t1 UNION ALL ('
                 +#13#10+'SELECT t2.int1, t3.str1 FROM t2 INNER JOIN t3 ON (t2.int1 = t3.int1)'
                 +#13#10+') ORDER BY 2';
   q.Open;
   if (q.RecordCount <> 4) then
    WriteToErrorLog(capt+'Error #19');
   if (q.Fields[0].AsInteger <> 1) then
    WriteToErrorLog(capt+'Error #20');
   if (q.Fields[1].AsString <> 'aaa') then
    WriteToErrorLog(capt+'Error #21');
   q.Next;
   if (q.Fields[0].AsInteger <> 2) then
    WriteToErrorLog(capt+'Error #22');
   if (q.Fields[1].AsString <> 'bbb') then
    WriteToErrorLog(capt+'Error #23');
   q.Next;
   if (q.Fields[0].AsInteger <> 3) then
    WriteToErrorLog(capt+'Error #24');
   if (q.Fields[1].AsString <> 'ccc') then
    WriteToErrorLog(capt+'Error #25');
   q.Next;
   if (q.Fields[0].AsInteger <> 3) then
    WriteToErrorLog(capt+'Error #26');
   if (q.Fields[1].AsString <> 'ccc') then
    WriteToErrorLog(capt+'Error #27');
   q.Next;
   if (not q.Eof) then
    WriteToErrorLog(capt+'Error #28');

   q.SQL.Text :=          'SELECT * FROM t1'
                  +#13#10+'UNION'
                  +#13#10+'(SELECT * FROM t1'
                  +#13#10+'EXCEPT ('
                  +#13#10+'SELECT * FROM t1'
                  +#13#10+')) ORDER BY int1';
   q.Open;
   if (q.RecordCount <> 3) then
    WriteToErrorLog(capt+'Error #29');
   if (q.Fields[0].AsInteger <> 1) then
    WriteToErrorLog(capt+'Error #30');
   if (q.Fields[1].AsString <> 'aaa') then
    WriteToErrorLog(capt+'Error #31');
   q.Next;
   if (q.Fields[0].AsInteger <> 2) then
    WriteToErrorLog(capt+'Error #32');
   if (q.Fields[1].AsString <> 'bbb') then
    WriteToErrorLog(capt+'Error #33');
   q.Next;
   if (q.Fields[0].AsInteger <> 3) then
    WriteToErrorLog(capt+'Error #34');
   if (q.Fields[1].AsString <> 'ccc') then
    WriteToErrorLog(capt+'Error #35');
   q.Next;
   if (not q.Eof) then
    WriteToErrorLog(capt+'Error #36');

   q.SQL.Text :=          'SELECT * FROM t1 JOIN t2 ON t1.int1 = t2.int1'
                  +#13#10+'UNION'
                  +#13#10+'(SELECT * FROM t1'
                  +#13#10+'EXCEPT ('
                  +#13#10+'SELECT * FROM t1'
                  +#13#10+')) ORDER BY int1';
   q.Open;
   if (q.FieldCount <> 2) then
    WriteToErrorLog(capt+'Error #37');
   if (q.RecordCount <> 1) then
    WriteToErrorLog(capt+'Error #38');
   if (q.Fields[0].AsInteger <> 3) then
    WriteToErrorLog(capt+'Error #39');
   if (q.Fields[1].AsString <> 'ccc') then
    WriteToErrorLog(capt+'Error #40');
   q.Next;
   if (not q.Eof) then
    WriteToErrorLog(capt+'Error #41');

   q.SQL.Text :=          'SELECT * FROM t1'
                  +#13#10+'UNION'
                  +#13#10+'(SELECT * FROM t1 JOIN t2 ON t1.int1 = t2.int1'
                  +#13#10+'EXCEPT ('
                  +#13#10+'SELECT * FROM t1'
                  +#13#10+')) ORDER BY int1';
   q.Open;

   if (q.RecordCount <> 3) then
    WriteToErrorLog(capt+'Error #42');
   if (q.Fields[0].AsInteger <> 1) then
    WriteToErrorLog(capt+'Error #43');
   if (q.Fields[1].AsString <> 'aaa') then
    WriteToErrorLog(capt+'Error #44');
   q.Next;
   if (q.Fields[0].AsInteger <> 2) then
    WriteToErrorLog(capt+'Error #45');
   if (q.Fields[1].AsString <> 'bbb') then
    WriteToErrorLog(capt+'Error #46');
   q.Next;
   if (q.Fields[0].AsInteger <> 3) then
    WriteToErrorLog(capt+'Error #47');
   if (q.Fields[1].AsString <> 'ccc') then
    WriteToErrorLog(capt+'Error #48');
   q.Next;
   if (not q.Eof) then
    WriteToErrorLog(capt+'Error #49');

   q.SQL.Text :=          'SELECT * FROM t1'
                  +#13#10+'UNION'
                  +#13#10+'SELECT * FROM t1'
                  +#13#10+'EXCEPT ('
                  +#13#10+'SELECT * FROM t1'
                  +#13#10+') ORDER BY int1';
   q.Open;
   if (not q.Eof) then
    WriteToErrorLog(capt+'Error #50');
   if (q.RecordCount <> 0) then
    WriteToErrorLog(capt+'Error #51');

   q.SQL.Text :=          'SELECT * FROM t1 JOIN t2 ON t1.int1 = t2.int1'
                  +#13#10+'UNION'
                  +#13#10+'SELECT * FROM t1'
                  +#13#10+'EXCEPT ('
                  +#13#10+'SELECT * FROM t1'
                  +#13#10+') ORDER BY int1';
   q.Open;
   if (not q.Eof) then
    WriteToErrorLog(capt+'Error #52');
   if (q.RecordCount <> 0) then
    WriteToErrorLog(capt+'Error #53');

   q.SQL.Text :=          'SELECT * FROM t1'
                  +#13#10+'UNION'
                  +#13#10+'SELECT * FROM t1 JOIN t2 ON t1.int1 = t2.int1'
                  +#13#10+'EXCEPT ('
                  +#13#10+'SELECT * FROM t1'
                  +#13#10+') ORDER BY int1';
   q.Open;
   if (not q.Eof) then
    WriteToErrorLog(capt+'Error #54');
   if (q.RecordCount <> 0) then
    WriteToErrorLog(capt+'Error #55');

   WriteToProcessLog(capt+'UNION ALL ok');
 finally
   q.SQL.Text := 'DROP TABLE t1; DROP TABLE t2; DROP TABLE t3;';
   q.ExecSQL;
   q.Free;
 end;
end;


procedure TUnitTestACRQuery.TestCreateDefaultsTable_Brian_Pettit_bug;
var q:    TACRQuery;
    db:   TACRDatabase;
    capt: AnsiString;
    i:    Integer;
begin
 capt := 'TestExceptWithSubQuery - ';
 db := TACRDatabase.Create(nil);
 q := TACRquery.Create(nil);
 try
   db.DatabaseFileName := TempDir+'test_brian_pettit.adb';
   db.CreateDatabase;
   db.Open;
   q.DatabaseName := db.DatabaseName;
   WriteToProcessLog(capt+'creating tables...');
   q.SQL.LoadFromFile(SQLDir+'create_Defaults_table_Brian_Pettit_bug.sql');
   q.ExecSQL;

   q.SQL.Text := 'SELECT * FROM Defaults';
   q.Open;
   if (q.RecordCount <> 1) then
    WriteToErrorLog(capt+'Error opening Defaults table, recCount = '+IntToStr(q.RecordCount));

 finally
   db.Close;
   db.DeleteDatabase;
   if (db.Exists) then
    WriteToErrorLog(capt + 'DB exists');
   q.Free;
   db.Free;
 end;
end; // TestCreateDefaultsTable_Brian_Pettit_bug



procedure TUnitTestACRQuery.TestLeftJoinOnConditionBug;
var q:      TACRQuery;
    capt:   String;
begin
  capt := 'TestLeftJoinOnConditionBug - ';
  q := TACRQuery.Create(nil);
  try
    q.InMemory := True;
    q.SQL.Text :=         'create table t1 (id integer, desc varchar2(20));'
                  +#13#10+'insert into t1 (id, desc) values (1, "a");'
                  +#13#10+'insert into t1 (id, desc) values (2, "b");'
                  +#13#10+'insert into t1 (id, desc) values (3, "c");'
                  +#13#10+'insert into t1 (id, desc) values (4, "d");'
                  +#13#10+'create table t2 (id integer, t1_id integer, flag boolean);'
                  +#13#10+'insert into t2 (id, t1_id, flag) values (1, 1, false);'
                  +#13#10+'insert into t2 (id, t1_id, flag) values (2, 1, true);'
                  +#13#10+'insert into t2 (id, t1_id, flag) values (3, 2, true);'
                  +#13#10+'insert into t2 (id, t1_id, flag) values (4, 3, false);'
                  +#13#10+'insert into t2 (id, t1_id, flag) values (5, 3, false);'
                  +#13#10+'insert into t2 (id, t1_id, flag) values (6, 3, true);';
    q.ExecSQL;
    q.SQL.Text := 'SELECT o.*,t.id FROM t1 o'
                  +#13#10+'LEFT OUTER JOIN t2 t ON (o.id = t.t1_id and t.flag = true)'
                  +#13#10+'ORDER BY o.id';
    q.Open;
    if (q.RecordCount <> 4) then
     WriteToErrorLog(capt+'Invalid RecordCount = '+IntToStr(q.RecordCount))
    else
     begin
      if (q.Fields[0].AsInteger <> 1) then
        WriteToErrorLog('error #1');
      if (q.Fields[1].AsString <> 'a') then
        WriteToErrorLog('error #2');
      if (q.Fields[2].AsInteger <> 2) then
        WriteToErrorLog('error #3');
      q.Next;
      if (q.Fields[0].AsInteger <> 2) then
        WriteToErrorLog('error #4');
      if (q.Fields[1].AsString <> 'b') then
        WriteToErrorLog('error #5');
      if (q.Fields[2].AsInteger <> 3) then
        WriteToErrorLog('error #6');
      q.Next;
      if (q.Fields[0].AsInteger <> 3) then
        WriteToErrorLog('error #7');
      if (q.Fields[1].AsString <> 'c') then
        WriteToErrorLog('error #8');
      if (q.Fields[2].AsInteger <> 6) then
        WriteToErrorLog('error #9');
      q.Next;
      if (q.Fields[0].AsInteger <> 4) then
        WriteToErrorLog('error #10');
      if (q.Fields[1].AsString <> 'd') then
        WriteToErrorLog('error #11');
      if (not q.Fields[2].IsNull) then
        WriteToErrorLog('error #12');
      q.Next;
      if (not q.Eof) then
        WriteToErrorLog('error #13');
     end;
  finally
    q.SQL.Text := 'DROP TABLE t1; DROP TABLE t2;';
    q.ExecSQL;
    q.Free;
  end;
end;


procedure TUnitTestACRQuery.TestIsNullAndNullIfFunctions;
var q:      TACRQuery;
    capt:   String;
begin
  capt := 'Test ISNULL and NULLIF functions - ';
  q := TACRQuery.Create(nil);
  try
    q.InMemory := True;
    q.SQL.Text :=         'create table t1 (id integer, desc char(20));'
                  +#13#10+'insert into t1 (id, desc) values (1, "a");'
                  +#13#10+'insert into t1 (id, desc) values (2, NULL);'
                  +#13#10+'insert into t1 (id, desc) values (3, "3");' // NULLIF
                  +#13#10+'insert into t1 (id, desc) values (NULL, NULL);' // NULLIF
                  ;
    q.ExecSQL;
    WriteToProcessLog(capt+'Table created');
    // last error: 17

    q.SQL.Text := 'SELECT id, NULLIF(id,[desc]) FROM t1 order by id';
    q.Open;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    if (q.RecordCount <> 4) then
     WriteToErrorLog(capt+'error #10 Invalid RecordCount = '+IntToStr(q.RecordCount))
    else
     begin
      if (not q.Fields[1].IsNull) then
        WriteToErrorLog('error #16');
      if (not q.Fields[1].IsNull) then
        WriteToErrorLog('error #17');
      q.Next;
      if (q.Fields[0].AsInteger <> 1) then
        WriteToErrorLog('error #11');
      if (q.Fields[1].AsInteger <> 1) then
        WriteToErrorLog('error #12');
      q.Next;
      if (q.Fields[0].AsInteger <> 2) then
        WriteToErrorLog('error #13');
      if (q.Fields[1].AsInteger <> 2) then
        WriteToErrorLog('error #14');
      q.Next;
      if (q.Fields[0].AsInteger <> 3) then
        WriteToErrorLog('error #14');
      if (not q.Fields[1].IsNull) then
        WriteToErrorLog('error #15');
      q.Next;
      if (not q.Eof) then
        WriteToErrorLog('error #16');
     end;

    q.SQL.Text := 'DELETE FROM t1 WHERE (CAST(IFNULL(id,100),INTEGER) >= 3)';
    q.ExecSQL;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    if (q.RowsAffected <> 2) then
      WriteToErrorLog(capt+'error #17 Invalid RowsAffected = '+IntToStr(q.RowsAffected));

    q.SQL.Text := 'SELECT id, ISNULL([desc],"UNKNOWN") FROM t1 order by id';
    q.Open;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    if (q.RecordCount <> 2) then
     WriteToErrorLog(capt+'error #1 Invalid RecordCount = '+IntToStr(q.RecordCount))
    else
     begin
      if (q.Fields[0].AsInteger <> 1) then
        WriteToErrorLog('error #3');
      if (q.Fields[1].AsString <> 'a') then
        WriteToErrorLog('error #4');
      q.Next;
      if (q.Fields[0].AsInteger <> 2) then
        WriteToErrorLog('error #5');
      if (q.Fields[1].AsString <> 'UNKNOWN') then
        WriteToErrorLog('error #6');
      q.Next;
      if (not q.Eof) then
        WriteToErrorLog('error #7');
     end;

    q.SQL.Text := 'SELECT id FROM t1 WHERE ISNULL([desc],"NULL")="NULL"';
    q.Open;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    if (q.RecordCount <> 1) then
     WriteToErrorLog(capt+'error #2 Invalid RecordCount = '+IntToStr(q.RecordCount))
    else
     begin
      if (q.Fields[0].AsInteger <> 2) then
        WriteToErrorLog('error #8');
      q.Next;
      if (not q.Eof) then
        WriteToErrorLog('error #9');
     end;
  finally
    q.SQL.Text := 'DROP TABLE t1';
    q.ExecSQL;
    q.Free;
  end;
end; // TestIsNullAndNullIfFunctions


procedure TUnitTestACRQuery.TestCorrelatedSubQueries;
var q:      TACRQuery;
    capt:   String;
begin
  capt := 'Test correlated Queries - ';
  q := TACRQuery.Create(nil);
  try
    WriteToProcessLog(capt+'Starting...');
    q.InMemory := True;

    q.SQL.Text :=  'CREATE TABLE tbPayment(ID AutoInc, Payment MONEY, OrderID INTEGER, PRIMARY KEY(ID)); '
                  +'CREATE INDEX idx1 ON tbPayment(OrderID); '
                  +'CREATE TABLE Orders(ID AutoInc, [Date] TimeStamp, OrderAmt Money, PRIMARY KEY(ID)); '
                  +'INSERT INTO Orders VALUES (NULL,NOW-1,-1); '     // 1
                  +'INSERT INTO Orders VALUES (NULL,NOW,-2); '       // 2
                  +'INSERT INTO Orders VALUES (NULL,NOW+1,-3); '     // 3
                  +'INSERT INTO tbPayment VALUES (NULL,10.00,1); '     // 1  1
                  +'INSERT INTO tbPayment VALUES (NULL,100,1); '       // 2  1
                  +'INSERT INTO tbPayment VALUES (NULL,2000,2); '      // 3  2
                  +'INSERT INTO tbPayment VALUES (NULL,3000.00,10); '  // 4  10
                  +'INSERT INTO tbPayment VALUES (NULL,4000,NULL); '   // 5  NULL
                 ;

    q.ExecSQL;

    WriteToProcessLog(capt+'Table 0 created...');
    q.SQL.Text :=         'CREATE TABLE [Payment] ( [payid]  AUTOINC (AUTOINC INITIALVALUE 0 INCREMENT 1 NOMINVALUE'
+#13#10+'MAXVALUE 2147483647 NOCYCLED),'
+#13#10+'[payment] FLOAT,'
+#13#10+'[PayDate] DATETIME'
+#13#10+');'
+#13#10+'INSERT INTO [Payment] VALUES ('
+#13#10+'     1,'
+#13#10+'     100,'
+#13#10+'     TODATE(''8/10/2010 0:0:0:0'',''M/D/YYYY HH24:N:S:Z'')'
+#13#10+');'
+#13#10+'INSERT INTO [Payment] VALUES ('
+#13#10+'     2,'
+#13#10+'     130,'
+#13#10+'     TODATE(''8/17/2010 0:0:0:0'',''M/D/YYYY HH24:N:S:Z'')'
+#13#10+');'
+#13#10+'INSERT INTO [Payment] VALUES ('
+#13#10+'     3,'
+#13#10+'     140,'
+#13#10+'     TODATE(''8/26/2010 0:0:0:0'',''M/D/YYYY HH24:N:S:Z'')'
+#13#10+');';
    q.ExecSQL;
    WriteToProcessLog(capt+'Table 1 created...');


    q.SQL.Text :=         'CREATE TABLE tbPayments ('
                  +#13#10+'PayId AUTOINC NOT NULL,'
                  +#13#10+'OrderID INTEGER DEFAULT 0 NOT NULL,'
                  +#13#10+'DebitAmount FLOAT DEFAULT 0,'
                  +#13#10+'CreditAmount FLOAT DEFAULT 0,'
                  +#13#10+'Balance FLOAT DEFAULT 0,'
                  +#13#10+'PRIMARY KEY PK_PayID (PayId)'
                  +#13#10+');'

                  +#13#10+'INSERT INTO tbPayments (PayId, OrderID, DebitAmount, CreditAmount, Balance) values (33, 2, 0, 0, 4037.885);'
                  +#13#10+'INSERT INTO tbPayments (PayId, OrderID, DebitAmount, CreditAmount, Balance) values (34, 5, 0, 0, 2500);'
                  +#13#10+'INSERT INTO tbPayments (PayId, OrderID, DebitAmount, CreditAmount, Balance) values (35, 5, 0, 1000, 0);'
                  +#13#10+'INSERT INTO tbPayments (PayId, OrderID, DebitAmount, CreditAmount, Balance) values (36, 5, 0, 750, 0);'
                  +#13#10+'INSERT INTO tbPayments (PayId, OrderID, DebitAmount, CreditAmount, Balance) values (37, 5, 0, 750, 0);'
                  +#13#10+'INSERT INTO tbPayments (PayId, OrderID, DebitAmount, CreditAmount, Balance) values (39, 2, 0, 150, 0);'
                  +#13#10+'INSERT INTO tbPayments (PayId, OrderID, DebitAmount, CreditAmount, Balance) values (43, 2, 0, 150, 0);'
                  +#13#10+'INSERT INTO tbPayments (PayId, OrderID, DebitAmount, CreditAmount, Balance) values (45, 2, 0, 0, 0);'
                  +#13#10+'INSERT INTO tbPayments (PayId, OrderID, DebitAmount, CreditAmount, Balance) values (46, 2, 0, 150, 0);'
                  +#13#10+'INSERT INTO tbPayments (PayId, OrderID, DebitAmount, CreditAmount, Balance) values (47, 2, 0, 150, 0);'
                  +#13#10+'INSERT INTO tbPayments (PayId, OrderID, DebitAmount, CreditAmount, Balance) values (49, 2, 0, 150, 0);'
                  +#13#10+'INSERT INTO tbPayments (PayId, OrderID, DebitAmount, CreditAmount, Balance) values (50, 2, 0, 150, 0);'
                  +#13#10+'INSERT INTO tbPayments (PayId, OrderID, DebitAmount, CreditAmount, Balance) values (52, 2, 0, 0, 0);'
                  +#13#10+'INSERT INTO tbPayments (PayId, OrderID, DebitAmount, CreditAmount, Balance) values (56, 4, 0, 0, 0);'
                  +#13#10+'INSERT INTO tbPayments (PayId, OrderID, DebitAmount, CreditAmount, Balance) values (57, 12, 0, 0, 0);'
                  +#13#10+'INSERT INTO tbPayments (PayId, OrderID, DebitAmount, CreditAmount, Balance) values (58, 13, 0, 0, 0);'
                  +#13#10+'INSERT INTO tbPayments (PayId, OrderID, DebitAmount, CreditAmount, Balance) values (59, 2, 0, 150, 0);'
                  +#13#10+'INSERT INTO tbPayments (PayId, OrderID, DebitAmount, CreditAmount, Balance) values (60, 2, 0, 150, 0);'

                  ;
    q.ExecSQL;
    WriteToProcessLog(capt+'Table 2 created...');

    q.SQL.Text :=  'CREATE TABLE Test (id AUTOINC NOT NULL, RefID Integer, PRIMARY KEY (id));';
    q.ExecSQL;
    WriteToProcessLog(capt+'Table 3 created...');

    q.SQL.LoadFromFile(SQLDir+'webit_update_join.sql');
    q.ExecSQL;
    WriteToProcessLog(capt+'Tables A and B created...');

    // last error code: 67

    // MAIN TEST

    // test IN with empty table
    q.SQL.Text :=  'SELECT * FROM Test WHERE id IN (SELECT payid FROM Payment)';
    q.Open;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    if (q.RecordCount <> 0) then
     WriteToErrorLog(capt+'error #67 Invalid RecordCount = '+IntToStr(q.RecordCount));


    // GROUP BY
    q.SQL.Text :=  'SELECT a.*,(SELECT sum(amount) FROM b WHERE a.recid = b.recid group by recid) as sm FROM a ORDER by sm desc';
    q.Open;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    if (q.RecordCount <> 41) then
     WriteToErrorLog(capt+'error #56 Invalid RecordCount = '+IntToStr(q.RecordCount))
    else
    begin
     if (q.FieldByName('sm').AsFloat <> 260) then
       WriteToErrorLog(capt+'error #57 Invalid sum = '+q.FieldByName('sm').AsString);
     q.Next;
     if (q.FieldByName('sm').AsFloat <> 150) then
       WriteToErrorLog(capt+'error #58 Invalid sum = '+q.FieldByName('sm').AsString);
     q.Next;
     if (q.FieldByName('sm').AsFloat <> 120) then
       WriteToErrorLog(capt+'error #59 Invalid sum = '+q.FieldByName('sm').AsString);
     q.Next;
     if (q.FieldByName('sm').AsString <> '') then
       WriteToErrorLog(capt+'error #60 Invalid sum = '+q.FieldByName('sm').AsString);
    end;

    q.SQL.Text := 'update a  set Balance= (select sum(amount) from b where a.recid = b.recid group by recid);';
    q.ExecSQL;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    if (q.RowsAffected <> 41) then
     WriteToErrorLog(capt+'error #61 Invalid RecordCount = '+IntToStr(q.RecordCount));

    q.SQL.Text := 'select recid, Price, Balance from a where Balance >0 order by Balance desc';
    q.Open;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    if (q.RecordCount <> 3) then
     WriteToErrorLog(capt+'error #62 Invalid RecordCount = '+IntToStr(q.RecordCount))
    else
    begin
     if (q.FieldByName('Balance').AsFloat <> 260) then
       WriteToErrorLog(capt+'error #63 Invalid sum = '+q.FieldByName('sm').AsString);
     q.Next;
     if (q.FieldByName('Balance').AsFloat <> 150) then
       WriteToErrorLog(capt+'error #64 Invalid sum = '+q.FieldByName('sm').AsString);
     q.Next;
     if (q.FieldByName('Balance').AsFloat <> 120) then
       WriteToErrorLog(capt+'error #65 Invalid sum = '+q.FieldByName('sm').AsString);
     q.Next;
     if (not q.Eof) then
       WriteToErrorLog(capt+'error #66 NOT Eof');
    end;

    // test IN with empty table
    q.SQL.Text :=  'SELECT * FROM Test WHERE id IN (SELECT ID FROM Test)';
    q.Open;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    if (q.RecordCount <> 0) then
     WriteToErrorLog(capt+'error #50 Invalid RecordCount = '+IntToStr(q.RecordCount));

    q.SQL.Text :=  'SELECT * FROM Test WHERE EXISTS (SELECT ID FROM Test)';
    q.Open;
    if (q.RecordCount <> 0) then
     WriteToErrorLog(capt+'error #55 Invalid RecordCount = '+IntToStr(q.RecordCount));

    // test IN with correlated query - self referencing table
    q.SQL.Text :=   'INSERT INTO Test (RefID) VALUES (NULL);'
                   +'INSERT INTO Test (RefID) VALUES (1);'
                   +'INSERT INTO Test (RefID) VALUES (15);'
                   +'INSERT INTO Test (RefID) VALUES (2);'
                   ;
    q.ExecSQL;
    q.SQL.Text :=  'SELECT id FROM Test WHERE RefID IN (SELECT ID FROM Test) ORDER BY id';
    q.Open;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    if (q.RecordCount <> 2) then
     WriteToErrorLog(capt+'error #51 Invalid RecordCount = '+IntToStr(q.RecordCount))
    else
    begin
      if (q.Fields[0].AsInteger <> 2) then
        WriteToErrorLog(capt+'error #52');
      q.Next;
      if (q.Fields[0].AsInteger <> 4) then
        WriteToErrorLog(capt+'error #53');
      q.Next;
      if (not q.Eof) then
        WriteToErrorLog(capt+'error #54');
    end;


    // correlated subquery with aggregated expression in SELECT LIST (SUM+SUM-SUM)
    q.SQL.Text :=  'SELECT PayID, Balance, CreditAmount, debitamount,'
                  +'(SELECT (sum(balance) + sum(debitamount)) - sum( Creditamount)'
                  +' FROM tbpayments'
                  +' WHERE payID <= O.payid and OrderID=5) AS "Running Total"'
                  +' FROM tbpayments O'
                  +' WHERE OrderID=5'
                  +' ORDER BY PayID';
    q.Open;
    if (q.RecordCount <> 4) then
     WriteToErrorLog(capt+'error #44 Invalid RecordCount = '+IntToStr(q.RecordCount))
    else
     begin
      if (q.Fields[0].AsInteger <> 34) or
         (q.Fields[1].AsFloat <> 2500) or
         (q.Fields[2].AsFloat <> 0) or
         (q.Fields[3].AsFloat <> 0) or
         (q.Fields[4].AsFloat <> 2500) then
        WriteToErrorLog(capt+'error #45: '+#13#10+
                        q.Fields[0].AsString+#9+q.Fields[1].AsString+#9+q.Fields[2].AsString+#9+q.Fields[3].AsString+#9+q.Fields[4].AsString);
      q.Next;
      if (q.Fields[0].AsInteger <> 35) or
         (q.Fields[1].AsFloat <> 0) or
         (q.Fields[2].AsFloat <> 1000) or
         (q.Fields[3].AsFloat <> 0) or
         (q.Fields[4].AsFloat <> 1500) then
        WriteToErrorLog(capt+'error #46: '+#13#10+
                        q.Fields[0].AsString+#9+q.Fields[1].AsString+#9+q.Fields[2].AsString+#9+q.Fields[3].AsString+#9+q.Fields[4].AsString);
      q.Next;
      if (q.Fields[0].AsInteger <> 36) or
         (q.Fields[1].AsFloat <> 0) or
         (q.Fields[2].AsFloat <> 750) or
         (q.Fields[3].AsFloat <> 0) or
         (q.Fields[4].AsFloat <> 750) then
        WriteToErrorLog(capt+'error #47: '+#13#10+
                        q.Fields[0].AsString+#9+q.Fields[1].AsString+#9+q.Fields[2].AsString+#9+q.Fields[3].AsString+#9+q.Fields[4].AsString);
      q.Next;
      if (q.Fields[0].AsInteger <> 37) or
         (q.Fields[1].AsFloat <> 0) or
         (q.Fields[2].AsFloat <> 750) or
         (q.Fields[3].AsFloat <> 0) or
         (q.Fields[4].AsFloat <> 0) then
        WriteToErrorLog(capt+'error #48: '+#13#10+
                        q.Fields[0].AsString+#9+q.Fields[1].AsString+#9+q.Fields[2].AsString+#9+q.Fields[3].AsString+#9+q.Fields[4].AsString);
      q.Next;
      if (not q.Eof) then
        WriteToErrorLog(capt+'error #49');
     end;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);

    // correlated query in <WHERE_expression>
    q.SQL.Text :=  'SELECT DISTINCT OrderID '
                  +'FROM tbPayment PAY '
                  +'WHERE EXISTS (SELECT ID FROM Orders as ORD WHERE ORD.ID = PAY.OrderID) '
                  +'ORDER BY 1';
    q.Open;
    if (q.RecordCount <> 2) then
     WriteToErrorLog(capt+'error #24 Invalid RecordCount = '+IntToStr(q.RecordCount))
    else
     begin
      if (q.Fields[0].AsInteger <> 1) then
        WriteToErrorLog(capt+'error #25');
      q.Next;
      if (q.Fields[0].AsInteger <> 2) then
        WriteToErrorLog(capt+'error #26');
      q.Next;
      if (not q.Eof) then
        WriteToErrorLog(capt+'error #27');
     end;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);

    // correlated query in <WHERE_expression>
    q.SQL.Text :=  'SELECT OrderID, SUM(Payment) as PayTotal '
                  +'FROM tbPayment PAY '
                  +'GROUP BY OrderID '
                  +'HAVING OrderID IN (SELECT ID FROM Orders as ORD WHERE ORD.ID = PAY.OrderID) '
                  +'ORDER BY 1';
    q.Open;
    if (q.RecordCount <> 2) then
     WriteToErrorLog(capt+'error #19 Invalid RecordCount = '+IntToStr(q.RecordCount))
    else
     begin
      if (q.Fields[0].AsInteger <> 1) then
        WriteToErrorLog(capt+'error #20');
      if (q.Fields[1].AsFloat <> 110.00) then
        WriteToErrorLog(capt+'error #21');
      q.Next;
      if (q.Fields[0].AsInteger <> 2) then
        WriteToErrorLog(capt+'error #22');
      if (q.Fields[1].AsFloat <> 2000.00) then
        WriteToErrorLog(capt+'error #23');
      q.Next;
      if (not q.Eof) then
        WriteToErrorLog(capt+'error #24');
     end;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    WriteToProcessLog(capt+'Correlated SELECT - OK');


    // correlated query in <Select_List> - Payment table
    q.SQL.Text :=  'select payid, payment'
                  +', (select sum(payment) FROM payment where payid <= pay_top.payid) as TotalPaid'
                  +' from payment as pay_top ORDER BY 1';
    q.Open;
    if (q.RecordCount <> 3) then
     WriteToErrorLog(capt+'error #8 Invalid RecordCount = '+IntToStr(q.RecordCount))
    else
     begin
      if (q.Fields[0].AsInteger <> 1) then
        WriteToErrorLog(capt+'error #9');
      if (q.Fields[1].AsInteger <> 100) then
        WriteToErrorLog(capt+'error #10');
      if (q.Fields[2].AsInteger <> 100) then
        WriteToErrorLog(capt+'error #11');
      q.Next;
      if (q.Fields[0].AsInteger <> 2) then
        WriteToErrorLog(capt+'error #12');
      if (q.Fields[1].AsInteger <> 130) then
        WriteToErrorLog(capt+'error #13');
      if (q.Fields[2].AsInteger <> 230) then
        WriteToErrorLog(capt+'error #14');
      q.Next;
      if (q.Fields[0].AsInteger <> 3) then
        WriteToErrorLog(capt+'error #15');
      if (q.Fields[1].AsInteger <> 140) then
        WriteToErrorLog(capt+'error #16');
      if (q.Fields[2].AsInteger <> 370) then
        WriteToErrorLog(capt+'error #17');
      q.Next;
      if (not q.Eof) then
        WriteToErrorLog(capt+'error #18');
     end;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);

    // uncorrelated query
    q.SQL.Text :=  'select payid, payment'
                  +', (select sum(payment) FROM payment where payid <= payment.payid) as TotalPaid'
                  +' from payment ORDER BY 1';
    q.Open;
    if (q.RecordCount <> 3) then
     WriteToErrorLog(capt+'error #1 Invalid RecordCount = '+IntToStr(q.RecordCount))
    else
     begin
      if (q.Fields[0].AsInteger <> 1) then
        WriteToErrorLog(capt+'error #2');
      if (q.Fields[1].AsInteger <> 100) then
        WriteToErrorLog(capt+'error #3');
      if (q.Fields[2].AsInteger <> 370) then
        WriteToErrorLog(capt+'error #4');
      q.Next;
      if (q.Fields[0].AsInteger <> 2) then
        WriteToErrorLog(capt+'error #5');
      if (q.Fields[1].AsInteger <> 130) then
        WriteToErrorLog(capt+'error #6');
      if (q.Fields[2].AsInteger <> 370) then
        WriteToErrorLog(capt+'error #7');
      q.Next;
      if (q.Fields[0].AsInteger <> 3) then
        WriteToErrorLog(capt+'error #8');
      if (q.Fields[1].AsInteger <> 140) then
        WriteToErrorLog(capt+'error #9');
      if (q.Fields[2].AsInteger <> 370) then
        WriteToErrorLog(capt+'error #10');
      q.Next;
      if (not q.Eof) then
        WriteToErrorLog(capt+'error #7');
     end;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);

    // correlated query in UPDATE WHERE expression
    q.SQL.Text :=  'UPDATE Orders ORD SET OrderAmt = 0 WHERE NOT EXISTS (SELECT ID FROM tbPayment PAY WHERE OrderID = ORD.ID)';
    q.ExecSQL;
    if (q.RowsAffected <> 1) then
     WriteToErrorLog(capt+'error #34 Invalid RowsAffected = '+IntToStr(q.RowsAffected));
    q.SQL.Text := 'SELECT * FROM Orders ORDER BY ID';
    q.Open;
    if (q.RecordCount <> 3) then
     WriteToErrorLog(capt+'error #35 Invalid RecordCount = '+IntToStr(q.RecordCount))
    else
     begin
      if (q.Fields[2].AsFloat <> -1) then
        WriteToErrorLog(capt+'error #36');
      q.Next;
      if (q.Fields[2].AsFloat <> -2) then
        WriteToErrorLog(capt+'error #37');
      q.Next;
      if (q.Fields[2].AsFloat <> 0) then
        WriteToErrorLog(capt+'error #38');
      q.Next;
      if (not q.Eof) then
        WriteToErrorLog(capt+'error #39');
     end;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);

    // correlated query in UPDATE SET expression
    q.SQL.Text :=  'UPDATE Orders ORD SET OrderAmt = (SELECT SUM(Payment) FROM tbPayment WHERE OrderID = ORD.ID)';
    q.ExecSQL;
    if (q.RowsAffected <> 3) then
     WriteToErrorLog(capt+'error #28 Invalid RowsAffected = '+IntToStr(q.RowsAffected));
    q.SQL.Text := 'SELECT * FROM orders ORDER BY ID';
    q.Open;
    if (q.RecordCount <> 3) then
     WriteToErrorLog(capt+'error #29 Invalid RecordCount = '+IntToStr(q.RecordCount))
    else
     begin
      if (q.Fields[2].AsFloat <> 110.0) then
        WriteToErrorLog(capt+'error #30');
      q.Next;
      if (q.Fields[2].AsFloat <> 2000) then
        WriteToErrorLog(capt+'error #31');
      q.Next;
      if (q.Fields[2].AsFloat <> 0) then
        WriteToErrorLog(capt+'error #32');
      q.Next;
      if (not q.Eof) then
        WriteToErrorLog(capt+'error #33');
     end;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);

    q.SQL.Text := 'DELETE FROM Orders as ORD WHERE id = (SELECT OrderID FROM tbPayment WHERE OrderID = ORD.id)';
    q.ExecSQL;
    if (q.RowsAffected <> 2) then
     WriteToErrorLog(capt+'error #40 Invalid RowsAffected = '+IntToStr(q.RowsAffected))
    else
    begin
      q.SQL.Text := 'SELECT id FROM Orders ORDER BY 1';
      q.Open;
      if (q.RecordCount <> 1) then
       WriteToErrorLog(capt+'error #41 Invalid RecordCount = '+IntToStr(q.RecordCount))
      else
       begin
        if (q.Fields[0].AsInteger <> 3) then
          WriteToErrorLog(capt+'error #42');
        q.Next;
        if (not q.Eof) then
          WriteToErrorLog(capt+'error #43');
       end;
    end;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);

    WriteToProcessLog(capt+'Finishing ... ');
  finally
    q.SQL.Text := 'DROP TABLE payment CASCADE; DROP TABLE Orders CASCADE; DROP TABLE tbPayment CASCADE; DROP TABLE tbPayments CASCADE; DROP TABLE Test CASCADE;DROP TABLE [A] CASCADE; DROP TABLE [B] CASCADE;';
    q.ExecSQL;
    q.Free;
    WriteToProcessLog(capt+'Finished');
  end;
end; // TestCorrelatedSubQueries


procedure TUnitTestACRQuery.TestRoundBug;
var q:      TACRQuery;
    capt:   String;
begin
  capt := 'Test Round Bug - ';
  q := TACRQuery.Create(nil);
  try
    WriteToProcessLog(capt+'Starting...');
    q.InMemory := True;

    // #6
    // Round(Coalesce)
    q.SQL.Text :=        'CREATE TABLE [Orders] ([OrderID] INTEGER,[OrderAmt] FLOAT,[OrderDate] DATETIME);'
                 +#13#10+'INSERT INTO [Orders] VALUES (1,10.5,TODATE("9/10/2010 16:30:20:15","M/D/YYYY H24:N:S:Z"));'
                 +#13#10+'INSERT INTO [Orders] VALUES (2,NULL,TODATE("9/10/2010 16:30:28:843","M/D/YYYY H24:N:S:Z"));'
                 +#13#10+'INSERT INTO [Orders] VALUES (3,0.041,TODATE("9/10/2010 16:30:37:328","M/D/YYYY H24:N:S:Z"));'
                 +#13#10+'INSERT INTO [Orders] VALUES (4,50.679,TODATE("9/10/2010 16:30:51:31","M/D/YYYY H24:N:S:Z"));'
                 ;
    q.ExecSQL;
    WriteToProcessLog(capt+'Table #1 created...');

    q.SQL.Text :=         'CREATE TABLE tbpayments (adjustment FLOAT DEFAULT 0);'
                  +#13#10+'INSERT INTO tbpayments values (-1000);';
    q.ExecSQL;
    WriteToProcessLog(capt+'Table #2 created...');

    // select OrderID, Orderamt, round(COALESCE(Orderamt,0) ,2) as TheOrderAmt from Orders;
    q.SQL.Text := 'select OrderID, Orderamt, round(COALESCE(Orderamt,0) ,2) as TheOrderAmt from Orders ORDER BY 1';
    q.Open;
    if (q.RecordCount <> 4) then
     WriteToErrorLog(capt+'error #7 Invalid RecordCount = '+IntToStr(q.RecordCount))
    else
    begin
      if (q.Fields[2].AsString <> '10.50') then
        WriteToErrorLog(capt+'error #8: '+q.Fields[2].AsString);
      q.Next;
      if (q.Fields[2].AsString <> '0.00') then
        WriteToErrorLog(capt+'error #9: '+q.Fields[2].AsString);
      q.Next;
      if (q.Fields[2].AsString <> '0.04') then
        WriteToErrorLog(capt+'error #10: '+q.Fields[2].AsString);
      q.Next;
      if (q.Fields[2].AsString <> '50.68') then
        WriteToErrorLog(capt+'error #11: '+q.Fields[2].AsString);
      q.Next;
      if (not q.Eof) then
        WriteToErrorLog(capt+'error #12: EOF = '+BoolToStr(q.Eof,True));
    end;
    WriteToProcessLog(capt+'Query executed...'+#13#10+q.SQL.Text);

    // ROUND
    q.SQL.Text :=  'select round(adjustment,2) from tbpayments';
    q.Open;
    WriteToProcessLog(capt+'Query executed...'+#13#10+q.SQL.Text);
    if (q.RecordCount <> 1) then
     WriteToErrorLog(capt+'error #1 Invalid RecordCount = '+IntToStr(q.RecordCount))
    else
    begin
      if (q.Fields[0].AsString <> '-1000.00') then
        WriteToErrorLog(capt+'error #2: '+q.Fields[0].AsString);
    end;

    q.SQL.Text := 'UPDATE tbpayments SET adjustment = -999.999999';
    q.ExecSQL;

    q.SQL.Text :=  'select round(adjustment,3) from tbpayments';
    q.Open;
    WriteToProcessLog(capt+'Query executed...'+#13#10+q.SQL.Text);
    if (q.RecordCount <> 1) then
     WriteToErrorLog(capt+'error #3 Invalid RecordCount = '+IntToStr(q.RecordCount))
    else
    begin
      if (q.Fields[0].AsString <> '-1000.000') then
        WriteToErrorLog(capt+'error #4: '+q.Fields[0].AsString);
    end;

    q.SQL.Text := 'UPDATE tbpayments SET adjustment = 0';
    q.ExecSQL;
    WriteToProcessLog(capt+'Query executed...'+#13#10+q.SQL.Text);

    q.SQL.Text :=  'select round(adjustment,3) from tbpayments';
    q.Open;
    WriteToProcessLog(capt+'Query executed...'+#13#10+q.SQL.Text);
    if (q.RecordCount <> 1) then
     WriteToErrorLog(capt+'error #5 Invalid RecordCount = '+IntToStr(q.RecordCount))
    else
    begin
      if (q.Fields[0].AsString <> '0.000') then
        WriteToErrorLog(capt+'error #6: '+q.Fields[0].AsString);
    end;

    WriteToProcessLog(capt+'Finishing ... ');
  finally
    q.SQL.Text := 'DROP TABLE tbpayments; DROP TABLE Orders;';
    q.ExecSQL;
    q.Free;
    WriteToProcessLog(capt+'Finished');
  end;
end;


procedure TUnitTestACRQuery.TestCaseAndCoalesce;
var q:      TACRQuery;
    capt:   String;
begin
  capt := 'Test CASE and COALESCE - ';
  q := TACRQuery.Create(nil);
  try
    WriteToProcessLog(capt+'Starting...');
    q.InMemory := True;

    q.SQL.Text :=         'CREATE TABLE [Orders] ([OrderID] INTEGER, [OrderAmt] FLOAT, [OrderDate] DATETIME);'
                 +#13#10+'INSERT INTO [Orders] VALUES (10,10.5,TODATE("9/10/2010 16:30:20:15","M/D/YYYY HH24:N:S:Z"));'
                 +#13#10+'INSERT INTO [Orders] VALUES (11,NULL,TODATE("9/10/2010 16:30:28:843","M/D/YYYY HH24:N:S:Z"));'
                 +#13#10+'INSERT INTO [Orders] VALUES (12,NULL,TODATE("9/10/2010 16:30:37:328","M/D/YYYY HH24:N:S:Z"));'
                 +#13#10+'INSERT INTO [Orders] VALUES (20,30,TODATE("9/10/2010 16:30:40:781","M/D/YYYY HH24:N:S:Z"));'
                 +#13#10+'INSERT INTO [Orders] VALUES (21,40,TODATE("9/10/2010 16:30:44:203","M/D/YYYY HH24:N:S:Z"));'
                 +#13#10+'INSERT INTO [Orders] VALUES (22,50.67,TODATE("9/10/2010 16:30:51:31","M/D/YYYY HH24:N:S:Z"));'
                 ;
    q.ExecSQL;

    WriteToProcessLog(capt+'Table Orders created...');

    q.SQL.Text :=         'CREATE TABLE test (id AutoInc, name Char(20), name2 Char(20), PRIMARY KEY (id));'
                  +#13#10+'INSERT INTO test (name,name2) values (NULL,NULL);'
                  +#13#10+'INSERT INTO test (name,name2) values ("aaa",NULL);'
                  +#13#10+'INSERT INTO test (name,name2) values (NULL,"bBb");'
                  +#13#10+'INSERT INTO test (name,name2) values ("ccc","ddd");'
                  ;
    q.ExecSQL;
    WriteToProcessLog(capt+'Table Test Created...');

    q.SQL.Text :=         'CREATE TABLE City (id AutoInc, name Char(20), PRIMARY KEY (id));'
                  +#13#10+'INSERT INTO City (name) values ("Berlin");'
                  +#13#10+'INSERT INTO City (name) values ("Paris");'
                  +#13#10+'INSERT INTO City (name) values ("London");'
                  +#13#10+'INSERT INTO City (name) values (NULL);'
                  ;
    q.ExecSQL;
    WriteToProcessLog(capt+'Table City Created...');

    q.SQL.Text :=         'CREATE TABLE [A] ([recid] INTEGER,[itemid] INTEGER,[Price] FLOAT,[Balance] FLOAT);'
                  +#13#10+'INSERT INTO [A] VALUES (1,2,NULL,100);'
                  +#13#10+'INSERT INTO [A] VALUES (1,3,12,NULL);'
                  ;
    q.ExecSQL;
    WriteToProcessLog(capt+'Table A Created...');

    // 60 last error

    q.SQL.Text := 'select Round(Sum(price)) FROM A WHERE recid = 2';
    q.Open;
    WriteToProcessLog(capt+'Query executed...'+#13#10+q.SQL.Text);
    if (q.RecordCount <> 1) then
     WriteToErrorLog(capt+'error #59 Invalid RecordCount = '+IntToStr(q.RecordCount))
    else
    if (not q.Fields[0].IsNull) then
     WriteToErrorLog(capt+'error #60 - NOT NULL');


    // Coalesce with 2 params
    q.SQL.Text := 'select sum(coalesce(price,0)) from a';
    q.Open;
    WriteToProcessLog(capt+'Query executed...'+#13#10+q.SQL.Text);
    if (q.RecordCount <> 1) then
     WriteToErrorLog(capt+'error #49 Invalid RecordCount = '+IntToStr(q.RecordCount))
    else
    if (q.FieldCount <> 1) then
     WriteToErrorLog(capt+'error #50 Invalid FieldCount = '+IntToStr(q.FieldCount))
    else
    begin
      if (q.Fields[0].AsString <> '12') then
        WriteToErrorLog(capt+'error #51: '+q.Fields[0].AsString);
      q.Next;
      if (not q.Eof) then
        WriteToErrorLog(capt+'error #52 - not EOF!');
    end;

    // insert ... select
    q.SQL.Text := 'INSERT INTO A (recid, itemid, Price, Balance)  select recid, itemid, Price, 140.87 from A where itemid=3';
    q.ExecSQL;
    WriteToProcessLog(capt+'Query executed...'+#13#10+q.SQL.Text);
    if (q.RowsAffected <> 1) then
     WriteToErrorLog(capt+'error #53 Invalid RowsAffected = '+IntToStr(q.RowsAffected));

    q.SQL.Text := 'SELECT * FROM A WHERE itemid = 3 ORDER BY Balance';
    q.Open;
    WriteToProcessLog(capt+'Query executed...'+#13#10+q.SQL.Text);
    if (q.RecordCount <> 2) then
     WriteToErrorLog(capt+'error #54 Invalid RecordCount = '+IntToStr(q.RecordCount))
    else
    if (q.FieldCount <> 4) then
     WriteToErrorLog(capt+'error #55 Invalid FieldCount = '+IntToStr(q.FieldCount))
    else
    begin
      if (not q.Fields[3].IsNull) then
        WriteToErrorLog(capt+'error #56: '+q.Fields[3].AsString);
      q.Next;
      if (q.Fields[3].AsString <> '140.87') then
        WriteToErrorLog(capt+'error #57: '+q.Fields[3].AsString);
      q.Next;
      if (not q.Eof) then
        WriteToErrorLog(capt+'error #58 - not EOF!');
    end;

    // Coalesce with 2 params
    q.SQL.Text := 'SELECT SUM(COALESCE(Orderamt,0)) from Orders';
    q.Open;
    WriteToProcessLog(capt+'Query executed...'+#13#10+q.SQL.Text);
    if (q.RecordCount <> 1) then
     WriteToErrorLog(capt+'error #46 Invalid RecordCount = '+IntToStr(q.RecordCount))
    else
    if (q.FieldCount <> 1) then
     WriteToErrorLog(capt+'error #47 Invalid FieldCount = '+IntToStr(q.FieldCount))
    else
    begin
      if (q.Fields[0].AsString <> '131.17') then
        WriteToErrorLog(capt+'error #48: '+q.Fields[0].AsString);
      q.Next;
      if (not q.Eof) then
        WriteToErrorLog(capt+'error #49 - not EOF!');
    end;


    // simple case with AS
    q.SQL.Text :=  'select id, '
                   +'Case Name '
                   +'WHEN "Berlin" then "Germany" '
                   +'WHEN "Paris" then "France" '
                   +'WHEN "London" then "England" '
                   +'ELSE "None" '
                   +'END '
                   +'As Country '
                   +'FROM City Order BY id';
    q.Open;
    WriteToProcessLog(capt+'Query executed...'+#13#10+q.SQL.Text);
    if (q.RecordCount <> 4) then
     WriteToErrorLog(capt+'error #40 Invalid RecordCount = '+IntToStr(q.RecordCount))
    else
    begin
      if (q.Fields[0].AsInteger <> 1) or (q.Fields[1].AsString <> 'Germany') then
        WriteToErrorLog(capt+'error #41: '+#9+q.Fields[0].AsString+#9+q.Fields[1].AsString);
      q.Next;
      if (q.Fields[0].AsInteger <> 2) or (q.Fields[1].AsString <> 'France') then
        WriteToErrorLog(capt+'error #42: '+#9+q.Fields[0].AsString+#9+q.Fields[1].AsString);
      q.Next;
      if (q.Fields[0].AsInteger <> 3) or (q.Fields[1].AsString <> 'England') then
        WriteToErrorLog(capt+'error #43: '+#9+q.Fields[0].AsString+#9+q.Fields[1].AsString);
      q.Next;
      if (q.Fields[0].AsInteger <> 4) or (q.Fields[1].AsString <> 'None') then
        WriteToErrorLog(capt+'error #44: '+#9+q.Fields[0].AsString+#9+q.Fields[1].AsString);
      q.Next;
      if (not q.Eof) then
        WriteToErrorLog(capt+'error #45 - not EOF!');
    end;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);

    // CASE Advanced with AND
    q.SQL.Text :=  'select test.*, '
                  +'CASE '
                  +'WHEN (name IS NOT NULL) and (name2 IS NOT NULL) THEN name || " " || name2 '
                  +'WHEN (name IS NULL) and (name2 IS NOT NULL) THEN "UNKNOWN " || LOWER(name2) '
                  +'WHEN (name2 IS NULL) and (name IS NOT NULL) THEN UPPER(name) || " UNKNOWN" '
                  +'WHEN (name IS NULL) and (name2 IS NULL) THEN "UNKNOWN NAMES" '
                  +'END '
                  +'FROM test order by id';
    q.Open;
    WriteToProcessLog(capt+'Query executed...'+#13#10+q.SQL.Text);
    if (q.RecordCount <> 4) then
     WriteToErrorLog(capt+'error #34 Invalid RecordCount = '+IntToStr(q.RecordCount))
    else
    begin
      if (q.Fields[3].AsString <> 'UNKNOWN NAMES') then
        WriteToErrorLog(capt+'error #35: '+q.Fields[3].AsString);
      q.Next;
      if (q.Fields[3].AsString <> UpperCase(q.Fields[1].AsString)+' UNKNOWN') then
        WriteToErrorLog(capt+'error #36: '+q.Fields[3].AsString);
      q.Next;
      if (q.Fields[3].AsString <> 'UNKNOWN '+LowerCase(q.Fields[2].AsString)) then
        WriteToErrorLog(capt+'error #37: '+q.Fields[3].AsString);
      q.Next;
      if (q.Fields[3].AsString <> q.Fields[1].AsString+' '+q.Fields[2].AsString) then
        WriteToErrorLog(capt+'error #38: '+q.Fields[3].AsString);
      q.Next;
      if (not q.Eof) then
        WriteToErrorLog(capt+'error #39 - not EOF!');
    end;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);

    // Coalesce with 2 params
    q.SQL.Text := 'SELECT OrderID, COALESCE(Orderamt,0) as TheOrderAmt  from Orders ORDER BY 1';
    q.Open;
    WriteToProcessLog(capt+'Query executed...'+#13#10+q.SQL.Text);
    if (q.RecordCount <> 6) then
     WriteToErrorLog(capt+'error #19 Invalid RecordCount = '+IntToStr(q.RecordCount))
    else
    if (q.FieldCount <> 2) then
     WriteToErrorLog(capt+'error #20 Invalid FieldCount = '+IntToStr(q.FieldCount))
    else
    begin
      if (q.Fields[0].AsInteger <> 10) then
        WriteToErrorLog(capt+'error #21: '+q.Fields[0].AsString);
      if (q.Fields[1].AsString <> '10.5') then
        WriteToErrorLog(capt+'error #22: '+q.Fields[1].AsString);
      q.Next;
      if (q.Fields[0].AsInteger <> 11) then
        WriteToErrorLog(capt+'error #23: '+q.Fields[0].AsString);
      if (q.Fields[1].AsString <> '0') then
        WriteToErrorLog(capt+'error #24: '+q.Fields[1].AsString);
      q.Next;
      if (q.Fields[0].AsInteger <> 12) then
        WriteToErrorLog(capt+'error #25: '+q.Fields[0].AsString);
      if (q.Fields[1].AsString <> '0') then
        WriteToErrorLog(capt+'error #26: '+q.Fields[1].AsString);
      q.Next;
      if (q.Fields[0].AsInteger <> 20) then
        WriteToErrorLog(capt+'error #27: '+q.Fields[0].AsString);
      if (q.Fields[1].AsString <> '30') then
        WriteToErrorLog(capt+'error #28: '+q.Fields[1].AsString);
      q.Next;
      if (q.Fields[0].AsInteger <> 21) then
        WriteToErrorLog(capt+'error #29: '+q.Fields[0].AsString);
      if (q.Fields[1].AsString <> '40') then
        WriteToErrorLog(capt+'error #30: '+q.Fields[1].AsString);
      q.Next;
      if (q.Fields[0].AsInteger <> 22) then
        WriteToErrorLog(capt+'error #31: '+q.Fields[0].AsString);
      if (q.Fields[1].AsString <> '50.67') then
        WriteToErrorLog(capt+'error #32: '+q.Fields[1].AsString);
      q.Next;
      if (not q.Eof) then
        WriteToErrorLog(capt+'error #33 - not EOF!');
    end;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);

    // CASE Simple
    q.SQL.Text :=  'select test.*, '
                  +'CASE name '
                  +'WHEN ("aaa") THEN UPPER(name) '
                  +'WHEN "ccc" THEN name||" "+name2 '
                  +'ELSE "NO NAME" '
                  +'END '
                  +'FROM test order by id';
    q.Open;
    WriteToProcessLog(capt+'Query executed...'+#13#10+q.SQL.Text);
    if (q.RecordCount <> 4) then
     WriteToErrorLog(capt+'error #13 Invalid RecordCount = '+IntToStr(q.RecordCount))
    else
    begin
      if (q.Fields[3].AsString <> 'NO NAME') then
        WriteToErrorLog(capt+'error #14: '+q.Fields[3].AsString);
      q.Next;
      if (q.Fields[3].AsString <> UpperCase(q.Fields[1].AsString)) then
        WriteToErrorLog(capt+'error #15: '+q.Fields[3].AsString);
      q.Next;
      if (q.Fields[3].AsString <> 'NO NAME') then
        WriteToErrorLog(capt+'error #16: '+q.Fields[3].AsString);
      q.Next;
      if (q.Fields[3].AsString <> q.Fields[1].AsString+' '+q.Fields[2].AsString) then
        WriteToErrorLog(capt+'error #17: '+q.Fields[3].AsString);
      q.Next;
      if (not q.Eof) then
        WriteToErrorLog(capt+'error #18 - not EOF!');
    end;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);

    // CASE Advanced
    q.SQL.Text :=  'select test.*, '
                  +'CASE '
                  +'WHEN (name IS NOT NULL) THEN name '
                  +'WHEN name2 IS NOT NULL THEN name2 '
                  +'ELSE "NO NAME" '
                  +'END '
                  +'FROM test order by id';
    q.Open;
    WriteToProcessLog(capt+'Query executed...'+#13#10+q.SQL.Text);
    if (q.RecordCount <> 4) then
     WriteToErrorLog(capt+'error #7 Invalid RecordCount = '+IntToStr(q.RecordCount))
    else
    begin
      if (q.Fields[3].AsString <> 'NO NAME') then
        WriteToErrorLog(capt+'error #8: '+q.Fields[3].AsString);
      q.Next;
      if (q.Fields[3].AsString <> q.Fields[1].AsString) then
        WriteToErrorLog(capt+'error #9: '+q.Fields[3].AsString);
      q.Next;
      if (q.Fields[3].AsString <> q.Fields[2].AsString) then
        WriteToErrorLog(capt+'error #10: '+q.Fields[3].AsString);
      q.Next;
      if (q.Fields[3].AsString <> q.Fields[1].AsString) then
        WriteToErrorLog(capt+'error #11: '+q.Fields[3].AsString);
      q.Next;
      if (not q.Eof) then
        WriteToErrorLog(capt+'error #12 - not EOF!');
    end;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);

    // COALESCE
    q.SQL.Text :=  'select test.*, COALESCE(name,name2,"NO NAME") from test order by id';
    q.Open;
    WriteToProcessLog(capt+'Query executed...'+#13#10+q.SQL.Text);
    if (q.RecordCount <> 4) then
     WriteToErrorLog(capt+'error #1 Invalid RecordCount = '+IntToStr(q.RecordCount))
    else
    begin
      if (q.Fields[3].AsString <> 'NO NAME') then
        WriteToErrorLog(capt+'error #2: '+q.Fields[3].AsString);
      q.Next;
      if (q.Fields[3].AsString <> q.Fields[1].AsString) then
        WriteToErrorLog(capt+'error #3: '+q.Fields[3].AsString);
      q.Next;
      if (q.Fields[3].AsString <> q.Fields[2].AsString) then
        WriteToErrorLog(capt+'error #4: '+q.Fields[3].AsString);
      q.Next;
      if (q.Fields[3].AsString <> q.Fields[1].AsString) then
        WriteToErrorLog(capt+'error #5: '+q.Fields[3].AsString);
      q.Next;
      if (not q.Eof) then
        WriteToErrorLog(capt+'error #6 - not EOF!');
    end;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);

    WriteToProcessLog(capt+'Finishing ... ');
  finally
    q.SQL.Text := 'DROP TABLE test; DROP TABLE Orders; DROP TABLE City; DROP TABLE A;';
    q.ExecSQL;
    q.Free;
    WriteToProcessLog(capt+'Finished');
  end;
end; // TestCaseAndCoalesce



procedure TUnitTestACRQuery.TestDateAddAndDateDiff;
var q:         TACRQuery;
    s,capt:    String;
    x:         Integer;
begin
  capt := 'Test DateAdd and DateDiff - ';
  q := TACRQuery.Create(nil);
  try
    WriteToProcessLog(capt+'Starting...');
    q.InMemory := True;
    q.SQL.Text :=         'CREATE TABLE Test (Date1 TIMESTAMP, Date2 TIMESTAMP, Date3 TIMESTAMP, Date4 TIMESTAMP);'
                 +#13#10+'INSERT INTO Test VALUES ('
                 +'TODATE("10/31/2010 13:30:40.500","M/D/YYYY HH24:N:S.Z"),'
                 +'TODATE("11/30/2010 14:40:50.600","M/D/YYYY HH24:N:S.Z"),'
                 +'TODATE("02/28/2007 08:25:29.100","M/D/YYYY HH24:N:S.Z"),'
                 +'TODATE("10/31/2010 14:15:05.100","M/D/YYYY HH24:N:S.Z")'
                 +');'
                 +' CREATE TABLE Test1(value Integer); INSERT INTO Test1 VALUES(1);'
                 ;
    q.ExecSQL;
    WriteToProcessLog(Capt+'Table Created');

    // last error: 43
    WriteToProcessLog(Capt+'Testing DateAdd...');

//    x := 2011;
    s := '10/31/2011 13:30:40.500';
    q.SQL.Text := 'SELECT TOSTRING(DATEADD(YEAR,(SELECT * FROM Test1),Date1),"MM/DD/YYYY HH24:NN:SS.ZZZ")  FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsString <> s) then
     WriteToErrorLog(Capt+'Error #42. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+IntToStr(x)+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

    x := 1;
    q.SQL.Text := 'SELECT DATEDIFF(DAY,Now,Now+1) FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsInteger <> x) then
     WriteToErrorLog(Capt+'Error #43. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+IntToStr(x)+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);


    x := 2664600;
    q.SQL.Text := 'SELECT DATEDIFF(MILLISECOND,Date1,Date4) FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsInteger <> x) then
     WriteToErrorLog(Capt+'Error #41. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+IntToStr(x)+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

    x := -2664600;
    q.SQL.Text := 'SELECT DATEDIFF(MILLISECOND,Date4,Date1) FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsInteger <> x) then
     WriteToErrorLog(Capt+'Error #40. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+IntToStr(x)+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

    x := -118476921;
    q.SQL.Text := 'SELECT DATEDIFF(SECOND,Date2,Date3) FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsInteger <> x) then
     WriteToErrorLog(Capt+'Error #39. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+IntToStr(x)+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

    x := 118476921;
    q.SQL.Text := 'SELECT DATEDIFF(SECOND,Date3,Date2) FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsInteger <> x) then
     WriteToErrorLog(Capt+'Error #38. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+IntToStr(x)+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

    x := -1974615;
    q.SQL.Text := 'SELECT DATEDIFF(MINUTE,Date2,Date3) FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsInteger <> x) then
     WriteToErrorLog(Capt+'Error #37. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+IntToStr(x)+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

    x := 1974615;
    q.SQL.Text := 'SELECT DATEDIFF(MINUTE,Date3,Date2) FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsInteger <> x) then
     WriteToErrorLog(Capt+'Error #36. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+IntToStr(x)+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

    x := -32910;
    q.SQL.Text := 'SELECT DATEDIFF(HOUR,Date2,Date3) FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsInteger <> x) then
     WriteToErrorLog(Capt+'Error #35. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+IntToStr(x)+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

    x := 32910;
    q.SQL.Text := 'SELECT DATEDIFF(HOUR,Date3,Date2) FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsInteger <> x) then
     WriteToErrorLog(Capt+'Error #34. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+IntToStr(x)+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

    WriteToProcessLog(Capt+'Testing DateDiff...');
    x := -1371;
    q.SQL.Text := 'SELECT DATEDIFF(DAY,Date2,Date3) FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsInteger <> x) then
     WriteToErrorLog(Capt+'Error #33. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+IntToStr(x)+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

    x := 1371;
    q.SQL.Text := 'SELECT DATEDIFF(DAY,Date3,Date2) FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsInteger <> x) then
     WriteToErrorLog(Capt+'Error #32. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+IntToStr(x)+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

    WriteToProcessLog(Capt+'Testing DateDiff...');
    x := -196;
    q.SQL.Text := 'SELECT DATEDIFF(WEEK,Date2,Date3) FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsInteger <> x) then
     WriteToErrorLog(Capt+'Error #31. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+IntToStr(x)+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

    x := 196;
    q.SQL.Text := 'SELECT DATEDIFF(WEEK,Date3,Date2) FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsInteger <> x) then
     WriteToErrorLog(Capt+'Error #30. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+IntToStr(x)+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

    WriteToProcessLog(Capt+'Testing DateDiff...');
    x := -45;
    q.SQL.Text := 'SELECT DATEDIFF(MONTH,Date2,Date3) FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsInteger <> x) then
     WriteToErrorLog(Capt+'Error #29. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+IntToStr(x)+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

    x := 45;
    q.SQL.Text := 'SELECT DATEDIFF(MONTH,Date3,Date2) FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsInteger <> x) then
     WriteToErrorLog(Capt+'Error #28. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+IntToStr(x)+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

    WriteToProcessLog(Capt+'Testing DateDiff...');
    x := -15;
    q.SQL.Text := 'SELECT DATEDIFF(QUARTER,Date2,Date3) FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsInteger <> x) then
     WriteToErrorLog(Capt+'Error #27. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+IntToStr(x)+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

    x := 15;
    q.SQL.Text := 'SELECT DATEDIFF(QUARTER,Date3,Date2) FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsInteger <> x) then
     WriteToErrorLog(Capt+'Error #26. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+IntToStr(x)+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

    WriteToProcessLog(Capt+'Testing DateDiff...');
    x := -3;
    q.SQL.Text := 'SELECT DATEDIFF(YEAR,Date2,Date3) FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsInteger <> x) then
     WriteToErrorLog(Capt+'Error #25. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+IntToStr(x)+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

    x := 3;
    q.SQL.Text := 'SELECT DATEDIFF(YEAR,Date3,Date2) FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsInteger <> x) then
     WriteToErrorLog(Capt+'Error #24. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+IntToStr(x)+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

    WriteToProcessLog(Capt+'Testing DateAdd...');

    s := '10/31/2010 13:30:39.714';
    q.SQL.Text := 'SELECT TOSTRING(DATEADD(MILLISECOND, -786, Date1),"MM/DD/YYYY HH24:NN:SS.ZZZ") FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsString <> s) then
     WriteToErrorLog(Capt+'Error #23. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+s+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

    s := '10/31/2010 13:30:41.731';
    q.SQL.Text := 'SELECT TOSTRING(DATEADD(MILLISECOND, 1231, Date1),"MM/DD/YYYY HH24:NN:SS.ZZZ") FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsString <> s) then
     WriteToErrorLog(Capt+'Error #22. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+s+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

    s := '09/13/2010 09:39:46.500';
    q.SQL.Text := 'SELECT TOSTRING(DATEADD(SECOND, -4161054, Date1),"MM/DD/YYYY HH24:NN:SS.ZZZ") FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsString <> s) then
     WriteToErrorLog(Capt+'Error #21. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+s+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

    s := '11/11/2010 08:59:15.500';
    q.SQL.Text := 'SELECT TOSTRING(DATEADD(SECOND, 934115, Date1),"MM/DD/YYYY HH24:NN:SS.ZZZ") FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsString <> s) then
     WriteToErrorLog(Capt+'Error #20. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+s+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

    s := '10/31/1980 13:30:40.500';
    q.SQL.Text := 'SELECT TOSTRING(DATEADD(YEAR, -30, Date1),"MM/DD/YYYY HH24:NN:SS.ZZZ") FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsString <> s) then
     WriteToErrorLog(Capt+'Error #19. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+s+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

    s := '09/30/2000 13:30:40.500';
    q.SQL.Text := 'SELECT TOSTRING(DATEADD(MONTH, -121, Date1),"MM/DD/YYYY HH24:NN:SS.ZZZ") FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsString <> s) then
     WriteToErrorLog(Capt+'Error #18. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+s+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

    s := '04/30/1947 13:30:40.500';
    q.SQL.Text := 'SELECT TOSTRING(DATEADD(QUARTER, -254, Date1),"MM/DD/YYYY HH24:NN:SS.ZZZ") FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsString <> s) then
     WriteToErrorLog(Capt+'Error #17. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+s+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

{ TODO : make uinternal ACREncodeDateTime, ACRDecodeDateTime to avoid bugs with TDateTime with too low value (1732 year for example) }
{
    s := '09/06/1732 13:30:40.500';
    q.SQL.Text := 'SELECT TOSTRING(DATEADD(DAY, -101592, Date1),"MM/DD/YYYY HH24:NN:SS.ZZZ") FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsString <> s) then
     WriteToErrorLog(Capt+'Error #16. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+s+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);
}
    s := '06/22/2006 13:30:40.500';
    q.SQL.Text := 'SELECT TOSTRING(DATEADD(DAY, -1592, Date1),"MM/DD/YYYY HH24:NN:SS.ZZZ") FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsString <> s) then
     WriteToErrorLog(Capt+'Error #15. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+s+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

    s := '01/30/2000 13:30:40.500';
    q.SQL.Text := 'SELECT TOSTRING(DATEADD(WEEK, -561, Date1),"MM/DD/YYYY HH24:NN:SS.ZZZ") FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsString <> s) then
     WriteToErrorLog(Capt+'Error #14. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+s+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

    s := '10/29/2010 22:22:40.500';
    q.SQL.Text := 'SELECT TOSTRING(DATEADD(MINUTE, -2348, Date1),"MM/DD/YYYY HH24:NN:SS.ZZZ") FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsString <> s) then
     WriteToErrorLog(Capt+'Error #13. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+s+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

    s := '12/22/2010 23:39:40.500';
    q.SQL.Text := 'SELECT TOSTRING(DATEADD(MINUTE, 75489, Date1),"MM/DD/YYYY HH24:NN:SS.ZZZ") FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsString <> s) then
     WriteToErrorLog(Capt+'Error #12. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+s+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

    s := '02/01/2009 22:30:40.500';
    q.SQL.Text := 'SELECT TOSTRING(DATEADD(HOUR, -15279, Date1),"MM/DD/YYYY HH24:NN:SS.ZZZ") FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsString <> s) then
     WriteToErrorLog(Capt+'Error #11. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+s+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

    s := '08/20/2022 05:30:40.500';
    q.SQL.Text := 'SELECT TOSTRING(DATEADD(HOUR, 103456, Date1),"MM/DD/YYYY HH24:NN:SS.ZZZ") FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsString <> s) then
     WriteToErrorLog(Capt+'Error #10. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+s+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

    s := '12/01/2010 00:40:50.600';
    q.SQL.Text := 'SELECT TOSTRING(DATEADD(HOUR, 10, Date2),"MM/DD/YYYY HH24:NN:SS.ZZZ") FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsString <> s) then
     WriteToErrorLog(Capt+'Error #9. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+s+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

    s := '12/07/2010 14:40:50.600';
    q.SQL.Text := 'SELECT TOSTRING(DATEADD(WEEK, 1, Date2),"MM/DD/YYYY HH24:NN:SS.ZZZ") FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsString <> s) then
     WriteToErrorLog(Capt+'Error #8. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+s+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);


    s := '11/07/2010 13:30:40.500';
    q.SQL.Text := 'SELECT TOSTRING(DATEADD(WEEK, 1, Date1),"MM/DD/YYYY HH24:NN:SS.ZZZ") FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsString <> s) then
     WriteToErrorLog(Capt+'Error #7. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+s+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

    s := '11/30/2010 13:30:40.500';
    q.SQL.Text := 'SELECT TOSTRING(DATEADD(DAY, 30, Date1),"MM/DD/YYYY HH24:NN:SS.ZZZ") FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsString <> s) then
     WriteToErrorLog(Capt+'Error #6. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+s+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

    s := '11/28/2011 14:40:50.600';
    q.SQL.Text := 'SELECT TOSTRING(DATEADD(DAY, 363, Date2),"MM/DD/YYYY HH24:NN:SS.ZZZ") FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsString <> s) then
     WriteToErrorLog(Capt+'Error #5. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+s+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

    s := '02/29/2016 14:40:50.600';
    q.SQL.Text := 'SELECT TOSTRING(DATEADD(MONTH, 63, Date2),"MM/DD/YYYY HH24:NN:SS.ZZZ") FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsString <> s) then
     WriteToErrorLog(Capt+'Error #4. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+s+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

    s := '02/28/2011 14:40:50.600';
    q.SQL.Text := 'SELECT TOSTRING(DATEADD(QUARTER, 1, Date2),"MM/DD/YYYY HH24:NN:SS.ZZZ") FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsString <> s) then
     WriteToErrorLog(Capt+'Error #3. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+s+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);

    s := '01/31/2011 13:30:40.500';
    q.SQL.Text := 'SELECT TOSTRING(DATEADD(QUARTER, 1, Date1),"MM/DD/YYYY HH24:NN:SS.ZZZ") FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsString <> s) then
     WriteToErrorLog(Capt+'Error #2. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+s+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);


    s := '10/31/2011 13:30:40.500';
    q.SQL.Text := 'SELECT TOSTRING(DATEADD(YEAR, 1, Date1),"MM/DD/YYYY HH24:NN:SS.ZZZ") FROM Test';
    q.Open;
    if (q.RecordCount <> 1) or (q.Fields[0].AsString <> s) then
     WriteToErrorLog(Capt+'Error #1. RecCount = '+IntToStr(q.RecordCount)+', Value = '+q.Fields[0].AsString+', ControlValue = '+s+#13#10+q.SQL.Text)
    else
     WriteToProcessLog(#13#10+q.SQL.Text+s);


    WriteToProcessLog(Capt+'DateAdd test finished');

    WriteToProcessLog(capt+'Table Orders created...');
    WriteToProcessLog(capt+'Finishing ... ');
  finally
    q.SQL.Text := 'DROP TABLE test; ';
    q.ExecSQL;
    q.Free;
    WriteToProcessLog(capt+'Finished');
  end;
end;


procedure TUnitTestACRQuery.TestBLOBAndMemo;
var q: TACRQuery;
    capt,s: String;
    buf: array [0..10*1024-1] of Byte;
    i: Integer;
    bs: TStream;
begin
  capt := 'Test BLOB And Memo - ';
  q := TACRQuery.Create(nil);
  try
    WriteToProcessLog(capt+'Starting...');
    q.InMemory := True;
    q.SQL.Text := 'DROP TABLE TableTest CASCADE; CREATE TABLE TableTest ('
                 +'ID INTEGER,	TestMemoField MEMO BLOBBLOCKSIZE 102400 BLOBCOMPRESSIONALGORITHM NONE BLOBCOMPRESSIONMODE 0,'
                 +'	TestBlobField BLOB BLOBBLOCKSIZE 102400 BLOBCOMPRESSIONALGORITHM NONE BLOBCOMPRESSIONMODE 0);';
    q.ExecSQL;

    WriteToProcessLog(capt+'Table created');

    q.SQL.Text := 'SELECT * FROM TableTest';
    q.Open;
    WriteToProcessLog(capt+'Query opened: '+#13#10+q.SQL.Text);
    s := q.FieldByName('TestMemoField').AsString;
    if (s <> '') then
      WriteToErrorLog(capt+'Memo is not empty');
    if (not q.FieldByName('TestBlobField').IsNull) then
      WriteToErrorLog(capt+'BLOB is not empty');

    q.SQL.Text := 'INSERT INTO TableTest (TestMemoField, TestBlobField) VALUES(NULL,NULL)';
    q.ExecSQL;

    q.SQL.Text := 'SELECT * FROM TableTest';
    q.Open;
    WriteToProcessLog(capt+'Query opened #2: '+#13#10+q.SQL.Text);
    s := q.FieldByName('TestMemoField').AsString;
    if (s <> '') then
      WriteToErrorLog(capt+'Memo is not empty #2');
    if (not q.FieldByName('TestBlobField').IsNull) then
      WriteToErrorLog(capt+'BLOB is not empty #2');

    FillChar(buf[0],SizeOf(buf),$FF);
    q.SQL.Text := 'UPDATE TableTest SET TestMemoField = "Test 123!", TestBlobField = :p0';
    q.Prepare;
    q.Params[0].SetBlobData(@buf[0],SizeOF(buf));
    q.ExecSQL;

    q.SQL.Text := 'SELECT * FROM TableTest';
    q.Open;
    WriteToProcessLog(capt+'Query opened #3: '+#13#10+q.SQL.Text);
    s := q.FieldByName('TestMemoField').AsString;
    if (s <> 'Test 123!') then
      WriteToErrorLog(capt+'Memo is invalid:'+#13#10+s);
    if (TBlobField(q.FieldByName('TestBlobField')).BlobSize <> SizeOf(buf)) then
      WriteToErrorLog(capt+'BLOB has wrong size: '+IntToStr(TBlobField(q.FieldByName('TestBlobField')).BlobSize))
    else
    begin
     FillChar(buf[0],SizeOf(buf),$00);
     bs := q.CreateBlobStream(TBlobField(q.FieldByName('TestBlobField')),bmRead);
     try
       bs.ReadBuffer(buf[0],SizeOf(buf));
     finally
       bs.Free;
     end;
     for i := 0 to SizeOf(buf)-1 do
      if (buf[i] <> $FF) then
       WriteToErrorLog(capt+'BLOB is invalid: i = '+IntToStr(i)+', buf[i] = '+IntToStr(buf[i]));
    end;
  finally
    q.SQL.Text := 'DROP TABLE TableTest CASCADE;';
    q.ExecSQL;
    q.Free;
  end;
end; // TestBLOBAndMemo


procedure TUnitTestACRQuery.TestNotLike;
var q:    TACRQuery;
    capt: String;
begin
  capt := 'Test NOT LIKE - ';
  q := TACRQuery.Create(nil);
  try
    WriteToProcessLog(capt+'Starting...');
    q.InMemory := True;
    q.SQL.Text :=  'DROP TABLE Table_TEST CASCADE; '
                  +'CREATE TABLE Table_TEST (Field1 INTEGER,Field2 CHAR (25),	Field3 CHAR (25)); '
                  +'INSERT INTO Table_TEST VALUES (1,"Paris=France","Europe"); '
                  +'INSERT INTO Table_TEST VALUES (2,"London","Europe"); '
                  +'INSERT INTO Table_TEST VALUES (3,"Buenos Aires=Argentina","America"); '
                  +'INSERT INTO Table_TEST VALUES (4,"Tokyo","Asia"); '
                  ;
    q.ExecSQL;
    // last error: #8
    WriteToProcessLog(capt+'Table created');
    q.SQL.Text := 'SELECT Field1,Field2 FROM Table_TEST WHERE Field2 NOT LIKE "%=%" ORDER BY 1';
    q.Open;
    WriteToProcessLog(capt+'Query opened: '+#13#10+q.SQL.Text);
    if (q.RecordCount <> 2) then
      WriteToErrorLog(capt+'Error #1: Invalid RecordCount = '+IntToStr(q.RecordCount))
    else
    begin
     if (q.Fields[0].AsInteger <> 2) then
      WriteToErrorLog(capt+'Error #2: '+q.Fields[0].AsString+#9+q.Fields[1].AsString);
      q.Next;
     if (q.Fields[0].AsInteger <> 4) then
      WriteToErrorLog(capt+'Error #3: '+q.Fields[0].AsString+#9+q.Fields[1].AsString);
      q.Next;
      if (not q.Eof) then
        WriteToErrorLog(capt+'error #4 - not EOF!');
    end;
    WriteToProcessLog(capt+'Table created');
    q.SQL.Text := 'SELECT Field1,Field2 FROM Table_TEST WHERE Field2 LIKE "%=%" ORDER BY 1';
    q.Open;
    WriteToProcessLog(capt+'Query opened: '+#13#10+q.SQL.Text);
    if (q.RecordCount <> 2) then
      WriteToErrorLog(capt+'Error #5: Invalid RecordCount = '+IntToStr(q.RecordCount))
    else
    begin
     if (q.Fields[0].AsInteger <> 1) then
      WriteToErrorLog(capt+'Error #6: '+q.Fields[0].AsString+#9+q.Fields[1].AsString);
      q.Next;
     if (q.Fields[0].AsInteger <> 3) then
      WriteToErrorLog(capt+'Error #7: '+q.Fields[0].AsString+#9+q.Fields[1].AsString);
      q.Next;
      if (not q.Eof) then
        WriteToErrorLog(capt+'error #8 - not EOF!');
    end;
  finally
    q.SQL.Text := 'DROP TABLE Table_TEST CASCADE;';
    q.ExecSQL;
    q.Free;
  end;
end; // TestNotLike


procedure TUnitTestACRQuery.TestBrunner_18_11_2010;
var q:    TACRQuery;
    capt: String;
begin
  capt := 'TestBrunner_18_11_2010 - ';
  q := TACRQuery.Create(nil);
  try
    WriteToProcessLog(capt+'Starting...');
    q.InMemory := True;
    q.SQL.LoadFromFile(SQLDir+'brunner_18_11_2010.sql');
    q.ExecSQL;

    WriteToProcessLog(capt+'DB created');

// last error: 6

    q.SQL.Text :=  'select * from Adressen where ID IN ('
                  +'select A1.ID from Adressen A1, Adressen A2 '
                  +'where A1.ID <> A2.ID and LOWER(A1.Stichwort) = LOWER(A2.Stichwort)'
                  +')';
    q.Open;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    if (q.RecordCount <> 0) then
      WriteToErrorLog(capt+'Error #5: Invalid RecordCount = '+IntToStr(q.RecordCount));



    q.SQL.Text := 'SELECT DISTINCT A.ID AS ID, A.AuftragsNr AS AuftragsNr, A.Stichwort AS Stichwort, A.GUID AS GUID, A.ExportStatus AS ExportStatus, A.ID_Installateur'
+#13#10+'AS ID_Installateur,'
+#13#10+'A.ID_Kontrolleur AS ID_Kontrolleur, A.ID_Werk AS ID_Werk, A.WerkNr AS WerkNr, A.Jahr AS Jahr, A.DatumInbetrieb AS DatumInbetrieb,'
+#13#10+'G.ID AS ID_Gebaeude, G.Strasse AS Strasse, G.HausNr AS HausNr, G.HausNrSort AS HausNrSort, G.PLZ AS PLZ,'
+#13#10+'G.PostOrt AS PostOrt, G.GebaeudeArt1 AS GebaeudeArt1, G.GebaeudeArt2 AS GebaeudeArt2, G.Gemeinde AS Gemeinde, G.ParzelleNr AS ParzelleNr,'
+#13#10+'G.AssekuranzNr AS AssekuranzNr, G.ID_Inhaber AS ID_Inhaber, G.ID_Verwaltung AS ID_Verwaltung,'
+#13#10+'A.ImportCRC'
+#13#10+'FROM EAuftraege A'
+#13#10+'JOIN ELeistungen L ON L.ID_Auftrag = A.ID'
+#13#10+'JOIN EAnlagen Anl ON Anl.ID = L.ID_Objekt'
+#13#10+'JOIN Gebaeude G ON G.ID = Anl.ID_Gebaeude'
+#13#10+'LEFT OUTER JOIN GeschPartner Werk ON Werk.ID = A.ID_Werk'
;

    q.Open;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    if (q.RecordCount <> 14) then
      WriteToErrorLog(capt+'Error #6: Invalid RecordCount = '+IntToStr(q.RecordCount));

    q.SQL.Text :='SELECT DISTINCT TOP 2500 EfProjekte.ID AS ID, EfProjekte.AuftragsNr AS AuftragsNr, EfProjekte.Stichwort AS Stichwort, EfProjekte.ID_Installateur AS'
+#13#10+'ID_Installateur, EfProjekte.ID_Kontrolleur AS ID_Kontrolleur, EfProjekte.WerkNr AS WerkNr, EfProjekte.Jahr AS Jahr, EfProjekte.DatumInbetrieb AS'
+#13#10+'DatumInbetrieb, EfProjekte.ID_Gebaeude AS ID_Gebaeude, EfProjekte.Gemeinde AS Gemeinde, EfProjekte.Strasse AS Strasse, EfProjekte.HausNr AS HausNr,'
+#13#10+'EfProjekte.PLZ AS PLZ, EfProjekte.PostOrt AS PostOrt, EfProjekte.GebaeudeArt1 AS GebaeudeArt1, EfProjekte.GebaeudeArt2 AS GebaeudeArt2,'
+#13#10+'EfProjekte.ParzelleNr AS ParzelleNr, EfProjekte.AssekuranzNr AS AssekuranzNr, EfProjekte.ID_Inhaber AS ID_Inhaber, EfProjekte.ID_Verwaltung AS'
+#13#10+'ID_Verwaltung, EfProjekte.ExportStatus AS ExportStatus, EfProjekte.ID_Werk AS ID_Werk'
+#13#10+'FROM (SELECT DISTINCT A.ID AS ID, A.AuftragsNr AS AuftragsNr, A.Stichwort AS Stichwort, A.GUID AS GUID, A.ExportStatus AS ExportStatus, A.ID_Installateur'
+#13#10+'AS ID_Installateur,'
+#13#10+'A.ID_Kontrolleur AS ID_Kontrolleur, A.ID_Werk AS ID_Werk, A.WerkNr AS WerkNr, A.Jahr AS Jahr, A.DatumInbetrieb AS DatumInbetrieb,'
+#13#10+'G.ID AS ID_Gebaeude, G.Strasse AS Strasse, G.HausNr AS HausNr, G.HausNrSort AS HausNrSort, G.PLZ AS PLZ,'
+#13#10+'G.PostOrt AS PostOrt, G.GebaeudeArt1 AS GebaeudeArt1, G.GebaeudeArt2 AS GebaeudeArt2, G.Gemeinde AS Gemeinde, G.ParzelleNr AS ParzelleNr,'
+#13#10+'G.AssekuranzNr AS AssekuranzNr, G.ID_Inhaber AS ID_Inhaber, G.ID_Verwaltung AS ID_Verwaltung,'
+#13#10+'A.ImportCRC'
+#13#10+'FROM EAuftraege A'
+#13#10+'JOIN ELeistungen L ON L.ID_Auftrag = A.ID'
+#13#10+'JOIN EAnlagen Anl ON Anl.ID = L.ID_Objekt'
+#13#10+'JOIN Gebaeude G ON G.ID = Anl.ID_Gebaeude'
+#13#10+'LEFT OUTER JOIN GeschPartner Werk ON Werk.ID = A.ID_Werk) AS EfProjekte'
+#13#10+'LEFT OUTER JOIN Adressen Inh ON Inh.ID = ID_Inhaber'
+#13#10+'LEFT OUTER JOIN Adressen Verw ON Verw.ID = ID_Verwaltung'
+#13#10+'WHERE (((UPPER(EfProjekte.Stichwort) LIKE UPPER("%biel%") OR UPPER(EfProjekte.Strasse) LIKE UPPER("%biel%") OR UPPER(EfProjekte.HausNr) = UPPER("biel")'
+#13#10+'OR UPPER(EfProjekte.PLZ) LIKE UPPER("%biel%") OR UPPER(EfProjekte.PostOrt) LIKE UPPER("%biel%") OR UPPER(EfProjekte.Gemeinde) LIKE UPPER("%biel%") OR'
+#13#10+'UPPER(Inh.Stichwort) LIKE UPPER("%biel%") OR UPPER(Verw.Stichwort) LIKE UPPER("%biel%"))) OR EfProjekte.ID IN (SELECT DISTINCT ID_Auftrag'
+#13#10+'FROM (SELECT L.ID AS ID, L.ID_Auftrag AS ID_Auftrag,'
+#13#10+'Anl.ID AS Anl_ID, Anl.ID_Gebaeude AS ID_Gebaeude,'
+#13#10+'Anl.GebaeudeTeil AS GebaeudeTeil, Anl.Bezeichnung AS Bezeichnung, Anl.ZaehlerNr1 AS ZaehlerNr1, Anl.ZaehlerNr2 AS ZaehlerNr2,'
+#13#10+'L.Erledigt AS Erledigt, L.LeistungsNr AS LeistungsNr, L.ID_Installateur AS ID_Installateur, L.ID_Kontrolleur AS ID_Kontrolleur, L.ID_SachbTechn AS'
+#13#10+'ID_SachbTechn, L.WerkNr AS WerkNr, L.Jahr AS Jahr, Anl.ID_Inhaber AS ID_Inhaber, Anl.ID_Stromkunde AS ID_Stromkunde'
+#13#10+'FROM ELeistungen L'
+#13#10+'JOIN EAnlagen Anl ON Anl.ID = L.ID_Objekt) AS EfAnlagen'
+#13#10+'JOIN Gebaeude G ON EfAnlagen.ID_Gebaeude = G.ID'
+#13#10+'LEFT OUTER JOIN Adressen Inh ON Inh.ID = EfAnlagen.ID_Inhaber'
+#13#10+'LEFT OUTER JOIN Adressen Stromk ON Stromk.ID = EfAnlagen.ID_Stromkunde'
+#13#10+'LEFT OUTER JOIN Adressen GebInh ON GebInh.ID = G.ID_Inhaber'
+#13#10+'JOIN EAuftraege Auf ON Auf.ID = EfAnlagen.ID_Auftrag'
+#13#10+'WHERE ((UPPER(Inh.Stichwort) LIKE UPPER("%biel%") OR UPPER(Stromk.Stichwort) LIKE UPPER("%biel%") OR UPPER(GebInh.Stichwort) LIKE UPPER("%biel%")))))'
+#13#10+'ORDER BY EfProjekte.ID DESC'
;
//q.SQL.SaveToFile(TempDir+'1.sql');
    q.Open;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    if (q.RecordCount <> 2) then
      WriteToErrorLog(capt+'Error #1: Invalid RecordCount = '+IntToStr(q.RecordCount))
    else
    begin
     if (q.Fields[0].AsInteger <> 17) then
      WriteToErrorLog(capt+'Error #2: '+q.Fields[0].AsString);
     q.Next;
     if (q.Fields[0].AsInteger <> 15) then
      WriteToErrorLog(capt+'Error #3: '+q.Fields[0].AsString);
      q.Next;
      if (not q.Eof) then
        WriteToErrorLog(capt+'error #4 - not EOF!');
    end;
  finally
    q.SQL.Text := 'DROP TABLE Adressen CASCADE; DROP TABLE EAnlagen CASCADE; DROP TABLE EAuftraege CASCADE; DROP TABLE ELeistungen CASCADE; DROP TABLE Gebaeude CASCADE; DROP TABLE GeschPartner CASCADE;';
    q.ExecSQL;
    q.Free;
  end;
end;

procedure TUnitTestACRQuery.TestSQLByRomanKorzh;
var q:      TACRQuery;
    capt,s: String;
begin
  capt := 'TestSQLByRomanKorzh - ';
  q := TACRQuery.Create(nil);
  try
    WriteToProcessLog(capt+'Starting...');
    q.InMemory := True;
    q.SQL.Text :=  'CREATE TABLE Test (ID Integer, Company Char(20)); '
                  +'CREATE TABLE Test1 (ID Integer, Company Char(20)); '
                  +'INSERT INTO Test Values(3,"C"); '
                  +'INSERT INTO Test Values(1,"A"); '
                  +'INSERT INTO Test Values(2,"B"); '
                  ;
    q.ExecSQL;
    q.SQL.LoadFromFile(SQLDir+'roman_korzh_test.sql');
    q.ExecSQL;
    WriteToProcessLog(capt+'DB created');
    // last error: 115

// from
// http://www.delphi-central.com/bdereplacement.aspx

    s := ShortDateFormat;
    ShortDateFormat := 'M/D/YYYY';

    // MAIN TESTS
    q.SQL.Text := 'SELECT First_Name+'' joined at ''+Joined FROM coders ORDER BY 1';
    q.Open;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    if (q.RecordCount <> 10) then
     WriteToErrorLog(capt+'Error #103 - Invalid RecordCount = '+IntToStr(q.RecordCount));
    if (q.FieldCount <> 1) then
     WriteToErrorLog(capt+'Error #104 - Invalid FieldCount = '+IntToStr(q.FieldCount));
    // check values
    if (q.Fields[0].AsString <> 'Arthur joined at 5/25/2002') then
     WriteToErrorLog(capt+'Error #105 - Invalid field values: '+q.Fields[0].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Bred joined at 4/9/2003') then
     WriteToErrorLog(capt+'Error #106 - Invalid field values: '+q.Fields[0].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Dave joined at 9/15/2001') then
     WriteToErrorLog(capt+'Error #107 - Invalid field values: '+q.Fields[0].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Ford joined at 7/18/2003') then
     WriteToErrorLog(capt+'Error #108 - Invalid field values: '+q.Fields[0].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Jimmy joined at 4/6/2004') then
     WriteToErrorLog(capt+'Error #109 - Invalid field values: '+q.Fields[0].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'John joined at 2/15/1998') then
     WriteToErrorLog(capt+'Error #110 - Invalid field values: '+q.Fields[0].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'John joined at 6/5/2003') then
     WriteToErrorLog(capt+'Error #111 - Invalid field values: '+q.Fields[0].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Luke joined at 2/1/2004') then
     WriteToErrorLog(capt+'Error #112 - Invalid field values: '+q.Fields[0].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Mark joined at 5/25/2002') then
     WriteToErrorLog(capt+'Error #113 - Invalid field values: '+q.Fields[0].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Nick joined at 11/30/2003') then
     WriteToErrorLog(capt+'Error #114 - Invalid field values: '+q.Fields[0].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #115 - not EOF!');
    ShortDateFormat := s;


    q.SQL.Text := 'SELECT * FROM coders c NATURAL INNER JOIN projects ORDER BY ID';
    q.Open;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    if (q.RecordCount <> 10) then
     WriteToErrorLog(capt+'Error #79 - Invalid RecordCount = '+IntToStr(q.RecordCount));
    if (q.FieldCount <> 11) then
     WriteToErrorLog(capt+'Error #80 - Invalid FieldCount = '+IntToStr(q.FieldCount));
    if (q.Fields[0].FieldName <> 'ID') then
     WriteToErrorLog(capt+'Error #81 - Invalid FieldName = '+q.Fields[0].FieldName);
    if (q.Fields[1].FieldName <> 'FIRST_NAME') then
     WriteToErrorLog(capt+'Error #82 - Invalid FieldName = '+q.Fields[1].FieldName);
    if (q.Fields[2].FieldName <> 'LAST_NAME') then
     WriteToErrorLog(capt+'Error #83 - Invalid FieldName = '+q.Fields[2].FieldName);
    if (q.Fields[3].FieldName <> 'EXPERIENCE') then
     WriteToErrorLog(capt+'Error #85 - Invalid FieldName = '+q.Fields[3].FieldName);
    if (q.Fields[4].FieldName <> 'SALARY') then
     WriteToErrorLog(capt+'Error #86 - Invalid FieldName = '+q.Fields[4].FieldName);
    if (q.Fields[5].FieldName <> 'JOINED') then
     WriteToErrorLog(capt+'Error #87 - Invalid FieldName = '+q.Fields[5].FieldName);
    if (q.Fields[6].FieldName <> 'CAPTION') then
     WriteToErrorLog(capt+'Error #88 - Invalid FieldName = '+q.Fields[6].FieldName);
    if (q.Fields[7].FieldName <> 'LEADER_ID') then
     WriteToErrorLog(capt+'Error #89 - Invalid FieldName = '+q.Fields[7].FieldName);
    if (q.Fields[8].FieldName <> 'CODERS') then
     WriteToErrorLog(capt+'Error #90 - Invalid FieldName = '+q.Fields[8].FieldName);
    if (q.Fields[9].FieldName <> 'COST') then
     WriteToErrorLog(capt+'Error #91 - Invalid FieldName = '+q.Fields[9].FieldName);
    if (q.Fields[10].FieldName <> 'DEADLINE') then
     WriteToErrorLog(capt+'Error #92 - Invalid FieldName = '+q.Fields[10].FieldName);
    // check values
    if (q.FieldByName('FIRST_NAME').AsString <> 'John') or (q.FieldByName('CAPTION').AsString <> 'Engine core') then
     WriteToErrorLog(capt+'Error #93 - Invalid field values: '+q.FieldByName('FIRST_NAME').AsString+#9+q.FieldByName('CAPTION').AsString);
    q.Next;
    if (q.FieldByName('FIRST_NAME').AsString <> 'Dave') or (q.FieldByName('CAPTION').AsString <> 'Core patch #1') then
     WriteToErrorLog(capt+'Error #94 - Invalid field values: '+q.FieldByName('FIRST_NAME').AsString+#9+q.FieldByName('CAPTION').AsString);
    q.Next;
    if (q.FieldByName('FIRST_NAME').AsString <> 'Mark') or (q.FieldByName('CAPTION').AsString <> 'Audio plugin') then
     WriteToErrorLog(capt+'Error #95 - Invalid field values: '+q.FieldByName('FIRST_NAME').AsString+#9+q.FieldByName('CAPTION').AsString);
    q.Next;
    if (q.FieldByName('FIRST_NAME').AsString <> 'Nick') or (q.FieldByName('CAPTION').AsString <> 'Core patch #2') then
     WriteToErrorLog(capt+'Error #96 - Invalid field values: '+q.FieldByName('FIRST_NAME').AsString+#9+q.FieldByName('CAPTION').AsString);
    q.Next;
    if (q.FieldByName('FIRST_NAME').AsString <> 'John') or (q.FieldByName('CAPTION').AsString <> 'Video plugin') then
     WriteToErrorLog(capt+'Error #97 - Invalid field values: '+q.FieldByName('FIRST_NAME').AsString+#9+q.FieldByName('CAPTION').AsString);
    q.Next;
    if (q.FieldByName('FIRST_NAME').AsString <> 'Luke') or (q.FieldByName('CAPTION').AsString <> 'Core patch #3') then
     WriteToErrorLog(capt+'Error #97 - Invalid field values: '+q.FieldByName('FIRST_NAME').AsString+#9+q.FieldByName('CAPTION').AsString);
    q.Next;
    if (q.FieldByName('FIRST_NAME').AsString <> 'Bred') or (q.FieldByName('CAPTION').AsString <> 'Skins support') then
     WriteToErrorLog(capt+'Error #98 - Invalid field values: '+q.FieldByName('FIRST_NAME').AsString+#9+q.FieldByName('CAPTION').AsString);
    q.Next;
    if (q.FieldByName('FIRST_NAME').AsString <> 'Arthur') or (q.FieldByName('CAPTION').AsString <> 'OS integration') then
     WriteToErrorLog(capt+'Error #99 - Invalid field values: '+q.FieldByName('FIRST_NAME').AsString+#9+q.FieldByName('CAPTION').AsString);
    q.Next;
    if (q.FieldByName('FIRST_NAME').AsString <> 'Jimmy') or (q.FieldByName('CAPTION').AsString <> 'Core patch #4') then
     WriteToErrorLog(capt+'Error #100 - Invalid field values: '+q.FieldByName('FIRST_NAME').AsString+#9+q.FieldByName('CAPTION').AsString);
    q.Next;
    if (q.FieldByName('FIRST_NAME').AsString <> 'Ford') or (q.FieldByName('CAPTION').AsString <> '*nix implementation') then
     WriteToErrorLog(capt+'Error #101 - Invalid field values: '+q.FieldByName('FIRST_NAME').AsString+#9+q.FieldByName('CAPTION').AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #102 - not EOF!');

    q.SQL.Text := 'SELECT * FROM coders WHERE Joined < ANY (SELECT Deadline FROM projects)';
    q.Open;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    if (q.RecordCount <> 10) then
     WriteToErrorLog(capt+'Error #49 - Invalid recordcount = '+IntToStr(q.RecordCount));

    q.SQL.Text := 'SELECT * FROM coders WHERE Joined < ALL (SELECT Deadline FROM projects) order by 1';
    q.Open;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    if (q.RecordCount <> 7) then
     WriteToErrorLog(capt+'Error #50 - Invalid recordcount = '+IntToStr(q.RecordCount))
    else
    begin
     if (q.Fields[0].AsInteger <> 1) then
       WriteToErrorLog(capt+'Error #51 - Invalid field value: '+q.Fields[0].AsString);
     q.Next;
     if (q.Fields[0].AsInteger <> 2) then
       WriteToErrorLog(capt+'Error #53 - Invalid field value: '+q.Fields[0].AsString);
     q.Next;
     if (q.Fields[0].AsInteger <> 3) then
       WriteToErrorLog(capt+'Error #54 - Invalid field value: '+q.Fields[0].AsString);
     q.Next;
     if (q.Fields[0].AsInteger <> 5) then
       WriteToErrorLog(capt+'Error #55 - Invalid field value: '+q.Fields[0].AsString);
     q.Next;
     if (q.Fields[0].AsInteger <> 7) then
       WriteToErrorLog(capt+'Error #56 - Invalid field value: '+q.Fields[0].AsString);
     q.Next;
     if (q.Fields[0].AsInteger <> 8) then
       WriteToErrorLog(capt+'Error #57 - Invalid field value: '+q.Fields[0].AsString);
     q.Next;
     if (q.Fields[0].AsInteger <> 10) then
       WriteToErrorLog(capt+'Error #58 - Invalid field value: '+q.Fields[0].AsString);
     q.Next;
     if (not q.Eof) then
        WriteToErrorLog(capt+'error #59 - not EOF!');
    end;

    q.SQL.Text := 'SELECT ID FROM coders WHERE Joined < ANY (SELECT Deadline FROM projects  WHERE DeadLine<TODATE("01/01/2004","MM/DD/YYYY")) ORDER BY 1';
    q.Open;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    if (q.RecordCount <> 8) then
     WriteToErrorLog(capt+'Error #60 - Invalid recordcount = '+IntToStr(q.RecordCount))
    else
    begin
     if (q.Fields[0].AsInteger <> 1) then
       WriteToErrorLog(capt+'Error #61 - Invalid field value: '+q.Fields[0].AsString);
     q.Next;
     if (q.Fields[0].AsInteger <> 2) then
       WriteToErrorLog(capt+'Error #62 - Invalid field value: '+q.Fields[0].AsString);
     q.Next;
     if (q.Fields[0].AsInteger <> 3) then
       WriteToErrorLog(capt+'Error #63 - Invalid field value: '+q.Fields[0].AsString);
     q.Next;
     if (q.Fields[0].AsInteger <> 4) then
       WriteToErrorLog(capt+'Error #64 - Invalid field value: '+q.Fields[0].AsString);
     q.Next;
     if (q.Fields[0].AsInteger <> 5) then
       WriteToErrorLog(capt+'Error #65 - Invalid field value: '+q.Fields[0].AsString);
     q.Next;
     if (q.Fields[0].AsInteger <> 7) then
       WriteToErrorLog(capt+'Error #66 - Invalid field value: '+q.Fields[0].AsString);
     q.Next;
     if (q.Fields[0].AsInteger <> 8) then
       WriteToErrorLog(capt+'Error #67 - Invalid field value: '+q.Fields[0].AsString);
     q.Next;
     if (q.Fields[0].AsInteger <> 10) then
       WriteToErrorLog(capt+'Error #68 - Invalid field value: '+q.Fields[0].AsString);
     q.Next;
     if (not q.Eof) then
        WriteToErrorLog(capt+'error #69 - not EOF!');
    end;

    q.SQL.Text := 'SELECT ID FROM coders WHERE Joined < ALL (SELECT Deadline FROM projects  WHERE DeadLine<TODATE("01/01/2004","MM/DD/YYYY")) ORDER BY 1';
    q.Open;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    if (q.RecordCount <> 7) then
     WriteToErrorLog(capt+'Error #70 - Invalid recordcount = '+IntToStr(q.RecordCount))
    else
    begin
     if (q.Fields[0].AsInteger <> 1) then
       WriteToErrorLog(capt+'Error #71 - Invalid field value: '+q.Fields[0].AsString);
     q.Next;
     if (q.Fields[0].AsInteger <> 2) then
       WriteToErrorLog(capt+'Error #72 - Invalid field value: '+q.Fields[0].AsString);
     q.Next;
     if (q.Fields[0].AsInteger <> 3) then
       WriteToErrorLog(capt+'Error #73 - Invalid field value: '+q.Fields[0].AsString);
     q.Next;
     if (q.Fields[0].AsInteger <> 5) then
       WriteToErrorLog(capt+'Error #74 - Invalid field value: '+q.Fields[0].AsString);
     q.Next;
     if (q.Fields[0].AsInteger <> 7) then
       WriteToErrorLog(capt+'Error #75 - Invalid field value: '+q.Fields[0].AsString);
     q.Next;
     if (q.Fields[0].AsInteger <> 8) then
       WriteToErrorLog(capt+'Error #76 - Invalid field value: '+q.Fields[0].AsString);
     q.Next;
     if (q.Fields[0].AsInteger <> 10) then
       WriteToErrorLog(capt+'Error #77 - Invalid field value: '+q.Fields[0].AsString);
     q.Next;
     if (not q.Eof) then
        WriteToErrorLog(capt+'error #78 - not EOF!');
    end;

    q.SQL.Text := ' SELECT COUNT(*) FROM (SELECT DISTINCT First_Name FROM coders)';
    q.Open;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    if (q.RecordCount <> 1) then
     WriteToErrorLog(capt+'Error #47 - Invalid recordcount = '+IntToStr(q.RecordCount));
    if (q.Fields[0].AsInteger <> 9) then
     WriteToErrorLog(capt+'Error #48 - Invalid field value: '+q.Fields[1].AsString);

    q.SQL.Text := 'SELECT TOP 1 Test.ID,IFNULL(test1.ID, "None") FROM Test LEFT JOIN Test1 ON (Test.ID = Test1.ID)';
    q.Open;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    if (q.RecordCount <> 1) then
     WriteToErrorLog(capt+'Error #45 - Invalid recordcount = '+IntToStr(q.RecordCount));
    if (q.Fields[1].AsString <> 'None') then
     WriteToErrorLog(capt+'Error #46 - Invalid field value: '+q.Fields[1].AsString);


    q.SQL.Text := 'SELECT TOP 1 First_Name, CAST(Experience AS CHAR(10)) FROM coders Order By 1';
    q.Open;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    if (q.RecordCount <> 1) then
     WriteToErrorLog(capt+'Error #42 - Invalid recordcount = '+IntToStr(q.RecordCount));
    if (q.Fields[0].AsString <> 'Arthur') then
     WriteToErrorLog(capt+'Error #43 - Invalid field value: '+q.Fields[0].AsString);
    if (q.Fields[1].AsString <> '4') then
     WriteToErrorLog(capt+'Error #44 - Invalid field value: '+q.Fields[1].AsString);


    q.SQL.Text := 'SELECT TOP 1 TRIM(LEADING "M" FROM "MADAM") FROM TABLES';
    q.Open;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    if (q.RecordCount <> 1) then
     WriteToErrorLog(capt+'Error #36 - Invalid recordcount = '+IntToStr(q.RecordCount));
    if (q.Fields[0].AsString <> 'ADAM') then
     WriteToErrorLog(capt+'Error #37 - Invalid field value: '+q.Fields[0].AsString);

    q.SQL.Text := 'SELECT TOP 1 TRIM(TRAILING "M" FROM "MADAM") FROM TABLES';
    q.Open;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    if (q.RecordCount <> 1) then
     WriteToErrorLog(capt+'Error #38 - Invalid recordcount = '+IntToStr(q.RecordCount));
    if (q.Fields[0].AsString <> 'MADA') then
     WriteToErrorLog(capt+'Error #39 - Invalid field value: '+q.Fields[0].AsString);

    q.SQL.Text := 'SELECT TOP 1 TRIM(BOTH "M" FROM "MADAM") FROM TABLES';
    q.Open;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    if (q.RecordCount <> 1) then
     WriteToErrorLog(capt+'Error #40 - Invalid recordcount = '+IntToStr(q.RecordCount));
    if (q.Fields[0].AsString <> 'ADA') then
     WriteToErrorLog(capt+'Error #41 - Invalid field value: '+q.Fields[0].AsString);

    // order by Leader_ID works in abs, order by 1 - does not
    q.SQL.Text := 'SELECT * FROM projects WHERE Cost>=100 UNION CORRESPONDING BY (Leader_ID, Coders, Caption, Cost) SELECT * FROM projects WHERE Leader_ID=2 ORDER BY 1,4';
    q.Open;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    if (q.FieldCount <> 4) then
     WriteToErrorLog(capt+'Error #34 - Invalid field count = '+IntToStr(q.FieldCount))
    else
    if (UpperCase(q.Fields[0].FieldName) <> 'LEADER_ID') or
       (UpperCase(q.Fields[1].FieldName) <> 'CODERS') or
       (UpperCase(q.Fields[2].FieldName) <> 'CAPTION') or
       (UpperCase(q.Fields[3].FieldName) <> 'COST') then
     WriteToErrorLog(capt+'Error #35 - Invalid field names: '+q.Fields[0].FieldName+#9+q.Fields[1].FieldName+#9+q.Fields[2].FieldName+#9+q.Fields[3].FieldName)
    else
    if (q.RecordCount <> 5) then
     WriteToErrorLog(capt+'Error #27 - Invalid record count = '+IntToStr(q.RecordCount))
    else
    begin
     if (q.Fields[0].AsInteger <> 2) or (q.Fields[3].AsFloat <> 10) then
      WriteToErrorLog(capt+'Error #28: '+q.Fields[0].AsString+#9+q.Fields[3].AsString);
     q.Next;
     if (q.Fields[0].AsInteger <> 2) or (q.Fields[3].AsFloat <> 100) then
      WriteToErrorLog(capt+'Error #29: '+q.Fields[0].AsString+#9+q.Fields[3].AsString);
     q.Next;
     if (q.Fields[0].AsInteger <> 3) or (q.Fields[3].AsFloat <> 200) then
      WriteToErrorLog(capt+'Error #30: '+q.Fields[0].AsString+#9+q.Fields[3].AsString);
     q.Next;
     if (q.Fields[0].AsInteger <> 5) or (q.Fields[3].AsFloat <> 200) then
      WriteToErrorLog(capt+'Error #31: '+q.Fields[0].AsString+#9+q.Fields[3].AsString);
     q.Next;
     if (q.Fields[0].AsInteger <> 10) or (q.Fields[3].AsFloat <> 120) then
      WriteToErrorLog(capt+'Error #32: '+q.Fields[0].AsString+#9+q.Fields[3].AsString);
     q.Next;
     if (not q.Eof) then
        WriteToErrorLog(capt+'error #33 - not EOF!');
    end;

    // from DBDemos.adb
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);

    q.SQL.Text := 'SELECT * FROM Test UNION CORRESPONDING BY (Company) SELECT * FROM Test1 ORDER BY 1';
    q.Open;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    if (q.FieldCount <> 1) then
     WriteToErrorLog(capt+'Error #1 - Invalid field count = '+IntToStr(q.FieldCount))
    else
    if (q.RecordCount <> 3) then
     WriteToErrorLog(capt+'Error #2 - Invalid record count = '+IntToStr(q.RecordCount))
    else
    begin
     if (q.Fields[0].AsString <> 'A') then
      WriteToErrorLog(capt+'Error #3: '+q.Fields[0].AsString);
     q.Next;
     if (q.Fields[0].AsString <> 'B') then
      WriteToErrorLog(capt+'Error #4: '+q.Fields[0].AsString);
      q.Next;
     if (q.Fields[0].AsString <> 'C') then
      WriteToErrorLog(capt+'Error #5: '+q.Fields[0].AsString);
      q.Next;
      if (not q.Eof) then
        WriteToErrorLog(capt+'error #6 - not EOF!');
    end;


    q.SQL.Text :=  'INSERT INTO Test1 Values(2,"B"); '
                  +'INSERT INTO Test1 Values(5,"D"); '
                  ;
    q.ExecSQL;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    q.SQL.Text := 'SELECT * FROM Test UNION CORRESPONDING BY (ID,Company) SELECT * FROM Test1 ORDER BY 1';
    q.Open;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    if (q.FieldCount <> 2) then
     WriteToErrorLog(capt+'Error #7 - Invalid field count = '+IntToStr(q.FieldCount))
    else
    if (q.RecordCount <> 4) then
     WriteToErrorLog(capt+'Error #8 - Invalid record count = '+IntToStr(q.RecordCount))
    else
    begin
     if (q.Fields[0].AsInteger <> 1) then
      WriteToErrorLog(capt+'Error #9: '+q.Fields[0].AsString);
     q.Next;
     if (q.Fields[0].AsInteger <> 2) then
      WriteToErrorLog(capt+'Error #10: '+q.Fields[0].AsString);
      q.Next;
     if (q.Fields[0].AsInteger <> 3) then
      WriteToErrorLog(capt+'Error #11: '+q.Fields[0].AsString);
      q.Next;
     if (q.Fields[0].AsInteger <> 5) then
      WriteToErrorLog(capt+'Error #12: '+q.Fields[0].AsString);
      q.Next;
      if (not q.Eof) then
        WriteToErrorLog(capt+'error #13 - not EOF!');
    end;

    q.SQL.Text := 'SELECT * FROM Test UNION ALL CORRESPONDING BY (ID,Company) SELECT * FROM Test1 ORDER BY 1';
    q.Open;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    if (q.FieldCount <> 2) then
     WriteToErrorLog(capt+'Error #14 - Invalid field count = '+IntToStr(q.FieldCount))
    else
    if (q.RecordCount <> 5) then
     WriteToErrorLog(capt+'Error #15 - Invalid record count = '+IntToStr(q.RecordCount))
    else
    begin
     if (q.Fields[0].AsInteger <> 1) then
      WriteToErrorLog(capt+'Error #16: '+q.Fields[0].AsString);
     q.Next;
     if (q.Fields[0].AsInteger <> 2) then
      WriteToErrorLog(capt+'Error #17: '+q.Fields[0].AsString);
      q.Next;
     if (q.Fields[0].AsInteger <> 2) then
      WriteToErrorLog(capt+'Error #18: '+q.Fields[0].AsString);
      q.Next;
     if (q.Fields[0].AsInteger <> 3) then
      WriteToErrorLog(capt+'Error #19: '+q.Fields[0].AsString);
      q.Next;
     if (q.Fields[0].AsInteger <> 5) then
      WriteToErrorLog(capt+'Error #20: '+q.Fields[0].AsString);
      q.Next;
      if (not q.Eof) then
        WriteToErrorLog(capt+'error #21 - not EOF!');
    end;

    q.SQL.Text := 'SELECT * FROM Test EXCEPT CORRESPONDING BY (Company) SELECT * FROM Test1 ORDER BY 1';
    q.Open;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    if (q.FieldCount <> 1) then
     WriteToErrorLog(capt+'Error #22 - Invalid field count = '+IntToStr(q.FieldCount))
    else
    if (q.RecordCount <> 2) then
     WriteToErrorLog(capt+'Error #23 - Invalid record count = '+IntToStr(q.RecordCount))
    else
    begin
     if (q.Fields[0].AsString <> 'A') then
      WriteToErrorLog(capt+'Error #24: '+q.Fields[0].AsString);
     q.Next;
     if (q.Fields[0].AsString <> 'C') then
      WriteToErrorLog(capt+'Error #25: '+q.Fields[0].AsString);
      q.Next;
      if (not q.Eof) then
        WriteToErrorLog(capt+'error #26 - not EOF!');
    end;

    WriteToProcessLog(capt+'Finished');

  finally
    q.SQL.Text := 'DROP TABLE Test CASCADE; DROP TABLE Test1 CASCADE; DROP TABLE coders CASCADE; DROP TABLE projects CASCADE;';
    q.ExecSQL;
    q.Free;
  end;
end;



procedure TUnitTestACRQuery.TestTrim;
var q:    TACRQuery;
    capt: String;
begin
  capt := 'TestTrim - ';
  q := TACRQuery.Create(nil);
  try
    WriteToProcessLog(capt+'Starting...');
    q.InMemory := True;
    q.SQL.Text :=  'CREATE TABLE IF NOT EXISTS Test (str1 Char(10), str2 WideChar(10),id AutoInc, Primary Key(id)); '
                  +'INSERT INTO Test Values("A","A"); '
                  +'INSERT INTO Test Values("AAABVAA","AAABVAA"); '
                  +'INSERT INTO Test Values(NULL,NULL,NULL); '
                  ;
    q.ExecSQL;
    WriteToProcessLog(capt+'DB created');
    // last error: 20

    // LEADING
    q.SQL.Text := 'SELECT TRIM(LEADING "A" FROM str1) as TrimA, TRIM(LEADING "A" FROM str2) as TrimW, id FROM Test ORDER BY id';
    q.Open;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    if (q.RecordCount <> 3) then
     WriteToErrorLog(capt+'Error #1 - Invalid recordcount = '+IntToStr(q.RecordCount))
    else
    begin
      if (not q.Fields[0].IsNull) or (not q.Fields[1].IsNull) or (q.Fields[2].AsInteger <> 1) then
       WriteToErrorLog(capt+'Error #2 - Invalid field value: '+q.Fields[0].AsString+#9+q.Fields[1].AsString+#9+q.Fields[2].AsString);
      q.Next;
      if (q.Fields[0].AsString <> 'BVAA') or (q.Fields[1].AsString <> 'BVAA') or (q.Fields[2].AsInteger <> 2) then
       WriteToErrorLog(capt+'Error #3 - Invalid field value: '+q.Fields[0].AsString+#9+q.Fields[1].AsString+#9+q.Fields[2].AsString);
      q.Next;
      if (not q.Fields[0].IsNull) or (not q.Fields[1].IsNull) or (q.Fields[2].AsInteger <> 3) then
       WriteToErrorLog(capt+'Error #4 - Invalid field value: '+q.Fields[0].AsString+#9+q.Fields[1].AsString+#9+q.Fields[2].AsString);
      q.Next;
      if (not q.Eof) then
        WriteToErrorLog(capt+'error #5 - not EOF!');
    end;
    // TRAILING
    q.SQL.Text := 'SELECT TRIM(TRAILING "A" FROM str1) as TrimA, TRIM(TRAILING "A" FROM str2) as TrimW, id FROM Test ORDER BY id';
    q.Open;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    if (q.RecordCount <> 3) then
     WriteToErrorLog(capt+'Error #6 - Invalid recordcount = '+IntToStr(q.RecordCount))
    else
    begin
      if (not q.Fields[0].IsNull) or (not q.Fields[1].IsNull) or (q.Fields[2].AsInteger <> 1) then
       WriteToErrorLog(capt+'Error #7 - Invalid field value: '+q.Fields[0].AsString+#9+q.Fields[1].AsString+#9+q.Fields[2].AsString);
      q.Next;
      if (q.Fields[0].AsString <> 'AAABV') or (q.Fields[1].AsString <> 'AAABV') or (q.Fields[2].AsInteger <> 2) then
       WriteToErrorLog(capt+'Error #8 - Invalid field value: '+q.Fields[0].AsString+#9+q.Fields[1].AsString+#9+q.Fields[2].AsString);
      q.Next;
      if (not q.Fields[0].IsNull) or (not q.Fields[1].IsNull) or (q.Fields[2].AsInteger <> 3) then
       WriteToErrorLog(capt+'Error #9 - Invalid field value: '+q.Fields[0].AsString+#9+q.Fields[1].AsString+#9+q.Fields[2].AsString);
      q.Next;
      if (not q.Eof) then
        WriteToErrorLog(capt+'error #10 - not EOF!');
    end;
    // BOTH
    q.SQL.Text := 'SELECT TRIM(BOTH "A" FROM str1) as TrimA, TRIM(BOTH "A" FROM str2) as TrimW, id FROM Test ORDER BY id';
    q.Open;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    if (q.RecordCount <> 3) then
     WriteToErrorLog(capt+'Error #11 - Invalid recordcount = '+IntToStr(q.RecordCount))
    else
    begin
      if (not q.Fields[0].IsNull) or (not q.Fields[1].IsNull) or (q.Fields[2].AsInteger <> 1) then
       WriteToErrorLog(capt+'Error #12 - Invalid field value: '+q.Fields[0].AsString+#9+q.Fields[1].AsString+#9+q.Fields[2].AsString);
      q.Next;
      if (q.Fields[0].AsString <> 'BV') or (q.Fields[1].AsString <> 'BV') or (q.Fields[2].AsInteger <> 2) then
       WriteToErrorLog(capt+'Error #13 - Invalid field value: '+q.Fields[0].AsString+#9+q.Fields[1].AsString+#9+q.Fields[2].AsString);
      q.Next;
      if (not q.Fields[0].IsNull) or (not q.Fields[1].IsNull) or (q.Fields[2].AsInteger <> 3) then
       WriteToErrorLog(capt+'Error #14 - Invalid field value: '+q.Fields[0].AsString+#9+q.Fields[1].AsString+#9+q.Fields[2].AsString);
      q.Next;
      if (not q.Eof) then
        WriteToErrorLog(capt+'error #15 - not EOF!');
    end;
    q.SQL.Text := 'EMPTY TABLE If Exists Test';
    q.ExecSQL;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    q.SQL.Text :=  'DROP TABLE Test CASCADE; CREATE TABLE Test (str1 Char(10), str2 WideChar(10),id AutoInc, Primary Key(id)); '
                  +'INSERT INTO Test Values(" "," "); '
                  +'INSERT INTO Test Values("   BV  ","   BV  "); '
                  +'INSERT INTO Test Values(NULL,NULL,NULL); '
                  ;
    q.ExecSQL;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    q.SQL.Text := 'SELECT TRIM(str1) as TrimA, TRIM(str2) as TrimW, id FROM Test ORDER BY id';
    q.Open;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    if (q.RecordCount <> 3) then
     WriteToErrorLog(capt+'Error #16 - Invalid recordcount = '+IntToStr(q.RecordCount))
    else
    begin
      if (not q.Fields[0].IsNull) or (not q.Fields[1].IsNull) or (q.Fields[2].AsInteger <> 1) then
       WriteToErrorLog(capt+'Error #17 - Invalid field value: '+q.Fields[0].AsString+#9+q.Fields[1].AsString+#9+q.Fields[2].AsString);
      q.Next;
      if (q.Fields[0].AsString <> 'BV') or (q.Fields[1].AsString <> 'BV') or (q.Fields[2].AsInteger <> 2) then
       WriteToErrorLog(capt+'Error #18 - Invalid field value: '+q.Fields[0].AsString+#9+q.Fields[1].AsString+#9+q.Fields[2].AsString);
      q.Next;
      if (not q.Fields[0].IsNull) or (not q.Fields[1].IsNull) or (q.Fields[2].AsInteger <> 3) then
       WriteToErrorLog(capt+'Error #19 - Invalid field value: '+q.Fields[0].AsString+#9+q.Fields[1].AsString+#9+q.Fields[2].AsString);
      q.Next;
      if (not q.Eof) then
        WriteToErrorLog(capt+'error #20 - not EOF!');
    end;
  finally
    q.SQL.Text := 'DROP TABLE Test CASCADE';
    q.ExecSQL;
    q.Free;
  end;
end; // TestTrim

procedure TUnitTestACRQuery.TestBrunner_08_03_2010;
var q:    TACRQuery;
    capt: String;
begin
  capt := 'TestBrunner_08_03_2010 - ';
  q := TACRQuery.Create(nil);
  try
    WriteToProcessLog(capt+'Starting...');
    q.InMemory := True;
    q.SQL.Text :=  'CREATE TABLE IF NOT EXISTS Test (id AutoInc, str Char(10), Primary Key(id)); '
                  +'INSERT INTO Test Values(NULL,"aaa"); '
                  +'INSERT INTO Test Values(NULL,"bbb"); '
                  ;
    q.ExecSQL;
    WriteToProcessLog(capt+'DB created');
    // last error: 6
//
    q.RequestLive := True;
    q.SQL.Text := 'select ID from (select * from Test) AS A WHERE id = 2';
    q.Open;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    if (q.RecordCount <> 1) then
     WriteToErrorLog(capt+'Error #1 - Invalid recordcount = '+IntToStr(q.RecordCount))
    else
    begin
      if (q.Fields[0].AsInteger <> 2) then
       WriteToErrorLog(capt+'Error #2 - Invalid field value: '+q.Fields[0].AsString);
      q.Next;
      if (not q.Eof) then
        WriteToErrorLog(capt+'error #3 - not EOF!');
    end;

    q.SQL.Text := 'select ID from (select * from Test where str = "bbb")';
    q.Open;
    WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
    if (q.RecordCount <> 1) then
     WriteToErrorLog(capt+'Error #4 - Invalid recordcount = '+IntToStr(q.RecordCount))
    else
    begin
      if (q.Fields[0].AsInteger <> 2) then
       WriteToErrorLog(capt+'Error #5 - Invalid field value: '+q.Fields[0].AsString);
      q.Next;
      if (not q.Eof) then
        WriteToErrorLog(capt+'error #6 - not EOF!');
    end;
  finally
    q.SQL.Text := 'DROP TABLE Test CASCADE';
    q.ExecSQL;
    q.Free;
  end;
end;

procedure TUnitTestACRQuery.TestBrunner_13_12_2010;
var q:    TACRQuery;
    capt: String;
begin
  capt := 'TestBrunner_08_03_2010 - ';
  q := TACRQuery.Create(nil);
  try
    WriteToProcessLog(capt+'Starting...');
    q.InMemory := True;
    q.SQL.LoadFromFile(SQLDir+'brunner_13_12_2010.sql');
    q.ExecSQL;
    WriteToProcessLog(capt+'DB created...');
    q.SQL.Text := 'SELECT ID , Objekt , MAX ( Faellig ) AS Faellig'
+#13#10+'FROM ('
+#13#10+'SELECT ID , Objekt , OrigFaellig AS Faellig'
+#13#10+'FROM ('
+#13#10+'SELECT ID , Objekt , BaldFaellig , DATEADD ( year , 1 , Datum ) AS OrigFaellig'
+#13#10+'FROM ('
+#13#10+'SELECT Ue . ID AS ID , Ue . ID_Objekt AS Objekt , Ue . Turnus AS Turnus , UeDef . BaldFaelligTage AS BaldFaellig , Gesch . Datum AS Datum'
+#13#10+'FROM EUeberwachungen Ue'
+#13#10+'JOIN EGeschichte Gesch ON Gesch . ID_Objekt = Ue . ID_Objekt AND Gesch . ID_UeberwachungDef = Ue . ID_UeberwachungDef'
+#13#10+'JOIN EUeberwachungDef UeDef ON UeDef . ID = Ue . ID_UeberwachungDef'
+#13#10+'WHERE Ue . DefaultTurnus = FALSE AND Ue . TurnusEinheit = 360 AND UeDef . ID_LeistungDef = 20 AND Ue . Aktiv = TRUE'

+#13#10+'UNION'
+#13#10+'('
+#13#10+'SELECT Ue . ID AS ID , Ue . ID_Objekt AS Objekt , UeDef . DefTurnus AS Turnus , UeDef . BaldFaelligTage AS BaldFaellig , Gesch . Datum AS Datum'
+#13#10+'FROM EUeberwachungen Ue'
+#13#10+'JOIN EGeschichte Gesch ON Gesch . ID_Objekt = Ue . ID_Objekt AND Gesch . ID_UeberwachungDef = Ue . ID_UeberwachungDef'
+#13#10+'JOIN EUeberwachungDef UeDef ON UeDef . ID = Ue . ID_UeberwachungDef'
+#13#10+'WHERE Ue . DefaultTurnus = TRUE AND UeDef . DefTurnusEinheit = 360 AND UeDef . ID_LeistungDef = 20 AND Ue . Aktiv = TRUE ) ) AS Jahr'

+#13#10+'UNION'
+#13#10+'('
+#13#10+'SELECT ID , Objekt , BaldFaellig , DATEADD ( month , 1 , Datum ) AS OrigFaellig'
+#13#10+'FROM ('
+#13#10+'SELECT Ue . ID AS ID , Ue . ID_Objekt AS Objekt , Ue . Turnus AS Turnus , UeDef . BaldFaelligTage AS BaldFaellig , Gesch . Datum AS Datum'
+#13#10+'FROM EUeberwachungen Ue'
+#13#10+'JOIN EGeschichte Gesch ON Gesch . ID_Objekt = Ue . ID_Objekt AND Gesch . ID_UeberwachungDef = Ue . ID_UeberwachungDef'
+#13#10+'JOIN EUeberwachungDef UeDef ON UeDef . ID = Ue . ID_UeberwachungDef'
+#13#10+'WHERE Ue . DefaultTurnus = FALSE AND Ue . TurnusEinheit = 30 AND UeDef . ID_LeistungDef = 20 AND Ue . Aktiv = TRUE'

+#13#10+'UNION'
+#13#10+'('
+#13#10+'SELECT Ue . ID AS ID , Ue . ID_Objekt AS Objekt , UeDef . DefTurnus AS Turnus , UeDef . BaldFaelligTage AS BaldFaellig , Gesch . Datum AS Datum FROM EUeberwachungen Ue'
+#13#10+'JOIN EGeschichte Gesch ON Gesch . ID_Objekt = Ue . ID_Objekt AND Gesch . ID_UeberwachungDef = Ue . ID_UeberwachungDef'
+#13#10+'JOIN EUeberwachungDef UeDef ON UeDef . ID = Ue . ID_UeberwachungDef'

+#13#10+'WHERE Ue . DefaultTurnus = TRUE AND UeDef . DefTurnusEinheit = 30 AND UeDef . ID_LeistungDef = 20 AND Ue . Aktiv = TRUE ) ) AS Monat'
+#13#10+'UNION'
+#13#10+'('
+#13#10+'SELECT ID , Objekt , BaldFaellig , DATEADD ( day , 1 , Datum ) AS OrigFaellig'
+#13#10+'FROM ('
+#13#10+'SELECT Ue . ID AS ID , Ue . ID_Objekt AS Objekt , Ue . Turnus AS Turnus , UeDef . BaldFaelligTage AS BaldFaellig , Gesch . Datum AS Datum'
+#13#10+'FROM EUeberwachungen Ue JOIN EGeschichte Gesch ON Gesch . ID_Objekt = Ue . ID_Objekt AND Gesch . ID_UeberwachungDef = Ue . ID_UeberwachungDef'
+#13#10+'JOIN EUeberwachungDef UeDef ON UeDef . ID = Ue . ID_UeberwachungDef'
+#13#10+'WHERE Ue . DefaultTurnus = FALSE AND Ue . TurnusEinheit = 1 AND UeDef . ID_LeistungDef = 20 AND Ue . Aktiv = TRUE'
+#13#10+'UNION'
+#13#10+'('
+#13#10+'SELECT Ue . ID AS ID , Ue . ID_Objekt AS Objekt , UeDef . DefTurnus AS Turnus , UeDef . BaldFaelligTage AS BaldFaellig , Gesch . Datum AS Datum'
+#13#10+'FROM EUeberwachungen Ue'
+#13#10+'JOIN EGeschichte Gesch ON Gesch . ID_Objekt = Ue . ID_Objekt AND Gesch . ID_UeberwachungDef = Ue . ID_UeberwachungDef'
+#13#10+'JOIN EUeberwachungDef UeDef ON UeDef . ID = Ue . ID_UeberwachungDef'
+#13#10+'WHERE Ue . DefaultTurnus = TRUE AND UeDef . DefTurnusEinheit = 1 AND UeDef . ID_LeistungDef = 20 AND Ue . Aktiv = TRUE ) ) AS Tag'
+#13#10+') ) ) AS F ) AS Faellige'
+#13#10+'GROUP BY ID , Objekt'
;
   q.Open;
   if (q.RecordCount <> 1) then
    WriteToErrorLog(capt+'Invalid RecordCount = '+IntToStr(q.RecordCount));
   WriteToProcessLog(capt+'Query executed: '+#13#10+q.SQL.Text);
//
  finally
    q.SQL.Text := 'DROP TABLE EGeschichte CASCADE; DROP TABLE EUeberwachungDef CASCADE; DROP TABLE EUeberwachungen CASCADE;';
    q.ExecSQL;
    q.Free;
  end;
end;


procedure TUnitTestACRQuery.TestExtract;
var q:      TACRQuery;
    capt:   String;
begin
  capt := 'TestExtract - ';
  q := TACRQuery.Create(nil);
  try
    WriteToProcessLog(capt+'Starting...');
    q.InMemory := True;
    q.SQL.Text :=  'CREATE TABLE test_extract(dt DATETIME); INSERT INTO test_extract '
                  +'VALUES (TODATE("26.02.1965 14:53:48.576","DD.MM.YYYY HH24:NN:SS.ZZZ"))';
    q.ExecSQL;
    WriteToProcessLog(capt+'table created');

    // last error: 30

    // year
    q.SQL.Text := 'SELECT EXTRACT(YEAR FROM dt), YEAR(dt) FROM test_extract';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 1) then
      WriteToErrorLog(capt+'Error #1 rc = '+IntToStr(q.RecordCount))
    else
    if (q.FieldCount <> 2) then
      WriteToErrorLog(capt+'Error #2 fc = '+IntToStr(q.FieldCount))
    else
    if (q.Fields[0].AsInteger <> 1965) or (q.Fields[1].AsInteger <> 1965) then
      WriteToErrorLog(capt+'Error #3: '+q.Fields[0].AsString +#9+q.Fields[1].AsString)
    else
      WriteToProcessLog(capt+'OK !!!'+#13#10+#13#10);

    // quarter
    q.SQL.Text := 'SELECT EXTRACT(QUARTER FROM dt), QUARTER(dt) FROM test_extract';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 1) then
      WriteToErrorLog(capt+'Error #4 rc = '+IntToStr(q.RecordCount))
    else
    if (q.FieldCount <> 2) then
      WriteToErrorLog(capt+'Error #5 fc = '+IntToStr(q.FieldCount))
    else
    if (q.Fields[0].AsInteger <> 1) or (q.Fields[1].AsInteger <> 1) then
      WriteToErrorLog(capt+'Error #6: '+q.Fields[0].AsString +#9+q.Fields[1].AsString)
    else
      WriteToProcessLog(capt+'OK !!!'+#13#10+#13#10);

    // month - 1:12
    q.SQL.Text := 'SELECT EXTRACT(MONTH FROM dt), MONTH(dt) FROM test_extract';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 1) then
      WriteToErrorLog(capt+'Error #7 rc = '+IntToStr(q.RecordCount))
    else
    if (q.FieldCount <> 2) then
      WriteToErrorLog(capt+'Error #8 fc = '+IntToStr(q.FieldCount))
    else
    if (q.Fields[0].AsInteger <> 2) or (q.Fields[1].AsInteger <> 2) then
      WriteToErrorLog(capt+'Error #9: '+q.Fields[0].AsString +#9+q.Fields[1].AsString)
    else
      WriteToProcessLog(capt+'OK !!!'+#13#10+#13#10);

    // month name: January, February, etc.
    q.SQL.Text := 'SELECT EXTRACT(MONTHNAME FROM dt), MONTHNAME(dt) FROM test_extract';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 1) then
      WriteToErrorLog(capt+'Error #10 rc = '+IntToStr(q.RecordCount))
    else
    if (q.FieldCount <> 2) then
      WriteToErrorLog(capt+'Error #11 fc = '+IntToStr(q.FieldCount))
    else
    if (q.Fields[0].AsString <> 'February') or (q.Fields[1].AsString <> 'February') then
      WriteToErrorLog(capt+'Error #12: '+q.Fields[0].AsString +#9+q.Fields[1].AsString)
    else
      WriteToProcessLog(capt+'OK !!!'+#13#10+#13#10);

    // week day
    q.SQL.Text := 'SELECT EXTRACT(WEEKDAY FROM dt), WEEKDAY(dt) FROM test_extract';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 1) then
      WriteToErrorLog(capt+'Error #13 rc = '+IntToStr(q.RecordCount))
    else
    if (q.FieldCount <> 2) then
      WriteToErrorLog(capt+'Error #14 fc = '+IntToStr(q.FieldCount))
    else
    if (q.Fields[0].AsInteger <> 6) or (q.Fields[1].AsInteger <> 6) then
      WriteToErrorLog(capt+'Error #15: '+q.Fields[0].AsString +#9+q.Fields[1].AsString)
    else
      WriteToProcessLog(capt+'OK !!!'+#13#10+#13#10);

    // day of week
    q.SQL.Text := 'SELECT EXTRACT(DAYOFWEEK FROM dt), DAYOFWEEK(dt) FROM test_extract';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 1) then
      WriteToErrorLog(capt+'Error #16 rc = '+IntToStr(q.RecordCount))
    else
    if (q.FieldCount <> 2) then
      WriteToErrorLog(capt+'Error #17 fc = '+IntToStr(q.FieldCount))
    else
    if (q.Fields[0].AsInteger <> 5) or (q.Fields[1].AsInteger <> 5) then
      WriteToErrorLog(capt+'Error #18: '+q.Fields[0].AsString +#9+q.Fields[1].AsString)
    else
      WriteToProcessLog(capt+'OK !!!'+#13#10+#13#10);

    // day of year
    q.SQL.Text := 'SELECT EXTRACT(DAY FROM dt), DAY(dt) FROM test_extract';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 1) then
      WriteToErrorLog(capt+'Error #19 rc = '+IntToStr(q.RecordCount))
    else
    if (q.FieldCount <> 2) then
      WriteToErrorLog(capt+'Error #20 fc = '+IntToStr(q.FieldCount))
    else
    if (q.Fields[0].AsInteger <> 26) or (q.Fields[1].AsInteger <> 26) then
      WriteToErrorLog(capt+'Error #21: '+q.Fields[0].AsString +#9+q.Fields[1].AsString)
    else
      WriteToProcessLog(capt+'OK !!!'+#13#10+#13#10);

    // day of year
    q.SQL.Text := 'SELECT EXTRACT(DAYOFYEAR FROM dt), DAYOFYEAR(dt) FROM test_extract';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 1) then
      WriteToErrorLog(capt+'Error #22 rc = '+IntToStr(q.RecordCount))
    else
    if (q.FieldCount <> 2) then
      WriteToErrorLog(capt+'Error #23 fc = '+IntToStr(q.FieldCount))
    else
    if (q.Fields[0].AsInteger <> 57) or (q.Fields[1].AsInteger <> 57) then
      WriteToErrorLog(capt+'Error #24: '+q.Fields[0].AsString +#9+q.Fields[1].AsString)
    else
      WriteToProcessLog(capt+'OK !!!'+#13#10+#13#10);

    // ISO week
    q.SQL.Text := 'SELECT EXTRACT(ISOWEEK FROM dt), ISOWEEK(dt) FROM test_extract';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 1) then
      WriteToErrorLog(capt+'Error #25 rc = '+IntToStr(q.RecordCount))
    else
    if (q.FieldCount <> 2) then
      WriteToErrorLog(capt+'Error #26 fc = '+IntToStr(q.FieldCount))
    else
    if (q.Fields[0].AsInteger <> 8) or (q.Fields[1].AsInteger <> 8) then
      WriteToErrorLog(capt+'Error #27: '+q.Fields[0].AsString +#9+q.Fields[1].AsString)
    else
      WriteToProcessLog(capt+'OK !!!'+#13#10+#13#10);

    // ISO week
    q.SQL.Text := 'SELECT EXTRACT(WEEK FROM dt), WEEK(dt) FROM test_extract';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 1) then
      WriteToErrorLog(capt+'Error #28 rc = '+IntToStr(q.RecordCount))
    else
    if (q.FieldCount <> 2) then
      WriteToErrorLog(capt+'Error #29 fc = '+IntToStr(q.FieldCount))
    else
    if (q.Fields[0].AsInteger <> 9) or (q.Fields[1].AsInteger <> 9) then
      WriteToErrorLog(capt+'Error #30: '+q.Fields[0].AsString +#9+q.Fields[1].AsString)
    else
      WriteToProcessLog(capt+'OK !!!'+#13#10+#13#10);
  finally
    q.SQL.Text := 'DROP TABLE test_extract';
    q.ExecSQL;
    q.Free;
  end;
end; // TestExtract

procedure TUnitTestACRQuery.TestVclDb;
var q:         TACRQuery;
    capt,s:    String;
begin
  capt := 'TestVclDb - ';
  q := TACRQuery.Create(nil);
  try
    WriteToProcessLog(capt+'Starting...');
    q.InMemory := True;
    q.SQL.LoadFromFile(SQLDir+'test_vcl_db.sql');
    q.ExecSQL;
    WriteToProcessLog(capt+'table created');

    // last error: 383
    s := ShortDateFormat;
    ShortDateFormat := 'M/D/YYYY';

    q.SQL.Text := 'SELECT CASE Gender WHEN ''F'' THEN ''Female'' ELSE ''Male'' END FROM emp ORDER BY Name';
    q.Open;
    if (q.RecordCount <> 6) then
      WriteToErrorLog(capt+'Error #375 rc = '+IntToStr(q.RecordCount));
    if (q.FieldCount <> 1) then
      WriteToErrorLog(capt+'Error #376 fc = '+IntToStr(q.FieldCount));
    if (q.Fields[0].AsString <> 'Female') then
      WriteToErrorLog(capt+'Error #377: '+q.Fields[0].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Female') then
      WriteToErrorLog(capt+'Error #378: '+q.Fields[0].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Female') then
      WriteToErrorLog(capt+'Error #379: '+q.Fields[0].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Female') then
      WriteToErrorLog(capt+'Error #380: '+q.Fields[0].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Male') then
      WriteToErrorLog(capt+'Error #381: '+q.Fields[0].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Male') then
      WriteToErrorLog(capt+'Error #382: '+q.Fields[0].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #383 - not EOF!');

    q.SQL.Text := 'SELECT * FROM orders WHERE CAST(Mileage AS CHAR(20)) <> ''''';
    q.Open;
    if (q.RecordCount <> 4) then
      WriteToErrorLog(capt+'Error #374 rc = '+IntToStr(q.RecordCount));

    q.SQL.Text := 'SELECT * FROM emp WHERE Name BETWEEN ''L'' and ''M''';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 1) then
      WriteToErrorLog(capt+'Error #364 rc = '+IntToStr(q.RecordCount));
    if (q.FieldCount <> 7) then
      WriteToErrorLog(capt+'Error #365 fc = '+IntToStr(q.FieldCount));
    if (q.Fields[0].AsInteger <> 5) then
      WriteToErrorLog(capt+'Error #366: '+q.Fields[0].AsString);
    if (q.Fields[1].AsString <> 'Laura') then
      WriteToErrorLog(capt+'Error #367: '+q.Fields[1].AsString);
    if (q.Fields[2].AsString <> 'Bright') then
      WriteToErrorLog(capt+'Error #368: '+q.Fields[2].AsString);
    if (q.Fields[3].AsInteger <> 13000) then
      WriteToErrorLog(capt+'Error #369: '+q.Fields[3].AsString);
    if (q.Fields[4].AsString <> 'F') then
      WriteToErrorLog(capt+'Error #370: '+q.Fields[4].AsString);
    if (q.Fields[5].AsString <> '12/31/1987') then
      WriteToErrorLog(capt+'Error #371: '+q.Fields[5].AsString);
    if (q.Fields[6].AsInteger <> 2) then
      WriteToErrorLog(capt+'Error #372: '+q.Fields[6].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #373 - not EOF!');

    q.SQL.Text := 'CREATE TABLE type30 (f1 NUMERIC(11,2),f2 DECIMAL(15)); INSERT INTO type30 VALUES(1234567890.97,-123456789012345); SELECT * FROM type30;';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 1) then
      WriteToErrorLog(capt+'Error #359 rc = '+IntToStr(q.RecordCount));
    if (q.FieldCount <> 2) then
      WriteToErrorLog(capt+'Error #360 fc = '+IntToStr(q.FieldCount));
    if (q.Fields[0].Value <> 1234567890.97) or (q.Fields[0].AsString <> '1234567890.97') then
      WriteToErrorLog(capt+'Error #361: '+q.Fields[0].AsString);
    if (TLargeintField(q.Fields[1]).AsLargeInt <> Int64(-123456789012345)) or (q.Fields[1].AsString <> '-123456789012345') then
      WriteToErrorLog(capt+'Error #362: '+q.Fields[1].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #363 - not EOF!');
    q.SQL.Text := 'DROP TABLE type30';
    q.ExecSQL;

    q.SQL.Text := 'CREATE TABLE type26 (f1 GUID); INSERT INTO type26 VALUES("{92DC9411-D8D6-47F2-AC3F-ECEC0230666D}"); SELECT * FROM type26;';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 1) then
      WriteToErrorLog(capt+'Error #355 rc = '+IntToStr(q.RecordCount));
    if (q.FieldCount <> 1) then
      WriteToErrorLog(capt+'Error #356 fc = '+IntToStr(q.FieldCount));
    if (q.Fields[0].AsString <> '{92DC9411-D8D6-47F2-AC3F-ECEC0230666D}') then
      WriteToErrorLog(capt+'Error #357: '+q.Fields[0].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #358 - not EOF!');
    q.SQL.Text := 'DROP TABLE type26';
    q.ExecSQL;

    q.SQL.Text := 'SELECT COUNT(*) as Quantity FROM Orders WHERE (SELECT Id FROM orders WHERE Sale_price < 10000) IS NULL';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 1) then
      WriteToErrorLog(capt+'Error #351 rc = '+IntToStr(q.RecordCount));
    if (q.FieldCount <> 1) then
      WriteToErrorLog(capt+'Error #352 fc = '+IntToStr(q.FieldCount));
    if (q.Fields[0].AsInteger <> 8) then
      WriteToErrorLog(capt+'Error #353: '+q.Fields[0].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #354 - not EOF!');

{
    q.SQL.Text := 'SELECT Name,Surname,'
                  +' ID as EMP_ID,DeptID,'
                  +' (SELECT SUM(Sale_price - Buy_price) * 0.8 FROM orders WHERE orders.empID = E.ID) AS Profit'
                  +' ,'
                  +'  (SELECT Max(Manager_Profit) as M_Profit FROM'
                  +'   (SELECT SUM(Sale_price - Buy_price) * 0.8 AS Manager_Profit'
                  +'    FROM orders AS O1,emp as E1'
                  +'    WHERE (O1.EmpID = E1.Id) AND (E1.DeptID = E.DeptID)'
                  +'    GROUP BY EmpID'
                  +'   ) AS TempTable'
                  +'  ) AS Max_Manager_Profit_Of_Department'
                  +' FROM emp AS E'
                  +' WHERE'
                  +' (SELECT SUM(Sale_price - Buy_price) * 0.8 FROM orders WHERE orders.empID = E.ID)'
                  +' ='
                  +'  (SELECT Max(Manager_Profit) as M_Profit FROM'
                  +'   (SELECT SUM(Sale_price - Buy_price) * 0.8 AS Manager_Profit'
                  +'    FROM orders AS O1,emp as E1'
                  +'    WHERE (O1.EmpID = E1.Id) AND (E1.DeptID = E.DeptID)'
                  +'    GROUP BY EmpID'
                  +'   ) AS TempTable'
                  +'  )'
                  ;

    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 2) then
      WriteToErrorLog(capt+'Error #346 rc = '+IntToStr(q.RecordCount));
    if (q.FieldCount <> 6) then
      WriteToErrorLog(capt+'Error #347 fc = '+IntToStr(q.FieldCount));
    if    (q.Fields[0].AsString <> 'Mike')
       or (q.Fields[1].AsString <> 'Tompson')
       or (q.Fields[2].AsInteger <> 1)
       or (q.Fields[3].AsInteger <> 1)
       or (q.Fields[4].AsCurrency <> 9360)
       or (q.Fields[5].AsCurrency <> 9360)
      then
      WriteToErrorLog(capt+'Error #348: '+q.Fields[0].AsString+#9+q.Fields[1].AsString+#9+q.Fields[2].AsString+#9+q.Fields[3].AsString+#9+q.Fields[4].AsString+#9+q.Fields[5].AsString);
    q.Next;
    if    (q.Fields[0].AsString <> 'Steve')
       or (q.Fields[1].AsString <> 'Masters')
       or (q.Fields[2].AsInteger <> 6)
       or (q.Fields[3].AsInteger <> 2)
       or (q.Fields[4].AsCurrency <> 12160)
       or (q.Fields[5].AsCurrency <> 12160)
      then
      WriteToErrorLog(capt+'Error #349: '+q.Fields[0].AsString+#9+q.Fields[1].AsString+#9+q.Fields[2].AsString+#9+q.Fields[3].AsString+#9+q.Fields[4].AsString+#9+q.Fields[5].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #350 - not EOF!');
}

{
    q.SQL.Text := 'SELECT Name,Surname,Salary,'
                    +' (SELECT SUM((Sale_price - Buy_price)*0.8) FROM orders AS O WHERE O.EmpID = E.Id)  AS Profit,'
                    +' (SELECT COUNT(*) FROM (SELECT DISTINCT EXTRACT(MONTH FROM Sale_date), EXTRACT(YEAR FROM Sale_date) FROM orders AS O2 WHERE O2.empID = E.Id)) AS Sale_months,'
                    +' Profit / Sale_months AS Rate'
                    +' FROM emp AS E'
                    +' ORDER BY Rate DESC'
                    ;
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 6) then
      WriteToErrorLog(capt+'Error #337 rc = '+IntToStr(q.RecordCount));
    if (q.FieldCount <> 6) then
      WriteToErrorLog(capt+'Error #338 fc = '+IntToStr(q.FieldCount));
    if    (q.Fields[0].AsString <> 'Steve')
       or (q.Fields[1].AsString <> 'Masters')
       or (q.Fields[2].AsCurrency <> 30000.00)
       or (q.Fields[3].AsInteger <> 12160)
       or (q.Fields[4].AsInteger <> 1)
       or (q.Fields[5].AsInteger <> 12160)
      then
      WriteToErrorLog(capt+'Error #339: '+q.Fields[0].AsString+#9+q.Fields[1].AsString+#9+q.Fields[2].AsString+#9+q.Fields[3].AsString+#9+q.Fields[4].AsString+#9+q.Fields[5].AsString);
    q.Next;
    if    (q.Fields[0].AsString <> 'Mike')
       or (q.Fields[1].AsString <> 'Tompson')
       or (q.Fields[2].AsCurrency <> 35000.00)
       or (q.Fields[3].AsInteger <> 9360)
       or (q.Fields[4].AsInteger <> 2)
       or (q.Fields[5].AsInteger <> 4680)
      then
      WriteToErrorLog(capt+'Error #340: '+q.Fields[0].AsString+#9+q.Fields[1].AsString+#9+q.Fields[2].AsString+#9+q.Fields[3].AsString+#9+q.Fields[4].AsString+#9+q.Fields[5].AsString);
    q.Next;
    if    (q.Fields[0].AsString <> 'Laura')
       or (q.Fields[1].AsString <> 'Bright')
       or (q.Fields[2].AsCurrency <> 13000.00)
       or (q.Fields[3].AsInteger <> 3360)
       or (q.Fields[4].AsInteger <> 1)
       or (q.Fields[5].AsInteger <> 3360)
      then
      WriteToErrorLog(capt+'Error #341: '+q.Fields[0].AsString+#9+q.Fields[1].AsString+#9+q.Fields[2].AsString+#9+q.Fields[3].AsString+#9+q.Fields[4].AsString+#9+q.Fields[5].AsString);
    q.Next;
    if    (q.Fields[0].AsString <> 'Marta')
       or (q.Fields[1].AsString <> 'Bernstein')
       or (q.Fields[2].AsCurrency <> 25000.00)
       or (q.Fields[3].AsInteger <> 2800)
       or (q.Fields[4].AsInteger <> 1)
       or (q.Fields[5].AsInteger <> 2800)
      then
      WriteToErrorLog(capt+'Error #342: '+q.Fields[0].AsString+#9+q.Fields[1].AsString+#9+q.Fields[2].AsString+#9+q.Fields[3].AsString+#9+q.Fields[4].AsString+#9+q.Fields[5].AsString);
    q.Next;
    if    (q.Fields[0].AsString <> 'Ann')
       or (q.Fields[1].AsString <> 'Swensson')
       or (q.Fields[2].AsCurrency <> 10000.00)
       or (q.Fields[3].AsInteger <> 2080)
       or (q.Fields[4].AsInteger <> 1)
       or (q.Fields[5].AsInteger <> 2080)
      then
      WriteToErrorLog(capt+'Error #343: '+q.Fields[0].AsString+#9+q.Fields[1].AsString+#9+q.Fields[2].AsString+#9+q.Fields[3].AsString+#9+q.Fields[4].AsString+#9+q.Fields[5].AsString);
    q.Next;
    if    (q.Fields[0].AsString <> 'Ann')
       or (q.Fields[1].AsString <> 'Nikolson')
       or (q.Fields[2].AsCurrency <> 12000.00)
       or (q.Fields[3].AsInteger <> 1200)
       or (q.Fields[4].AsInteger <> 1)
       or (q.Fields[5].AsInteger <> 1200)
      then
      WriteToErrorLog(capt+'Error #344: '+q.Fields[0].AsString+#9+q.Fields[1].AsString+#9+q.Fields[2].AsString+#9+q.Fields[3].AsString+#9+q.Fields[4].AsString+#9+q.Fields[5].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #345 - not EOF!');
}
    q.SQL.Text := 'SELECT (SELECT Name FROM dept AS D2 WHERE D2.ID = D.ID) AS Department,'
                  +' (SELECT Sum((Sale_price - Buy_price) * 0.8) AS Profit FROM orders,emp WHERE orders.empID = emp.ID AND emp.DeptId = D.Id) AS Total FROM dept AS D'
                  +' GROUP BY D.Id'
                  ;
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 2) then
      WriteToErrorLog(capt+'Error #332 rc = '+IntToStr(q.RecordCount));
    if (q.FieldCount <> 2) then
      WriteToErrorLog(capt+'Error #333 fc = '+IntToStr(q.FieldCount));
    if (q.Fields[0].AsString <> 'New cars department') or  (q.Fields[1].AsInteger <> 13360) then
      WriteToErrorLog(capt+'Error #334: '+q.Fields[0].AsString+#9+q.Fields[1].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Used cars department') or  (q.Fields[1].AsInteger <> 17600) then
      WriteToErrorLog(capt+'Error #335: '+q.Fields[0].AsString+#9+q.Fields[1].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #336 - not EOF!');


    q.SQL.Text := 'SELECT Count(*) FROM emp AS E WHERE  (SELECT SUM (Sale_price - Buy_price) * 0.8 FROM orders AS O WHERE O.EmpID = E.Id)  > 3000';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 1) then
      WriteToErrorLog(capt+'Error #329 rc = '+IntToStr(q.RecordCount));
    if (q.FieldCount <> 1) then
      WriteToErrorLog(capt+'Error #330 fc = '+IntToStr(q.FieldCount));
    if (q.Fields[0].AsInteger <> 3) then
      WriteToErrorLog(capt+'Error #331: '+q.Fields[0].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #332 - not EOF!');


    q.SQL.Text := 'SELECT Id,Car,Sale_price FROM orders'
+' INTERSECT'
+' SELECT Id,Car,Sale_price FROM orders WHERE Sale_price >= 35000'
+' ORDER BY Sale_price';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 5) then
      WriteToErrorLog(capt+'Error #321 rc = '+IntToStr(q.RecordCount));
    if (q.FieldCount <> 3) then
      WriteToErrorLog(capt+'Error #322 fc = '+IntToStr(q.FieldCount));
    if (q.Fields[0].AsInteger <> 2) or (q.Fields[1].AsString <> 'Audi A4') or (q.Fields[2].AsInteger <> 35000)  then
      WriteToErrorLog(capt+'Error #323: '+q.Fields[0].AsString+#9+q.Fields[1].AsString+#9+q.Fields[2].AsString);
    q.Next;
    if (q.Fields[0].AsInteger <> 5) or (q.Fields[1].AsString <> 'Ford Explorer') or (q.Fields[2].AsInteger <> 38000)  then
      WriteToErrorLog(capt+'Error #324: '+q.Fields[0].AsString+#9+q.Fields[1].AsString+#9+q.Fields[2].AsString);
    q.Next;
    if (q.Fields[0].AsInteger <> 1) or (q.Fields[1].AsString <> 'BMW X5') or (q.Fields[2].AsInteger <> 42000)  then
      WriteToErrorLog(capt+'Error #325: '+q.Fields[0].AsString+#9+q.Fields[1].AsString+#9+q.Fields[2].AsString);
    q.Next;
    if (q.Fields[0].AsInteger <> 4) or (q.Fields[1].AsString <> 'Lexus rx350') or (q.Fields[2].AsInteger <> 79000)  then
      WriteToErrorLog(capt+'Error #326: '+q.Fields[0].AsString+#9+q.Fields[1].AsString+#9+q.Fields[2].AsString);
    q.Next;
    if (q.Fields[0].AsInteger <> 8) or (q.Fields[1].AsString <> 'Volkswagen Touareg ') or (q.Fields[2].AsInteger <> 88000)  then
      WriteToErrorLog(capt+'Error #327: '+q.Fields[0].AsString+#9+q.Fields[1].AsString+#9+q.Fields[2].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #328 - not EOF!');


    q.SQL.Text := 'SELECT * FROM dept INNER JOIN emp USING (ID) ORDER BY dept.Name';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 2) then
      WriteToErrorLog(capt+'Error #316 rc = '+IntToStr(q.RecordCount));
    if (q.FieldCount <> 8) then
      WriteToErrorLog(capt+'Error #317 fc = '+IntToStr(q.FieldCount));
    if (q.Fields[0].AsInteger <> 1) or (q.Fields[1].AsString <> 'New cars department')  then
      WriteToErrorLog(capt+'Error #318: '+q.Fields[0].AsString+#9+q.Fields[1].AsString);
    q.Next;
    if (q.Fields[0].AsInteger <> 2) or (q.Fields[1].AsString <> 'Used cars department')  then
      WriteToErrorLog(capt+'Error #319: '+q.Fields[0].AsString+#9+q.Fields[1].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #320 - not EOF!');

    q.SQL.Text := 'SELECT * FROM dept NATURAL INNER JOIN dept as dept2 ORDER BY 1';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 2) then
      WriteToErrorLog(capt+'Error #311 rc = '+IntToStr(q.RecordCount));
    if (q.FieldCount <> 2) then
      WriteToErrorLog(capt+'Error #312 fc = '+IntToStr(q.FieldCount));
    if (q.Fields[0].AsInteger <> 1) or (q.Fields[1].AsString <> 'New cars department')  then
      WriteToErrorLog(capt+'Error #313: '+q.Fields[0].AsString+#9+q.Fields[1].AsString);
    q.Next;
    if (q.Fields[0].AsInteger <> 2) or (q.Fields[1].AsString <> 'Used cars department')  then
      WriteToErrorLog(capt+'Error #314: '+q.Fields[0].AsString+#9+q.Fields[1].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #315 - not EOF!');


{
    q.SQL.Text := 'SELECT Car,Sale_price,Sale_date, E.Name, e.Surname, E.ID FROM emp AS E FULL JOIN orders AS O ON O.EmpID = E.ID AND E.ID IN (1,3,4) AND (Car NOT LIKE ''Ford%'') ORDER BY Car, E.ID';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 13) then
      WriteToErrorLog(capt+'Error #296 rc = '+IntToStr(q.RecordCount));
    if (q.FieldCount <> 6) then
      WriteToErrorLog(capt+'Error #297 fc = '+IntToStr(q.FieldCount));
    if (not q.Fields[0].IsNull) or (q.Fields[5].AsInteger <> 2)  then
      WriteToErrorLog(capt+'Error #298: '+q.Fields[0].AsString+#9+q.Fields[5].AsString);
    q.Next;
    if (not q.Fields[0].IsNull) or (q.Fields[5].AsInteger <> 3)  then
      WriteToErrorLog(capt+'Error #299: '+q.Fields[0].AsString+#9+q.Fields[5].AsString);
    q.Next;
    if (not q.Fields[0].IsNull) or (q.Fields[5].AsInteger <> 4)  then
      WriteToErrorLog(capt+'Error #300: '+q.Fields[0].AsString+#9+q.Fields[5].AsString);
    q.Next;
    if (not q.Fields[0].IsNull) or (q.Fields[5].AsInteger <> 5)  then
      WriteToErrorLog(capt+'Error #301: '+q.Fields[0].AsString+#9+q.Fields[5].AsString);
    q.Next;
    if (not q.Fields[0].IsNull) or (q.Fields[5].AsInteger <> 6)  then
      WriteToErrorLog(capt+'Error #301: '+q.Fields[0].AsString+#9+q.Fields[5].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Audi A4') or (not q.Fields[5].IsNull)  then
      WriteToErrorLog(capt+'Error #302: '+q.Fields[0].AsString+#9+q.Fields[5].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'BMW X5') or (q.Fields[5].AsInteger <> 1)  then
      WriteToErrorLog(capt+'Error #303: '+q.Fields[0].AsString+#9+q.Fields[5].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Chevrolet Captiva') or (not q.Fields[5].IsNull)  then
      WriteToErrorLog(capt+'Error #304: '+q.Fields[0].AsString+#9+q.Fields[5].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Chevrolet TrailBlazer') or (not q.Fields[5].IsNull)  then
      WriteToErrorLog(capt+'Error #305: '+q.Fields[0].AsString+#9+q.Fields[5].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Ford Explorer') or (not q.Fields[5].IsNull)  then
      WriteToErrorLog(capt+'Error #306: '+q.Fields[0].AsString+#9+q.Fields[5].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Ford Focus') or (not q.Fields[5].IsNull)  then
      WriteToErrorLog(capt+'Error #307: '+q.Fields[0].AsString+#9+q.Fields[5].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Lexus rx350') or (q.Fields[5].AsInteger <> 1)  then
      WriteToErrorLog(capt+'Error #308: '+q.Fields[0].AsString+#9+q.Fields[5].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Volkswagen Touareg') or (not q.Fields[5].IsNull)  then
      WriteToErrorLog(capt+'Error #309: '+q.Fields[0].AsString+#9+q.Fields[5].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #310 - not EOF!');

{
    q.SQL.Text := 'SELECT Car,Sale_price,Sale_date, E.Name, e.Surname, E.ID FROM emp AS E FULL JOIN orders AS O ON O.EmpID = E.ID AND E.ID IN (1,3,4) ORDER BY Car, E.ID';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 11) then
      WriteToErrorLog(capt+'Error #282 rc = '+IntToStr(q.RecordCount));
    if (q.FieldCount <> 6) then
      WriteToErrorLog(capt+'Error #283 fc = '+IntToStr(q.FieldCount));
    if (not q.Fields[0].IsNull) or (q.Fields[5].AsInteger <> 2)  then
      WriteToErrorLog(capt+'Error #284: '+q.Fields[0].AsString+#9+q.Fields[5].AsString);
    q.Next;
    if (not q.Fields[0].IsNull) or (q.Fields[5].AsInteger <> 5)  then
      WriteToErrorLog(capt+'Error #285: '+q.Fields[0].AsString+#9+q.Fields[5].AsString);
    q.Next;
    if (not q.Fields[0].IsNull) or (q.Fields[5].AsInteger <> 6)  then
      WriteToErrorLog(capt+'Error #286: '+q.Fields[0].AsString+#9+q.Fields[5].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Audi A4') or (not q.Fields[5].IsNull)  then
      WriteToErrorLog(capt+'Error #287: '+q.Fields[0].AsString+#9+q.Fields[5].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'BMW X5') or (q.Fields[5].AsInteger <> 1)  then
      WriteToErrorLog(capt+'Error #288: '+q.Fields[0].AsString+#9+q.Fields[5].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Chevrolet Captiva') or (not q.Fields[5].IsNull)  then
      WriteToErrorLog(capt+'Error #289: '+q.Fields[0].AsString+#9+q.Fields[5].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Chevrolet TrailBlazer') or (not q.Fields[5].IsNull)  then
      WriteToErrorLog(capt+'Error #290: '+q.Fields[0].AsString+#9+q.Fields[5].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Ford Explorer') or (q.Fields[5].AsInteger <> 4)  then
      WriteToErrorLog(capt+'Error #291: '+q.Fields[0].AsString+#9+q.Fields[5].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Ford Focus') or (q.Fields[5].AsInteger <> 3)  then
      WriteToErrorLog(capt+'Error #292: '+q.Fields[0].AsString+#9+q.Fields[5].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Lexus rx350') or (q.Fields[5].AsInteger <> 1)  then
      WriteToErrorLog(capt+'Error #293: '+q.Fields[0].AsString+#9+q.Fields[5].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Volkswagen Touareg') or (not q.Fields[5].IsNull)  then
      WriteToErrorLog(capt+'Error #294: '+q.Fields[0].AsString+#9+q.Fields[5].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #295 - not EOF!');


    q.SQL.Text := 'SELECT E.Name,E.Surname, SUM(Sale_price - Buy_price) * 0.7 AS Profit,'
                  +' E.Salary, EXTRACT(MONTH FROM Sale_date) as Sale_month'
                  +' FROM emp AS E INNER JOIN orders AS O ON E.ID = O.EmpID'
                  +' GROUP BY E.Name, E.Surname, E.Salary,Sale_month ORDER BY E.Name, E.Surname, E.Salary, Sale_month'
                  ;
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 7) then
      WriteToErrorLog(capt+'Error #245 rc = '+IntToStr(q.RecordCount))
    else
    if (q.FieldCount <> 5) then
      WriteToErrorLog(capt+'Error #246 fc = '+IntToStr(q.FieldCount));
    if (q.Fields[0].AsString <> 'Ann')  then
      WriteToErrorLog(capt+'Error #247: '+q.Fields[0].AsString);
    if (q.Fields[1].AsString <> 'Nikolson')  then
      WriteToErrorLog(capt+'Error #248: '+q.Fields[1].AsString);
    if (q.Fields[2].AsCurrency <> 1050)  then
      WriteToErrorLog(capt+'Error #249: '+q.Fields[2].AsString);
    if (q.Fields[3].AsCurrency <> 12000)  then
      WriteToErrorLog(capt+'Error #250: '+q.Fields[3].AsString);
    if (q.Fields[4].AsInteger <> 1)  then
      WriteToErrorLog(capt+'Error #251: '+q.Fields[4].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Ann')  then
      WriteToErrorLog(capt+'Error #252: '+q.Fields[0].AsString);
    if (q.Fields[1].AsString <> 'Swensson')  then
      WriteToErrorLog(capt+'Error #253: '+q.Fields[1].AsString);
    if (q.Fields[2].AsCurrency <> 1820)  then
      WriteToErrorLog(capt+'Error #254: '+q.Fields[2].AsString);
    if (q.Fields[3].AsCurrency <> 10000)  then
      WriteToErrorLog(capt+'Error #255: '+q.Fields[3].AsString);
    if (q.Fields[4].AsInteger <> 2)  then
      WriteToErrorLog(capt+'Error #256: '+q.Fields[4].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Laura')  then
      WriteToErrorLog(capt+'Error #257: '+q.Fields[0].AsString);
    if (q.Fields[1].AsString <> 'Bright')  then
      WriteToErrorLog(capt+'Error #258: '+q.Fields[1].AsString);
    if (q.Fields[2].AsCurrency <> 2940)  then
      WriteToErrorLog(capt+'Error #259: '+q.Fields[2].AsString);
    if (q.Fields[3].AsCurrency <> 13000)  then
      WriteToErrorLog(capt+'Error #260: '+q.Fields[3].AsString);
    if (q.Fields[4].AsInteger <> 1)  then
      WriteToErrorLog(capt+'Error #261: '+q.Fields[4].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Marta')  then
      WriteToErrorLog(capt+'Error #262: '+q.Fields[0].AsString);
    if (q.Fields[1].AsString <> 'Bernstein')  then
      WriteToErrorLog(capt+'Error #263: '+q.Fields[1].AsString);
    if (q.Fields[2].AsCurrency <> 2450)  then
      WriteToErrorLog(capt+'Error #264: '+q.Fields[2].AsString);
    if (q.Fields[3].AsCurrency <> 25000)  then
      WriteToErrorLog(capt+'Error #265: '+q.Fields[3].AsString);
    if (q.Fields[4].AsInteger <> 1)  then
      WriteToErrorLog(capt+'Error #266: '+q.Fields[4].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Mike')  then
      WriteToErrorLog(capt+'Error #267: '+q.Fields[0].AsString);
    if (q.Fields[1].AsString <> 'Tompson')  then
      WriteToErrorLog(capt+'Error #268: '+q.Fields[1].AsString);
    if (q.Fields[2].AsCurrency <> 2800)  then
      WriteToErrorLog(capt+'Error #269: '+q.Fields[2].AsString);
    if (q.Fields[3].AsCurrency <> 35000)  then
      WriteToErrorLog(capt+'Error #270: '+q.Fields[3].AsString);
    if (q.Fields[4].AsInteger <> 1)  then
      WriteToErrorLog(capt+'Error #271: '+q.Fields[4].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Mike')  then
      WriteToErrorLog(capt+'Error #272: '+q.Fields[0].AsString);
    if (q.Fields[1].AsString <> 'Tompson')  then
      WriteToErrorLog(capt+'Error #273: '+q.Fields[1].AsString);
    if (q.Fields[2].AsCurrency <> 5390)  then
      WriteToErrorLog(capt+'Error #274: '+q.Fields[2].AsString);
    if (q.Fields[3].AsCurrency <> 35000)  then
      WriteToErrorLog(capt+'Error #275: '+q.Fields[3].AsString);
    if (q.Fields[4].AsInteger <> 2)  then
      WriteToErrorLog(capt+'Error #276: '+q.Fields[4].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Steve')  then
      WriteToErrorLog(capt+'Error #277: '+q.Fields[0].AsString);
    if (q.Fields[1].AsString <> 'Masters')  then
      WriteToErrorLog(capt+'Error #278: '+q.Fields[1].AsString);
    if (q.Fields[2].AsCurrency <> 10640)  then
      WriteToErrorLog(capt+'Error #279: '+q.Fields[2].AsString);
    if (q.Fields[3].AsCurrency <> 30000)  then
      WriteToErrorLog(capt+'Error #280: '+q.Fields[3].AsString);
    if (q.Fields[4].AsInteger <> 2)  then
      WriteToErrorLog(capt+'Error #281: '+q.Fields[4].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #282 - not EOF!');
}


    q.SQL.Text :=
//'SELECT ((O.Sale_price - O.Buy_price) * 0.8) AS Profit, E.Name, E.Surname, D.Name as Department'
                   'SELECT O.Car, O.Prod_year, ((O.Sale_price - O.Buy_price) * 0.8) AS Profit, E.Name, E.Surname, D.Name as Department'
                  +' FROM orders AS O INNER JOIN emp AS E ON O.empID = E.ID INNER JOIN dept as D ON E.deptID = D.ID'
                  +' WHERE (((O.Sale_price - O.Buy_price) * 0.8) > 3000) OR (O.Prod_Year >= 2009) ORDER BY Profit DESC, Car'
                  ;

    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 7) then
      WriteToErrorLog(capt+'Error #201 rc = '+IntToStr(q.RecordCount))
    else
    if (q.FieldCount <> 6) then
      WriteToErrorLog(capt+'Error #202 fc = '+IntToStr(q.FieldCount));
    if (q.Fields[0].AsString <> 'Volkswagen Touareg ')  then
      WriteToErrorLog(capt+'Error #203: '+q.Fields[0].AsString);
    if (q.Fields[1].AsString <> '2008')  then
      WriteToErrorLog(capt+'Error #204: '+q.Fields[1].AsString);
    if (q.Fields[2].AsString <> '8800')  then
      WriteToErrorLog(capt+'Error #205: '+q.Fields[2].AsString);
    if (q.Fields[3].AsString <> 'Steve')  then
      WriteToErrorLog(capt+'Error #205: '+q.Fields[3].AsString);
    if (q.Fields[4].AsString <> 'Masters')  then
      WriteToErrorLog(capt+'Error #206: '+q.Fields[4].AsString);
    if (q.Fields[5].AsString <> 'Used cars department')  then
      WriteToErrorLog(capt+'Error #207: '+q.Fields[5].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Lexus rx350')  then
      WriteToErrorLog(capt+'Error #208: '+q.Fields[0].AsString);
    if (q.Fields[1].AsString <> '2010')  then
      WriteToErrorLog(capt+'Error #209: '+q.Fields[1].AsString);
    if (q.Fields[2].AsString <> '6160')  then
      WriteToErrorLog(capt+'Error #210: '+q.Fields[2].AsString);
    if (q.Fields[3].AsString <> 'Mike')  then
      WriteToErrorLog(capt+'Error #211: '+q.Fields[3].AsString);
    if (q.Fields[4].AsString <> 'Tompson')  then
      WriteToErrorLog(capt+'Error #212: '+q.Fields[4].AsString);
    if (q.Fields[5].AsString <> 'New cars department')  then
      WriteToErrorLog(capt+'Error #213: '+q.Fields[5].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Chevrolet Captiva')  then
      WriteToErrorLog(capt+'Error #214: '+q.Fields[0].AsString);
    if (q.Fields[1].AsString <> '2006')  then
      WriteToErrorLog(capt+'Error #215: '+q.Fields[1].AsString);
    if (q.Fields[2].AsString <> '3360')  then
      WriteToErrorLog(capt+'Error #216: '+q.Fields[2].AsString);
    if (q.Fields[3].AsString <> 'Laura')  then
      WriteToErrorLog(capt+'Error #217: '+q.Fields[3].AsString);
    if (q.Fields[4].AsString <> 'Bright')  then
      WriteToErrorLog(capt+'Error #218: '+q.Fields[4].AsString);
    if (q.Fields[5].AsString <> 'Used cars department')  then
      WriteToErrorLog(capt+'Error #219: '+q.Fields[5].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Chevrolet TrailBlazer')  then
      WriteToErrorLog(capt+'Error #220: '+q.Fields[0].AsString);
    if (q.Fields[1].AsString <> '2005')  then
      WriteToErrorLog(capt+'Error #221: '+q.Fields[1].AsString);
    if (q.Fields[2].AsString <> '3360')  then
      WriteToErrorLog(capt+'Error #222: '+q.Fields[2].AsString);
    if (q.Fields[3].AsString <> 'Steve')  then
      WriteToErrorLog(capt+'Error #223: '+q.Fields[3].AsString);
    if (q.Fields[4].AsString <> 'Masters')  then
      WriteToErrorLog(capt+'Error #224: '+q.Fields[4].AsString);
    if (q.Fields[5].AsString <> 'Used cars department')  then
      WriteToErrorLog(capt+'Error #225: '+q.Fields[5].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'BMW X5')  then
      WriteToErrorLog(capt+'Error #226: '+q.Fields[0].AsString);
    if (q.Fields[1].AsString <> '2009')  then
      WriteToErrorLog(capt+'Error #227: '+q.Fields[1].AsString);
    if (q.Fields[2].AsString <> '3200')  then
      WriteToErrorLog(capt+'Error #228: '+q.Fields[2].AsString);
    if (q.Fields[3].AsString <> 'Mike')  then
      WriteToErrorLog(capt+'Error #229: '+q.Fields[3].AsString);
    if (q.Fields[4].AsString <> 'Tompson')  then
      WriteToErrorLog(capt+'Error #230: '+q.Fields[4].AsString);
    if (q.Fields[5].AsString <> 'New cars department')  then
      WriteToErrorLog(capt+'Error #231: '+q.Fields[5].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Audi A4')  then
      WriteToErrorLog(capt+'Error #232: '+q.Fields[0].AsString);
    if (q.Fields[1].AsString <> '2009')  then
      WriteToErrorLog(capt+'Error #233: '+q.Fields[1].AsString);
    if (q.Fields[2].AsString <> '2800')  then
      WriteToErrorLog(capt+'Error #234: '+q.Fields[2].AsString);
    if (q.Fields[3].AsString <> 'Marta')  then
      WriteToErrorLog(capt+'Error #235: '+q.Fields[3].AsString);
    if (q.Fields[4].AsString <> 'Bernstein')  then
      WriteToErrorLog(capt+'Error #236: '+q.Fields[4].AsString);
    if (q.Fields[5].AsString <> 'New cars department')  then
      WriteToErrorLog(capt+'Error #237: '+q.Fields[5].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Ford Focus')  then
      WriteToErrorLog(capt+'Error #238: '+q.Fields[0].AsString);
    if (q.Fields[1].AsString <> '2010')  then
      WriteToErrorLog(capt+'Error #239: '+q.Fields[1].AsString);
    if (q.Fields[2].AsString <> '1200')  then
      WriteToErrorLog(capt+'Error #240: '+q.Fields[2].AsString);
    if (q.Fields[3].AsString <> 'Ann')  then
      WriteToErrorLog(capt+'Error #241: '+q.Fields[3].AsString);
    if (q.Fields[4].AsString <> 'Nikolson')  then
      WriteToErrorLog(capt+'Error #242: '+q.Fields[4].AsString);
    if (q.Fields[5].AsString <> 'New cars department')  then
      WriteToErrorLog(capt+'Error #243: '+q.Fields[5].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #244 - not EOF!');

    q.SQL.Text := 'SELECT Id,(Id > 3), (id >= 3),(id = 3), (id < 3), (id <= 3), (id <> 3) FROM emp ORDER BY Id';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);


    q.SQL.Text := 'SELECT ID as [#], Name, SurName, Salary as Sal FROM emp WHERE Sal > 12000 and Salary < 30000  ORDER BY [#] DESC';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 2) then
      WriteToErrorLog(capt+'Error #190 rc = '+IntToStr(q.RecordCount))
    else
    if (q.FieldCount <> 4) then
      WriteToErrorLog(capt+'Error #191 fc = '+IntToStr(q.FieldCount));
    if (q.Fields[0].AsString <> '5')  then
      WriteToErrorLog(capt+'Error #192: '+q.Fields[0].AsString);
    if (q.Fields[1].AsString <> 'Laura')  then
      WriteToErrorLog(capt+'Error #193: '+q.Fields[1].AsString);
    if (q.Fields[2].AsString <> 'Bright')  then
      WriteToErrorLog(capt+'Error #194: '+q.Fields[2].AsString);
    if (q.Fields[3].AsInteger <> 13000)  then
      WriteToErrorLog(capt+'Error #195: '+q.Fields[3].AsString);
    q.Next;
    if (q.Fields[0].AsString <> '2')  then
      WriteToErrorLog(capt+'Error #196: '+q.Fields[0].AsString);
    if (q.Fields[1].AsString <> 'Marta')  then
      WriteToErrorLog(capt+'Error #197: '+q.Fields[1].AsString);
    if (q.Fields[2].AsString <> 'Bernstein')  then
      WriteToErrorLog(capt+'Error #198: '+q.Fields[2].AsString);
    if (q.Fields[3].AsCurrency <> 25000.00)  then
      WriteToErrorLog(capt+'Error #199: '+q.Fields[3].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #200 - not EOF!');

    q.SQL.Text := 'SELECT * FROM dept,dept AS dept2 WHERE dept.ID = dept2.ID AND dept2.ID = 2 ORDER BY dept.ID, dept2.ID';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 1) then
      WriteToErrorLog(capt+'Error #183 rc = '+IntToStr(q.RecordCount))
    else
    if (q.FieldCount <> 4) then
      WriteToErrorLog(capt+'Error #184 fc = '+IntToStr(q.FieldCount));
    if (q.Fields[0].AsString <> '2')  then
      WriteToErrorLog(capt+'Error #185: '+q.Fields[0].AsString);
    if (q.Fields[1].AsString <> 'Used cars department')  then
      WriteToErrorLog(capt+'Error #186: '+q.Fields[1].AsString);
    if (q.Fields[2].AsString <> '2')  then
      WriteToErrorLog(capt+'Error #187: '+q.Fields[2].AsString);
    if (q.Fields[3].AsString <> 'Used cars department')  then
      WriteToErrorLog(capt+'Error #188: '+q.Fields[3].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #189 - not EOF!');

    q.SQL.Text := 'SELECT * FROM dept,dept AS dept2 WHERE dept.ID = dept2.ID ORDER BY dept.ID DESC';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 2) then
      WriteToErrorLog(capt+'Error #172 rc = '+IntToStr(q.RecordCount))
    else
    if (q.FieldCount <> 4) then
      WriteToErrorLog(capt+'Error #173 fc = '+IntToStr(q.FieldCount));
    if (q.Fields[0].AsString <> '2')  then
      WriteToErrorLog(capt+'Error #174: '+q.Fields[0].AsString);
    if (q.Fields[1].AsString <> 'Used cars department')  then
      WriteToErrorLog(capt+'Error #175: '+q.Fields[1].AsString);
    if (q.Fields[2].AsString <> '2')  then
      WriteToErrorLog(capt+'Error #176: '+q.Fields[2].AsString);
    if (q.Fields[3].AsString <> 'Used cars department')  then
      WriteToErrorLog(capt+'Error #177: '+q.Fields[3].AsString);
    q.Next;
    if (q.Fields[0].AsString <> '1')  then
      WriteToErrorLog(capt+'Error #178: '+q.Fields[0].AsString);
    if (q.Fields[1].AsString <> 'New cars department')  then
      WriteToErrorLog(capt+'Error #179: '+q.Fields[1].AsString);
    if (q.Fields[2].AsString <> '1')  then
      WriteToErrorLog(capt+'Error #180: '+q.Fields[2].AsString);
    if (q.Fields[3].AsString <> 'New cars department')  then
      WriteToErrorLog(capt+'Error #181: '+q.Fields[3].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #182 - not EOF!');


    q.SQL.Text := 'SELECT DEGREES(1.5), RADIANS(1.5), PI FROM emp WHERE id = 1';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 1) then
      WriteToErrorLog(capt+'Error #166 rc = '+IntToStr(q.RecordCount))
    else
    if (q.FieldCount <> 3) then
      WriteToErrorLog(capt+'Error #167 fc = '+IntToStr(q.FieldCount));
    if (q.Fields[0].AsString <> '85.9436692696235')  then
      WriteToErrorLog(capt+'Error #168: '+q.Fields[0].AsString);
    if (q.Fields[1].AsString <> '0.0261799387799149')  then
      WriteToErrorLog(capt+'Error #169: '+q.Fields[1].AsString);
    if (q.Fields[2].AsString <> '3.14159265358979')  then
      WriteToErrorLog(capt+'Error #170: '+q.Fields[2].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #171 - not EOF!');

    q.SQL.Text := 'SELECT SQRT(144),SQR(25) FROM emp WHERE id = 1';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 1) then
      WriteToErrorLog(capt+'Error #161 rc = '+IntToStr(q.RecordCount))
    else
    if (q.FieldCount <> 2) then
      WriteToErrorLog(capt+'Error #162 fc = '+IntToStr(q.FieldCount));
    if (q.Fields[0].AsString <> '12')  then
      WriteToErrorLog(capt+'Error #163: '+q.Fields[0].AsString);
    if (q.Fields[1].AsString <> '625')  then
      WriteToErrorLog(capt+'Error #164: '+q.Fields[1].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #165 - not EOF!');

    q.SQL.Text := 'SELECT COT(0.35), TAN(0.67) FROM emp WHERE id = 1';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 1) then
      WriteToErrorLog(capt+'Error #156 rc = '+IntToStr(q.RecordCount))
    else
    if (q.FieldCount <> 2) then
      WriteToErrorLog(capt+'Error #157 fc = '+IntToStr(q.FieldCount));
    if (q.Fields[0].AsString <> '2.73951215908378')  then
      WriteToErrorLog(capt+'Error #158: '+q.Fields[0].AsString);
    if (q.Fields[1].AsString <> '0.792254174728257')  then
      WriteToErrorLog(capt+'Error #159: '+q.Fields[1].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #160 - not EOF!');

    q.SQL.Text := 'SELECT ATAN(0.123),ATAN2(2.3,-3.5) FROM emp WHERE id = 1';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 1) then
      WriteToErrorLog(capt+'Error #151 rc = '+IntToStr(q.RecordCount))
    else
    if (q.FieldCount <> 2) then
      WriteToErrorLog(capt+'Error #152 fc = '+IntToStr(q.FieldCount));
    if (q.Fields[0].AsString <> '0.122385281471803')  then
      WriteToErrorLog(capt+'Error #153: '+q.Fields[0].AsString);
    if (q.Fields[1].AsString <> '2.56021246978489')  then
      WriteToErrorLog(capt+'Error #154: '+q.Fields[1].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #155 - not EOF!');

    q.SQL.Text := 'SELECT ACOS(0.12),ASIN(0.12) FROM emp WHERE id = 1';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 1) then
      WriteToErrorLog(capt+'Error #146 rc = '+IntToStr(q.RecordCount))
    else
    if (q.FieldCount <> 2) then
      WriteToErrorLog(capt+'Error #147 fc = '+IntToStr(q.FieldCount));
    if (q.Fields[0].AsString <> '1.45050644440011')  then
      WriteToErrorLog(capt+'Error #148: '+q.Fields[0].AsString);
    if (q.Fields[1].AsString <> '0.120289882394788')  then
      WriteToErrorLog(capt+'Error #149: '+q.Fields[1].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #150 - not EOF!');

    q.SQL.Text := 'SELECT COS(1.5),SIN(1.5) FROM emp WHERE id = 1';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 1) then
      WriteToErrorLog(capt+'Error #141 rc = '+IntToStr(q.RecordCount))
    else
    if (q.FieldCount <> 2) then
      WriteToErrorLog(capt+'Error #142 fc = '+IntToStr(q.FieldCount));
    if (q.Fields[0].AsString <> '0.0707372016677029')  then
      WriteToErrorLog(capt+'Error #143: '+q.Fields[0].AsString);
    if (q.Fields[1].AsString <> '0.997494986604054')  then
      WriteToErrorLog(capt+'Error #144: '+q.Fields[1].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #145 - not EOF!');


    q.SQL.Text := 'SELECT EXP(123.45), LN(123.45), LOG10(123.45), LOG(123.45,10) FROM emp WHERE id = 1';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 1) then
      WriteToErrorLog(capt+'Error #134 rc = '+IntToStr(q.RecordCount))
    else
    if (q.FieldCount <> 4) then
      WriteToErrorLog(capt+'Error #135 fc = '+IntToStr(q.FieldCount));
    if (q.Fields[0].AsString <> '4.1082209310967E53')  then
      WriteToErrorLog(capt+'Error #136: '+q.Fields[0].AsString);
    if (q.Fields[1].AsString <> '4.81583621579119')  then
      WriteToErrorLog(capt+'Error #137: '+q.Fields[1].AsString);
    if (q.Fields[2].AsString <> '2.09149109426795')  then
      WriteToErrorLog(capt+'Error #138: '+q.Fields[2].AsString);
    if (q.Fields[3].AsString <> '2.09149109426795')  then
      WriteToErrorLog(capt+'Error #139: '+q.Fields[3].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #140 - not EOF!');

    q.SQL.Text := 'SELECT COALESCE(Mileage,''None'') FROM orders ORDER BY 1';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 8) then
      WriteToErrorLog(capt+'Error #123 rc = '+IntToStr(q.RecordCount))
    else
    if (q.FieldCount <> 1) then
      WriteToErrorLog(capt+'Error #124 fc = '+IntToStr(q.FieldCount));
    if (q.Fields[0].AsString <> '15000')  then
      WriteToErrorLog(capt+'Error #125: '+q.Fields[0].AsString);
    q.Next;
    if (q.Fields[0].AsString <> '27000')  then
      WriteToErrorLog(capt+'Error #126: '+q.Fields[0].AsString);
    q.Next;
    if (q.Fields[0].AsString <> '36100')  then
      WriteToErrorLog(capt+'Error #127: '+q.Fields[0].AsString);
    q.Next;
    if (q.Fields[0].AsString <> '54300')  then
      WriteToErrorLog(capt+'Error #128: '+q.Fields[0].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'None')  then
      WriteToErrorLog(capt+'Error #129: '+q.Fields[0].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'None')  then
      WriteToErrorLog(capt+'Error #130: '+q.Fields[0].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'None')  then
      WriteToErrorLog(capt+'Error #131: '+q.Fields[0].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'None')  then
      WriteToErrorLog(capt+'Error #132: '+q.Fields[0].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #133 - not EOF!');

    q.SQL.Text := 'SELECT Mileage, Mileage IS NULL, Mileage IS NOT NULL FROM orders ORDER BY Mileage';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 8) then
      WriteToErrorLog(capt+'Error #96 rc = '+IntToStr(q.RecordCount))
    else
    if (q.FieldCount <> 3) then
      WriteToErrorLog(capt+'Error #97 fc = '+IntToStr(q.FieldCount));
    if (not q.Fields[0].IsNull)  then
      WriteToErrorLog(capt+'Error #98: '+q.Fields[0].AsString);
    if (not q.Fields[1].AsBoolean)  then
      WriteToErrorLog(capt+'Error #99: '+q.Fields[2].AsString);
    if (q.Fields[2].AsBoolean)  then
      WriteToErrorLog(capt+'Error #100: '+q.Fields[1].AsString);
    q.Next;
    if (not q.Fields[0].IsNull)  then
      WriteToErrorLog(capt+'Error #101: '+q.Fields[0].AsString);
    if (not q.Fields[1].AsBoolean)  then
      WriteToErrorLog(capt+'Error #102: '+q.Fields[2].AsString);
    if (q.Fields[2].AsBoolean)  then
      WriteToErrorLog(capt+'Error #103: '+q.Fields[1].AsString);
    q.Next;
    if (not q.Fields[0].IsNull)  then
      WriteToErrorLog(capt+'Error #104: '+q.Fields[0].AsString);
    if (not q.Fields[1].AsBoolean)  then
      WriteToErrorLog(capt+'Error #105: '+q.Fields[2].AsString);
    if (q.Fields[2].AsBoolean)  then
      WriteToErrorLog(capt+'Error #106: '+q.Fields[1].AsString);
    q.Next;
    if (not q.Fields[0].IsNull)  then
      WriteToErrorLog(capt+'Error #107: '+q.Fields[0].AsString);
    if (not q.Fields[1].AsBoolean)  then
      WriteToErrorLog(capt+'Error #108: '+q.Fields[2].AsString);
    if (q.Fields[2].AsBoolean)  then
      WriteToErrorLog(capt+'Error #109: '+q.Fields[1].AsString);
    q.Next;
    if (q.Fields[0].AsInteger <> 15000)  then
      WriteToErrorLog(capt+'Error #110: '+q.Fields[0].AsString);
    if (q.Fields[1].AsBoolean)  then
      WriteToErrorLog(capt+'Error #111: '+q.Fields[2].AsString);
    if (not q.Fields[2].AsBoolean)  then
      WriteToErrorLog(capt+'Error #112: '+q.Fields[1].AsString);
    q.Next;
    if (q.Fields[0].AsInteger <> 27000)  then
      WriteToErrorLog(capt+'Error #113: '+q.Fields[0].AsString);
    if (q.Fields[1].AsBoolean)  then
      WriteToErrorLog(capt+'Error #114: '+q.Fields[2].AsString);
    if (not q.Fields[2].AsBoolean)  then
      WriteToErrorLog(capt+'Error #115: '+q.Fields[1].AsString);
    q.Next;
    if (q.Fields[0].AsInteger <> 36100)  then
      WriteToErrorLog(capt+'Error #116: '+q.Fields[0].AsString);
    if (q.Fields[1].AsBoolean)  then
      WriteToErrorLog(capt+'Error #117: '+q.Fields[2].AsString);
    if (not q.Fields[2].AsBoolean)  then
      WriteToErrorLog(capt+'Error #118: '+q.Fields[1].AsString);
    q.Next;
    if (q.Fields[0].AsInteger <> 54300)  then
      WriteToErrorLog(capt+'Error #119: '+q.Fields[0].AsString);
    if (q.Fields[1].AsBoolean)  then
      WriteToErrorLog(capt+'Error #120: '+q.Fields[2].AsString);
    if (not q.Fields[2].AsBoolean)  then
      WriteToErrorLog(capt+'Error #121: '+q.Fields[1].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #122 - not EOF!');


    q.SQL.Text := 'SELECT Id,(Id > 3), (id >= 3),(id = 3), (id < 3), (id <= 3), (id <> 3) FROM emp ORDER BY Id';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 6) then
      WriteToErrorLog(capt+'Error #50 rc = '+IntToStr(q.RecordCount))
    else
    if (q.FieldCount <> 7) then
      WriteToErrorLog(capt+'Error #51 fc = '+IntToStr(q.FieldCount));
    if (q.Fields[0].AsInteger <> 1)  then
      WriteToErrorLog(capt+'Error #52: '+q.Fields[0].AsString);
    if (q.Fields[1].AsBoolean)  then
      WriteToErrorLog(capt+'Error #53: '+q.Fields[1].AsString);
    if (q.Fields[2].AsBoolean)  then
      WriteToErrorLog(capt+'Error #54: '+q.Fields[2].AsString);
    if (q.Fields[3].AsBoolean)  then
      WriteToErrorLog(capt+'Error #55: '+q.Fields[3].AsString);
    if (not q.Fields[4].AsBoolean)  then
      WriteToErrorLog(capt+'Error #56: '+q.Fields[4].AsString);
    if (not q.Fields[5].AsBoolean)  then
      WriteToErrorLog(capt+'Error #57: '+q.Fields[5].AsString);
    if (not q.Fields[6].AsBoolean)  then
      WriteToErrorLog(capt+'Error #58: '+q.Fields[6].AsString);
    q.Next;
    if (q.Fields[0].AsInteger <> 2)  then
      WriteToErrorLog(capt+'Error #59: '+q.Fields[0].AsString);
    if (q.Fields[1].AsBoolean)  then
      WriteToErrorLog(capt+'Error #60: '+q.Fields[1].AsString);
    if (q.Fields[2].AsBoolean)  then
      WriteToErrorLog(capt+'Error #61: '+q.Fields[2].AsString);
    if (q.Fields[3].AsBoolean)  then
      WriteToErrorLog(capt+'Error #62: '+q.Fields[3].AsString);
    if (not q.Fields[4].AsBoolean)  then
      WriteToErrorLog(capt+'Error #63: '+q.Fields[4].AsString);
    if (not q.Fields[5].AsBoolean)  then
      WriteToErrorLog(capt+'Error #64: '+q.Fields[5].AsString);
    if (not q.Fields[6].AsBoolean)  then
      WriteToErrorLog(capt+'Error #65: '+q.Fields[6].AsString);
    q.Next;
    if (q.Fields[0].AsInteger <> 3)  then
      WriteToErrorLog(capt+'Error #67: '+q.Fields[0].AsString);
    if (q.Fields[1].AsBoolean)  then
      WriteToErrorLog(capt+'Error #68: '+q.Fields[1].AsString);
    if (not q.Fields[2].AsBoolean)  then
      WriteToErrorLog(capt+'Error #69: '+q.Fields[2].AsString);
    if (not q.Fields[3].AsBoolean)  then
      WriteToErrorLog(capt+'Error #70: '+q.Fields[3].AsString);
    if (q.Fields[4].AsBoolean)  then
      WriteToErrorLog(capt+'Error #71: '+q.Fields[4].AsString);
    if (not q.Fields[5].AsBoolean)  then
      WriteToErrorLog(capt+'Error #72: '+q.Fields[5].AsString);
    if (q.Fields[6].AsBoolean)  then
      WriteToErrorLog(capt+'Error #73: '+q.Fields[6].AsString);
    q.Next;
    if (q.Fields[0].AsInteger <> 4)  then
      WriteToErrorLog(capt+'Error #74: '+q.Fields[0].AsString);
    if (not q.Fields[1].AsBoolean)  then
      WriteToErrorLog(capt+'Error #75: '+q.Fields[1].AsString);
    if (not q.Fields[2].AsBoolean)  then
      WriteToErrorLog(capt+'Error #76: '+q.Fields[2].AsString);
    if (q.Fields[3].AsBoolean)  then
      WriteToErrorLog(capt+'Error #77: '+q.Fields[3].AsString);
    if (q.Fields[4].AsBoolean)  then
      WriteToErrorLog(capt+'Error #78: '+q.Fields[4].AsString);
    if (q.Fields[5].AsBoolean)  then
      WriteToErrorLog(capt+'Error #79: '+q.Fields[5].AsString);
    if (not q.Fields[6].AsBoolean)  then
      WriteToErrorLog(capt+'Error #80: '+q.Fields[6].AsString);
    q.Next;
    if (q.Fields[0].AsInteger <> 5)  then
      WriteToErrorLog(capt+'Error #81: '+q.Fields[0].AsString);
    if (not q.Fields[1].AsBoolean)  then
      WriteToErrorLog(capt+'Error #82: '+q.Fields[1].AsString);
    if (not q.Fields[2].AsBoolean)  then
      WriteToErrorLog(capt+'Error #83: '+q.Fields[2].AsString);
    if (q.Fields[3].AsBoolean)  then
      WriteToErrorLog(capt+'Error #84: '+q.Fields[3].AsString);
    if (q.Fields[4].AsBoolean)  then
      WriteToErrorLog(capt+'Error #85: '+q.Fields[4].AsString);
    if (q.Fields[5].AsBoolean)  then
      WriteToErrorLog(capt+'Error #86: '+q.Fields[5].AsString);
    if (not q.Fields[6].AsBoolean)  then
      WriteToErrorLog(capt+'Error #87: '+q.Fields[6].AsString);
    q.Next;
    if (q.Fields[0].AsInteger <> 6)  then
      WriteToErrorLog(capt+'Error #88: '+q.Fields[0].AsString);
    if (not q.Fields[1].AsBoolean)  then
      WriteToErrorLog(capt+'Error #89: '+q.Fields[1].AsString);
    if (not q.Fields[2].AsBoolean)  then
      WriteToErrorLog(capt+'Error #90: '+q.Fields[2].AsString);
    if (q.Fields[3].AsBoolean)  then
      WriteToErrorLog(capt+'Error #91: '+q.Fields[3].AsString);
    if (q.Fields[4].AsBoolean)  then
      WriteToErrorLog(capt+'Error #92: '+q.Fields[4].AsString);
    if (q.Fields[5].AsBoolean)  then
      WriteToErrorLog(capt+'Error #93: '+q.Fields[5].AsString);
    if (not q.Fields[6].AsBoolean)  then
      WriteToErrorLog(capt+'Error #94: '+q.Fields[6].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #95 - not EOF!');

    q.SQL.Text := 'SELECT Replace (''ABABA'',''B'',''D'') FROM emp WHERE Id = 1';
    q.Open;
    if (q.RecordCount <> 1) then
      WriteToErrorLog(capt+'Error #46 rc = '+IntToStr(q.RecordCount))
    else
    if (q.FieldCount <> 1) then
      WriteToErrorLog(capt+'Error #47 fc = '+IntToStr(q.FieldCount));
    if (q.Fields[0].AsString <> 'ADADA')  then
      WriteToErrorLog(capt+'Error #48: '+q.Fields[0].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #49 - not EOF!');

    q.SQL.Text := 'SELECT REPEAT(''A'',3) FROM emp WHERE Id = 1';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 1) then
      WriteToErrorLog(capt+'Error #42 rc = '+IntToStr(q.RecordCount))
    else
    if (q.FieldCount <> 1) then
      WriteToErrorLog(capt+'Error #43 fc = '+IntToStr(q.FieldCount));
    if (q.Fields[0].AsString <> 'AAA')  then
      WriteToErrorLog(capt+'Error #44: '+q.Fields[0].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #45 - not EOF!');

    q.SQL.Text := 'SELECT CHAR(97),CHR(97) FROM emp WHERE Id = 1';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 1) then
      WriteToErrorLog(capt+'Error #38 rc = '+IntToStr(q.RecordCount))
    else
    if (q.FieldCount <> 2) then
      WriteToErrorLog(capt+'Error #39 fc = '+IntToStr(q.FieldCount));
    if (q.Fields[0].AsString <> 'a') or (q.Fields[1].AsString <> 'a') then
      WriteToErrorLog(capt+'Error #40: '+q.Fields[0].AsString +#9+q.Fields[1].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #41 - not EOF!');

    q.SQL.Text := 'SELECT ASCII(Name),Name FROM emp ORDER BY Name';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 6) then
      WriteToErrorLog(capt+'Error #29 rc = '+IntToStr(q.RecordCount))
    else
    if (q.FieldCount <> 2) then
      WriteToErrorLog(capt+'Error #30 fc = '+IntToStr(q.FieldCount));
    if (q.Fields[0].AsInteger <> 65) or (q.Fields[1].AsString <> 'Ann') then
      WriteToErrorLog(capt+'Error #31: '+q.Fields[0].AsString +#9+q.Fields[1].AsString);
    q.Next;
    if (q.Fields[0].AsInteger <> 65) or (q.Fields[1].AsString <> 'Ann') then
      WriteToErrorLog(capt+'Error #32: '+q.Fields[0].AsString +#9+q.Fields[1].AsString);
    q.Next;
    if (q.Fields[0].AsInteger <> 76) or (q.Fields[1].AsString <> 'Laura') then
      WriteToErrorLog(capt+'Error #33: '+q.Fields[0].AsString +#9+q.Fields[1].AsString);
    q.Next;
    if (q.Fields[0].AsInteger <> 77) or (q.Fields[1].AsString <> 'Marta') then
      WriteToErrorLog(capt+'Error #34: '+q.Fields[0].AsString +#9+q.Fields[1].AsString);
    q.Next;
    if (q.Fields[0].AsInteger <> 77) or (q.Fields[1].AsString <> 'Mike') then
      WriteToErrorLog(capt+'Error #35: '+q.Fields[0].AsString +#9+q.Fields[1].AsString);
    q.Next;
    if (q.Fields[0].AsInteger <> 83) or (q.Fields[1].AsString <> 'Steve') then
      WriteToErrorLog(capt+'Error #36: '+q.Fields[0].AsString +#9+q.Fields[1].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #37 - not EOF!');

    q.SQL.Text := 'SELECT Id,CONCAT(CONCAT(Name,'' ''),Surname) FROM emp ORDER BY Id';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 6) then
      WriteToErrorLog(capt+'Error #20 rc = '+IntToStr(q.RecordCount))
    else
    if (q.FieldCount <> 2) then
      WriteToErrorLog(capt+'Error #21 fc = '+IntToStr(q.FieldCount));
    if (q.Fields[0].AsInteger <> 1) or (q.Fields[1].AsString <> 'Mike Tompson') then
      WriteToErrorLog(capt+'Error #22: '+q.Fields[0].AsString +#9+q.Fields[1].AsString);
    q.Next;
    if (q.Fields[0].AsInteger <> 2) or (q.Fields[1].AsString <> 'Marta Bernstein') then
      WriteToErrorLog(capt+'Error #23: '+q.Fields[0].AsString +#9+q.Fields[1].AsString);
    q.Next;
    if (q.Fields[0].AsInteger <> 3) or (q.Fields[1].AsString <> 'Ann Nikolson') then
      WriteToErrorLog(capt+'Error #24: '+q.Fields[0].AsString +#9+q.Fields[1].AsString);
    q.Next;
    if (q.Fields[0].AsInteger <> 4) or (q.Fields[1].AsString <> 'Ann Swensson') then
      WriteToErrorLog(capt+'Error #25: '+q.Fields[0].AsString +#9+q.Fields[1].AsString);
    q.Next;
    if (q.Fields[0].AsInteger <> 5) or (q.Fields[1].AsString <> 'Laura Bright') then
      WriteToErrorLog(capt+'Error #26: '+q.Fields[0].AsString +#9+q.Fields[1].AsString);
    q.Next;
    if (q.Fields[0].AsInteger <> 6) or (q.Fields[1].AsString <> 'Steve Masters') then
      WriteToErrorLog(capt+'Error #27: '+q.Fields[0].AsString +#9+q.Fields[1].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #28 - not EOF!');

    q.SQL.Text := 'SELECT Car, Sale_price AS sp FROM orders WHERE sp > 30000 ORDER BY sp DESC';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 5) then
      WriteToErrorLog(capt+'Error #12 rc = '+IntToStr(q.RecordCount))
    else
    if (q.FieldCount <> 2) then
      WriteToErrorLog(capt+'Error #13 fc = '+IntToStr(q.FieldCount));
    if (q.Fields[0].AsString <> 'Volkswagen Touareg ') or (q.Fields[1].AsCurrency <> 88000.00) then
      WriteToErrorLog(capt+'Error #14: '+q.Fields[0].AsString +#9+q.Fields[1].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Lexus rx350') or (q.Fields[1].AsCurrency <> 79000.00) then
      WriteToErrorLog(capt+'Error #15: '+q.Fields[0].AsString +#9+q.Fields[1].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'BMW X5') or (q.Fields[1].AsCurrency <> 42000.00) then
      WriteToErrorLog(capt+'Error #16: '+q.Fields[0].AsString +#9+q.Fields[1].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Ford Explorer') or (q.Fields[1].AsCurrency <> 38000.00) then
      WriteToErrorLog(capt+'Error #17: '+q.Fields[0].AsString +#9+q.Fields[1].AsString);
    q.Next;
    if (q.Fields[0].AsString <> 'Audi A4') or (q.Fields[1].AsCurrency <> 35000.00) then
      WriteToErrorLog(capt+'Error #18: '+q.Fields[0].AsString +#9+q.Fields[1].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #19 - not EOF!');

    q.SQL.Text := 'SELECT STDDEV(Sale_price) FROM orders';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 1) then
      WriteToErrorLog(capt+'Error #10 rc = '+IntToStr(q.RecordCount))
    else
    if (q.Fields[0].AsString <> '25249.4094697565') then
      WriteToErrorLog(capt+'Error #11 STDDEV = '+q.Fields[0].AsString);

    // #1
    q.SQL.Text := 'SELECT ID, Name + '' was born '' + Birthday FROM emp ORDER BY ID';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 6) then
      WriteToErrorLog(capt+'Error #1 rc = '+IntToStr(q.RecordCount))
    else
    if (q.FieldCount <> 2) then
      WriteToErrorLog(capt+'Error #2 fc = '+IntToStr(q.FieldCount));
    if (q.Fields[0].AsInteger <> 1) or (q.Fields[1].AsString <> 'Mike was born 11/8/1973') then
      WriteToErrorLog(capt+'Error #3: '+q.Fields[0].AsString +#9+q.Fields[1].AsString);
    q.Next;
    if (q.Fields[0].AsInteger <> 2) or (q.Fields[1].AsString <> 'Marta was born 6/17/1984') then
      WriteToErrorLog(capt+'Error #4: '+q.Fields[0].AsString +#9+q.Fields[1].AsString);
    q.Next;
    if (q.Fields[0].AsInteger <> 3) or (q.Fields[1].AsString <> 'Ann was born 8/30/1993') then
      WriteToErrorLog(capt+'Error #5: '+q.Fields[0].AsString +#9+q.Fields[1].AsString);
    q.Next;
    if (q.Fields[0].AsInteger <> 4) or (q.Fields[1].AsString <> 'Ann was born 4/25/1990') then
      WriteToErrorLog(capt+'Error #6: '+q.Fields[0].AsString +#9+q.Fields[1].AsString);
    q.Next;
    if (q.Fields[0].AsInteger <> 5) or (q.Fields[1].AsString <> 'Laura was born 12/31/1987') then
      WriteToErrorLog(capt+'Error #7: '+q.Fields[0].AsString +#9+q.Fields[1].AsString);
    q.Next;
    if (q.Fields[0].AsInteger <> 6) or (q.Fields[1].AsString <> 'Steve was born 2/26/1965') then
      WriteToErrorLog(capt+'Error #8: '+q.Fields[0].AsString +#9+q.Fields[1].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #9 - not EOF!');

    ShortDateFormat := s;
  finally
    q.SQL.Text := 'DROP TABLE emp; DROP TABLE dept; DROP TABLE orders;';
    q.ExecSQL;
    q.Free;
  end;
end; // TestVclDb

procedure TUnitTestACRQuery.TestInnerJoinBugYabut_23_02_2011;
var q:         TACRQuery;
    capt,s:    String;
begin
  capt := 'Test Inner Join Bug Yabut 23.02.2011 - ';
  q := TACRQuery.Create(nil);
  try
    WriteToProcessLog(capt+'Starting...');
    q.InMemory := True;
    q.SQL.LoadFromFile(SQLDir+'inner_join_bug_yabut_23_02_2011.sql');
    q.ExecSQL;
    WriteToProcessLog(capt+'table created');

    // last error: 8
    s := ShortDateFormat;
    ShortDateFormat := 'M/D/YYYY';

    q.SQL.Text := 'SELECT'
+' c.id as c_id, ppc.id as p_id, ppc.checkdate_id AS id, c.datecreated AS checkdate, ppc.rank'
+' FROM ppc_ads ppc JOIN'
+' checkdate c ON c.id = ppc.checkdate_id'
+' WHERE ppc.keyword_id = 2 AND'
+' ppc.display_url_id = 13 AND'
+' ppc.searchengine_id = 36'
+' ORDER BY c.datecreated ';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 1) then
      WriteToErrorLog(capt+'Error #1 rc = '+IntToStr(q.RecordCount))
    else
    if (q.FieldCount <> 5) then
      WriteToErrorLog(capt+'Error #2 fc = '+IntToStr(q.FieldCount));
    if (q.Fields[0].AsInteger <> 8)  then
      WriteToErrorLog(capt+'Error #3: '+q.Fields[0].AsString);
    if (q.Fields[1].AsInteger <> 2)  then
      WriteToErrorLog(capt+'Error #4: '+q.Fields[1].AsString);
    if (q.Fields[2].AsInteger <> 8)  then
      WriteToErrorLog(capt+'Error #5: '+q.Fields[2].AsString);
    if (q.Fields[3].AsString <> '2/22/2011 8:52:26 AM')  then
      WriteToErrorLog(capt+'Error #6: '+q.Fields[3].AsString);
    if (q.Fields[4].AsInteger <> 2)  then
      WriteToErrorLog(capt+'Error #7: '+q.Fields[4].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #8 - not EOF!');

    ShortDateFormat := s;
  finally
    q.SQL.Text := 'DROP TABLE emp; DROP TABLE dept; DROP TABLE orders;';
    q.ExecSQL;
    q.Free;
  end;
end; // TestInnerJoinBugYabut_23_02_2011


procedure TUnitTestACRQuery.TestSimpleExpressions;
var q:         TACRQuery;
    capt,s:    String;
begin
  capt := 'Test Simple Expressions - ';
  q := TACRQuery.Create(nil);
  try
    s := ShortDateFormat;
    ShortDateFormat := 'M/D/YYYY';

    WriteToProcessLog(capt+'Starting...');
    q.InMemory := True;
    q.SQL.Text := 'CREATE TABLE test (id AutoInc, f1 INTEGER, f2 DOUBLE, f3 CHAR(20), f4 DATETIME, f5 Logical);'
+'INSERT INTO test VALUES (NULL, -100, 1250.67, "Test ABC",TODATE("09.03.2011","DD.MM.YYYY"),true);'
+'INSERT INTO test VALUES (NULL, 150, -250.67, NULL, NULL, false);'
;
    q.ExecSQL;
    WriteToProcessLog(capt+'table created');

    // last error: 18

    q.SQL.Text := 'SELECT f3 LIKE "Test"+"%" FROM test WHERE id = 1';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 1) or (q.FieldCount <> 1) then
      WriteToErrorLog(capt+'Error #16 rc = '+IntToStr(q.RecordCount)+#9+IntToStr(q.FieldCount));
    if (not q.Fields[0].AsBoolean) then
      WriteToErrorLog(capt+'Error #17: '+q.Fields[0].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #18 - not EOF!');

    q.SQL.Text := 'SELECT id, id << 4, 32 >> 2, 1 & 3, 0 | 5, 3 ^ 3, ~CAST(65535 AS WORD), ~f5, !id FROM test WHERE id = 8 shr 3';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 1) or (q.FieldCount <> 9) then
      WriteToErrorLog(capt+'Error #13 rc = '+IntToStr(q.RecordCount)+#9+IntToStr(q.FieldCount));
    if (q.Fields[0].AsInteger <> 1) or
       (q.Fields[1].AsInteger <> 16) or
       (q.Fields[2].AsInteger <> 8) or
       (q.Fields[3].AsInteger <> 1) or
       (q.Fields[4].AsInteger <> 5) or
       (q.Fields[5].AsInteger <> 0) or
       (q.Fields[6].AsInteger <> 0) or
       (q.Fields[7].AsBoolean) or
       (q.Fields[8].AsBoolean)
    then
      WriteToErrorLog(capt+'Error #14: '+q.Fields[0].AsString+#9+q.Fields[1].AsString
      +#9+q.Fields[2].AsString+#9+q.Fields[3].AsString+#9+q.Fields[4].AsString
      +#9+q.Fields[5].AsString+#9+q.Fields[6].AsString+#9+q.Fields[7].AsString
      +#9+q.Fields[8].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #15 - not EOF!');


    q.SQL.Text := 'SELECT COUNT(*) FROM test WHERE ((false))';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 1) or (q.FieldCount <> 1) then
      WriteToErrorLog(capt+'Error #10 rc = '+IntToStr(q.RecordCount)+#9+IntToStr(q.FieldCount));
    if (q.Fields[0].AsInteger <> 0)  then
      WriteToErrorLog(capt+'Error #11: '+q.Fields[0].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #12 - not EOF!');

    q.SQL.Text := 'SELECT COUNT(*) FROM test WHERE true';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 1) or (q.FieldCount <> 1) then
      WriteToErrorLog(capt+'Error #7 rc = '+IntToStr(q.RecordCount)+#9+IntToStr(q.FieldCount));
    if (q.Fields[0].AsInteger <> 2)  then
      WriteToErrorLog(capt+'Error #8: '+q.Fields[0].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #9 - not EOF!');

    q.SQL.Text := 'SELECT 20-((10-(7-3*2)))*(-2) FROM test WHERE id = 1';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 1) or (q.FieldCount <> 1) then
      WriteToErrorLog(capt+'Error #4 rc = '+IntToStr(q.RecordCount)+#9+IntToStr(q.FieldCount));
    if (q.Fields[0].AsString <> '38')  then
      WriteToErrorLog(capt+'Error #5: '+q.Fields[0].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #6 - not EOF!');

    q.SQL.Text := 'SELECT -id*(f1+f2*2)+0.5*2 FROM test WHERE id = 1 AND f3 IS NOT NULL AND f5 IS NOT FALSE';
    q.Open;
    WriteToProcessLog(capt+'query executed: '+q.SQL.Text);
    if (q.RecordCount <> 1) or (q.FieldCount <> 1) then
      WriteToErrorLog(capt+'Error #1 rc = '+IntToStr(q.RecordCount)+#9+IntToStr(q.FieldCount));
    if (q.Fields[0].AsString <> '-2400.34')  then
      WriteToErrorLog(capt+'Error #2: '+q.Fields[0].AsString);
    q.Next;
    if (not q.Eof) then
      WriteToErrorLog(capt+'error #3 - not EOF!');

  finally
    q.SQL.Text := 'DROP TABLE test;';
    q.ExecSQL;
    q.Free;
  end;
end; // TestSimpleExpressions


{$IFDEF TEST_CI}
procedure TUnitTestACRQuery.TestCaseInsensitiveExpressions;

var q:  TACRQuery;
    t:  TACRTable;
    db: TACRDatabase;

 procedure RunTest(q: TACRQuery; t: TACRTable; db: TACRDatabase);
 var capt: String;
 begin
   if (db = nil) then
    capt := 'TestCaseInsensitiveExpressions (MEMORY) - '
   else
   if (db.InMemory) then
    capt := 'TestCaseInsensitiveExpressions (MEMORY DB) - '
   else
    capt := 'TestCaseInsensitiveExpressions (DISK) - ';
   try
    // test table
    if (t.Exists) then
     t.DeleteTable(True);
    t.ClearDefinitions;
    t.FieldDefs.Add('f1',ftFixedChar,20);
    t.IndexDefs.Add('i1','f1',[ixCaseInsensitive]);
    t.IndexDefs.Add('i2','f1',[]);
    t.CreateTable;
    t.Open;
    WriteToProcessLog(capt+'table created');
    t.InsertRecord(['aaa']);
    t.InsertRecord(['baa']);
    t.InsertRecord(['Aaa']);
    WriteToProcessLog(capt+'records inserted');
    // last error: 13

    // query test
    q.CaseInsensitive := False;
    // read only
    q.RequestLive := False;
    q.SQL.Text := 'SELECT * FROM '+t.TableName+' WHERE f1 = "Baa"';
    q.Open;
    if (q.RecordCount = 0) then
     WriteToProcessLog(capt+t.Filter+' #11 - OK')
    else
     WriteToErrorLog(capt+t.Filter+' #11 - FAILED'+#13#10+IntToStr(q.RecordCount));
    q.CaseInsensitive := True;
    q.SQL.Text := 'SELECT * FROM '+t.TableName+' WHERE f1 = "Baa"';
    q.Open;
    if (q.RecordCount = 1) then
     WriteToProcessLog(capt+t.Filter+' #12 - OK')
    else
     WriteToErrorLog(capt+t.Filter+' #12 - FAILED'+#13#10+IntToStr(q.RecordCount));
    // live
    q.SQL.Text := 'SELECT * FROM '+t.TableName+' WHERE f1 = "bAa"';
    q.RequestLive := True;
    q.Open;
    if (q.RecordCount = 1) then
     WriteToProcessLog(capt+t.Filter+' #13 - OK')
    else
     WriteToErrorLog(capt+t.Filter+' #13 - FAILED'+#13#10+IntToStr(q.RecordCount));

    // table test
    t.CaseInsensitive := False;
    t.FilterOptions := [];
    t.Filtered := False;
    t.Filter := 'f1 = "aaa"';
    t.Filtered := True;
    if (t.RecordCount = 1) then
     WriteToProcessLog(capt+t.Filter+' #1 - OK')
    else
     WriteToErrorLog(capt+t.Filter+' #1 - FAILED'+#13#10+IntToStr(t.RecordCount));
    t.Filtered := False;

    t.CaseInsensitive := True;
    t.Filtered := False;
    t.Filter := 'f1 = "Aaa"';
    t.Filtered := True;
    if (t.RecordCount = 2) then
     WriteToProcessLog(capt+t.Filter+' #2 - OK')
    else
     WriteToErrorLog(capt+t.Filter+' #2 - FAILED'+#13#10+IntToStr(t.RecordCount));
    t.Filtered := False;

    t.CaseInsensitive := False;
    if (t.Locate('f1','Baa',[])) then
     WriteToErrorLog(capt+'#3 - FAILED')
    else
     WriteToProcessLog(capt+'#3 - OK');

    t.CaseInsensitive := True;
    if (not t.Locate('f1','Baa',[])) then
     WriteToErrorLog(capt+'#4 - FAILED')
    else
     WriteToProcessLog(capt+'#4 - OK');
    if (db <> nil) then
    begin
      // test db - case sensitive
      db.CaseInsensitive := False;
      if (t.CaseInsensitive <> db.CaseInsensitive) then
       WriteToErrorLog(capt+'#7 FAILED');
      t.Filtered := False;
      t.Filter := 'f1 = "Aaa"';
      t.Filtered := True;
      if (t.RecordCount = 1) then
       WriteToProcessLog(capt+t.Filter+' #5 - OK')
      else
       WriteToErrorLog(capt+t.Filter+' #5 - FAILED'+#13#10+IntToStr(t.RecordCount));
      t.Filtered := False;
      if (t.Locate('f1','Baa',[])) then
       WriteToErrorLog(capt+'#6 - FAILED')
      else
       WriteToProcessLog(capt+'#6 - OK');
      // test db - case insensitive
      db.CaseInsensitive := True;
      if (t.CaseInsensitive <> db.CaseInsensitive) then
       WriteToErrorLog(capt+'#8 FAILED');
      t.Filtered := False;
      t.Filter := 'f1 = "Aaa"';
      t.Filtered := True;
      if (t.RecordCount = 2) then
       WriteToProcessLog(capt+t.Filter+' #9 - OK')
      else
       WriteToErrorLog(capt+t.Filter+' #9 - FAILED'+#13#10+IntToStr(t.RecordCount));
      t.Filtered := False;
      if (not t.Locate('f1','Baa',[])) then
       WriteToErrorLog(capt+'#10 - FAILED')
      else
       WriteToProcessLog(capt+'#10 - OK');
    end;
   finally
     t.Close;
     q.Close;
     if (t.Exists) then
      t.DeleteTable(True);
   end;
 end; // RunTest

begin
 q := TACRQuery.Create(nil);
 t := TACRTable.Create(nil);
 db := TACRDatabase.Create(nil);
 try
   // test in-memory mode (InMemory property)
   t.TableName := 'test_ci_expr';
   t.InMemory := True;
   q.InMemory := True;
   RunTest(q,t,nil);

   // test in-memory mode with database (InMemory property)
   db.InMemory := True;
   q.DatabaseName := db.DatabaseName;
   t.DatabaseName := db.DatabaseName;
   RunTest(q,t,db);

   // test disk database
   db.Close;
   db.InMemory := False;
   db.DatabaseFileName := TempDir+'test_ci_expr.adb';
   db.CreateDatabase;
   db.Open;
   q.InMemory := False;
   q.DatabaseName := db.DatabaseName;
   t.InMemory := False;
   t.DatabaseName := db.DatabaseName;
   RunTest(q,t,db);

 finally
   q.Free;
   t.Free;
   db.Close;
   db.DeleteDatabase;
   db.Free;
 end;
end; // TestCaseInsensitiveExpressions
{$ENDIF}

procedure TUnitTestACRQuery.TestConstraint;
var q:         TACRQuery;
    capt,s:    String;
begin
  capt := 'TestConstraint - ';
  q := TACRQuery.Create(nil);
  try
    WriteToProcessLog(capt+'Starting...');
    q.InMemory := True;

    q.SQL.Text := 'CREATE TABLE Suppliers (id INTEGER CONSTRAINT NN_supplier_id NOT NULL, '
                 +'name CHAR(50) CONSTRAINT NOT NULL, '
                 +'CONSTRAINT PRIMARY KEY (id))';
    q.ExecSQL;
    WriteToProcessLog(capt+'OK: '+#13#10+q.SQL.Text);

    q.SQL.Text := 'CREATE TABLE "Products" ( "product_id" INTEGER NOT NULL,'
                 +'"product_type_code" CHAR(15) NOT NULL,'
                 +'"supplier_code" VARCHAR(15) NOT NULL,'
                 +'CONSTRAINT [PK_Products] PRIMARY KEY ([product_id]))';
    q.ExecSQL;
    WriteToProcessLog(capt+'OK: '+#13#10+q.SQL.Text);

    WriteToProcessLog(capt+'tables created');

    q.SQL.Text := 'ALTER TABLE Products ADD CONSTRAINT Suppliers_Products '
                 +'FOREIGN KEY (supplier_code) REFERENCES Suppliers (supplier_code)';
    q.ExecSQL;
    WriteToProcessLog(capt+'OK: '+#13#10+q.SQL.Text);

    q.SQL.Text := 'ALTER TABLE Products ADD COLUMN (sup_code INTEGER)';
    q.ExecSQL;
    WriteToProcessLog(capt+'OK: '+#13#10+q.SQL.Text);

  finally
    q.SQL.Text := 'DROP TABLE Products CASCADE; DROP TABLE Suppliers CASCADE;';
    q.ExecSQL;
    WriteToProcessLog(capt+'OK: '+#13#10+q.SQL.Text);
    q.Free;
  end;
end; // TestConstraint


initialization
  UnitTestACRQuery := TUnitTestACRQuery.Create(UnitTestList);

finalization
  UnitTestACRQuery.Free;

end.
