unit uMain;

interface

{$I TETManager.inc}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, Menus, ActnList, EasyTable, Db, StdCtrls, DBCtrls, Grids,
  DBGrids, ExtCtrls, AboutUnit, Buttons;

type
  TfmMain = class(TForm)
    StatusBar1: TStatusBar;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Database1: TMenuItem;
    Help1: TMenuItem;
    LoadSQLscript1: TMenuItem;
    Save1: TMenuItem;
    N1: TMenuItem;
    Ext1: TMenuItem;
    Open1: TMenuItem;
    Close1: TMenuItem;
    About1: TMenuItem;
    ds1: TDataSource;
    CurrentTable: TEasyTable;
    CurrentDB: TEasyDatabase;
    CurrentQuery: TEasyQuery;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    New1: TMenuItem;
    Splitter1: TSplitter;
    Panel1: TPanel;
    Panel2: TPanel;
    gbTables: TGroupBox;
    lbTables: TListBox;
    gbRes: TGroupBox;
    DBGrid1: TDBGrid;
    Panel3: TPanel;
    DBNavigator1: TDBNavigator;
    Splitter2: TSplitter;
    gbSQL: TGroupBox;
    reSQL: TRichEdit;
    bnOpenTable: TButton;
    bnRunSQL: TButton;
    bnCloseTable: TButton;
    Table1: TMenuItem;
    Opentable1: TMenuItem;
    Closetable1: TMenuItem;
    Query1: TMenuItem;
    Run1: TMenuItem;
    btOpenSQL: TButton;
    OpenQuery: TMenuItem;
    ReopenDatabaseItem: TMenuItem;
    procedure Open1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure bnExitClick(Sender: TObject);
    procedure Close1Click(Sender: TObject);
    procedure About1Click(Sender: TObject);
    procedure Ext1Click(Sender: TObject);
    procedure bnOpenTableClick(Sender: TObject);
    procedure lbTablesDblClick(Sender: TObject);
    procedure bnCloseTableClick(Sender: TObject);
    procedure CurrentTableAfterScroll(DataSet: TDataSet);
    procedure reSQLSelectionChange(Sender: TObject);
    procedure bnRunSQLClick(Sender: TObject);
    procedure New1Click(Sender: TObject);
    procedure CurrentTableAfterPost(DataSet: TDataSet);
    procedure CurrentTableAfterDelete(DataSet: TDataSet);
    procedure LoadSQLscript1Click(Sender: TObject);
    procedure Save1Click(Sender: TObject);
    procedure Run1Click(Sender: TObject);
    procedure Opentable1Click(Sender: TObject);
    procedure Closetable1Click(Sender: TObject);
    procedure DBGrid1TitleClick(Column: TColumn);
    procedure btOpenSQLClick(Sender: TObject);
    procedure ReopenDatabaseItemClick(Sender: TObject);
  private
    FBatchMode: boolean;
    FOutputFileName: string; // output for messages
    procedure AddDBToMRUList(const ADBName: string);
    function GetInitialDBName: string;
    function GetMRUDBName: string;
    procedure LoadMRUList(AList: TStringList);
    procedure SaveMRUList(AList: TStringList);
    procedure UpdateMRUList(AList: TStringList);
    procedure CloseDB;
    procedure SetDBName(ADBName: string);
    procedure InitMRUList;
    procedure ExportToFile(AExportFileName: string;
      AFieldNamesInFirstLineCSV: boolean; ACsvDelimiter: string);
    procedure ExecBatchQuery;
    procedure LogError(AMsg: string);
    { Private declarations }
  public
    { Public declarations }
    function OpenDatabase: Boolean;
    procedure OpenTable;
  end;

var
  fmMain: TfmMain;

implementation
uses
  Registry;
  
{$R *.DFM}
const
  SREG_APP_ROOT = '\Software\SQLConsole';
  MRU_MAX_CNT = 5;

