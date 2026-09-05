unit uMain;

// ByPS START
(*************************************************************
* Original source developed for Delphi2006 by AidAim Software
* Modified source code for Turbo Delphi
* Modifications made by Petr Skaloud  alias  ByPS
*    ByPS@Seznam.cz
*    www.ByPS.cz
*************************************************************)
// ByPS START

interface

{$I ver.inc}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, Menus, ActnList, Db, StdCtrls, DBCtrls, Grids,
  DBGrids, ExtCtrls, AboutUnit, Buttons, SQLMemMain, SQLMemComMain, SQLMemExcept, SQLMemTypes;

type
  TfmMain = class(TForm)
    StatusBar1: TStatusBar;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Help1: TMenuItem;
    LoadSQLscript1: TMenuItem;
    Save1: TMenuItem;
    N1: TMenuItem;
    Ext1: TMenuItem;
    About1: TMenuItem;
    ds1: TDataSource;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    Splitter1: TSplitter;
    Panel1: TPanel;
    Panel2: TPanel;
    gbTables: TGroupBox;
    lbTables: TListBox;
    Splitter2: TSplitter;
    gbSQL: TGroupBox;
    reSQL: TRichEdit;
    Table1: TMenuItem;
    Opentable1: TMenuItem;
    Closetable1: TMenuItem;
    Query1: TMenuItem;
    OpenQuery: TMenuItem;
    gbRes: TGroupBox;
    DBGrid1: TDBGrid;
    Panel3: TPanel;
    DBNavigator1: TDBNavigator;
    Panel4: TPanel;
    bnOpenQuery: TButton;
    Panel5: TPanel;
    bnOpenTable: TButton;
    bnCloseTable: TButton;
    Loadtable1: TMenuItem;
    Loadmultipletables1: TMenuItem;
    Savetable1: TMenuItem;
    Saveselectedtables1: TMenuItem;
    Savealltables1: TMenuItem;
    E1: TMenuItem;
    bnExecSQL: TButton;
    cbLiveQuery: TCheckBox;
    miExportTableToSQL: TMenuItem;
    miExportselectedtablestoSQL: TMenuItem;
    miExportalltablestoSQL: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure bnExitClick(Sender: TObject);
    procedure About1Click(Sender: TObject);
    procedure Ext1Click(Sender: TObject);
    procedure bnOpenTableClick(Sender: TObject);
    procedure lbTablesDblClick(Sender: TObject);
    procedure bnCloseTableClick(Sender: TObject);
    procedure CurrentTableAfterScroll(DataSet: TDataSet);
    procedure reSQLSelectionChange(Sender: TObject);
    procedure bnRunSQLClick(Sender: TObject);
    procedure CurrentTableAfterPost(DataSet: TDataSet);
    procedure CurrentTableAfterDelete(DataSet: TDataSet);
    procedure LoadSQLscript1Click(Sender: TObject);
    procedure Save1Click(Sender: TObject);
    procedure Opentable1Click(Sender: TObject);
    procedure Closetable1Click(Sender: TObject);
    procedure DBGrid1TitleClick(Column: TColumn);
    procedure btOpenSQLClick(Sender: TObject);
    procedure Loadtable1Click(Sender: TObject);
    procedure Savetable1Click(Sender: TObject);
    procedure Loadmultipletables1Click(Sender: TObject);
    procedure Savealltables1Click(Sender: TObject);
    procedure E1Click(Sender: TObject);
    procedure bnExecSQLClick(Sender: TObject);
    procedure Saveselectedtables1Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FillTablesList;
    procedure miExportTableToSQLClick(Sender: TObject);
    procedure miExportalltablestoSQLClick(Sender: TObject);
  private
    { Private declarations }
    // ByPS START
    // moved from form objects declaration
    CurrentTable: TSQLMemTable;
    SQLMemTable1: TSQLMemTable;
    // ByPS END
  public
    { Public declarations }
    // ByPS START
    // moved from form objects declaration
    // the about dialog is accessing this object.
    // the conversion for turbo delphi is in the most easy way
    CurrentQuery: TSQLMemQuery;
    // ByPS END
    function OpenDatabase: Boolean;
    procedure OpenTable;
    procedure UpdateTableList;
  end;

