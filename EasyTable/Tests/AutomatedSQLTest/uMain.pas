unit uMain;

interface

{$O-}
{$HINTS OFF}
{$WARNINGS OFF}

{DEFINE EXCLUSIVE}
{DEFINE ACCURACER}
// for memory mode
// remove $ for disk mode
{DEFINE ACCURACER_MEMORY}

{$DEFINE EASYTABLE}
{DEFINE EASYTABLE_ODBC}
{$DEFINE BDE_PARADOX}
{DEFINE BDE_ACCESS}
{$DEFINE DBISAM}
{DEFINE ADVANTAGE}
{DEFINE KEYDB}

{DEFINE RUN_ALL}

{DEFINE MEM_CHECK}
uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, ExtCtrls, Db, Grids, DBGrids, DBCtrls, ComCtrls
  ,DBTables,  ACRDebug
{$IFDEF MEM_CHECK}
  ,Memcheck
{$ENDIF}
{$IFDEF ACCURACER}
  ,ACRMain
{$ENDIF}
{$IFDEF EASYTABLE}
  ,EasyTable
{$ENDIF}
{$IFDEF ADVANTAGE}
  ,adscnnct, adsdata, adsset,
  adsfunc, adstable
{$ENDIF}
{$IFDEF DBISAM}
, DBISAMTb
{$ENDIF}
{$IFDEF KEYDB}
,udbDatabase
,udbSQL, DBCtrls
{$ENDIF}
  ;
const LogFileName = 'ast.csv';
const ErrorLogFileName = 'ast_err.csv';
const crlf = #13#10;
const CurrentTest = ''; // all tests will be run
const SQLDir = 'SQL';
const EngineNames: array [0..8] of string =
  ('Paradox','Access','Advantage','DBISAM','KeyDb',
   'Accuracer Memory','Accuracer','EasyTable','EasyTable ODBC');

const ODBCAccessAlias = 'AST';
const BDEAccessAliasName = 'BDEAccess';
const ODBCTetAlias = 'ODBCTet'; // alias to ODBC data source
const BDETetAliasName = 'BDETet'; // alias to bde

var Test1Name, Test2Name: String;

type
 TEngineType = (etParadox,etAccess,etAdvantage,etDBISAM,etKeyDb,
                etAccuracerMemory,etAccuracer,etEasyTable,etEasyTableODBC);


const DefaultTestEngine = etEasyTable;
//const DefaultTestEngine = etAccess;
//const DefaultTestEngine = etDBISAM;
//const DefaultTestEngine = etParadox;
//const DefaultTestEngine = etEasyTableODBC;
const DefaultEtaloneEngine = etParadox;
//const DefaultEtaloneEngine = etParadox;

type
  TSQLCmd = record
   Text:      string;
   bExecute:  Boolean;
  end;


  TfmMain = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    dsTET: TDataSource;
    bnClose: TBitBtn;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    Splitter1: TSplitter;
    dsTest: TDataSource;
    ErrorLog: TMemo;
    Log: TMemo;
    gbBDE: TGroupBox;
    gbTET: TGroupBox;
    DBGrid1: TDBGrid;
    DBGrid2: TDBGrid;
    Splitter2: TSplitter;
    DBMemoTest2: TDBMemo;
    DBMemoTest1: TDBMemo;
    procedure bnCloseClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure qTest1AfterScroll(DataSet: TDataSet);
    procedure qTest2AfterScroll(DataSet: TDataSet);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    TestQueries:  array of string;
    TestNames:  array of string;
    TestCount:    integer;
    bConsoleMode: boolean;
    path: string;
  public
    { Public declarations }
    procedure SQLWriteLog(s: string; bError: Boolean = false);
    procedure RunTests;
    function CompareResults(qTest1: TDataset; qTest2: TDataset): Boolean;
    function ProcessScript(query: string): Boolean;
  end;


var
  fmMain: TfmMain;

{$IFDEF BDE_PARADOX}
 qPARADOX: TQuery;
{$ENDIF}
{$IFDEF BDE_ACCESS}
 qACCESS: TQuery;
 dbODBC: TDatabase;
{$ENDIF}
{$IFDEF DBISAM}
 qDBISAM: TDBISAMQuery;
{$ENDIF}
{$IFDEF ADVANTAGE}
 qADS: TAdsQuery;
 dbADS: TAdsConnection;
{$ENDIF}
{$IFDEF KEYDB}
 qKEYDB: TUdbQuery;
 dbKeyDB: TUdbDatabase;
{$ENDIF}

