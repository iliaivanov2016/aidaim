unit uMain;

interface

{$DEFINE SMALL_DATABASE}
{$DEFINE BDE_PARADOX}
{DEFINE BDE_ACCESS}
{$DEFINE DBISAM}
{DEFINE ADVANTAGE}
{DEFINE KEYDB}
{$DEFINE ACCURACER}
{$DEFINE ACCURACER_DISK}
{$DEFINE EASYTABLE}

{DEFINE MEM_CHECK}
{DEFINE AUTORUN}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, Db, DBTables, Gauges
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
,udbSQL
{$ENDIF}
  ;
const ODBCAccessAlias = 'AST';
const BDEAccessAliasName = 'BDEAccess';
const ODBCTetAlias = 'ODBCTet'; // alias to ODBC data source
const BDETetAliasName = 'BDETet'; // alias to bde

type
  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
    Indicator: TGauge;
    Log: TMemo;
    bnStart: TBitBtn;
    procedure BitBtn1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure bnStartClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
   procedure RunTests;
   procedure SQLWriteLog(s: string);
  end;

var
  Form1: TForm1;
{$IFDEF BDE_PARADOX}
 tBDE: TTable;
{$ENDIF}
{$IFDEF BDE_Access}
 tODBC:  TTable;
 dbODBC: TDatabase;
{$ENDIF}
{$IFDEF DBISAM}
 tDBISAM: TDBISAMTable;
{$ENDIF}
{$IFDEF ADVANTAGE}
  tADS: TAdsTable;
  dbADS: TAdsConnection;
{$ENDIF}
{$IFDEF KEYDB}
 tKeyDB: TUdbTable;
 dbKeyDB: TUdbDatabase;
{$ENDIF}
{$IFDEF ACCURACER}
  tACR: TACRTable;
  ACRdb: TACRDatabase;
  tACRMemory: TACRTable;
{$ENDIF}
{$IFDEF EASYTABLE}
  tET: TEasyTable;
{$ENDIF}

const
{$IFDEF SMALL_DATABASE}
 NumRecords1 = 100;
 NumRecords2 = 100;
 NumRecords3 = 100;
 NumGroups = 1;
{$ELSE}
 NumRecords1 = 1000;
 NumRecords2 = 1000;
 NumRecords3 = 1000;
 NumGroups = 10;
{$ENDIF}
 NumEqualRecords = 10;
 StringLength = 50;
 MinMemoLength = 1024;
 MaxMemoLength = 10240;
 LogFileName = 'log.csv';

function GenerateString(
                       len : Integer
                       ) : String; // returns serial
implementation

{$R *.DFM}

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
 Close;
 Application.Terminate;
 Application.ProcessMessages;
end;

procedure TForm1.RunTests;
var path,str,memo:   string;
    i,j,k,int,n,g:  integer;
    t:              cardinal;
    eInt:           array [0..NumGroups-1] of integer;
    eStr:           array [0..NumGroups-1] of string;
    timeET,
    timeACR,
    timeACRDisk,
    timeADVANTAGE,
    timeDBISAM,
    timeKEYDB,
    timePARADOX,
    timeACCESS:        cardinal;

 // return time
 function InsertRecord(ds: TDataset; FInteger: Integer; FString: String;
                      FMemo: String; id: Integer = -1): Cardinal;
 begin
  Result := GetTickCount;
  ds.Insert;
  if (id <> -1) then
   ds.FieldByName('ID').AsInteger := id;
  ds.FieldByName('FInteger').AsInteger := FInteger;
  ds.FieldByName('FString').AsString := FString;
  if (FMemo = '') then
    ds.FieldByName('FMemo').Clear
  else
    ds.FieldByName('FMemo').AsString := FMemo;
  ds.Post;
  Result := GetTickCount - Result;
 end; // InsertRecord

