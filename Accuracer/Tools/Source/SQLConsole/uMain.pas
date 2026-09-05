unit uMain;

interface

{$I ver.inc}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, Menus, ActnList, Db, StdCtrls, DBCtrls, Grids,
  OpenDatabase,
  DBGrids, ExtCtrls, AboutUnit, Buttons, ACRExcept, ACRMain, ACRComMain
  {$IFDEF DEBUG_MEMCHECK}
  ,memcheck
  {$ENDIF}
  {$IFDEF DEBUG_LOG}
  ,ACRDebug
  {$ENDIF}
  ;

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
    CurrentQuery: TACRQuery;
    CurrentTable: TACRTable;
    Database1: TMenuItem;
    New1: TMenuItem;
    Open1: TMenuItem;
    Close1: TMenuItem;
    miExportselectedtablestoSQL: TMenuItem;
    miExportalltablestoSQL: TMenuItem;
    CurrentDB: TACRDatabase;


    function GetDatabaseName: String;
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
    procedure Close1Click(Sender: TObject);
    procedure New1Click(Sender: TObject);
    procedure Open1Click(Sender: TObject);
    procedure miExportselectedtablestoSQLClick(Sender: TObject);
    procedure miExportalltablestoSQLClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    function OpenDatabase(DBFileName:    String;
                          LocalDatabase: Boolean = True;
                          DatabaseName:  String = '';
                          RemoteHost:    String = '';
                          RemotePort:    Integer = 0;
                          LocalPort:     Integer = 0
                          ): Boolean;
    procedure OpenTable;
    procedure FillTablesList;
    procedure UpdateTableList;
  end;

var
  fmMain: TfmMain;
  DBFileName : String;

implementation

uses Security, NewDatabase, WorkGrids, ExportToSQL;

{$R *.DFM}

{
function TfmMain.OpenDatabase: Boolean;
begin
 if not CurrentDB.Exists then
  Exit;
 DBFileName := CurrentDB.DatabaseFilename;
 if CurrentDB.IsDatabaseEncrypted then
  begin
   if FormSecurity = nil then
    FormSecurity := TFormSecurity.Create(Application);
   FormSecurity.Caption := 'Database "'+DBFileName+'" authentification';
   adbFileName := DBFileName;
   Security.Data := CurrentDB;
   if CurrentDB.IsDatabaseEncryptedByPassword then
    begin
     FormSecurity.KeyGrid.Hide;
     FormSecurity.edKeyFile.Hide;
     FormSecurity.Label5.Hide;
     FormSecurity.Label13.Hide;
     FormSecurity.Button2.Hide;
     FormSecurity.tPassword.Show;
     FormSecurity.Label2.Show;
    end
   else
    begin
     FormSecurity.tPassword.Hide;
     FormSecurity.Label2.Hide;
     FormSecurity.KeyGrid.Show;
     FormSecurity.edKeyFile.Show;
     FormSecurity.Label5.Show;
     FormSecurity.Label13.Show;
     FormSecurity.Button2.Show
    end;
   if (FormSecurity.ShowModal = mrCancel) then
    Exit;
   if CurrentDB.IsCryptoParamsValid then CurrentDB.Open;
  end
 else
  CurrentDB.Open;
 bnOpenTable.Enabled := true;
 lbTables.Items.Clear();
 CurrentDB.Handle.GetTablesList(lbTables.Items);
 gbTables.Caption := ' Available tables: '+IntToStr(lbTables.Items.Count)+' ';
 fmMain.Caption := 'Accuracer SQL Console - Database "' + ExtractFileName(DBFileName)+ '"';
 bnCloseTable.Enabled := false;
end; // OpenDatabase
}

//------------------------------------------------------------------------------
// Open database
//------------------------------------------------------------------------------
function TfmMain.OpenDatabase(DBFileName:    String;
                          LocalDatabase: Boolean = True;
                          DatabaseName:  String = '';
                          RemoteHost:    String = '';
                          RemotePort:    Integer = 0;
                          LocalPort:     Integer = 0
                          ): Boolean;