{$IFDEF ACCURACER}
 {$IFDEF ACCURACER_MEMORY}
  tACR1: TACRTable;
  tACR2: TACRTable;
  tACR3: TACRTable;
  qACRMemory: TACRQuery;
  {$ELSE}
  ACRdb: TACRDatabase;
  qACR: TACRQuery;
   {$ENDIF}
{$ENDIF}
{$IFDEF EASYTABLE}
  qEZT: TEasyQuery;
{$ENDIF}
{$IFDEF EASYTABLE_ODBC}
 qTET_ODBC: TQuery;
 dbTET_ODBC: TDatabase;
{$ENDIF}


implementation

{$R *.DFM}

procedure TfmMain.SQLWriteLog(s: string; bError: Boolean = false);
begin
 if (bError) then
  begin
   ErrorLog.Lines.Add(s);
   ErrorLog.Lines.SaveToFile(ErrorLogFileName);
  end
 else
  begin
   Log.Lines.Add(s);
   Log.Lines.SaveToFile(LogFileName);
  end;
end;


procedure TfmMain.bnCloseClick(Sender: TObject);
begin
 Close;
 Application.Terminate;
 Application.ProcessMessages;
end;

procedure TfmMain.FormShow(Sender: TObject);

 procedure FindScripts(StartDir: string; Recursive: Boolean);
 var sr: TSearchRec;
     sl: TStringList;
     name,s: string;
     i: integer;
 begin
 if (FindFirst(StartDir+'\*.*',faAnyFile,sr)= 0) then
  begin
   repeat
    if (sr.Name = '.') or (sr.Name = '..') then continue;
    name := StartDir+'\'+sr.Name;
    if ((sr.Attr and faDirectory) <> 0) then
     begin
      if (Recursive) then
       FindScripts(name,true);
     end
    else
     if (Pos('.SQL',UpperCase(sr.Name)) > 0) then
      begin
        // loading script
        inc(TestCount);
        SetLength(TestQueries,TestCount);
        SetLength(TestNames,TestCount);
        i := Length(ExtractFilePath(Application.ExeName))+1;
        s := Copy(name,i,Length(name)-i+1);
        TestNames[TestCount-1] := s;
        sl := TStringList.Create;
        sl.LoadFromFile(name);
        TestQueries[TestCount-1] := sl.Text;
        sl.Free;
      end; // script file found
   until FindNext(sr)<>0;
  end;
 end; // FindScripts


 var
    bRecursive: Boolean;
begin
{$IFDEF MEM_CHECK}
if (not bConsoleMode) then
 MemChk;
  {$IFDEF RUN_ALL}
  MemChk;
  {$ENDIF}
{$ENDIF}
 bRecursive := false;
 if (bConsoleMode) then
  SQLWriteLog('Running in console mode');
 {$IFDEF RUN_ALL}
 bRecursive := true;
 SQLWriteLog('Running all tests');
 {$ENDIF}
 if (bConsoleMode) then
   bRecursive := true;

 PageControl1.ActivePageIndex := 0;
 TestCount := 0;
 FindScripts(ExtractFilePath(Application.Exename)+SQLDir,bRecursive);
 RunTests;

end;


//------------------------------------------------------------------------------
// tet dataset scroll
//------------------------------------------------------------------------------
procedure TfmMain.qTest1AfterScroll(DataSet: TDataSet);
begin
 gbTET.Caption := Test1Name + ': Record '+IntToStr(DataSet.RecNo) +' of '+ IntToStr(DataSet.RecordCount);
end;


//------------------------------------------------------------------------------
// Test dataset scroll
//------------------------------------------------------------------------------
procedure TfmMain.qTest2AfterScroll(DataSet: TDataSet);
begin
 gbBDE.Caption := Test2Name + ': Record '+IntToStr(DataSet.RecNo) +' of '+ IntToStr(DataSet.RecordCount);
end;


//------------------------------------------------------------------------------
// finalize app
//------------------------------------------------------------------------------
procedure TfmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
dsTest.DataSet := nil;
{$IFDEF BDE_PARADOX}
 qPARADOX.Free;
{$ENDIF}
{$IFDEF BDE_ACCESS}
 qACCESS.Free;
 dbODBC.Free;
{$ENDIF}
{$IFDEF ADVANTAGE}
 qADS.Free;
 dbADS.Free;
{$ENDIF}
{$IFDEF KEYDB}
 qKeyDB.Free;
 dbKeyDb.Free;
{$ENDIF}
{$IFDEF ACCURACER}
 {$IFDEF ACCURACER_MEMORY}
  tACR1.Free;
  tACR2.Free;
  tACR3.Free;
  qACRMemory.Free;
  {$ELSE}
  ACRdb.Free;
  qACR.Free;
  {$ENDIF}
{$ENDIF}
{$IFDEF EASYTABLE}
  qEZT.Free;
{$ENDIF}
{$IFDEF EASYTABLE_ODBC}
 qTET_ODBC.Free;
 dbTET_ODBC.Free;
{$ENDIF}
end; // FormClose


