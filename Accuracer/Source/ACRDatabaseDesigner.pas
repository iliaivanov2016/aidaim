unit ACRDatabaseDesigner;

interface

{$I ACRVer.Inc}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, DB, DBCtrls, Grids, DBGrids, StdCtrls, ComCtrls

  {$IFDEF D6H}
  ,Variants
  {$ENDIF}

{$IFNDEF D5H}
   ,ACRD4Routines
{$ENDIF}
  , ACRMain, ACRComMain, ACRConst, ACRTypes, ACRConverts
  {$IFDEF DEBUG_LOG}
  ,ACRDebug
  {$ENDIF}
  ,dbcgrids, Mask;

type
  TACRFormDatabaseDesigner = class(TForm)
    gbTables: TGroupBox;
    Splitter1: TSplitter;
    dbManager: TGroupBox;
    lbTables: TListBox;
    pgMain: TPageControl;
    tsTableManager: TTabSheet;
    tsDataImport: TTabSheet;
    tsExportToSQL: TTabSheet;
    tsSQLConsole: TTabSheet;
    Splitter2: TSplitter;
    Panel1: TPanel;
    bnLoad: TButton;
    bnClose: TButton;
    bnSave: TButton;
    pgTableManager: TPageControl;
    tsData: TTabSheet;
    tsFields: TTabSheet;
    tsIndexes: TTabSheet;
    tsForeignKeys: TTabSheet;
    DBGrid1: TDBGrid;
    Panel2: TPanel;
    DBNavigator1: TDBNavigator;
    dsTableData: TDataSource;
    Panel3: TPanel;
    bnImport: TButton;
    bnRefresh: TButton;
    dsImport: TDataSource;
    DBCtrlGrid1: TDBCtrlGrid;
    DBGrid2: TDBGrid;
    Panel4: TPanel;
    reSQLConsole: TRichEdit;
    DBCheckBox1: TDBCheckBox;
    DBEdit1: TDBEdit;
    DBEdit2: TDBEdit;
    DBEdit3: TDBEdit;
    DBEdit4: TDBEdit;
    tsErrorLog: TTabSheet;
    reErrorLog: TRichEdit;
    bnOpenQuery: TButton;
    bnExecSQL: TButton;
    bnLoadSQLScript: TButton;
    bnSaveSQL: TButton;
    lbSQLTime: TLabel;
    GroupBox1: TGroupBox;
    rbAll: TRadioButton;
    rbStructure: TRadioButton;
    lbImportTime: TLabel;
    bnAll: TButton;
    bnNone: TButton;
    sdSaveDB: TSaveDialog;
    odLoadDB: TOpenDialog;
    sdSaveSQL: TSaveDialog;
    odLoadSQL: TOpenDialog;
    dsSQL: TDataSource;
    bnCloseSQL: TButton;
    cbUseBrackets: TCheckBox;
    GroupBox2: TGroupBox;
    cbExportStructure: TCheckBox;
    cbAddDROPTable: TCheckBox;
    GroupBox3: TGroupBox;
    cbExportIndexes: TCheckBox;
    cbAddDROPIndex: TCheckBox;
    GroupBox4: TGroupBox;
    cbExportData: TCheckBox;
    cbExportBLOBFields: TCheckBox;
    rgExportScope: TRadioGroup;
    bnExportToSQL: TButton;
    dsFields: TDataSource;
    dsIndexes: TDataSource;
    dsForeignKeys: TDataSource;
    DBGrid3: TDBGrid;
    Panel5: TPanel;
    DBNavigator2: TDBNavigator;
    Panel6: TPanel;
    DBNavigator3: TDBNavigator;
    DBGrid4: TDBGrid;
    DBGrid5: TDBGrid;
    Panel7: TPanel;
    DBNavigator4: TDBNavigator;
    procedure bnCloseClick(Sender: TObject);
    procedure bnLoadClick(Sender: TObject);
    procedure bnSaveClick(Sender: TObject);
    procedure bnRefreshClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure bnImportClick(Sender: TObject);
    procedure lbTablesClick(Sender: TObject);
    procedure bnAllClick(Sender: TObject);
    procedure bnLoadSQLScriptClick(Sender: TObject);
    procedure bnSaveSQLClick(Sender: TObject);
    procedure bnOpenQueryClick(Sender: TObject);
    procedure bnCloseSQLClick(Sender: TObject);
    procedure bnExportToSQLClick(Sender: TObject);
    procedure reSQLConsoleChange(Sender: TObject);
  private
    { Private declarations }
    DataTable, FieldsTable, IndexesTable, ForeignKeysTable,
    ImportTable: TACRTable;
    Query:       TACRQuery;
    DefaultPath: String;
    FSQLChanged: Boolean;
  public
    Database: TACRDatabase;
  public
    { Public declarations }
    procedure GetTables;
    procedure GetSourceDatasets;
    procedure CreateFieldsTable;
    procedure CreateIndexesTable;
    procedure CreateForeignKeysTable(skipNameCheck: Boolean = false);
    procedure FillFieldsTable(SourceTable: TACRDataset);
  end;