var Handle: Integer;
begin
 CurrentDb.Connected := false;
 CurrentDb.ReadOnly := False;
 CurrentDb.DatabaseFileName := DBFileName;
 CurrentDB.LocalDatabase := LocalDatabase;
 if (not CurrentDB.LocalDatabase) then
  begin
   CurrentDB.ConnectionParams.DatabaseName := DatabaseName;
   CurrentDB.ConnectionParams.RemoteHost := RemoteHost;
   CurrentDB.ConnectionParams.RemotePort := RemotePort;
   CurrentDB.ConnectionParams.LocalPort := LocalPort;
  end;
 Result := False;

 if (CurrentDB.LocalDatabase) then
  begin
   Handle := SysUtils.FileOpen(DBFileName,fmOpenRead or fmShareDenyNone);
   if (Handle < 0) then
    begin
     Result := False;
     SysUtils.FileClose(Handle);
     Exit;
    end
   else
    SysUtils.FileClose(Handle);
  end;
 if CurrentDb.IsDatabaseEncrypted then
  begin
   if FormSecurity = nil then
    FormSecurity := TFormSecurity.Create(Application);
   FormSecurity.Caption := 'Database "'+DBFileName+'" authentification';
   adbFileName := DBFileName;
   Security.Data := CurrentDb;
   if CurrentDB.IsDatabaseEncryptedByPassword then
    begin
     FormSecurity.KeyGrid.Hide;
     FormSecurity.edKeyFile.Hide;
     FormSecurity.Label5.Hide;
     FormSecurity.Label13.Hide;
     FormSecurity.Button2.Hide;
     FormSecurity.tPassword.Show;
     FormSecurity.Label2.Show;
    end
   else
    begin
     FormSecurity.tPassword.Hide;
     FormSecurity.Label2.Hide;
     FormSecurity.KeyGrid.Show;
     FormSecurity.edKeyFile.Show;
     FormSecurity.Label5.Show;
     FormSecurity.Label13.Show;
     FormSecurity.Button2.Show
    end;
   if (FormSecurity.ShowModal = mrCancel) then
    Exit;
   if CurrentDB.IsCryptoParamsValid then
     try
       CurrentDb.Connected := true;
     except
       Result := False;
       Exit;
     end;
  end
 else
   try
     CurrentDb.Connected := true;
   except
     Result := False;
     Exit;
   end;
 Result := True;
 if (CurrentDB.Connected) then
  begin
   CurrentTable.DatabaseName := CurrentDB.DatabaseName;
   CurrentQuery.DatabaseName := CurrentDB.DatabaseName;
  end;
 if (Result) then
  begin
   bnOpenTable.Enabled := true;
   lbTables.Items.Clear();
   CurrentDB.GetTablesList(lbTables.Items);
   gbTables.Caption := ' Available tables: '+IntToStr(lbTables.Items.Count)+' ';
   fmMain.Caption := 'Accuracer SQL Console - Database "' + GetDatabaseName + '"';
   bnCloseTable.Enabled := false;
  end;

end;// OpenDatabase


function TfmMain.GetDatabaseName: String;
begin
 if (CurrentDB.LocalDatabase) then
  Result := ExtractFileName(CurrentDB.DatabaseFileName)
 else
  Result := CurrentDB.ConnectionParams.DatabaseName;
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
  {$IFDEF DEBUG_MEMCHECK}