//------------------------------------------------------------------------------
// initialize app
//------------------------------------------------------------------------------
procedure TfmMain.FormCreate(Sender: TObject);
begin
 DeleteFile(LogFileName);
 DeleteFile(ErrorLogFileName);
 Log.Lines.Clear;
 ErrorLog.Lines.Clear;
 bConsoleMode := ParamCount > 0;
 path := ExtractFilePath(Application.Exename)+'Data';
 {$IFDEF BDE_PARADOX}
 qPARADOX := TQuery.Create(self);
 qPARADOX.DatabaseName := path+'\Paradox';
 {$ENDIF}

 {$IFDEF BDE_ACCESS}
 qACCESS := TQuery.Create(self);
 dbODBC := TDatabase.Create(self);
 dbODBC.AliasName := ODBCAccessAlias; // alias
 dbODBC.LoginPrompt := false;
 dbODBC.KeepConnection := true;
 dbODBC.DatabaseName := BDEAccessAliasName;
 dbODBC.Connected := true;
 qACCESS.DatabaseName := BDEAccessAliasName;
 {$ENDIF}
 {$IFDEF DBISAM}
 qDBISAM := TDBISAMQuery.Create(self);
 qDBISAM.DatabaseName := path+'\Dbisam';
 {$ENDIF}
 {$IFDEF ADVANTAGE}
 qADS := TADSQuery.Create(self);
 dbADS := TAdsConnection.Create(self);
 dbADS.ConnectPath := path+'\Advantage';
 dbADS.AdsServerTypes := [stADS_LOCAL];
 dbADS.IsConnected := true;
 dbADS.Name := 'dbAds';
 qADS.DatabaseName := dbADS.Name;
 {$ENDIF}
 {$IFDEF KEYDB}
  qKEYDB := TUdbQuery.Create(self);
  dbKeyDB := TUdbDatabase.Create(self);
  dbKeyDB.Databasename := path+'\test.udb';
  dbKeyDB.Connected := true;
  qKEYDB.DataBase := dbKeyDB;
 {$ENDIF}
{$IFDEF ACCURACER}
 {$IFDEF ACCURACER_MEMORY}
  tACR1 := TACRTable.Create(self);
  tACR1.InMemory := True;
  tACR1.LoadTableFromFile(path+'\acr_m1.tbl');
  tACR2 := TACRTable.Create(self);
  tACR2.InMemory := True;
  tACR2.LoadTableFromFile(path+'\acr_m2.tbl');
  tACR3 := TACRTable.Create(self);
  tACR3.InMemory := True;
  tACR3.LoadTableFromFile(path+'\acr_m3.tbl');
  qACRMemory := TACRQuery.Create(self);
  qACRMemory.InMemory := True;
  tACR1.Open;
  tACR2.Open;
  tACR3.Open;
  {$ELSE}
  ACRdb := TACRDatabase.Create(nil);
  ACRdb.DatabaseName := 'TestDB';
  ACRdb.DatabaseFileName := path+'\test.adb';
    {$IFDEF EXCLUSIVE}
    ACRdb.Exclusive := True;
    {$ELSE}
    ACRdb.Exclusive := False;
    {$ENDIF}
  ACRdb.Open;
  qACR := TACRQuery.Create(self);
  qACR.DatabaseName := ACRdb.DatabaseName;
  {$ENDIF}
{$ENDIF}
{$IFDEF EASYTABLE}
  qEZT := TEasyQuery.Create(self);
  qEZT.DatabaseFileName := path + '\test.edb';
{$ENDIF}
{$IFDEF EASYTABLE_ODBC}
 qTET_ODBC := TQuery.Create(self);
 dbTET_ODBC := TDatabase.Create(self);
 dbTET_ODBC.AliasName := ODBCTetAlias; // alias
 dbTET_ODBC.LoginPrompt := false;
 dbTET_ODBC.KeepConnection := true;
 dbTET_ODBC.DatabaseName := BDETetAliasName;
 dbTET_ODBC.Connected := true;
 qTET_ODBC.DatabaseName := BDETetAliasName;
{$ENDIF}
end; // FormCreate