var
  fmACRDatabaseDesigner: TACRFormDatabaseDesigner;

procedure GetAllDatasets(parent: TComponent; list: TList);

implementation

uses Math;

{$R *.dfm}

procedure GetAllDatasets(parent: TComponent; list: TList);
var i: Integer;
begin
 if (parent = nil) then
  Exit;
 for i := 0 to parent.ComponentCount-1 do
  if (parent.Components[i] is TDataset) then
   list.Add(parent.Components[i]);
end;

procedure TACRFormDatabaseDesigner.bnCloseClick(Sender: TObject);
begin
 Close;
end;

procedure TACRFormDatabaseDesigner.bnLoadClick(Sender: TObject);
var dataActive:   Boolean;
    importActive: Boolean;
begin
  dataActive := DataTable.Active;
  if (dataActive) then DataTable.Close;
  importActive := ImportTable.Active;
  if (importActive) then ImportTable.Close;
  try
   if (Database <> nil) then
    if (odLoadDB.Execute) then
     try
      {$IFDEF D12H}
       Database.LoadDatabaseFromFile('',WideString(odLoadDB.FileName));
      {$ELSE}
       Database.LoadDatabaseFromFile(odLoadDB.FileName,'');
      {$ENDIF}
     except
       on e: Exception do
        MessageDlg('Error loading memory database from file '+#13#10+odLoadDB.FileName+#13#10+e.Message,mtError,[mbOK],0);
     end;
  finally
   if (dataActive) then DataTable.Open;
   if (importActive) then ImportTable.Open;
  end;
end;

procedure TACRFormDatabaseDesigner.bnSaveClick(Sender: TObject);
begin
 if (Database <> nil) then
  if (sdSaveDB.Execute) then
   try
    {$IFDEF D12H}
     Database.SaveDatabaseToFile('',WideString(sdSaveDB.FileName),caZLIB,9);
    {$ELSE}
     Database.SaveDatabaseToFile(sdSaveDB.FileName,'',caZLIB,9);
    {$ENDIF}
   except
     on e: Exception do
      MessageDlg('Error saving memory database to file '+#13#10+sdSaveDB.FileName+#13#10+e.Message,mtError,[mbOK],0);
   end;
end;

procedure TACRFormDatabaseDesigner.bnRefreshClick(Sender: TObject);
var dataActive: Boolean;
begin
  dataActive := DataTable.Active;
  if (dataActive) then DataTable.Close;
  try
   GetSourceDatasets;
  finally
   if (dataActive) then DataTable.Open;
  end;
end;

procedure TACRFormDatabaseDesigner.GetTables;
begin
  if (Database <> nil) then
   begin
    if (not Query.Active) then
     begin
      Query.InMemory := Database.InMemory;
      Query.DatabaseName := Database.DatabaseName;
     end;
    lbTables.Clear;
    Database.GetTablesList(lbTables.Items);
    gbTables.Caption := ' Tables: '+IntToStr(lbTables.Items.Count)+' ';
    Caption := 'Database: '+Database.DatabaseName;
    if (Database.InMemory) then
     begin
      bnLoad.Enabled := True;
      bnSave.Enabled := True;
     end
    else
     begin
      bnLoad.Enabled := False;
      bnSave.Enabled := False;
     end;
   end;
end;

procedure TACRFormDatabaseDesigner.GetSourceDatasets;
var dsList: TList;
    i:      Integer;

procedure AddDataset(ds: TDataset);
var bName,newName,tName,cName: AnsiString;
    n: Integer;
begin
 tName := '';
 cName := ds.Name;
 if (ds is TACRTable) then
  tName := TACRTable(ds).TableName;
 if (tName <> '') then
  newName := tName
 else
  newName := cName;
 n := 1;
 bName := NewName + '_';
 if (ImportTable.Locate('Name',newName,[loCaseInsensitive])) then
  repeat
   NewName := bName+IntToStr(n);
   Inc(n);
  until (not ImportTable.Locate('Name',newName,[loCaseInsensitive]));
 ImportTable.Insert;
 ImportTable.Fields[0].AsBoolean := False;
 ImportTable.Fields[1].AsString := NewName;
 // parent
 if (ds.Owner <> nil) then
  ImportTable.Fields[2].AsString := ds.Owner.Name;
 // component
 ImportTable.Fields[3].AsString := cName;
 // class
 ImportTable.Fields[4].AsString := ds.ClassName;
 // table name
  ImportTable.Fields[5].AsString := tName;
 // dataset
 ImportTable.Fields[6].AsInteger := Integer(ds);
 ImportTable.Post;
end;

begin
 dsList := TList.Create;
 dsImport.DataSet := nil;
 try
   for i := 0 to Screen.CustomFormCount-1 do
    GetAllDatasets(Screen.CustomForms[i],dsList);
   for i := 0 to Screen.DataModuleCount-1 do
    GetAllDatasets(Screen.DataModules[i],dsList);
   ImportTable.Close;
   ImportTable.AdvFieldDefs.Clear;
   ImportTable.FieldDefs.Clear;
   ImportTable.IndexDefs.Clear;
   ImportTable.ForeignKeyDefs.Clear;
   ImportTable.AdvFieldDefs.Add('Selected',aftBoolean,0);
   ImportTable.AdvFieldDefs.Add('Name',aftChar,255,True);
   ImportTable.AdvFieldDefs.Add('Parent',aftChar,255);
   ImportTable.AdvFieldDefs.Add('Component',aftChar,255);
   ImportTable.AdvFieldDefs.Add('Class',aftChar,255);
   ImportTable.AdvFieldDefs.Add('TableName',aftChar,255);
   ImportTable.AdvFieldDefs.Add('Dataset',aftInteger,0);
   ImportTable.IndexDefs.Add('PK','Name',[ixPrimary,ixCaseInsensitive]);
   ImportTable.IndexDefs.Add('Idx1','Selected',[]);
   ImportTable.IndexDefs.Add('Idx2','Parent',[]);
   ImportTable.IndexDefs.Add('Idx3','Component',[]);
   ImportTable.IndexDefs.Add('Idx4','Class',[]);
   ImportTable.IndexDefs.Add('Idx5','TableName',[]);
   ImportTable.IndexDefs.Add('Idx6','Dataset',[ixUnique]);
   ImportTable.IndexDefs.Add('Default','Parent,Class,Component,TableName',[]);
   ImportTable.CreateTable;
   ImportTable.Open;
   for i := 0 to dsList.Count-1 do
     AddDataset(TDataset(dsList.Items[i]));
   ImportTable.IndexName := 'Default';
   ImportTable.First;
 finally
   dsList.Free;
   dsImport.DataSet := ImportTable;
 end;
end;

procedure TACRFormDatabaseDesigner.FormCreate(Sender: TObject);
begin
  FSQLChanged := False;
  DefaultPath := ExtractFilePath(ParamStr(0));
  odLoadDB.InitialDir := DefaultPath;
  sdSaveDB.InitialDir := DefaultPath;
  odLoadSQL.InitialDir := DefaultPath;
  sdSaveSQL.InitialDir := DefaultPath;
  if (Sender is TACRDatabase) then
   Database := TACRDatabase(Sender)
  else
   Database := nil;
  DataTable := TACRTable.Create(nil);
  FieldsTable := TACRTable.Create(nil);
  FieldsTable.InMemory := True;
  FieldsTable.TableName := '@FieldsTable';
  ForeignKeysTable := TACRTable.Create(nil);
  ForeignKeysTable.InMemory := True;
  ForeignKeysTable.TableName := '@ForeignKeysTable';
  IndexesTable := TACRTable.Create(nil);
  IndexesTable.InMemory := True;
  IndexesTable.TableName := '@IndexesTable';

  ImportTable := TACRTable.Create(nil);
  ImportTable.InMemory := True;
  ImportTable.TableName := '@ImportTable';
  dsImport.DataSet := ImportTable;
  Query := TACRQuery.Create(nil);
  pgMain.ActivePage := tsTableManager;
  pgTableManager.ActivePage := tsData;
end;

procedure TACRFormDatabaseDesigner.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  DataTable.Free;
  Query.Free;
  if (ImportTable.Exists) then
   begin
    ImportTable.Close;
    ImportTable.DeleteTable(True);
   end;
  ImportTable.Free;
end;

procedure TACRFormDatabaseDesigner.FormShow(Sender: TObject);
begin
 GetTables;
 GetSourceDatasets;
end;

procedure TACRFormDatabaseDesigner.bnImportClick(Sender: TObject);
var s,s1:       AnsiString;
    t:          Cardinal;
    n,er:       Integer;
    f:          Double;
    tbl:        TACRTable;
    ds:         TDataset;
    dsClosed:   Boolean;
    dataActive: Boolean;
begin
 Screen.Cursor := crHourGlass;
 n := 0;
 er := 0;
 s := '';
 tbl := TACRTable.Create(nil);
 tbl.DatabaseName := Database.DatabaseName;
 ImportTable.DisableControls;
 dataActive := (DataTable.Active);
 if (dataActive) then
  DataTable.Close;
 t := GetTickCount;
 try
  ImportTable.First;
  while (not ImportTable.Eof) do
   begin
    ds := TDataset(ImportTable.FieldByName('Dataset').AsInteger);
    if (ImportTable.FieldByName('Selected').AsBoolean) and (ds <> nil) then
     begin
      // import dataset
      tbl.TableName := ImportTable.FieldByName('Name').AsString;
      tbl.ClearDefinitions;
      s1 := '';
      dsClosed := not ds.Active;
      try
        if (dsClosed) then ds.Open;
        if (rbAll.Checked) then
         tbl.ImportTable(ds,s1)
        else
         begin
          if (ds is TACRDataSet) then
           begin
            tbl.AssignDefinitions(TACRDataset(ds));
           end
          else
           begin
            tbl.FieldDefs.Assign(ds.FieldDefs);
           end;
          tbl.CreateTable;
         end;
        if (dsClosed) then ds.Close;
      except
       on E: Exception do
        begin
         s1 := 'Import failed - cannot open dataset "'+tbl.TableName+'".'+#13#10+e.Message;
        end;
      end;
      if (s1 <> '') then
       begin
        Inc(er);
        s := s + s1;
       end
      else
       Inc(n);
     end;
    ImportTable.Next;
   end;
 finally
  ImportTable.EnableControls;
  t := GetTickCount-t;
  tbl.free;
  if (dataActive) then
   DataTable.Open;
  f := t / 1000.0;
  lbImportTime.Caption := FormatFloat('#,##0.000',f);
  GetTables;
  Screen.Cursor := crDefault;
  if (s <> '') then
   begin
    reErrorLog.Text := s;
    pgMain.ActivePage := tsErrorLog;
    MessageDlg('Errors occurred during import process - '+IntToStr(er)+' datasets failed.'
      +#13#10+IntToStr(n)+' datasets imported without errors.',mtError,[mbOK],0);
   end
  else
    MessageDlg(IntToStr(n)+' datasets imported without errors',mtInformation,[mbOK],0);
 end;
end;

procedure TACRFormDatabaseDesigner.lbTablesClick(Sender: TObject);
var n: Integer;
begin
 dsTableData.DataSet := nil;
 Query.Close;
 if (Database <> nil) then
  begin
   DataTable.Close;
   n := lbTables.ItemIndex;
   if (n >= 0) and (n < lbTables.Items.Count) then
    DataTable.TableName := lbTables.Items[n];
   DataTable.InMemory := Database.InMemory;
   DataTable.DatabaseName := Database.DatabaseName;
   DataTable.Open;
   dsTableData.DataSet := DataTable;
   pgMain.ActivePage := tsTableManager;
   pgTableManager.ActivePage := tsData;
   try
    FillFieldsTable(DataTable);
   except
   end;
  end;
end;

procedure TACRFormDatabaseDesigner.bnAllClick(Sender: TObject);
var
    idx:  String;
    bm:   TBookmark;
begin
 bm := ImportTable.GetBookMark;
 ImportTable.DisableControls;
 try
   idx := ImportTable.IndexName;
   if (idx <> '') then
    ImportTable.IndexName := '';
   ImportTable.First;
   while (not ImportTable.Eof) do
    begin
     ImportTable.Edit;
     ImportTable.FieldByName('Selected').AsBoolean := (Sender = bnAll);
     ImportTable.Post;
     ImportTable.Next;
    end;
 finally
   if (idx <> '') then
    ImportTable.IndexName := 'idx';
   ImportTable.GotoBookmark(bm);
   ImportTable.FreeBookmark(bm);
   ImportTable.EnableControls;
 end;
end;

procedure TACRFormDatabaseDesigner.bnLoadSQLScriptClick(Sender: TObject);
begin
 if (Database <> nil) then
  if (odLoadSQL.Execute) then
   try
     Query.SQL.LoadFromFile(odLoadSQL.FileName);
     reSQLConsole.OnChange := nil;
     try
       reSQLConsole.Text := Query.SQL.Text;
       FSQLChanged := False;
     finally
       reSQLConsole.OnChange := reSQLConsoleChange;
     end;
   except
     on e: Exception do
      MessageDlg('Error loading SQL script from file '+#13#10+odLoadSQL.FileName+#13#10+e.Message,mtError,[mbOK],0);
   end;
end;

procedure TACRFormDatabaseDesigner.bnSaveSQLClick(Sender: TObject);
begin
 if (Database <> nil) then
  if (sdSaveSQL.Execute) then
   try
     if (FSQLChanged) then
      Query.SQL.Text := reSQLConsole.Text;
     Query.SQL.SaveToFile(sdSaveSQL.FileName);
   except
     on e: Exception do
      MessageDlg('Error saving SQL script to file '+#13#10+sdSaveSQL.FileName+#13#10+e.Message,mtError,[mbOK],0);
   end;
end;

procedure TACRFormDatabaseDesigner.bnOpenQueryClick(Sender: TObject);
var
    t:            Cardinal;
    f:            Double;
    s,s1:         AnsiString;
    dataActive:   Boolean;
    importActive: Boolean;
begin
 Screen.Cursor := crHourGlass;
 s := '';
 s1 := '';
 dsSQL.DataSet := nil;
 dataActive := DataTable.Active;
 if (dataActive) then DataTable.Close;
 importActive := ImportTable.Active;
 if (importActive) then ImportTable.Close;
 t := GetTickCount;
 try
  if (FSQLChanged) then
   Query.SQL.Text := reSQLConsole.Text;
  try
    if (Sender = bnOpenQuery) then
     begin
      Query.Open;
      dsSQL.DataSet := Query;
      s1 := ' Records: '+IntToStr(Query.RecordCount);
      try
        FillFieldsTable(DataTable);
      except
      end;
     end
    else
     begin
      Query.ExecSQL;
      s1 := ' RowsAffected: '+IntToStr(Query.RowsAffected);
     end;
  except
   on e: Exception do
    begin
     s := 'Error executing query: '+#13#10+e.Message;
    end;
  end;
 finally
  t := GetTickCount-t;
  if (dataActive) then DataTable.Open;
  if (importActive) then ImportTable.Open;
  f := t / 1000.0;
  lbSQLTime.Caption := FormatFloat('#,##0.000',f);
  GetTables;
  GetSourceDatasets;
  Screen.Cursor := crDefault;
  if (s <> '') then
   begin
    reErrorLog.Text := s;
    pgMain.ActivePage := tsErrorLog;
    MessageDlg('Error occurred during running query!'+s1,mtError,[mbOK],0);
   end
  else
    MessageDlg('Query executed without errors!'+s1,mtInformation,[mbOK],0);
 end;
end;

procedure TACRFormDatabaseDesigner.bnCloseSQLClick(Sender: TObject);
begin
 Query.Close;
end;

procedure TACRFormDatabaseDesigner.bnExportToSQLClick(Sender: TObject);
var s:     WideString;
    t:        Cardinal;
    f:        Double;
begin
  Screen.Cursor := crHourGlass;
  try
   t := GetTickCount;
   if (rgExportScope.ItemIndex = 0) then
      s := Database.ExportDatabaseToSQL(cbExportStructure.Checked,
                                  cbAddDROPTable.Checked,
                                  cbExportIndexes.Checked,
                                  cbAddDROPIndex.Checked,
                                  cbExportData.Checked,
                                  cbExportBLOBFields.Checked,
                                  cbUseBrackets.Checked)
   else
   // table
      s := DataTable.ExportTableToSQL(cbExportStructure.Checked,
                                  cbAddDROPTable.Checked,
                                  cbExportIndexes.Checked,
                                  cbAddDROPIndex.Checked,
                                  cbExportData.Checked,
                                  cbExportBLOBFields.Checked,
                                  cbUseBrackets.Checked);
   t := GetTickCount - t;
   Screen.Cursor := crDefault;
   Query.SQL.Text := s;
   reSQLConsole.OnChange := nil;
   try
      reSQLConsole.Text := s;
      FSQLChanged := False;
   finally
      reSQLConsole.OnChange := reSQLConsoleChange;
   end;
   f := t / 1000.0;
   lbSQLTime.Caption := FormatFloat('#,##0.000',f);
   pgMain.ActivePage := tsSQLConsole;
  except
   on E: Exception do
    begin
     Screen.Cursor := crDefault;
     MessageDlg('Export to SQL failed: '+#13#10+e.Message,mtError,[mbOK],0);
    end;
  end;
end;

procedure TACRFormDatabaseDesigner.CreateFieldsTable;
var i: Integer;
begin
  with FieldsTable do
   begin
     Active := false;
     ReadOnly := false;
     ForeignKeyDefs.Clear;
     AdvFieldDefs.Clear;
     IndexDefs.Clear;
     AdvIndexDefs.Clear;
     FieldDefs.Clear;
     FieldDefs.Add('id',ftAutoInc,0,false);
     FieldDefs.Add('Name',ftString,255,false);
     FieldDefs.Add('Type',ftString,50,false);
     FieldDefs.Add('Size',ftInteger,0,false);
     FieldDefs.Add('Required',ftBoolean,0,false);
     FieldDefs.Add('CompressionAlgorithm',ftInteger,0,false);
     FieldDefs.Add('CompressionMode',ftInteger,0,false);
     FieldDefs.Add('BLOBBlockSize',ftInteger,0,false);
     FieldDefs.Add('DefaultValue',ftMemo,0,false);
     FieldDefs.Add('MinimumValue',ftMemo,0,false);
     FieldDefs.Add('MaximumValue',ftMemo,0,false);
     FieldDefs.Add('AIMinValue',ftLargeint,0,false);
     FieldDefs.Add('AIMaxValue',ftLargeint,0,false);
     FieldDefs.Add('AIInitValue',ftLargeint,0,false);
     FieldDefs.Add('AIIncValue',ftLargeint,0,false);
     FieldDefs.Add('AICycled',ftBoolean,0,false);
     IndexDefs.Clear;
     IndexDefs.Add('idx_id','id',[]);
     CreateTable;
     Active := true;
     IndexName := 'idx_id';
     First;
   end; //table fields
end;

procedure TACRFormDatabaseDesigner.CreateIndexesTable;
begin
  with IndexesTable do
   begin
     Active := false;
     ReadOnly := false;
     ForeignKeyDefs.Clear;
     AdvFieldDefs.Clear;
     IndexDefs.Clear;
     AdvIndexDefs.Clear;
     FieldDefs.Clear;
     FieldDefs.Add('Index_name',ftString,255,true);
     FieldDefs.Add('Descending',ftBoolean,0,false);
     FieldDefs.Add('Case_insensitive',ftBoolean,0,false);
     FieldDefs.Add('Index_fields',ftString,5000,true);
     FieldDefs.Add('Desc_fields',ftString,5000,false);
     FieldDefs.Add('Case_ins_fields',ftString,5000,false);
     FieldDefs.Add('Primary',ftBoolean,0,false);
     FieldDefs.Add('Unique',ftBoolean,0,false);
     IndexDefs.Clear;
//     IndexDefs.Add('name index','Index_name',[ixUnique,ixCaseInsensitive]);
     CreateTable;
     Active := true;
     First;
   end; //table indexes
end;


procedure TACRFormDatabaseDesigner.CreateForeignKeysTable(skipNameCheck: Boolean = false);
var i:  Integer;
    sl: TStringList;
begin
{
   FKMatchType.Close;
   FKMatchType.CreateTable;
   FKMatchType.Open;
   FKMatchType.AppendRecord([0,'Default']);
   FKMatchType.AppendRecord([1,'Full']);
   FKMatchType.AppendRecord([2,'Partial']);

   FKUpdateActionType.Close;
   FKDeleteActionType.Close;
   FKDeleteActionType.CreateTable;
   FKDeleteActionType.Open;
   FKDeleteActionType.AppendRecord([0,'Default']);
   FKDeleteActionType.AppendRecord([1,'Cascade']);
   FKDeleteActionType.AppendRecord([2,'Set Null']);
   FKDeleteActionType.AppendRecord([3,'Set Default']);
   FKDeleteActionType.AppendRecord([4,'No Action']);
   FKUpdateActionType.Open;

   TableNames.Close;
   TableNames.CreateTable;
   TableNames.Open;
   sl := TStringList.Create;
   try
     CurrentDB.GetTablesList(sl);
     for i := 0 to sl.Count-1 do
      begin
       TableNames.Insert;
       TableNames.FieldByName('Name').AsString := AnsiLowerCase(sl.Strings[i]);
       TableNames.Post;
      end;
   finally
     sl.Free;
   end;
}
   ForeignKeysTable.Close;
{
   if (skipNameCheck) then
    begin
     ForeignKeysTable.FieldDefs[0].Required := False;
     ForeignKeysTable.IndexDefs[0].Options := [];
    end
   else
    begin
     ForeignKeysTable.FieldDefs[0].Required := True;
     ForeignKeysTable.IndexDefs[0].Options := [ixPrimary];
    end;
}
{
    ForeignKeysTable.FieldByName('Name').AsString := SourceTable.ForeignKeyDefs.Items[i].Name;
    ForeignKeysTable.FieldByName('IntReferencedTableName').AsString := AnsiLowerCase(SourceTable.ForeignKeyDefs.Items[i].ReferencedTableName);
    ForeignKeysTable.FieldByName('Fields').AsString := SourceTable.ForeignKeyDefs.Items[i].Columns;
    ForeignKeysTable.FieldByName('IntMatchType').AsInteger := Integer(SourceTable.ForeignKeyDefs.Items[i].MatchType);
    ForeignKeysTable.FieldByName('IntDeleteAction').AsInteger := Integer(SourceTable.ForeignKeyDefs.Items[i].DeleteAction);
    ForeignKeysTable.FieldByName('IntUpdateAction').AsInteger := Integer(SourceTable.ForeignKeyDefs.Items[i].UpdateAction);

}
   ForeignKeysTable.ClearDefinitions;
   ForeignKeysTable.AdvFieldDefs.Add('Name',aftChar,255);
   ForeignKeysTable.AdvFieldDefs.Add('IntReferencedTableName',aftChar,255);
   ForeignKeysTable.AdvFieldDefs.Add('Fields',aftChar,255);
   ForeignKeysTable.AdvFieldDefs.Add('IntMatchType',aftInteger,0);
   ForeignKeysTable.AdvFieldDefs.Add('IntDeleteAction',aftInteger,0);
   ForeignKeysTable.AdvFieldDefs.Add('IntUpdateAction',aftInteger,0);
   ForeignKeysTable.CreateTable;
   ForeignKeysTable.Open;
   ForeignKeysTable.First;
end;// table foreign keys


procedure TACRFormDatabaseDesigner.FillFieldsTable(SourceTable: TACRDataset);
var i,j : integer;
    s : string;
begin
{
 if ((SourceTable = DataTable) or (SourceTable = Query)) then
  begin
   eRecordSize.Text := IntToStr(TACRDataset(SourceTable).GetDiskRecordSize);
   eOptimalPageSize.Text := IntToStr(TACRDataset(SourceTable).GetOptimalPageSize);
  end;
}
dsFields.DataSet := nil;
dsIndexes.DataSet := nil;
dsForeignKeys.DataSet := nil;
try
 try
  CreateIndexesTable;
  with IndexesTable do
  begin
     for i := 0 to SourceTable.IndexDefs.Count-1 do
      begin
       Insert;
       s := SourceTable.IndexDefs.Items[i].Name;
//       if s[1] = '@' then continue;
       FieldByName('Index_Name').AsString := s;
       //unique
       if (ixUnique in SourceTable.IndexDefs.Items[i].Options) then
        FieldByName('Unique').AsBoolean := true
       else
        FieldByName('Unique').AsBoolean := false;
       //primary
       if (ixPrimary in SourceTable.IndexDefs.Items[i].Options) then
        FieldByName('Primary').AsBoolean := true
       else
        FieldByName('Primary').AsBoolean := false;
       //desc
       if (ixDescending in SourceTable.IndexDefs.Items[i].Options) then
        FieldByName('Descending').AsBoolean := true
       else
        FieldByName('Descending').AsBoolean := false;
       //case_ins
       if (ixCaseInsensitive in SourceTable.IndexDefs.Items[i].Options) then
        FieldByName('Case_insensitive').AsBoolean := true
       else
        FieldByName('Case_insensitive').AsBoolean := false;
       // fields
       s := SourceTable.IndexDefs.Items[i].Fields;
       FieldByName('Index_fields').AsString := s;
       //primary
{
       if (ixPrimary in SourceTable.IndexDefs.Items[i].Options) then
        begin
         Primary_key.text := s;
         Cancel;
         Continue;
        end;
}
       //desc_fields
       s := SourceTable.IndexDefs.Items[i].DescFields;
       FieldByName('Desc_fields').AsString := s;
       //case_ins fields
       s := SourceTable.IndexDefs.Items[i].CaseInsFields;
       FieldByName('Case_ins_fields').AsString := s;
       // save it
       Post;
      end;
     First;
  end; //table indexes
  CreateFieldsTable;
  with FieldsTable do
  begin
     for i := 0 to SourceTable.AdvFieldDefs.Count-1 do
      begin
       Insert;
       FieldByName('Name').AsString := SourceTable.FieldDefs.Items[i].Name;
      // ftype := SourceTable.FieldDefs.Items[i].DataType;
       s := '';
       for j := Low(ACRFieldTypes) to High(ACRFieldTypes) do
        if (ACRFieldTypes[j].AdvancedFieldType = SourceTable.AdvFieldDefs.Items[i].DataType) then
         begin
          s := ACRFieldTypes[j].Name;
          break;
         end;
       FieldByName('Type').AsString := s;
       FieldByName('Size').AsInteger := SourceTable.AdvFieldDefs.Items[i].Size;
       FieldByName('Required').AsBoolean := SourceTable.AdvFieldDefs.Items[i].Required;
       FieldByName('CompressionAlgorithm').AsInteger :=
        Integer(SourceTable.AdvFieldDefs.Items[i].BLOBCompressionAlgorithm);
       if (FieldByName('CompressionAlgorithm').AsInteger = 0) then
        FieldByName('CompressionMode').AsInteger := 0
       else
        FieldByName('CompressionMode').AsInteger :=
         Integer(SourceTable.AdvFieldDefs.Items[i].BLOBCompressionMode);
       FieldByName('BLOBBlockSize').AsInteger :=
         Integer(SourceTable.AdvFieldDefs.Items[i].BLOBBlockSize);
       FieldByName('AICycled').AsBoolean :=
                 SourceTable.AdvFieldDefs.Items[i].AutoincCycled;
       if (SourceTable.AdvFieldDefs.Items[i].AutoincMinValue <> 0) then
        TLargeintField(FieldByName('AIMinValue')).AsLargeInt :=
          SourceTable.AdvFieldDefs.Items[i].AutoincMinValue;
       if (SourceTable.AdvFieldDefs.Items[i].AutoincMaxValue < High(Int64)) then
        TLargeintField(FieldByName('AIMaxValue')).AsLargeInt :=
          SourceTable.AdvFieldDefs.Items[i].AutoincMaxValue;
       if (SourceTable.AdvFieldDefs.Items[i].AutoincInitialValue <> 0) then
        TLargeintField(FieldByName('AIInitValue')).AsLargeInt :=
          SourceTable.AdvFieldDefs.Items[i].AutoincInitialValue;
       if (SourceTable.AdvFieldDefs.Items[i].AutoincIncrement <> 0) then
        TLargeintField(FieldByName('AIIncValue')).AsLargeInt :=
          SourceTable.AdvFieldDefs.Items[i].AutoincIncrement;
       if (not SourceTable.AdvFieldDefs.Items[i].DefaultValue.IsNull) then
        FieldByName('DefaultValue').AsString :=
          SourceTable.AdvFieldDefs.Items[i].DefaultValue.AsString;
       if (not SourceTable.AdvFieldDefs.Items[i].MinValue.IsNull) then
        FieldByName('MinimumValue').AsString :=
          SourceTable.AdvFieldDefs.Items[i].MinValue.AsString;
       if (not SourceTable.AdvFieldDefs.Items[i].MaxValue.IsNull) then
        FieldByName('MaximumValue').AsString :=
          SourceTable.AdvFieldDefs.Items[i].MaxValue.AsString;
       Post;
      end;
     First;
  end; //table fields
  CreateForeignKeysTable(true);
  for i := 0 to SourceTable.ForeignKeyDefs.Count-1 do
   begin
    ForeignKeysTable.Insert;
    ForeignKeysTable.FieldByName('Name').AsString := SourceTable.ForeignKeyDefs.Items[i].Name;
    ForeignKeysTable.FieldByName('IntReferencedTableName').AsString := AnsiLowerCase(SourceTable.ForeignKeyDefs.Items[i].ReferencedTableName);
    ForeignKeysTable.FieldByName('Fields').AsString := SourceTable.ForeignKeyDefs.Items[i].Columns;
    ForeignKeysTable.FieldByName('IntMatchType').AsInteger := Integer(SourceTable.ForeignKeyDefs.Items[i].MatchType);
    ForeignKeysTable.FieldByName('IntDeleteAction').AsInteger := Integer(SourceTable.ForeignKeyDefs.Items[i].DeleteAction);
    ForeignKeysTable.FieldByName('IntUpdateAction').AsInteger := Integer(SourceTable.ForeignKeyDefs.Items[i].UpdateAction);
    ForeignKeysTable.Post;
   end;
 except
  on e: Exception do
  begin
    FieldsTable.Close;
    IndexesTable.Close;
    ForeignKeysTable.Close;
    FieldsTable.EmptyTable;
    IndexesTable.EmptyTable;
    ForeignKeysTable.EmptyTable;
    ShowMessage('Error creating definitions tables: '+#13#10+e.Message);
  end;
 end;
finally
 dsFields.DataSet := FieldsTable;
 dsIndexes.DataSet := IndexesTable;
 dsForeignKeys.DataSet := ForeignKeysTable;
end;
end;


procedure TACRFormDatabaseDesigner.reSQLConsoleChange(Sender: TObject);
begin
  FSQLChanged := True;
end;

end.