MemChk;
{$ENDIF}

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
// if (not OpenDatabase

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
// gbRes.Caption :=  ' Total records: 0 ';
 bnCloseTable.Enabled := false;
 CurrentTable.Active := false;
 CurrentTable.TableName := lbTables.Items[lbTables.ItemIndex];
 try
  CurrentTable.Active := true;
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
begin
 if not (CurrentDB.Connected) then
  begin
   MessageDlg('You should create or open database first',mtWarning,[mbOK],0);
   Exit;
  end;
 bnCloseTableClick(self);
 gbRes.Caption :=  ' Total records: 0 ';
 CurrentQuery.Active := false;
 CurrentQuery.SQL.Text := reSQL.Text;
 try
  ds1.DataSet := nil;
  ds1.Enabled := false;
  CurrentQuery.DisableControls;

  CurrentQuery.Active := true;
  lbTables.Items.Clear();
  CurrentDB.GetTablesList(lbTables.Items);
  gbTables.Caption := ' Available tables: '+IntToStr(lbTables.Items.Count)+' ';

  ds1.DataSet := CurrentQuery;
  CurrentQuery.EnableControls;

  gbRes.Caption :=  ' Total records: '+ IntToStr(CurrentQuery.RecordCount) +' ';

  ds1.Enabled := true;
  bnCloseTable.Enabled := true;
 except
  on E: EACRException do
   begin
    lbTables.Items.Clear();
    CurrentDB.GetTablesList(lbTables.Items);
    gbTables.Caption := ' Available tables: '+IntToStr(lbTables.Items.Count)+' ';
     if (E.NativeError <> 20001) then
      begin
       CurrentQuery.Active := false;
       raise;
      end;
   end
  else
   begin
     lbTables.Items.Clear();
     CurrentDB.GetTablesList(lbTables.Items);
     gbTables.Caption := ' Available tables: '+IntToStr(lbTables.Items.Count)+' ';
     CurrentQuery.Active := false;
     raise;
   end;
 end;
end;

procedure TfmMain.Close1Click(Sender: TObject);
begin
 CurrentDB.Close;
 lbTables.Items.Clear;
 gbTables.Caption := ' Available tables: '+IntToStr(lbTables.Items.Count)+' ';
 bnOpenTable.Enabled := False;
 fmMain.Caption := 'Accuracer SQL Console';
end;

procedure TfmMain.New1Click(Sender: TObject);
var
    keyfile,invfile: TFileStream;
    key, inv : PChar;
    keyHEX, invHEX :string;
begin
 if (SaveDialog.Execute) then
  begin
   CurrentDB.Close;
   CurrentDB.DatabaseFileName := SaveDialog.FileName;
   FormNewDatabase.edDBFileName.Text := CurrentDB.DatabaseFileName;
   if (FormNewDatabase.ShowModal = mrCancel) then
    Exit;
   CurrentDB.DatabaseFileName := FormNewDatabase.edDBFileName.Text;
   CurrentDB.Options.PageSize := FormNewDatabase.sePageSize.Value;
   CurrentDB.Options.MaxSessionCount := FormNewDatabase.seMaxConnections.Value;
   if (FormNewDatabase.Encrypted.Checked) then
    begin
     case FormNewDatabase.cbAlgorithm.ItemIndex of
      0:CurrentDB.CryptoParams.CryptoAlgorithm := craRijndael_128;
      1:CurrentDB.CryptoParams.CryptoAlgorithm := craRijndael_256;
      2:CurrentDB.CryptoParams.CryptoAlgorithm := craBlowfish;
      3:CurrentDB.CryptoParams.CryptoAlgorithm := craTwofish_128;
      4:CurrentDB.CryptoParams.CryptoAlgorithm := craTwofish_256;
      5:CurrentDB.CryptoParams.CryptoAlgorithm := craSquare;
      6:CurrentDB.CryptoParams.CryptoAlgorithm := craDES_Single_8;
      7:CurrentDB.CryptoParams.CryptoAlgorithm := craDES_Double_8;
      8:CurrentDB.CryptoParams.CryptoAlgorithm := craDES_Double_16;
      9:CurrentDB.CryptoParams.CryptoAlgorithm := craDES_Triple_8;
      10:CurrentDB.CryptoParams.CryptoAlgorithm := craDES_Triple_16;
      11:CurrentDB.CryptoParams.CryptoAlgorithm := craDES_Triple_24;
     end;
     CurrentDB.CryptoParams.CryptoMode := TACRCryptoMode(FormNewDatabase.cbMode.ItemIndex);
     if FormNewDatabase.IsInitVector.Checked then
      begin
       CurrentDB.CryptoParams.UseInitVector := true;
       invHEX := GetString(FormNewDatabase.InitVectorGrid);
       inv := AllocMem(length(invHEX) div 2);
       HexToBin(PChar(LowerCase(invHEX)),inv,length(invHEX) div 2);
       CurrentDB.CryptoParams.SetInitVector(inv,length(invHEX) div 2);
       if FormNewDatabase.VectorSave.Checked then
        begin
         invfile := TFileStream.Create(FormNewDatabase.edInvFileName.Text, fmCreate);
         invfile.WriteBuffer(inv^,CurrentDB.CryptoParams.MaxInitVectorSize);
         invfile.Free;
        end;
       FreeMem(inv);
      end
    end;
   if (FormNewDatabase.Encrypted.Checked) and (FormNewDatabase.EncryptPageControl.TabIndex = 0)
    then
     CurrentDB.CryptoParams.Password := FormNewDatabase.tPassword.Text
    else
     if (FormNewDatabase.Encrypted.Checked) and (FormNewDatabase.EncryptPageControl.TabIndex = 1)
      then
       begin
        keyHEX := GetString(FormNewDatabase.KeyGrid);
        key := AllocMem(length(keyHEX) div 2);
        HexToBin(PChar(LowerCase(keyHEX)),key,length(keyHEX) div 2);
        CurrentDB.CryptoParams.SetKey(key,length(keyHEX) div 2);
        if FormNewDatabase.KeySave.Checked then
         begin
          keyfile := TFileStream.Create(FormNewDatabase.edKeyFileName.Text, fmCreate);
          keyfile.WriteBuffer(key^,CurrentDB.CryptoParams.KeySize);
          keyfile.Free;
         end;
        FreeMem(key);
       end
     else
      CurrentDB.CryptoParams.Password := '';
   FormNewDatabase.Encrypted.Checked := false;
   FormNewDatabase.EncryptedClick(fmMain);
   CurrentDB.CreateDatabase;
   if (not OpenDatabase(CurrentDB.DatabaseFileName,CurrentDB.LocalDatabase,
       CurrentDB.ConnectionParams.DatabaseName,CurrentDB.ConnectionParams.RemoteHost,
       CurrentDB.ConnectionParams.RemotePort,CurrentDB.ConnectionParams.LocalPort)) then
    MessageDlg('Cannot open database '+GetDatabaseName,mtError,[mbOK],0);
  end;