//------------------------------------------------------------------------------
// run tests
//------------------------------------------------------------------------------
procedure TfmMain.RunTests;
var i: integer;
    result: boolean;
begin
 SQLWriteLog(crlf+'Current date: ,'+ FormatDateTime('dd.mm.yyyy',Now));
 for i := 0 to TestCount-1 do
  begin
   if (Application.Terminated) then
    Exit;
   if (CurrentTest <> '') then
    if (UpperCase(TestNames[i]) <> UpperCase(CurrentTest)) then
     continue;
   SQLWriteLog(crlf+'Script #'+IntToStr(i+1)+', file '+TestNames[i]+'  Start time: ,'+
    FormatDateTime('hh:mm:ss.zzz',Now)
    +', ...');
   Application.ProcessMessages;
   result := ProcessScript(TestQueries[i]);
   if (not result) then
    begin
     SQLWriteLog('Error in Script #'+IntToStr(i+1)+', file '+
      TestNames[i]+crlf,true);
     if (not bConsoleMode) then
      break;
    end;
  end; // tests
 // errors
 Application.ProcessMessages;
 if (bConsoleMode) then
  begin
   Close;
   Application.Terminate;
   Application.ProcessMessages;
  end;
end; // RunTests


//------------------------------------------------------------------------------
// compare results
//------------------------------------------------------------------------------
function TfmMain.CompareResults(qTest1: TDataset; qTest2: TDataset): Boolean;
var i,j: integer;
    name: string;
    TestRecordCount1 : integer;
    TestRecordCount2 : integer;

 function CompareFields: Boolean;
 begin
  result := false;
  if (qTest1.Fields[j].IsBlob) then
   begin
    DBMemoTest1.DataField := qTest1.Fields[j].FieldName;
    DBMemoTest2.DataField := qTest2.Fields[j].FieldName;
   end;
  name := qTest1.Fields[j].FieldName;
  if (qTest1.Fields[j].IsNull <> qTest2.FieldByName(name).IsNull) then
   begin
    SQLWriteLog('Error - null values are not equal.');
    SQLWriteLog('Error - null values are not equal.',true);
    Exit;
   end;
  if (qTest1.Fields[j].IsBlob <> qTest2.FieldByName(name).IsBlob) then
   begin
    SQLWriteLog('Error - blob flags are not equal.');
    SQLWriteLog('Error - blob flags are not equal.',true);
   end;

  if (qTest1.Fields[j].AsString <> qTest2.FieldByName(name).AsString) then
   begin
      SQLWriteLog('Error - non-blob values are not equal.');
      SQLWriteLog('Error - non-blob values are not equal.',true);
      Exit;
   end;
  Result := true;
 end; // CompareFields

begin
 qTest1.First;
 qTest2.First;
 result := false;
 SQLWriteLog('Checking results ...');
 Application.ProcessMessages;
 if (qTest1.FieldCount <> qTest2.FieldCount) then
  begin
   SQLWriteLog('Error - field count differs. qTest1 FC = '+
    IntToStr(qTest1.FieldCount)+', qTest2 FC = '+IntToStr(qTest2.FieldCount));
   SQLWriteLog('Error - field count differs. qTest1 FC = '+
    IntToStr(qTest1.FieldCount)+', qTest2 FC = '+IntToStr(qTest2.FieldCount),true);
   Exit;
  end;
 if (qTest1.FieldDefs.Count <> qTest2.FieldDefs.Count) then
  begin
   SQLWriteLog('Error - field defs count differs. qTest1 FC = '+
    IntToStr(qTest1.FieldDefs.Count)+', qTest2 FC = '+IntToStr(qTest2.FieldDefs.Count));
   SQLWriteLog('Error - field defs count differs. qTest1 FC = '+
    IntToStr(qTest1.FieldDefs.Count)+', qTest2 FC = '+IntToStr(qTest2.FieldDefs.Count),true);
   Exit;
  end;

 TestRecordCount1 := 0;
 while (not qTest1.EOF) do
  begin
   inc(TestRecordCount1);
   qTest1.Next;
  end;

 TestRecordCount2 := 0;
 while (not qTest2.EOF) do
  begin
   inc(TestRecordCount2);
   qTest2.Next;
  end;

 qTest1.First;
 qTest2.First;
 if (TestRecordCount1 <> TestRecordCount2) then
  begin
   SQLWriteLog('Error - record count differs. qTest1 RecCount = '+
    IntToStr(TestRecordCount1)+', qTest2 RecCount = '+IntToStr(TestRecordCount2));
   SQLWriteLog('Error - record count differs. qTest1 RecCount = '+
    IntToStr(TestRecordCount1)+', qTest2 RecCount = '+IntToStr(TestRecordCount2),true);
   Exit;
  end;
 // check for skipped fields
 for i := 0 to qTest2.FieldDefs.Count-1 do
  begin
   if (qTest1.FieldDefs.IndexOf(qTest2.FieldDefs[i].Name) < 0) then
    begin
     SQLWriteLog('Error - field does not exists in TET query. FieldNo = '+
      IntToStr(i)+', qTest2 FieldName = '+qTest2.FieldDefs[i].Name);
     SQLWriteLog('Error - field does not exists in TET query. FieldNo = '+
      IntToStr(i)+', qTest2 FieldName = '+qTest2.FieldDefs[i].Name,true);
     Exit;
    end;
  end;
 // scanning structure
 for i := 0 to qTest1.FieldDefs.Count-1 do
  begin
   if (qTest2.FieldDefs.IndexOf(qTest1.FieldDefs[i].Name) < 0) then
    begin
     SQLWriteLog('Error - field does not exists in BDE query. FieldNo = '+
      IntToStr(i)+', qTest1 FieldName = '+
      qTest1.FieldDefs[i].Name);
     SQLWriteLog('Error - field does not exists in BDE query. FieldNo = '+
      IntToStr(i)+', qTest1 FieldName = '+
      qTest1.FieldDefs[i].Name,true);
     Exit;
    end;