begin
 bnStart.Enabled := false;
 path := ExtractFilePath(Application.Exename);
 str := GetCurrentDir;
 SetCurrentDir(path + '..\Data');
 path := GetCurrentDir;
 SetCurrentDir(str);
 {$IFDEF BDE_PARADOX}
 tBDE := TTable.Create(self);
 tBDE.DatabaseName := path+'\Paradox';
 {$ENDIF}
 {$IFDEF BDE_ACCESS}
 tODBC := TTable.Create(self);
 dbODBC := TDatabase.Create(self);
 dbODBC.AliasName := ODBCAccessAlias; // alias
 dbODBC.LoginPrompt := false;
 dbODBC.KeepConnection := true;
 dbODBC.DatabaseName := BDEAccessAliasName;
 dbODBC.Connected := true;
 tODBC.DatabaseName := BDEAccessAliasName;
 {$ENDIF}
 {$IFDEF DBISAM}
 tDBISAM := TDBISAMTable.Create(self);
 tDBISAM.DatabaseName := path+'\Dbisam';
 {$ENDIF}
 {$IFDEF ADVANTAGE}
 tADS := TADSTable.Create(self);
 dbADS := TAdsConnection.Create(self);
 dbADS.ConnectPath := path+'\Advantage';
 dbADS.AdsServerTypes := [stADS_LOCAL];
 dbADS.IsConnected := true;
 tADS.AdsConnection := dbADS;
 {$ENDIF}
 {$IFDEF KEYDB}
  tKeyDB := TUdbTable.Create(self);
  dbKeyDB := TUdbDatabase.Create(self);
  dbKeyDB.Exclusive := true;
  dbKeyDB.Databasename := path+'\test.udb';
  dbKeyDB.CreateDatabase;
  dbKeyDB.Connected := true;
  tKeyDB.DataBase := dbKeyDB;
 {$ENDIF}
{$IFDEF ACCURACER}
      {$IFDEF ACCURACER_DISK}
      ACRdb:= TACRDatabase.Create(self);
      ACRdb.DatabaseFileName := path+'\test.adb';
      ACRdb.DatabaseName := 'TestDB';
      if (ACRdb.Exists) then
       ACRdb.DeleteDatabase;
      ACRdb.CreateDatabase;
      ACRdb.Exclusive := True;
      ACRdb.Open;
      tACR := TACRTable.Create(self);
      tACR.DatabaseName := ACRdb.DatabaseName;
      {$ENDIF}
  tACRMemory := TACRTable.Create(self);
  tACRMemory.InMemory := True;
{$ENDIF}
{$IFDEF EASYTABLE}
  tET := TEasyTable.Create(self);
  tET.DatabaseFileName := path+'\test.edb';
{$ENDIF}

 for i := 0 to NumGroups - 1 do
  begin
   eInt[i] := Random(MAXINT); // key integer
   eStr[i] := GenerateString(StringLength);  // key string
  end;

 for i := 1 to 3 do
  begin
    SQLWriteLog('Creating table #'+IntToStr(i));
    Application.ProcessMessages;
    {$IFDEF EASYTABLE}
     tET.Close;
     tET.TableName := 'JT'+IntToStr(i);
     tET.IndexDefs.Clear;
     tET.FieldDefs.Clear;
     tET.FieldDefs.Add('ID',ftAutoInc);
     tET.FieldDefs.Add('FInteger',ftInteger);
     tET.FieldDefs.Add('FString',ftString,StringLength);
     tET.FieldDefs.Add('FMemo',ftMemo);
     tET.IndexDefs.Add('IdxID','ID',[ixPrimary]);
     tET.IndexDefs.Add('IdxInt','FInteger',[]);
     tET.IndexDefs.Add('IdxStr','FString',[]);
     tET.IndexDefs.Add('IdxIntStr','FString;FInteger',[]);
     tET.CreateTable;
     tET.Open;
    {$ENDIF}
    {$IFDEF ACCURACER}

      {$IFDEF ACCURACER_DISK}
       tACR.Close;
       tACR.TableName := 'JT'+IntToStr(i);
       tACR.IndexDefs.Clear;
       tACR.FieldDefs.Clear;
       tACR.FieldDefs.Add('ID',ftAutoInc);
       tACR.FieldDefs.Add('FInteger',ftInteger);
       tACR.FieldDefs.Add('FString',ftString,StringLength);
       tACR.FieldDefs.Add('FMemo',ftMemo);
       tACR.IndexDefs.Add('IdxID','ID',[ixPrimary]);
       tACR.IndexDefs.Add('IdxInt','FInteger',[]);
       tACR.IndexDefs.Add('IdxStr','FString',[]);
       tACR.IndexDefs.Add('IdxIntStr','FString;FInteger',[]);
       tACR.CreateTable;
       tACR.Open;
      {$ENDIF}

       tACRMemory.Close;
       tACRMemory.TableName := 'JT'+IntToStr(i);
       tACRMemory.IndexDefs.Clear;
       tACRMemory.FieldDefs.Clear;
       tACRMemory.FieldDefs.Add('ID',ftAutoInc);
       tACRMemory.FieldDefs.Add('FInteger',ftInteger);
       tACRMemory.FieldDefs.Add('FString',ftString,StringLength);
       tACRMemory.FieldDefs.Add('FMemo',ftMemo);
       tACRMemory.IndexDefs.Add('IdxID','ID',[ixPrimary]);
       tACRMemory.IndexDefs.Add('IdxInt','FInteger',[]);
       tACRMemory.IndexDefs.Add('IdxStr','FString',[]);
       tACRMemory.IndexDefs.Add('IdxIntStr','FString;FInteger',[]);
       tACRMemory.CreateTable;
       tACRMemory.Open;

    {$ENDIF}
    {$IFDEF BDE_PARADOX}
     tBDE.Close;
     tBDE.TableName := 'JT'+IntToStr(i);
     tBDE.IndexDefs.Clear;
     tBDE.FieldDefs.Clear;
     tBDE.FieldDefs.Add('ID',ftAutoInc);
     tBDE.FieldDefs.Add('FInteger',ftInteger);
     tBDE.FieldDefs.Add('FString',ftString,StringLength);
     tBDE.FieldDefs.Add('FMemo',ftMemo);
     tBDE.IndexDefs.Add('','ID',[ixPrimary]);
     tBDE.IndexDefs.Add('IdxInt','FInteger',[ixDescending]);
     tBDE.IndexDefs.Add('IdxStr','FString',[ixDescending]);
     tBDE.IndexDefs.Add('IdxIntStr','FString;FInteger',[ixDescending]);

     tBDE.CreateTable;
     tBDE.Open;
    {$ENDIF}
    {$IFDEF BDE_ACCESS}
     tODBC.Close;
     tODBC.TableName := 'JT'+IntToStr(i);
     tODBC.IndexDefs.Clear;
     tODBC.FieldDefs.Clear;
     tODBC.FieldDefs.Add('ID',ftAutoInc);
     tODBC.FieldDefs.Add('FInteger',ftInteger);
     tODBC.FieldDefs.Add('FString',ftString,StringLength);
     tODBC.FieldDefs.Add('FMemo',ftMemo);
     tODBC.IndexDefs.Add('IdxID','ID',[ixPrimary]);
{
     tODBC.IndexDefs.Add('IdxInt','FInteger',[ixDescending]);
     tODBC.IndexDefs.Add('IdxStr','FString',[ixDescending]);
     tODBC.IndexDefs.Add('IdxIntStr','FString;FInteger',[ixDescending]);
}
     tODBC.IndexDefs.Add('IdxInt','FInteger',[]);
     tODBC.IndexDefs.Add('IdxStr','FString',[]);
     tODBC.IndexDefs.Add('IdxIntStr','FString;FInteger',[]);
     tODBC.CreateTable;
     tODBC.Open;
    {$ENDIF}
    {$IFDEF DBISAM}
     tDBISAM.Close;
     tDBISAM.TableName := 'JT'+IntToStr(i);
     tDBISAM.IndexDefs.Clear;
     tDBISAM.FieldDefs.Clear;
     tDBISAM.FieldDefs.Add('ID',ftAutoInc);
     tDBISAM.FieldDefs.Add('FInteger',ftInteger);
     tDBISAM.FieldDefs.Add('FString',ftString,StringLength);
     tDBISAM.FieldDefs.Add('FMemo',ftMemo);
     tDBISAM.IndexDefs.Add('IdxID','ID',[ixPrimary]);
     tDBISAM.IndexDefs.Add('IdxInt','FInteger',[]);
     tDBISAM.IndexDefs.Add('IdxStr','FString',[]);
     tDBISAM.IndexDefs.Add('IdxIntStr','FString;FInteger',[]);
     tDBISAM.CreateTable;
     tDBISAM.Open;
    {$ENDIF}
    {$IFDEF ADVANTAGE}
     tADS.Close;
     tADS.TableName := 'JT'+IntToStr(i);
     tADS.IndexDefs.Clear;
     tADS.FieldDefs.Clear;
     tADS.FieldDefs.Add('ID',ftAutoInc);
     tADS.FieldDefs.Add('FInteger',ftInteger);
     tADS.FieldDefs.Add('FString',ftString,StringLength);
     tADS.FieldDefs.Add('FMemo',ftMemo);
     tADS.IndexDefs.Add('IdxID','ID',[ixPrimary]);
     tADS.IndexDefs.Add('IdxInt','FInteger',[]);
     tADS.IndexDefs.Add('IdxStr','FString',[]);
     tADS.IndexDefs.Add('IdxIntStr','FString;FInteger',[]);
     tADS.CreateTable;
     tADS.Open;
    {$ENDIF}
    {$IFDEF KEYDB}
     tKeyDb.Close;
     tKeyDb.TableName := 'JT'+IntToStr(i);
     tKeyDb.IndexDefs.Clear;
     tKeyDb.FieldDefs.Clear;
     tKeyDb.FieldDefs.Add('ID',ftAutoInc);
     tKeyDb.FieldDefs.Add('FInteger',ftInteger);
     tKeyDb.FieldDefs.Add('FString',ftString,StringLength);
     tKeyDB.FieldDefs.Add('FMemo',ftMemo);
     tKeyDb.IndexDefs.Add('IdxID','ID',[ixPrimary]);
     tKeyDb.IndexDefs.Add('IdxInt','FInteger',[]);
     tKeyDb.IndexDefs.Add('IdxStr','FString',[]);
     tKeyDb.IndexDefs.Add('IdxIntStr','FString;FInteger',[]);
     tKeyDb.CreateTable;
     tKeyDb.Open;
    {$ENDIF}
    k := 0;
    if (i = 1) then
     k := NumRecords1;
    if (i = 2) then
     k := NumRecords2;
    if (i = 3) then
     k := NumRecords3;
    SQLWriteLog('Filling table #'+IntToStr(i)+
      ' record count = ,'+IntToStr(k)+
      ', key records quantity = ,'+IntToStr(NumEqualRecords)+
      ', key records groups quantity = ,'+IntToStr(NumGroups)
      );
    Indicator.MaxValue := k;
    Indicator.MinValue := 0;
    Indicator.Progress := 0;
    Application.ProcessMessages;
    timeACR := 0;
    timeET := 0;
    timeACCESS := 0;
    timePARADOX := 0;
    timeKEYDB := 0;
    timeDBISAM := 0;
    timeADVANTAGE := 0;
    n := 0; // number of equal records inserted
    g := 0;
    for j := 1 to k do
     begin
      if ((j mod 3) = 0) then
       memo := ''
      else
       memo := GenerateString(Random(MaxMemoLength-MinMemoLength)+MinMemoLength);
      if (j mod NumEqualRecords = 0) and (j >= NumEqualRecords) and
         (n < NumEqualRecords) and (g < NumGroups) then
       begin
        // key record
        int := eInt[g];
        str := eStr[g];
        memo := str;
        inc(n);
        if (n = NumEqualREcords) then
         begin
          inc(g);
          n := 0;
         end;
       end
      else
       begin
        int := Random(MAXINT);
        str := GenerateString(StringLength);
       end;
      // inserting record

      // EasyTable
{$IFDEF EASYTABLE}
      Inc(TimeET,InsertRecord(tET,int,str,memo));
{$ENDIF}

      // Accuracer
{$IFDEF ACCURACER}
  {$IFDEF ACCURACER_DISK}
      Inc(TimeACRDisk,InsertRecord(tACR,int,str,memo));
  {$ENDIF}
      Inc(TimeACR,InsertRecord(tACRMemory,int,str,memo));
{$ENDIF}

      // BDE Paradox
{$IFDEF BDE_PARADOX}
      Inc(timePARADOX,InsertRecord(tBDE,int,str,memo));
{$ENDIF}

      // BDE Access
{$IFDEF BDE_ACCESS}
      Inc(timeACCESS,InsertRecord(tODBC,int,str,memo,j));
{$ENDIF}

      // DBISAM
{$IFDEF DBISAM}
      Inc(timeDBISAM,InsertRecord(tDBISAM,int,str,memo));
{$ENDIF}

      // ADVANTAGE
{$IFDEF ADVANTAGE}
      Inc(timeADVANTAGE,InsertRecord(tADS,int,str,memo));
{$ENDIF}

      // KEYDB
{$IFDEF KEYDB}
      Inc(timeKEYDB,InsertRecord(tKeyDB,int,str,memo));
{$ENDIF}

      Indicator.Progress := j;
      Application.ProcessMessages;
      if (Application.Terminated) then
       Exit;
     end; // inserting data
    if (n <> 0) then
     raise Exception.Create('invalid number of equal records inserted'); // number of equal records inserted
    if (g <> NumGroups) then
     raise Exception.Create('invalid number of groups of equal records inserted'); // number of equal records inserted
    SQLWriteLog('Time Accuracer = ,'+IntToStr(timeACRDisk));
    SQLWriteLog('Time Accuracer Memory = ,'+IntToStr(timeACR));
    SQLWriteLog('Time EasyTable = ,'+IntToStr(timeET));
    SQLWriteLog('Time BDE PARADOX = ,'+IntToStr(timePARADOX));
    SQLWriteLog('Time BDE ACCESS = ,'+IntToStr(timeACCESS));
    SQLWriteLog('Time DBISAM = ,'+IntToStr(timeDBISAM));
    SQLWriteLog('Time ADVANTAGE = ,'+IntToStr(timeADVANTAGE));
    SQLWriteLog('Time KEYDB = ,'+IntToStr(timeKEYDB)+#13#10);
    tACRMemory.Close;
    tACRMemory.SaveTableToFile(path+'\acr_m'+IntToStr(i)+'.tbl');
  end; // creating and filling tables
 Close;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 Application.ProcessMessages;
{$IFDEF ACCURACER}
 tACR.Free;
 tACRMemory.Free;
{$ENDIF}
{$IFDEF EASYTABLE}
 tET.Free;
{$ENDIF}
{$IFDEF BDE_PARADOX}
 tBDE.Free;
{$ENDIF}
{$IFDEF BDE_ACCESS}
 tODBC.Free;
 dbODBC.Free;
{$ENDIF}
{$IFDEF DBISAM}
 tDBISAM.Free;
{$ENDIF}
{$IFDEF ADVANTAGE}
 tADS.Free;
 dbADS.Free;
{$ENDIF}
{$IFDEF KEYDB}
 tKeyDb.Free;
 dbKeyDb.Free;
{$ENDIF}
 Application.Terminate;
end;

function GenerateString(
                       len : Integer 
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

procedure TForm1.SQLWriteLog(s: string);
begin
 Log.Lines.Add(s);
 Log.Lines.SaveToFile(LogFileName);
end;

procedure TForm1.bnStartClick(Sender: TObject);
begin
 RunTests;
end;

procedure TForm1.FormActivate(Sender: TObject);
begin
{$IFDEF AUTORUN}
 RunTests;
{$ENDIF}
end;

initialization

Randomize;

end.