var
  fmMain: TfmMain;

implementation

uses Math, ExportToSQL;

{$R *.DFM}

function TfmMain.OpenDatabase: Boolean;
begin
  Result := true;
  bnOpenTable.Enabled := true;
  lbTables.Items.Clear();
  gbTables.Caption := ' Available tables: '+IntToStr(lbTables.Items.Count)+' ';
  fmMain.Caption := 'SQLMemTable SQL Console';
  bnCloseTable.Enabled := false;
end; // OpenDatabase

procedure TfmMain.FillTablesList;
begin
 lbTables.Items.Clear();
 CurrentTable.GetTableNames(lbTables.Items);
 gbTables.Caption := ' Available tables: '+IntToStr(lbTables.Items.Count)+' ';
end;

procedure TfmMain.FormCreate(Sender: TObject);
var
  SqlFileName,
  CsvDelimiter: String;
  ExportFileName: String;
  FieldNamesInFirstLineCSV: boolean;
  pn,i: Integer;
  fs: TFileStream;
  d, line, field: String;

begin
  // ByPS START
  // because turbo delphi can not use 3rd party component in design time,
  // I have to create objects manualy and set them the properties.
  CurrentQuery := TSQLMemQuery.Create(Self);
  CurrentTable := TSQLMemTable.Create(Self);
  SQLMemTable1 := TSQLMemTable.Create(Self);
  // converted from original DFM for Delphi2006
  // property TOP and LEFT removed
  with CurrentQuery do begin
    //CurrentVersion := '3.60 ';
    ReadOnly := False;
    AfterScroll := CurrentTableAfterScroll;
  end;
  // converted from original DFM for Delphi2006
  // property TOP and LEFT removed
  with CurrentTable do begin
    //CurrentVersion := '3.60 ';
    ReadOnly := False;
    AfterPost := CurrentTableAfterPost;
    AfterDelete := CurrentTableAfterDelete;
    AfterScroll := CurrentTableAfterScroll;
    TableName := 'Table864688926';
    Exclusive := False;
    MemoryTableAllocBy := 1000;
  end;
  // converted from original DFM for Delphi2006
  // property TOP and LEFT removed
  with SQLMemTable1 do begin
    //CurrentVersion := '3.60 ';
    ReadOnly := False;
    TableName := 'Table77742488';
    Exclusive := False;
    MemoryTableAllocBy := 1000;
  end;
  // ByPS END


 OpenDialog1.InitialDir := ExtractFilePath(Application.ExeName);
 SaveDialog1.InitialDir := ExtractFilePath(Application.ExeName);

 // Query FileName
 if ParamCount >= 2 then
  SqlFileName := ParamStr(2)
 else
  SqlFileName := '';

 // ExportFileName
 if ParamCount >= 3 then
  ExportFileName := ParamStr(3)
 else
  ExportFileName := '';

 pn := 4;
 CsvDelimiter := ',';
 FieldNamesInFirstLineCSV := false;

 while pn <= ParamCount do
  begin
   // Delimiter <char>
   if (ParamCount >= pn+1) and ((UpperCase(ParamStr(pn))='-D') or
                             (UpperCase(ParamStr(pn))='-DELIMITER')) then
    begin
     CsvDelimiter := ParamStr(pn+1);
     inc(pn,2);
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
 OpenDatabase();

 // Load Sql
 if SqlFileName <> '' then
  begin
   reSQL.Lines.LoadFromFile(ParamStr(2));
  end;

 // Export ?
 if ExportFileName <> '' then
  begin
   // Open Query
   btOpenSQLClick(Sender);
   fs := TFileStream.Create(ExportFileName,fmOpenWrite or fmCreate);
   try

     // First Line in CSV contains Fild Names
     if FieldNamesInFirstLineCSV then
      begin
       line := '';
       d := '';
       for i:= 0 to CurrentQuery.FieldCount-1 do
        begin
         // Skip Blobs
         if CurrentQuery.Fields[i].DataType in [ftMemo, ftFmtMemo, ftGraphic,
                                                ftBLOB, ftBCD, ftBytes] then Continue;
         line := line + d + CurrentQuery.Fields[i].FieldName;
         d := CsvDelimiter;
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
        if Pos(CsvDelimiter, field) <> 0 then
         begin
          StringReplace(field,'"','""',[rfReplaceAll]);
          field := '"' + field + '"';
         end;
        line := line + d + field;
        d := CsvDelimiter;
       end;
      line := line + #13#10;
      fs.Write(line[1], length(line));
      CurrentQuery.Next;
     end;
   finally
    fs.Free;
   end;
   Application.Terminate;
  end;