//   if (qTest1.FieldDefs[i].DataType  <> qTest2.FieldDefs[i].DataType) then
if (false) then
    begin
     SQLWriteLog('Error - field types differs. FieldNo = '+IntToStr(i)+', qTest1 FieldName = '+
      qTest1.FieldDefs[i].Name+', qTest2 FieldName = '+qTest2.FieldDefs[i].Name);
     SQLWriteLog('Error - field types differs. FieldNo = '+IntToStr(i)+', qTest1 FieldName = '+
      qTest1.FieldDefs[i].Name+', qTest2 FieldName = '+qTest2.FieldDefs[i].Name,true);
     Exit;
    end;
//   if (qTest1.FieldDefs[i].Size <> qTest2.FieldDefs[i].Size) then
if (false) then
    begin
     SQLWriteLog('Error - field sizes differs. FieldNo = '+IntToStr(i)+', qTest1 FieldName = '+
      qTest1.FieldDefs[i].Name+', qTest2 FieldName = '+qTest2.FieldDefs[i].Name+
      ', qTest1 field size = '+
      IntToStr(qTest1.FieldDefs[i].Size)+', qTest2 field size = '+IntToStr(qTest2.FieldDefs[i].Size));
     SQLWriteLog('Error - field sizes differs. FieldNo = '+IntToStr(i)+', qTest1 FieldName = '+
      qTest1.FieldDefs[i].Name+', qTest2 FieldName = '+qTest2.FieldDefs[i].Name+
      ', qTest1 field size = '+
      IntToStr(qTest1.FieldDefs[i].Size)+', qTest2 field size = '+IntToStr(qTest2.FieldDefs[i].Size),true);
     Exit;
    end;
  end;

 i := 1; // first record
 while (not qTest1.EOF) do
  begin
   Application.ProcessMessages;
   for j := 0 to qTest1.FieldCount - 1 do
    if (not CompareFields) then
     begin
      SQLWriteLog('Error - records differs. RecordNo = '+
       IntToStr(i)+', FieldNo = '+
       IntToStr(j)+', qTest1 FieldName = '+
       qTest1.Fields[j].FieldName+', qTest2 FieldName = '+qTest2.FieldByName(name).FieldName);
      SQLWriteLog('Error - records differs. RecordNo = '+
       IntToStr(i)+', FieldNo = '+
       IntToStr(j)+', qTest1 FieldName = '+
       qTest1.Fields[j].FieldName+', qTest2 FieldName = '+qTest2.FieldByName(name).FieldName,true);
      Exit;
     end;
   qTest1.Next;
   qTest2.Next;
   if (qTest1.EOF <> qTest2.EOF) then
    begin
     SQLWriteLog('Error - EOF differs. RecordNo = '+IntToStr(i));
     SQLWriteLog('Error - EOF differs. RecordNo = '+IntToStr(i),true);
     Exit;
    end;
   inc(i);
  end; // records
 Result := true;
end; // CompareResults