procedure TfmMain.Open1Click(Sender: TObject);
var s: string;
begin
 CurrentDb.Connected := false;
 s := CurrentDb.DatabaseFileName;
 Close1.Enabled := false;
 OpenDialog.FileName := s;
 if (OpenDialog.Execute) then
  begin
   SetDBName(OpenDialog.FileName);
   if (not OpenDatabase) then
    begin
     CurrentDb.Connected := false;
     MessageDlg('Could not open database '''+CurrentDb.DatabaseFileName+'''.',
       mtError,[mbOk],0);
    end
   else
    Close1.Enabled := true;
  end;
end;


function TfmMain.OpenDatabase: Boolean;
var
  pass: string;
begin
 Close1.Enabled := false;
 CurrentDb.Connected := false;
 result := False;
 if (CurrentDb.Encrypted) then
  repeat
   try
    if (not InputQuery('Database "'+CurrentDB.DatabaseFileName+'" authentification','Enter password: ', pass)) then
		 break;
    CurrentDB.Password := pass;
    CurrentDb.Connected := true;
    Result := True;
   except
    CurrentDB.Connected := false;
    Result := False;
   end;
  until result
 else
  begin
    try
      CurrentDb.Connected := true;
      Result := True;
    except
      Result := False;
    end;
  end;
 if (Result) then
  begin
   bnOpenTable.Enabled := true;
   bnRunSQL.Enabled := true;
   lbTables.Items.Clear();
   CurrentDB.GetTablesList(lbTables.Items);
   gbTables.Caption := ' Available tables: '+IntToStr(lbTables.Items.Count)+' ';
   fmMain.Caption := 'EasyTable SQL Console - Database '''+
    ExtractFileName(CurrentDB.DatabaseFileName)+'''';
   Close1.Enabled := true;
  end;
 bnCloseTable.Enabled := false;
end; // OpenDatabase

procedure TfmMain.FormCreate(Sender: TObject);
var
  DbFileName,
  SqlFileName,
  CsvDelimiter: String;
  ExportFileName: String;
  FieldNamesInFirstLineCSV: boolean;
  pn: Integer;
begin
 OpenDialog1.InitialDir := ExtractFilePath(Application.ExeName);
 SaveDialog1.InitialDir := ExtractFilePath(Application.ExeName);

 DbFileName := GetInitialDBName;

 // Query FileName
 if ParamCount >= 2 then
  SqlFileName := ParamStr(2)
 else
  SqlFileName := '';

 pn := 3;
 CsvDelimiter := ',';
 FieldNamesInFirstLineCSV := false;
 FBatchMode := False;
 FOutputFileName := '';

 while pn <= ParamCount do
  begin
   // Export <filename>
   if (ParamCount >= pn+1) and ((UpperCase(ParamStr(pn))='-E') or
			     (UpperCase(ParamStr(pn))='-EXPORTNAME')) then
    begin
     ExportFileName := ParamStr(pn+1);
     inc(pn,2);
     Continue;
    end;

   // Output <filename> (for messages)
   if (ParamCount >= pn+1) and ((UpperCase(ParamStr(pn))='-O') or
			     (UpperCase(ParamStr(pn))='-OUTPUTNAME')) then
    begin
     FOutputFileName := ParamStr(pn+1);
     inc(pn,2);
     Continue;
    end;

   // Delimiter <char>
   if (ParamCount >= pn+1) and ((UpperCase(ParamStr(pn))='-D') or
			     (UpperCase(ParamStr(pn))='-DELIMITER')) then
    begin
     CsvDelimiter := ParamStr(pn+1);
     inc(pn,2);
     Continue;
    end;

   if (ParamCount >= pn) and ((UpperCase(ParamStr(pn))='-B') or
			     (UpperCase(ParamStr(pn))='-BATCH')) then
    begin
     FBatchMode := True;
     inc(pn);
     Continue;
    end;

   // Field Names In First Line CSV
   if (ParamCount >= pn) and ((UpperCase(ParamStr(pn))='-FNL') or
			     (UpperCase(ParamStr(pn))='FieldNamesInFirstLineCSV')) then
    begin
     inc(pn);
     FieldNamesInFirstLineCSV := true;
     Continue;
    end;
   inc(pn);
  end;

 // Open DataBase
 SetDBName(DbFileName);
 Close1Click(self);
 OpenDatabase();

 // Load Sql
 if SqlFileName <> '' then
  begin
   reSQL.Lines.LoadFromFile(ParamStr(2));

  end;

  // Export ?
  if ExportFileName <> '' then
  begin
    ExportToFile(ExportFileName, FieldNamesInFirstLineCSV, CsvDelimiter);
    Application.Terminate;
  end
  else if FBatchMode and (SqlFileName<>'') then
  // execute and exit
  begin
    ExecBatchQuery;
    Application.Terminate;
  end;

  InitMRUList;
end;

procedure TfmMain.ExecBatchQuery;
begin
  try
    bnRunSQLClick(Self);
  except
    on E:Exception do
    begin
      LogError(E.ClassName+': '+E.Message);
      Halt(1);
    end;
  end;
end;

procedure TfmMain.LogError(AMsg: string);
var
  OutputList: TStringList;
begin
  try
    if FOutputFileName<>'' then
    begin
      OutputList := TStringList.Create;
      try
	OutputList.Text := AMsg;
	OutputList.SaveToFile(FOutputFileName);
      finally
	OutputList.Free;
      end;
    end;
  except // ignore errors here
  end;
end;

procedure TfmMain.ExportToFile(AExportFileName: string;
  AFieldNamesInFirstLineCSV: boolean; ACsvDelimiter: string);
var
  fs: TFileStream;
  d, line, field: String;
  i: integer;
begin
   // Open Query
   btOpenSQLClick(Self);
   fs := TFileStream.Create(AExportFileName,fmOpenWrite or fmCreate);
   try

     // First Line in CSV contains Fild Names
     if AFieldNamesInFirstLineCSV then
      begin
       line := '';
       d := '';
       for i:= 0 to CurrentQuery.FieldCount-1 do
	begin
	 // Skip Blobs
	 if CurrentQuery.Fields[i].DataType in [ftMemo, ftFmtMemo, ftGraphic,
						ftBLOB, ftBCD, ftBytes] then Continue;
	 line := line + d + CurrentQuery.Fields[i].FieldName;
	 d := ACsvDelimiter;
	end;
       line := line + #13#10;
       fs.Write(line[1], length(line));
      end;

     // Write Data to CSV
     while not CurrentQuery.Eof do
     begin
      line := '';
      d := '';
      for i:= 0 to CurrentQuery.FieldCount-1 do
       begin
	// Skip Blobs
	if CurrentQuery.Fields[i].DataType in [ftMemo, ftFmtMemo, ftGraphic,
					       ftBLOB, ftBCD, ftBytes] then Continue;

	field := CurrentQuery.Fields[i].AsString;
	if Pos(ACsvDelimiter, field) <> 0 then
	 begin
	  StringReplace(field,'"','""',[rfReplaceAll]);
	  field := '"' + field + '"';
	 end;
	line := line + d + field;
	d := ACsvDelimiter;
       end;
      line := line + #13#10;
      fs.Write(line[1], length(line));
      CurrentQuery.Next;
     end;
   finally
    fs.Free;
   end;
end;

procedure TfmMain.bnExitClick(Sender: TObject);
begin
 Close();
end;

procedure TfmMain.Close1Click(Sender: TObject);
begin
 CurrentDB.Connected := false;
 fmMain.Caption := 'EasyTable SQL Console - No database opened';
 lbTables.Items.Clear();
 gbTables.Caption := ' Available tables: '+IntToStr(lbTables.Items.Count)+' ';
 bnOpenTable.Enabled := false;
 bnRunSQL.Enabled := false;
 Close1.Enabled := false;
end;

procedure TfmMain.About1Click(Sender: TObject);
begin
 SQLConsoleAbout.ShowModal();
end;

procedure TfmMain.Ext1Click(Sender: TObject);
begin
 Close();
end;

procedure TfmMain.OpenTable;
var f: boolean;
    name: string;
begin
 if (lbTables.ItemIndex = -1) then
  begin
   MessageDlg('You should select a table from available tables list.',
       mtError,[mbOk],0);
   Exit;
  end;
 gbRes.Caption :=  ' Total records: 0 ';
 bnCloseTable.Enabled := false;
 CurrentTable.Active := false;
 CurrentTable.TableName := lbTables.Items[lbTables.ItemIndex];
 if (not CurrentTable.IsTableEncrypted) then
  begin
   try
    CurrentTable.Active := true;
   except
    CurrentTable.Active := false;
    MessageDlg('Could not open table '''+CurrentTable.TableName+'''.',
       mtError,[mbOk],0);
    Exit;
   end;
  end // not encrypted
 else
  begin
   repeat
    try
     name:= InputBox('Table "'+CurrentTable.TableName+'" authentification','Enter password: ', '');
     if (name = '') then Exit;
     CurrentTable.Password := name;
     CurrentTable.Active := true;
     f := true;
    except
     f := false;
     if (MessageDlg('Invalid password. Do you want to try again?',mtConfirmation,[mbYes,mbNo],0) <> mrYes) then
      begin
       CurrentTable.Active := false;
       Exit;
      end;
    end;
   until f;
  end; // encrypted
 ds1.Enabled := false;
 ds1.DataSet := CurrentTable;
 ds1.Enabled := true;
 gbRes.Caption := ' Total records in table '''+CurrentTable.TableName+''': '+
   IntToStr(CurrentTable.RecordCount)+' ';
 bnCloseTable.Enabled := true;
end;


procedure TfmMain.bnOpenTableClick(Sender: TObject);
begin
 OpenTable;
end;

procedure TfmMain.lbTablesDblClick(Sender: TObject);
begin
 OpenTable;
end;

procedure TfmMain.bnCloseTableClick(Sender: TObject);
begin
 CurrentTable.Close;
 gbRes.Caption :=  ' Total records: 0 ';
 StatusBar1.Panels.Items[2].Text := '';
end;

procedure TfmMain.CurrentTableAfterScroll(DataSet: TDataSet);
begin
 if (DataSet.Active) then
  StatusBar1.Panels.Items[2].Text := 'Record # '+Format('%6d',[DataSet.RecNo])+' of '
   + Format('%6d',[DataSet.RecordCount])
 else
  StatusBar1.Panels.Items[2].Text := '';
 if (Dataset = TDataset(CurrentTable)) then
  if (DataSet.Active) then
   gbRes.Caption := ' Total records in table '''+CurrentTable.TableName+''': '+
    IntToStr(CurrentTable.RecordCount)+' ';
end;

procedure TfmMain.reSQLSelectionChange(Sender: TObject);
var point: TPoint;
begin
 point := reSQL.CaretPos;
 StatusBar1.Panels[1].Text := ' ' + Format('%6d',[point.y+1]) +
 ': ' + Format('%6d',[point.x+1]);
end;

procedure TfmMain.bnRunSQLClick(Sender: TObject);
var s: string;
begin
 bnCloseTableClick(self);
 gbRes.Caption :=  ' Total records: 0 ';
 CurrentQuery.Active := false;
 CurrentQuery.SQL.Text := reSQL.Text;
 s := '';
 try
  CurrentQuery.ExecSQL;
//  OpenDatabase;
  if FBatchMode then
    Exit;

  lbTables.Items.Clear();
  CurrentDB.GetTablesList(lbTables.Items);
  gbTables.Caption := ' Available tables: '+IntToStr(lbTables.Items.Count)+' ';
  if (CurrentQuery.RowsAffected <> -1) then
   MessageDlg('Query have been executed successfully. '+
	     IntToStr(CurrentQuery.RowsAffected)+
	     ' rows affected', mtInformation,[mbOk],0)
  else
   MessageDlg('Query have been executed successfully. ',
	      mtInformation,[mbOk],0);
 except
  on e: Exception do
   begin
    CurrentQuery.Active := false;
    if not FBatchMode then
      MessageDlg('Error executing query - '+e.Message,mtError,[mbOk],0)
    else
      raise;  
   end;
 end;
end;

procedure TfmMain.New1Click(Sender: TObject);
var s: string;
begin
 CurrentDb.Connected := false;
 s := CurrentDb.DatabaseFileName;
 SaveDialog.FileName := CurrentDb.DatabaseFileName;
 if (SaveDialog.Execute) then
  begin
   SetDBName(SaveDialog.FileName);
   CurrentDb.CreateDatabase;
  end;
 Close1.Enabled := false;
   if (not OpenDatabase) then
    begin
     CurrentDb.Connected := false;
     MessageDlg('Could not open database '''+CurrentDb.DatabaseFileName+'''.',
       mtError,[mbOk],0);
    end
   else
    Close1.Enabled := true;
end;

procedure TfmMain.CurrentTableAfterPost(DataSet: TDataSet);
begin
 if (Dataset = TDataset(CurrentTable)) then
  gbRes.Caption := ' Total records in table '''+CurrentTable.TableName+''': '+
   IntToStr(CurrentTable.RecordCount)+' ';
end;

procedure TfmMain.CurrentTableAfterDelete(DataSet: TDataSet);
begin
 if (Dataset = TDataset(CurrentTable)) then
  gbRes.Caption := ' Total records in table '''+CurrentTable.TableName+''': '+
   IntToStr(CurrentTable.RecordCount)+' ';
end;

procedure TfmMain.LoadSQLscript1Click(Sender: TObject);
begin
 if (OpenDialog1.Execute) then
  begin
   reSQL.Lines.LoadFromFile(OpenDialog1.FileName);
  end;
end;

procedure TfmMain.Save1Click(Sender: TObject);
begin
 if (SaveDialog1.Execute) then
  begin
   reSQL.Lines.SaveToFile(SaveDialog1.FileName);
  end;
end;

procedure TfmMain.Run1Click(Sender: TObject);
begin
 bnRunSQLClick(self);
end;

procedure TfmMain.Opentable1Click(Sender: TObject);
begin
 bnOpenTableClick(self);
end;

procedure TfmMain.Closetable1Click(Sender: TObject);
begin
 bnCloseTableClick(self);
end;

procedure TfmMain.DBGrid1TitleClick(Column: TColumn);
var s,s1: string;
begin
 if (ds1.Dataset = TDataSet(CurrentTable)) then
  begin
   try
    s := CurrentTable.IndexFieldNames;
    s1 := CurrentTable.IndexName;
    CurrentTable.IndexFieldNames := Column.FieldName;
   except
    if (s <> '') then
     CurrentTable.IndexFieldNames := s
    else 
     CurrentTable.IndexName := s1;
   end;
  end;
end;

procedure TfmMain.btOpenSQLClick(Sender: TObject);
var s: string;
begin
 bnCloseTableClick(self);
 gbRes.Caption :=  ' Total records: 0 ';
 CurrentQuery.Active := false;
 CurrentQuery.SQL.Text := reSQL.Text;
 s := '';
 try
  CurrentQuery.Active := true;
  ds1.Enabled := false;
  ds1.DataSet := CurrentQuery;
  ds1.Enabled := true;
  gbRes.Caption :=  ' Total records: '+ IntToStr(CurrentQuery.RecordCount) +' ';
  lbTables.Items.Clear();
  CurrentDB.GetTablesList(lbTables.Items);
  gbTables.Caption := ' Available tables: '+IntToStr(lbTables.Items.Count)+' ';
  Exit;
 except
  on E: Exception do
   begin
     CurrentQuery.Active := false;
     raise;
   end;
 end;
end;

{********************  PiotrL's code begin  ************************}

function TfmMain.GetInitialDBName: string;
begin
  // DataBase FileName
  if ParamCount >= 1 then
    Result := ParamStr(1)
  else
  begin
    Result := GetMRUDBName;
    if Result = '' then
      Result := ExtractFilePath(Application.ExeName)+'..\..\..\Demos\Data\DBDemos.edb';
  end;
  Result := ExpandFileName(Result);    
end;

procedure TfmMain.CloseDB;
begin
  Close1Click(self);
end;

procedure TfmMain.SetDBName(ADBName: string);
begin
  if CurrentDB.DatabaseFileName<>ADBName then
  begin
    CloseDB;
    CurrentDB.DatabaseFileName := ADBName;
    AddDBToMRUList(ADBName);
  end;
end;

function TfmMain.GetMRUDBName: string;
var
  slList: TStringList;
begin
  slList := TStringList.Create;
  try
    LoadMRUList(slList);
    if slList.Count>0 then
      Result := slList[0]
    else
      Result := '';
  finally
    slList.Free;
  end;
end;

procedure TfmMain.AddDBToMRUList(const ADBName: string);
var
  slList: TStringList;
  Idx: integer;
begin
  slList := TStringList.Create;
  try
    LoadMRUList(slList);
    Idx := slList.IndexOf(ADBName);

    if Idx>=0 then
      slList.Move(Idx, 0)
    else if slList.Count >= MRU_MAX_CNT then
    begin
      slList.Delete(slList.Count-1);
      slList.Insert(0, ADBName);
    end else
      slList.Insert(0, ADBName);

    SaveMRUList(slList);
    UpdateMRUList(slList);
  finally
    slList.Free;
  end;
end;

procedure TfmMain.InitMRUList;
var
  slList: TStringList;
begin
  slList := TStringList.Create;
  try
    LoadMRUList(slList);
    UpdateMRUList(slList);
  finally
    slList.Free;
  end;
end;

procedure TfmMain.LoadMRUList(AList: TStringList);
var
  Reg: TRegIniFile;
  i: Integer;
  Item: string;
begin
  Reg := TRegIniFile.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKey(SREG_APP_ROOT, True) then
      for i := 0 to MRU_MAX_CNT-1 do
      begin
	Item := Reg.ReadString('','File' + IntToStr(i),'');
	if Item <> '' then
	  AList.Add(Item)
	else
	  break;
      end;
  finally
    Reg.Free;
  end;
end;

procedure TfmMain.SaveMRUList(AList: TStringList);
var
  Reg: TRegIniFile;
  i: Integer;
  ItemName: string;
begin
  Reg := TRegIniFile.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKey(SREG_APP_ROOT, True) then
      for i := 0 to AList.Count-1 do
      begin
	ItemName := 'File' + IntToStr(i);
	Reg.WriteString('', ItemName, AList[i]);
      end;
  finally
    Reg.Free;
  end;
end;

// update menu items
procedure TfmMain.UpdateMRUList(AList: TStringList);
var
  NewMenuItem: TMenuItem;
  i: integer;
  sFilePath: string;
begin
  // delete all old items
  for i := 0 to ReopenDatabaseItem.Count - 1 do
  begin
    ReopenDatabaseItem.Delete(0);
  end;

  // add new items
  for i := 0 to AList.Count - 1 do
  begin
    sFilePath := AList[i];
    NewMenuItem := TMenuItem.Create(MainMenu1);
    ReopenDatabaseItem.Add(NewMenuItem);
    NewMenuItem.Caption := IntToStr(i) + ' ' + sFilePath;
    NewMenuItem.OnClick := ReopenDatabaseItemClick;
    if sFilePath = CurrentDB.DatabaseFileName then
      NewMenuItem.Checked := true;
  end;
  ReopenDatabaseItem.Enabled := AList.Count > 0;
end;

{********************  PiotrL's code end  ************************}

procedure TfmMain.ReopenDatabaseItemClick(Sender: TObject); //mroy
var
  sDatabaseFile: String;
begin
  sDatabaseFile := (Sender as TMenuItem).Caption;
  sDatabaseFile := StringReplace(sDatabaseFile, '&', '',[rfreplaceAll]);
  sDatabaseFile := Copy(sDatabaseFile, 3, Length(sDatabaseFile));
  SetDBName(sDatabaseFile);
  OpenDatabase;
end;


end.