end;

procedure TfmMain.Open1Click(Sender: TObject);
var LocalPort,RemotePort: Integer;
    LocalDatabase: Boolean;
begin
 fmOpenDatabase.OpenDialog.Options := [ofHideReadOnly,ofFileMustExist,ofPathMustExist];
 fmOpenDatabase.edDatabaseFile.Text := CurrentDB.DatabaseFileName;
 if (fmOpenDatabase.ShowModal = mrOK) then
  begin
   CurrentDB.Close;
   LocalDatabase := (fmOpenDatabase.rgLocalDatabase.ItemIndex = 0);
   if (LocalDatabase) then
    begin
     CurrentDB.DatabaseFileName := fmOpenDatabase.edDatabaseFile.Text;
     RemotePort := 0;
     LocalPort := 0;
    end
   else
    begin
     RemotePort := StrToInt(fmOpenDatabase.edRemotePort.Text);
     LocalPort := StrToInt(fmOpenDatabase.edLocalPort.Text);
    end;
   if (not OpenDatabase(CurrentDB.DatabaseFileName,LocalDatabase,
       fmOpenDatabase.edDBName.Text,fmOpenDatabase.edRemoteHost.Text,
       RemotePort,LocalPort)) then
    MessageDlg('Cannot open database '+GetDatabaseName,mtError,[mbOK],0);
  end;
end;

procedure TfmMain.miExportselectedtablestoSQLClick(Sender: TObject);
var table: TACRTable;
    s:     AnsiString;
    i:     Integer;
begin
 fmExportToSQL.Caption := 'Export tables to SQL Script';
 if (fmExportToSQL.ShowModal = mrOk) then
  begin
   s := '';
   table := TACRTable.Create(self);
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
var table: TACRTable;
    s:     AnsiString;
    i:     Integer;
begin
 UpdateTableList;
 fmExportToSQL.Caption := 'Export all tables to SQL Script';
 if (fmExportToSQL.ShowModal = mrOk) then
  begin
   s := '';
   table := TACRTable.Create(self);
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

procedure TfmMain.FillTablesList;
begin
 lbTables.Items.Clear();
 CurrentDB.GetTablesList(lbTables.Items);
 gbTables.Caption := ' Available tables: '+IntToStr(lbTables.Items.Count)+' ';
end;

end.