//------------------------------------------------------------------------------
// processes script
// if returns false - break loop and show errors using grids
//------------------------------------------------------------------------------
function TfmMain.ProcessScript(query: string): Boolean;
var
    bExceptTest1,bExceptTest2: String;
    qTest1,qTest2: TDataset;
    Test1Time,Test2Time: Cardinal;
    Test1Commands,Test2Commands: array of TSQLCmd;
    NumTest1Commands,NumTest2Commands: integer;
    Engine1: TEngineType;
    Engine2: TEngineType;
    bTry:          Boolean;
    i:             integer;
//
 procedure ParseScript;
 var s,
     tet,test:    string;
     i,k:         integer;

  procedure Parse(bTest1: Boolean);
  var  s,ss:        string;
       sl:          TStringList;
       bExec:       Boolean;
       i,j:         integer;

   procedure AddCommand;
   begin
    if (bTest1) then
     begin
      inc(NumTest1Commands);
      SetLength(Test1Commands,NumTest1Commands);
      Test1Commands[NumTest1Commands-1].Text := ss;
      Test1Commands[NumTest1Commands-1].bExecute := bExec;
     end
    else
     begin
      inc(NumTest2Commands);
      SetLength(Test2Commands,NumTest2Commands);
      Test2Commands[NumTest2Commands-1].Text := ss;
      Test2Commands[NumTest2Commands-1].bExecute := bExec;
     end;
    ss := '';
    bExec := false;
   end; // AddCommand


  begin
    bExec := false;
    sl := TStringList.Create;
    if (bTest1) then
     sl.Text := tet
    else
     sl.Text := test;
    if (bTest1) then
     NumTest1Commands := 0
   else
     NumTest2Commands := 0;
    ss := '';
    for i := 0 to sl.Count-1 do
     begin
      s := sl.Strings[i];
      if (Length(s) > 0) then
       if (s[1] = '#') then
        begin
         if (Pos('EXEC',UpperCase(s)) > 0) then
          begin
           if (ss <> '') then
            AddCommand;
           bExec := true;
          end; // #exec
         continue;
        end; // #
      j := Pos(';',s);
      if (j > 0) or (i = sl.Count-1) then
       begin
        if (j > 0) then
          ss := ss + crlf + Copy(s,1,j-1)
        else
         ss := ss + crlf + s;
        // add command
        AddCommand;
       end // add command
      else
       ss := ss + crlf + s; // add line to the current command
     end; // lines
   if (ss <> '') then
    AddCommand;
   sl.Free;
  end; // Parse

  function GetDatasetForEngine(aEngine: TEngineType): TDataset;
  begin
    Result := nil;
    case aEngine of
    {$IFDEF BDE_PARADOX}
       etParadox:   Result := qParadox;
    {$ENDIF}
    {$IFDEF BDE_ACCESS}
       etAccess:    Result := qAccess;
    {$ENDIF}
    {$IFDEF ADVANTAGE}
       etAdvantage: Result := qADS;
    {$ENDIF}
    {$IFDEF DBISAM}
       etDBISAM:    Result := qDBISAM;
    {$ENDIF}
    {$IFDEF KEYDB}
       etKeyDb:     Result := qKeyDb;
    {$ENDIF}
    {$IFDEF ACCURACER}
      {$IFDEF ACCURACER_MEMORY}
      etAccuracerMemory: Result := qACRMemory;
      {$ELSE}
      etAccuracer: Result := qACR;
      {$ENDIF}
    {$ENDIF}
    {$IFDEF EASYTABLE}
      etEasyTable: Result := qEZT;
    {$ENDIF}
    {$IFDEF EASYTABLE_ODBC}
      etEasyTableODBC: Result := qTET_ODBC;
    {$ENDIF}
      end;
  end; // GetDatasetForEngine

 // ParseScript
 begin
  Engine1 := DefaultTestEngine;
  Engine2 := DefaultEtaloneEngine;
  s := UpperCase(query);
  k := -1;
  i := Pos(UpperCase('#'+EngineNames[Integer(etParadox)]),s);
  if (i > 0) then
   begin
    Engine2 := etParadox;
    k := i;
   end;
  i := Pos(UpperCase('#'+EngineNames[Integer(etAccess)]),s);
  if (i > 0) then
   begin
    Engine2 := etAccess;
    k := i;
   end;
  i := Pos(UpperCase('#'+EngineNames[Integer(etAdvantage)]),s);
  if (i > 0) then
   begin
    Engine2 := etAdvantage;
    k := i;
   end;
  i := Pos(UpperCase('#'+EngineNames[Integer(etDBISAM)]),s);
  if (i > 0) then
   begin
    Engine2 := etDBISAM;
    k := i;
   end;
  i := Pos(UpperCase('#'+EngineNames[Integer(etKeyDb)]),s);
  if (i > 0) then
   begin
    Engine2 := etKeyDb;
    k := i;
   end;
  i := Pos(UpperCase('#'+EngineNames[Integer(etEasyTable)]),s);
  if (i > 0) then
   begin
    Engine2 := etEasyTable;
    k := i;
   end;
  i := Pos(UpperCase('#'+EngineNames[Integer(etEasyTableODBC)]),s);
  if (i > 0) then
   begin
    Engine2 := etEasyTableODBC;
    k := i;
   end;
  i := Pos(UpperCase('#'+EngineNames[Integer(etAccuracer)]),s);
  if (i > 0) then
   begin
    Engine2 := etAccuracer;
    k := i;
   end;
  i := Pos(UpperCase('#'+EngineNames[Integer(etAccuracerMemory)]),s);
  if (i > 0) then
   begin
    Engine2 := etAccuracerMemory;
    k := i;
   end;
  // detect if engine was specified
  if (k > 0) then
   begin
    tet := Copy(query,1,k-1);
    test := Copy(query,k,Length(query)-k+1);
   end
  else
   begin
    tet := query;
    test := query;
   end;
  // parse tet
  Parse(true);
  // parse test
  Parse(false);
  qTest1 := GetDatasetForEngine(Engine1);
  if (qTest1 = nil) then
    raise Exception.Create('Engine 1 is not defined');
  qTest2 := GetDatasetForEngine(Engine2);
  if (qTest2 = nil) then
    raise Exception.Create('Engine 2 is not defined');
 end; // ParseScript

 // return true if exception was raised
 function RunSQLSommand(aEngine: TEngineType; aqTest: TDataset; aSQLCommand: TSQLCmd): String;
 begin
  Result := '';
  try
    case aEngine of
     etParadox:
      begin
{$IFDEF BDE_PARADOX}
        TQuery(aqTest).SQL.Text := aSQLCommand.Text;
        if (aSQLCommand.bExecute) then
         TQuery(aqTest).ExecSQL
        else
         aqTest.Open;
{$ENDIF}
      end;
     etAccess:
      begin
{$IFDEF BDE_ACCESS}
        TQuery(aqTest).SQL.Text := aSQLCommand.Text;
        if (aSQLCommand.bExecute) then
         TQuery(aqTest).ExecSQL
        else
         aqTest.Open;
{$ENDIF}
      end;
     etAdvantage:
      begin
{$IFDEF ADVANTAGE}
        TAdsQuery(aqTest).SQL.Text := aSQLCommand.Text;
        if (aSQLCommand.bExecute) then
         TAdsQuery(aqTest).ExecSQL
        else
         aqTest.Open;
{$ENDIF}
      end;
     etDBISAM:
      begin
{$IFDEF DBISAM}
        TDBISAMQuery(aqTest).SQL.Text := aSQLCommand.Text;
        if (aSQLCommand.bExecute) then
         TDBISAMQuery(aqTest).ExecSQL
        else
         aqTest.Open;
{$ENDIF}
      end;
     etKeyDb:
      begin
{$IFDEF KEYDB}
        TUdbQuery(aqTest).SQL.Text := aSQLCommand.Text;
        if (aSQLCommand.bExecute) then
         TUdbQuery(aqTest).ExecSQL
        else
         aqTest.Open;
{$ENDIF}
      end;
     etAccuracer, etAccuracerMemory:
      begin
{$IFDEF ACCURACER}
       TACRQuery(aqTest).SQL.Text := aSQLCommand.Text;
       if (aSQLCommand.bExecute) then
         TACRQuery(aqTest).ExecSQL
       else
         aqTest.Open;
{$ENDIF}
      end;
     etEasyTable:
      begin
{$IFDEF EASYTABLE}
       TEasyQuery(aqTest).SQL.Text := aSQLCommand.Text;
       if (aSQLCommand.bExecute) then
         TEasyQuery(aqTest).ExecSQL
       else
         aqTest.Open;
{$ENDIF}
      end;
     etEasyTableODBC:
      begin
{$IFDEF EASYTABLE_ODBC}
        TQuery(aqTest).SQL.Text := aSQLCommand.Text;
        if (aSQLCommand.bExecute) then
         TQuery(aqTest).ExecSQL
        else
         aqTest.Open;
{$ENDIF}
      end;
    end; // case engine
  except
   on e: Exception do
    begin
     Result := e.Message;
    end;
  end;
 end; // RunSQLSommand