end;

procedure TfmMain.FormDestroy(Sender: TObject);
begin
  // ByPS START
  // free the local instances
  CurrentQuery.Free;
  CurrentTable.Free;
  SQLMemTable1.Free;
  // ByPS START
end;

procedure TfmMain.bnExitClick(Sender: TObject);
begin
 Close();
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
begin
 if (lbTables.ItemIndex = -1) then
  begin
   MessageDlg('You should select a table from available tables list.',
       mtError,[mbOk],0);
   Exit;
  end;
 if (lbTables.Items.Count <= 0) then
  begin
   MessageDlg('You should create a memory table at first.',
       mtError,[mbOk],0);
   Exit;
  end;
 gbRes.Caption :=  ' Total records: 0 ';
 bnCloseTable.Enabled := false;
 CurrentQuery.Close;
 CurrentTable.Active := false;
 CurrentTable.TableName := lbTables.Items[lbTables.ItemIndex];
 try
  CurrentTable.Active := true;
  FillTablesList;
 except
  CurrentTable.Active := false;
  MessageDlg('Could not open table '''+CurrentTable.TableName+'''.',
     mtError,[mbOk],0);
  Exit;
 end;
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
 CurrentQuery.Close;
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
  UpdateTableList;
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
    MessageDlg('Error executing query - '+e.Message,mtError,[mbOk],0);
   end;
 end;
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
var s:    String;
    t:    Cardinal;
    d,d1: Double;
begin
 bnCloseTableClick(self);
 gbRes.Caption :=  ' Total records: 0 ';
 CurrentQuery.Active := false;
 t := GetTickCount;
 CurrentQuery.SQL.Text := reSQL.Text;
 s := '';
 try
  CurrentQuery.RequestLive := cbLiveQuery.Checked;
  CurrentQuery.Active := true;
  t := GetTickCount - t;
  ds1.Enabled := false;
  ds1.DataSet := CurrentQuery;
  ds1.Enabled := true;
  gbRes.Caption :=  ' Total records: '+ IntToStr(CurrentQuery.RecordCount) +' ';
  d := t / 1000.0;
  d1 := CurrentQuery.RecordCount;
  bnOpenQuery.Hint := 'Query execution time, seconds: '+
  FormatFloat('#,##0.000',d)+'. Record count: '+FormatFloat('#,##0',d1);
  bnCloseTable.Enabled := true;
 except
  on E: ESQLMemException do
   begin
     if (E.NativeError <> 20001) then
      begin
       CurrentQuery.Active := false;
       raise;
      end;
   end
  else
   begin
     CurrentQuery.Active := false;
     raise;
   end;
 end;
 FillTablesList;
end;

procedure TfmMain.Loadtable1Click(Sender: TObject);
begin
 if OpenDialog.Execute then
  begin
   CurrentQuery.Close;
   CurrentTable.Close;
   CurrentTable.LoadTableFromFile(OpenDialog.FileName);
   CurrentTable.Open;
   ds1.DataSet := CurrentTable;
   UpdateTableList;
  end;
end;

procedure TfmMain.Savetable1Click(Sender: TObject);
begin
 if (not CurrentTable.Exists) then
  begin
   MessageDlg('Error: table '+QuotedStr(CurrentTable.TableName)+' does not exists',
              mtError,[mbOK],0);
   Exit;
  end;
 SaveDialog.Title := 'Save table '+ CurrentTable.TableName;
 if SaveDialog.Execute then
  try
   CurrentTable.Close;
   CurrentQuery.Close;
   CurrentTable.SaveTableToFile(SaveDialog.FileName);
   CurrentTable.Open;
   ds1.DataSet := CurrentTable;
  except
   on e: Exception do
    begin
     SysUtils.DeleteFile(SaveDialog.FileName);
     MessageDlg('Error saving table: '+#13#10+e.Message,mtError,[mbOK],0);
    end;
  end;
end;

procedure TfmMain.Loadmultipletables1Click(Sender: TObject);
begin
 if OpenDialog.Execute then
  begin
   SQLMemTable1.LoadAllTablesFromFile(OpenDialog.FileName);
   UpdateTableList;
  end;
end;

procedure TfmMain.Savealltables1Click(Sender: TObject);
var t,q: Boolean;
begin
 if (lbTables.Items.Count <= 0) then
  begin
   MessageDlg('There are no tables!',
              mtWarning,[mbOK],0);
   Exit;
  end;
 SaveDialog.Title := 'Save all tables';
 if SaveDialog.Execute then
  try
   t := CurrentTable.Active;
   q := CurrentQuery.Active;
   CurrentTable.Close;
   CurrentQuery.Close;
   CurrentTable.SaveAllTablesToFile(SaveDialog.FileName);
   if (t) then
    CurrentTable.Open;
   if (q) then
    CurrentQuery.Open;
  except
   on e: Exception do
    begin
     SysUtils.DeleteFile(SaveDialog.FileName);
     MessageDlg('Error saving table: '+#13#10+e.Message,mtError,[mbOK],0);
    end;
  end;
end;

procedure TfmMain.UpdateTableList;
var sl:  TStringList;
    sel: array of Boolean;
    i,j: Integer;
begin
 sl := TStringList.Create;
 sel := nil;
 try
   sl.Clear;
   sl.Assign(lbTables.Items);
   SetLength(sel,sl.Count);
   for i := 0 to sl.Count-1 do
     sel[i] := lbTables.Selected[i];
   FillTablesList;
   for i := 0 to sl.Count-1 do
    begin
     j := lbTables.Items.IndexOf(sl.Strings[i]);
     if (j >= 0) then
      lbTables.Selected[j] := sel[i];
    end;
 finally
  sl.Free;
  sel := nil;
 end;
 gbTables.Caption := 'Selected tables: ' +
       IntToStr(lbTables.SelCount) + ' of ' +
        IntToStr(lbTables.Items.Count);
end;

procedure TfmMain.E1Click(Sender: TObject);
begin
 bnExecSQLClick(Self);
end;

procedure TfmMain.bnExecSQLClick(Sender: TObject);
var
  t:    Cardinal;
  d,d1: Double;
begin
 t := GetTickCount;
 CurrentQuery.SQL.Text := reSQL.Text;
 CurrentQuery.ExecSQL;
 FillTablesList;
 t := GetTickCount - t;
 d := t / 1000.0;
 d1 := CurrentQuery.RowsAffected;
 bnExecSQL.Hint := 'Query execution time, seconds: '+
 FormatFloat('#,##0.000',d)+'. Rows affected: '+FormatFloat('#,##0',d1);
 MessageDlg(bnExecSQL.Hint,mtInformation,[mbOK],0);
end;

procedure TfmMain.Saveselectedtables1Click(Sender: TObject);
var t,q: Boolean;
    sl:  TSQLMemWideStringList;
    i:   Integer;
begin
 if (lbTables.Items.Count <= 0) then
  begin
   MessageDlg('There are no tables!',
              mtWarning,[mbOK],0);
   Exit;
  end;
 sl := TSQLMemWideStringList.Create;
 try
   for i := 0 to lbTables.Items.Count-1 do
    if (lbTables.Selected[i]) then
     sl.Add(lbTables.Items.Strings[i]);
   SaveDialog.Title := 'Save all tables';
   if SaveDialog.Execute then
    try
     t := CurrentTable.Active;
     q := CurrentQuery.Active;
     CurrentTable.Close;
     CurrentQuery.Close;
     CurrentTable.SaveTablesToFile(sl,SaveDialog.FileName);
     if (t) then
      CurrentTable.Open;
     if (q) then
      CurrentQuery.Open;
    except
     on e: Exception do
      begin
       SysUtils.DeleteFile(SaveDialog.FileName);
       MessageDlg('Error saving table: '+#13#10+e.Message,mtError,[mbOK],0);
      end;
    end;
 finally

 end;
end;

procedure TfmMain.miExportTableToSQLClick(Sender: TObject);
var table: TSQLMemTable;
    s:     AnsiString;
    i:     Integer;
begin
 fmExportToSQL.Caption := 'Export tables to SQL Script';
 if (fmExportToSQL.ShowModal = mrOk) then
  begin
   s := '';
   table := TSQLMemTable.Create(self);
   try
    Screen.Cursor := crHourGlass;
    if (CurrentTable.Active) then
     begin
      table.DatabaseName := CurrentTable.DatabaseName;
      table.TableName := CurrentTable.Handle.TableName;
      s := s + #13#10+table.ExportTableToSQL(fmExportToSQL.cbExportStructure.Checked,
                                       fmExportToSQL.cbAddDROPTable.Checked,
                                       fmExportToSQL.cbExportIndexes.Checked,
                                       fmExportToSQL.cbAddDROPIndex.Checked,
                                       fmExportToSQL.cbExportData.Checked,
                                       fmExportToSQL.cbExportBLOBFields.Checked,
                                       fmExportToSQL.cbUseBrackets.Checked)+#13#10;
     end;
    table.DatabaseName := CurrentTable.DatabaseName;
    for i := 0 to lbTables.Items.Count - 1 do
     if (lbTables.Selected[i]) then
      begin
       table.TableName := lbTables.Items[i];
       if (table.TableName = CurrentTable.TableName) and (CurrentTable.Active) then
        continue;
       if (i > 0) then
        s := s + #13#10;
       s := s + table.ExportTableToSQL(fmExportToSQL.cbExportStructure.Checked,
                                       fmExportToSQL.cbAddDROPTable.Checked,
                                       fmExportToSQL.cbExportIndexes.Checked,
                                       fmExportToSQL.cbAddDROPIndex.Checked,
                                       fmExportToSQL.cbExportData.Checked,
                                       fmExportToSQL.cbExportBLOBFields.Checked,
                                       fmExportToSQL.cbUseBrackets.Checked);

      end;
   finally
    table.Free;
    reSQL.Lines.Text := s;
    Screen.Cursor := crDefault;
   end;
  end;
end;

procedure TfmMain.miExportalltablestoSQLClick(Sender: TObject);
var table: TSQLMemTable;
    s:     AnsiString;
    i:     Integer;
begin
 UpdateTableList;
 fmExportToSQL.Caption := 'Export all tables to SQL Script';
 if (fmExportToSQL.ShowModal = mrOk) then
  begin
   s := '';
   table := TSQLMemTable.Create(self);
   try
    Screen.Cursor := crHourGlass;
    table.DatabaseName := CurrentTable.DatabaseName;
    for i := 0 to lbTables.Items.Count - 1 do
      begin
       table.TableName := lbTables.Items[i];
       if (i > 0) then
        s := s + #13#10;
       s := s + table.ExportTableToSQL(fmExportToSQL.cbExportStructure.Checked,
                                       fmExportToSQL.cbAddDROPTable.Checked,
                                       fmExportToSQL.cbExportIndexes.Checked,
                                       fmExportToSQL.cbAddDROPIndex.Checked,
                                       fmExportToSQL.cbExportData.Checked,
                                       fmExportToSQL.cbExportBLOBFields.Checked,
                                       fmExportToSQL.cbUseBrackets.Checked);

      end;
   finally
    table.Free;
    reSQL.Lines.Text := s;
    Screen.Cursor := crDefault;
   end;
  end;
end;

end.