begin
 bTry := Pos('#TRY',UpperCase(query)) > 0;
 // parse script
 ParseScript;
 // set qTest2 to etalon query
 Test1Name := EngineNames[Integer(Engine1)];
 Test2Name := EngineNames[Integer(Engine2)];
 SQLWriteLog('Comparing '+Test1Name+' with '+Test2Name);

 qTest1.DisableControls;
 qTest2.DisableControls;

  bExceptTest1 := '';
  Test1Time := 0;
  for i := 0 to NumTest1Commands-1 do
   begin
    qTest1.Close;
    aaInitTime;
    aaStartTime;
    bExceptTest1 := RunSQLSommand(Engine1,qTest1,Test1Commands[i]);
    aaStopTime;
    Inc(Test1Time,aaGetTime);
    SQLWriteLog('Command #'+ IntToStr(i+1)+', '+ Test1Name+' time = ,'+IntToStr(aaGetTime));
   end; // run test query

  bExceptTest2 := '';
  Test2Time := 0;
  for i := 0 to NumTest2Commands-1 do
   begin
    qTest2.Close;
    aaInitTime;
    aaStartTime;
    bExceptTest2 := RunSQLSommand(Engine2,qTest2,Test2Commands[i]);
    aaStopTime;
    Inc(Test2Time,aaGetTime);
    SQLWriteLog('Command #'+ IntToStr(i+1)+', '+ Test2Name+' time = ,'+IntToStr(aaGetTime));
   end; // run test query


 if ((Length(bExceptTest1) > 0) or (Length(bExceptTest2) > 0)) then
  begin
   result := false;
    if (bTry and (Length(bExceptTest1) > 0) and (Length(bExceptTest2) > 0)) then
     begin
      SQLWriteLog('Both engines have raised an excpetions - TRY directive OK.');
      result := true;
     end
    else
    if ((Length(bExceptTest1) > 0) and (Length(bExceptTest2) > 0)) then
     begin
      SQLWriteLog('Both engines have raised an excpetions: '+#13#10+Test1Name+':'+#13#10+bExceptTest1+#13#10+Test2Name+':'+#13#10+bExceptTest2);
      SQLWriteLog('Both engines have raised an excpetions.'+#13#10+Test1Name+':'+#13#10+bExceptTest1+#13#10+Test2Name+':'+#13#10+bExceptTest2,true);
     end
    else
    if ((Length(bExceptTest1) > 0)) then
     begin
      SQLWriteLog(Test1Name+' raised an exception.'+#13#10+Test1Name+':'+#13#10+bExceptTest1);
      SQLWriteLog(Test1Name+' raised an exception.'+#13#10+Test1Name+':'+#13#10+bExceptTest1,true);
     end
    else
    if ((Length(bExceptTest2) > 0)) then
     begin
      SQLWriteLog(Test2Name+' raised an exception.'+#13#10+Test2Name+':'+#13#10+bExceptTest2);
      SQLWriteLog(Test2Name+' raised an exception.'+#13#10+Test2Name+':'+#13#10+bExceptTest2,true);
     end;
   qTest1.EnableControls;
   qTest2.EnableControls;
   Exit;
  end; // exception was raised

  DBGrid1.DataSource := nil;
  DBGrid2.DataSource := nil;
  Result := CompareResults(qTest1,qTest2);

  qTest1.EnableControls;
  qTest2.EnableControls;
  DBGrid1.DataSource := dsTet;
  DBGrid2.DataSource := dsTest;

  if (result) then
   begin
    SQLWriteLog('OK. '+Test1Name+' full time = ,'+IntToStr(Test1Time)+', '+
      Test2Name+' full time = ,'+IntToStr(Test2Time)+crlf);
    if (not bConsoleMode) then
     begin
       dsTET.DataSet := qTest1;
       qTest1.AfterScroll := qTest1AfterScroll;
       qTest1AfterScroll(qTest1);

       dsTest.DataSet := qTest2;
       qTest2.AfterScroll := qTest2AfterScroll;
       qTest2AfterScroll(qTest2);
     end;
   end
  else
    begin
     result := false;
     if (bConsoleMode) then
      begin
//       result := true;
      end
     else
      begin
       PageControl1.ActivePageIndex := 1;
       dsTET.DataSet := qTest1;
       qTest1.AfterScroll := qTest1AfterScroll;
       qTest1AfterScroll(qTest1);

       dsTest.DataSet := qTest2;
       qTest2.AfterScroll := qTest2AfterScroll;
       qTest2AfterScroll(qTest2);
      end;
    end;
end; // ProcessScript

end.
