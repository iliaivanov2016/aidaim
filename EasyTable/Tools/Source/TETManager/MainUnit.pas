//==============================================================================
// Unit name: MainUnit
// Copyright AidAim Software, 2000-2018. All rights reserved.
// Description: EasyTable Manager
// Version: 3.0
// History:
// Version 6.20 - create / restructure pages updated
//              - SQL tab and menu added
//              - SQL history added
//              - table / query view page redesigned
// Version 5.10 - print table structure function removed due to incompatibility with D7
// Version 3.0 - print table structure, thanks to Scott Lynn
// Version 3.0 - print table structure, thanks to Scott Lynn
// Version 2.4 - minor bug fixes, database encryption is added
// Version 2.3 - minor bug fixes, interface improvement,
//               thanks to Michel Roy
// Version 2.2 - minor bug fixes, interface improvement
// Version 2.1 - works only with EasyTable 3.00 and higher
//  - Single file database support added
// Version 2.0
//  - Unique indexes support is added
// Version 1.9
//  - Type lists free calls are added
// Version 1.8
//  - Progress indicator bug is fixed
// Version 1.7
//  - Post and Cancel BLOB fields changes are added
// Version 1.6
//  - Table is closed on close form
//  - Visual controls now disabled during import / repair operation
// Version 1.5
//  - Importing log message was fixed
// Version 1.4
//  - Repair and Export capabilities were added
// Version 1.3
//  - Progress Indicator added
// Version 1.2
//  - Now works with EasyTable 1.20 only
//  - Fields size is shown after import
//  - Import / Export for Memo field was updated
// Version 1.01
//  - AboutBox units name conflict was solved
//==============================================================================
unit MainUnit;

interface

{DEFINE MEMCHK}
{$I TETManager.inc}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, CheckLst, ExtCtrls, StdActns, ActnList, ComCtrls, IniFiles,
  ToolWin, Menus, ImgList, Grids, DBGrids, Db, Spin,
  ETblLexer,
  EasyTable, ETblConst, ETblCommon, Buttons, DBCtrls,
{$IFDEF MEMCHK}
  MemCheck,
{$ENDIF}
{$IFDEF D6H}
  Variants,
{$ENDIF}
  ProgressIndicator,  ProgInd, Borrow,
  UseIndex, Find, Filter, RecNo, FindKey, Locate, NewDatabase, System.Actions,
  System.ImageList;


type
  TMainForm = class(TForm)
    Panel2: TPanel;
    Notebook: TNotebook;
    Bevel1: TBevel;
    StatusBar: TStatusBar;
    ImageList1: TImageList;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    FileNewItem: TMenuItem;
    FileOpenItem: TMenuItem;
    N1: TMenuItem;
    FileExitItem: TMenuItem;
    Help1: TMenuItem;
    HelpAboutItem: TMenuItem;
    ToolBar1: TToolBar;
    NewTableButton: TToolButton;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    Close1: TMenuItem;
    IndexDataSource: TDataSource;
    FieldsDataSource: TDataSource;
    CreateTableControl: TPageControl;
    StructureTab: TTabSheet;
    IndexesTab: TTabSheet;
    GroupBox1: TGroupBox;
    Panel1: TPanel;
    Label2: TLabel;
    Label3: TLabel;
    Compression_mode: TComboBox;
    Block_size: TSpinEdit;
    Encrypted: TCheckBox;
    Password: TEdit;
    FieldsGrid: TDBGrid;
    CurrentTable: TEasyTable;
    CurrentDataSource: TDataSource;
    IndexesTable: TEasyTable;
    IndexGrid: TDBGrid;
    DialogsTable: TEasyTable;
    DialogDataSource: TDataSource;
    FieldsTable: TEasyTable;
    BDEDataSource: TDataSource;

    {Added by M.Faraone * Begin}
    lHindex: TLabel;
    Bevel2: TBevel;
    PopupMenuSQL: TpopupMenu;
    Undo1: TMenuItem;
    N3: TMenuItem;
    Cut1: TMenuItem;
    Copy1: TMenuItem;
    Paste1: TMenuItem;
    N5: TMenuItem;
    SelectAll1: TMenuItem;
    N6: TMenuItem;
    SaveAs1: TMenuItem;
    Load1: TMenuItem;
    N7: TMenuItem;
    PriorSQL: TMenuItem;
    NextSQL: TMenuItem;
    ExecSQL1: TMenuItem;
    N8: TMenuItem;
    OpenQuery2: TMenuItem;
    Clear1: TMenuItem;
    N9: TMenuItem;
    HistoryClear: TMenuItem;
    HistorySave: TMenuItem;
    {Added by M.Faraone * End}
    cbLiveQuery: TCheckBox;

//    Panel4: TPanel;
//    DBNavigator3: TDBNavigator;
//    RecQty: TLabel;
    Panel4: TPanel;
    dbnView: TDBNavigator;
    RecQty: TLabel;
    bnPrint: TBitBtn;
    Label12: TLabel;
    seRecNo: TSpinEdit;
    bnSetRecNo: TSpeedButton;
    RecQtyAll: TLabel;
    lbStructureQty: TLabel;
    ToolsMenu: TMenuItem;
    Restructuretable1: TMenuItem;
    Repairtable1: TMenuItem;
    RepairButton: TToolButton;
    CurrentDB: TEasyDatabase;
    Repairdatabase1: TMenuItem;
    Createtable1: TMenuItem;
    Opentable1: TMenuItem;
    Closetable1: TMenuItem;
    N2: TMenuItem;
    Exporttables1: TMenuItem;
    N4: TMenuItem;
    Renametables1: TMenuItem;
    Copytables1: TMenuItem;
    Deletetables1: TMenuItem;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    ToolButton8: TToolButton;
    ToolButton10: TToolButton;
    ToolButton11: TToolButton;
    ToolButton12: TToolButton;
    ToolButton13: TToolButton;
    ToolButton14: TToolButton;
    ToolButton15: TToolButton;
    Label4: TLabel;
    BitBtn6: TBitBtn;
    pmActions: TMenuItem;
    Selectindex1: TMenuItem;
    Findrecord1: TMenuItem;
    Filterexpression1: TMenuItem;
    Findkey1: TMenuItem;
    Setrange1: TMenuItem;
    Gotorecord1: TMenuItem;
    Locate1: TMenuItem;
    Compactdatabase1: TMenuItem;
    ToolButton9: TToolButton;
    Panel5: TPanel;
    lbSelectedTables: TLabel;
    lbTableList: TListBox;
    Splitter1: TSplitter;
    ScrollBox1: TScrollBox;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    BitBtn10: TBitBtn;
    BitBtn5: TBitBtn;
    BitBtn7: TBitBtn;
    BitBtn8: TBitBtn;
    BitBtn9: TBitBtn;
    BitBtn4: TBitBtn;
    BitBtn11: TBitBtn;
    Renametables2: TMenuItem;
    Deletetables2: TMenuItem;
    Label5: TLabel;
    spAutoInc: TSpinEdit;
    Changedatabaseencryption1: TMenuItem;
    ReopenDatabaseItem: TMenuItem;
    Addrecords1: TMenuItem;
    Changepassword1: TMenuItem;
    CreateAutoIndexes: TCheckBox;
    Panel6: TPanel;
    SpinButton1: TSpinButton;
    
    Panel8: TPanel;
    Button1: TButton;
    dbnCreateTable: TDBNavigator;
    btnOk: TBitBtn;
    btnCancel: TBitBtn;
    bnBorrow: TButton;
    lbCreateQty: TLabel;
    CurrentQuery: TEasyQuery;
    pcDataSQL: TPageControl;
    tsData: TTabSheet;
    tsViewFields: TTabSheet;
    tsViewIndexes: TTabSheet;
    tsSQL: TTabSheet;
    mSQL: TRichEdit;
    OpenGrid: TDBGrid;
    DBGrid1: TDBGrid;
    DBGrid2: TDBGrid;
    odLoadSQL: TOpenDialog;
    sdSaveSQL: TSaveDialog;
    ActionList: TActionList;
    acFilter: TAction;
    acRestructureTable: TAction;
    acSetRange: TAction;
    acFindKey: TAction;
    FileNew: TAction;
    FileOpen: TAction;
    FileRename: TAction;
    FileDelete: TAction;
    FileExit: TAction;
    HelpAbout1: TAction;
    FileClose: TAction;
    acRepairTable: TAction;
    acDeleteTable: TAction;
    acCloseTable: TAction;
    acCreateTable: TAction;
    acOpenTable: TAction;
    FileRepair: TAction;
    acRenameTable: TAction;
    acCopyTable: TAction;
    acEmptyTable: TAction;
    acUseIndex: TAction;
    acFind: TAction;
    acRecNo: TAction;
    acLocate: TAction;
    FileCompact: TAction;
    acChangePasswordOfTable: TAction;
    FileCopy: TAction;
    FileChangeEncryption: TAction;
    acAddRecords: TAction;
    FilePrintStructure: TAction;
    acSwitchPans: TAction;
    FilePrintStructure1: TMenuItem;
    SQL1: TMenuItem;
    OpenSQLQuery1: TMenuItem;
    ExecuteSQLScript1: TMenuItem;
    EditSQLScript1: TMenuItem;
    LoadSQLScript1: TMenuItem;
    SaveSQLScript1: TMenuItem;
    miSQLSyntax: TMenuItem;

    procedure HelpAboutItemClick(Sender: TObject);
    procedure FileExitItemClick(Sender: TObject);
    procedure NewTableButtonClick(Sender: TObject);
    procedure Close1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure EncryptedClick(Sender: TObject);
    procedure FieldsTableNewRecord(DataSet: TDataSet);
    procedure FieldsTableCalcFields(DataSet: TDataSet);
    procedure FieldsTableBeforePost(DataSet: TDataSet);
    procedure FileOpenExecute(Sender: TObject);
    procedure IndexGridCellClick(Column: TColumn);
    procedure IndexesTableNewRecord(DataSet: TDataSet);
    procedure IndexGridColEnter(Sender: TObject);
    procedure IndexGridDblClick(Sender: TObject);
    procedure IndexGridEditButtonClick(Sender: TObject);
    procedure OpenGridCellClick(Column: TColumn);
    procedure OpenGridDblClick(Sender: TObject);
    procedure CurrentTableAfterScroll(DataSet: TDataSet);
    procedure acRestructureTableExecute(Sender: TObject);
    procedure acRepairTableExecute(Sender: TObject);
    procedure CurrentTableProgress(Sender: TEasyDataset; PercentDone: Double;
      ProgressProcess: TaaProgressProcess);
    procedure CurrentTableProg(Sender: TEasyDataset; PercentDone: Double;
      ProgressProcess: TaaProgressProcess);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FileNewExecute(Sender: TObject);
    procedure acCloseTableExecute(Sender: TObject);
    procedure lbTableListClick(Sender: TObject);
    procedure acCreateTableExecute(Sender: TObject);
    procedure acOpenTableExecute(Sender: TObject);
    procedure acRenameTableExecute(Sender: TObject);
    procedure acCopyTableExecute(Sender: TObject);
    procedure acDeleteTableExecute(Sender: TObject);
    procedure FileRepairExecute(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
    procedure FileCloseExecute(Sender: TObject);
    procedure acEmptyTableExecute(Sender: TObject);
    procedure bnBorrowClick(Sender: TObject);
    procedure BitBtn6Click(Sender: TObject);
    procedure OpenGridTitleClick(Column: TColumn);
    procedure acUseIndexExecute(Sender: TObject);
    procedure acFindExecute(Sender: TObject);
    procedure acFilterExecute(Sender: TObject);
    procedure acRecNoExecute(Sender: TObject);
    procedure acFindKeyExecute(Sender: TObject);
    procedure acSetRangeExecute(Sender: TObject);
    procedure acLocateExecute(Sender: TObject);
    procedure FileCompactExecute(Sender: TObject);
    procedure CurrentDBProgress(Sender: TComponent; PercentDone: Double;
      ProgressProcess: TaaProgressProcess; var Cancel: Boolean);
    procedure FieldsTableAfterPost(DataSet: TDataSet);
    procedure acChangePasswordOfTableExecute(Sender: TObject);
    procedure FileDeleteExecute(Sender: TObject);
    procedure FileRenameExecute(Sender: TObject);
    procedure IndexesTableBeforePost(DataSet: TDataSet);
    procedure FileChangeEncryptionExecute(Sender: TObject);
    procedure acAddRecordsExecute(Sender: TObject);
    procedure SpinButton1UpClick(Sender: TObject);
    procedure SpinButton1DownClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure Panel5CanResize(Sender: TObject; var NewWidth,
      NewHeight: Integer; var Resize: Boolean);
    procedure Button1Click(Sender: TObject);
    procedure StructureTabShow(Sender: TObject);
    procedure IndexesTabShow(Sender: TObject);
    procedure FieldsTableAfterScroll(DataSet: TDataSet);
    procedure IndexesTableAfterScroll(DataSet: TDataSet);
    procedure IndexesTableAfterPost(DataSet: TDataSet);
    {Added by M.Faraone * Begin}
    procedure acSwitchPansExecute(Sender: TObject);
    procedure PopupSQLMenuPopup(Sender: TObject);
    procedure PopupSQLMenuClick(Sender: TObject);
    procedure NavigSQLClick(Sender: TObject);
    procedure EnableSQLHistoryItems;
    procedure UpdateSQLHistory;
    procedure FilePrintStructureExecute(Sender: TObject);
    procedure DocStructure(Table: TEasyDataset);
    procedure FormDestroy(Sender: TObject);
    procedure SaveSQLHistory;
    //These three functions come from library RX...
    //{         Copyright (c) 1995, 1996 AO ROSNO             }
    //{         Copyright (c) 1997, 1998 Master-Bank          }
    function LeftStr(const S: string; N: Integer): string;
    function MakeStr(C: Char; N: Integer): string;
    function AddCharR(C: Char; const S: string; N: Integer): string;
    {Added by M.Faraone * End}
    procedure OpenQuery1Click(Sender: TObject);
    procedure ExecuteSQLscript1Click(Sender: TObject);
    procedure LoadSQLscript1Click(Sender: TObject);
    procedure SaveSQLScript1Click(Sender: TObject);
    procedure EditSQLScript1Click(Sender: TObject);
    procedure bnPrintClick(Sender: TObject);
    procedure PaintSQLWord(pos: Integer; length: Integer;
                ToBold: Boolean = False; ToUPPER: Boolean = False; col: TColor = clBlue);
    procedure ParseSQL;
    procedure bnSQLClick(Sender: TObject);
    procedure tsDataShow(Sender: TObject);
    procedure tsViewFieldsShow(Sender: TObject);
    procedure tsViewIndexesShow(Sender: TObject);
    procedure tsSQLShow(Sender: TObject);
    procedure bnSetRecNoClick(Sender: TObject);
    procedure FormCanResize(Sender: TObject; var NewWidth,
      NewHeight: Integer; var Resize: Boolean);
    procedure mSQLChange(Sender: TObject);
    procedure miSQLSyntaxClick(Sender: TObject);
  private
    { Private declarations }
    prevPageNo: integer;
    FSkipSyntaxHighlighting: Boolean;
    {Added by M.Faraone * Start}
    iSQLHistoryIndex: Integer;
    oSQLHistory: TStrings;
    QueryRunning: Boolean;
    {Added by M.Faraone * End}

    function OpenDatabase(DBFileName: string): boolean;
    procedure ViewActionsMenu(Show: Boolean);
    procedure ViewDatabaseActions(Show: Boolean);
    procedure SetNewPage(newPage : integer);
    procedure InitCreateTable;
    procedure FillFieldsTable(SourceTable: TEasyDataset);
    procedure InitRestructTable;
    procedure InitAll;
    procedure CreateTable;
    function RestructTable: Boolean;
    function OpenTable: Boolean;
    procedure LoadSettings;
    procedure SaveSettings;
    procedure SetDatabaseFile(DBFileName: string;
                                bOpenLastFile: Boolean);
    procedure LoadDatabaseFile;
    procedure ReopenDatabaseItemClick(Sender: TObject);
  public
    { Public declarations }
    procedure SetStructureCaption(Dataset: TDataset);
    procedure ReopenStructureTables(ReadOnly: Boolean; Save: Boolean = False);
    procedure UpdateTableList;
  end;
procedure GetFilePathAndName(pathName : string; var path,name,ext : string);

var
  MainForm: TMainForm;
  pageNo : integer = 0;
  tet_action : string = '';
  SetupTitle : string='EasyTable Manager - ';
  typeList : TaaList;
  typeNameList : TStringList;
  bdeExt : string;
  DoNotCheckAutoInc: Boolean;
  IniFile : TIniFile;

{Added by M.Faraone * Start}
const
  SQLHistoryCapacity: Integer = 40;
{Added by M.Faraone * End}
  
implementation

uses fileCtrl, AddIndex, EditMemo, EditFmtMemo,
  EditGraphic, EditBlob, AboutUnit, SetRange, ProgressCancel, AddRecords
    //Added by M.Faraone * Start
  ,ClipBrd, TypInfo
  //Added by M.Faraone * End
  ;

{$R *.DFM}

Function ShellExecute(hWnd:HWND;lpOperation:Pchar;lpFile:Pchar;lpParameter:Pchar;
                      lpDirectory:Pchar;nShowCmd:Integer):Thandle; Stdcall;
External 'Shell32.Dll' name 'ShellExecuteA';


//------------------------------------------------------------------------------
// Open database
//------------------------------------------------------------------------------
function TMainForm.OpenDatabase(DBFileName: string): boolean;
var
  pass: string;
begin
 CurrentDb.Connected := false;
 CurrentDb.ReadOnly := False;
 CurrentDb.DatabaseFileName := DBFileName;
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
    CurrentDb.Connected := true;
    Result := True;
  end;
 if (CurrentDB.Connected) then
  begin
   CurrentTable.DatabaseName := CurrentDB.DatabaseName;
   SetNewPage(3);
  end;
end;// OpenDatabase


//------------------------------------------------------------------------------
// show / hide Actions menu
//------------------------------------------------------------------------------
procedure TMainForm.ViewActionsMenu(Show: Boolean);
begin
  acRecNo.Enabled := Show;
  acFilter.Enabled := Show;
  acFindKey.Enabled := Show;
  acLocate.Enabled := Show;
  acUseIndex.Enabled := Show;
  acSetRange.Enabled := Show;
  acFind.Enabled := Show;
  acAddRecords.Enabled := Show;
end; // ViewActionsMenu


procedure TMainForm.ViewDatabaseActions(Show: Boolean);
begin
 FilePrintStructure.Enabled := Show;
 FileClose.Enabled := Show;
 FileRepair.Enabled := Show;
 FileCompact.Enabled := Show;
 FileDelete.Enabled := Show;
 FileCopy.Enabled := Show;
 FileRename.Enabled := Show;
 FileRepair.Enabled := Show;
end; // ViewDatabaseActions


//------------------------------------------------------------------------------
// Set new notebook page
//------------------------------------------------------------------------------
procedure TMainForm.SetNewPage(newPage : integer);
begin
 case newPage of
  0 : begin
       lbTableList.Items.Clear;
       CurrentDb.Connected := false;
       MainForm.Caption := SetupTitle+'Welcome';
       MainForm.Notebook.Color := clGray;
       // actions
       FileNew.Enabled := true;
       FileOpen.Enabled := true;
       FileChangeEncryption.Enabled := false;
		   acCreateTable.Enabled := false;
		   acOpenTable.Enabled := false;
			 acRestructureTable.Enabled := false;
			 acChangePasswordOfTable.Enabled := false;
			 acRepairTable.Enabled := false;
			 acEmptyTable.Enabled := false;
			 acRenameTable.Enabled := false;
			 acCopyTable.Enabled := false;
			 acDeleteTable.Enabled := false;
			 acCloseTable.Enabled := false;
       ViewActionsMenu(False);
       ViewDatabaseActions(false);
      end;
  1 : begin
       if (tet_action = 'create') then
        MainForm.Caption := SetupTitle+'Create new table'+
       			' in database "'+ ExtractFileName(CurrentDb.DatabaseFileName) +'"'
       else
        MainForm.Caption := SetupTitle+'Restructure table "'+CurrentTable.TableName+
       			'" in database "'+ ExtractFileName(CurrentDb.DatabaseFileName) +'"';
       MainForm.Notebook.Color := clBtnFace;
		   acCreateTable.Enabled := false;
		   acOpenTable.Enabled := false;
			 acRestructureTable.Enabled := false;
			 acChangePasswordOfTable.Enabled := false;
			 acRepairTable.Enabled := false;
			 acEmptyTable.Enabled := false;
			 acRenameTable.Enabled := false;
			 acCopyTable.Enabled := false;
			 acDeleteTable.Enabled := false;
			 acCloseTable.Enabled := true;
       ViewActionsMenu(False);
       ViewDatabaseActions(true);
      end;
  2 : begin
       MainForm.Caption := SetupTitle+'Manage table "'+CurrentTable.TableName+
       			'" in database "'+ ExtractFileName(CurrentDb.DatabaseFileName) +'"';
       MainForm.Notebook.Color := clBtnFace;
       UpdateTableList;
		   acCreateTable.Enabled := false;
		   acOpenTable.Enabled := false;
			 acRestructureTable.Enabled := true;
			 acChangePasswordOfTable.Enabled := true;
			 acRepairTable.Enabled := true;
			 acEmptyTable.Enabled := true;
			 acRenameTable.Enabled := true;
			 acCopyTable.Enabled := true;
			 acDeleteTable.Enabled := true;
			 acCloseTable.Enabled := true;
       ViewDatabaseActions(true);
       ViewActionsMenu(True);
       pcDataSQL.ActivePageIndex := tsData.PageIndex;
			 FormIndex.lbIndexes.Items.Clear;
			 CurrentTable.GetIndexNames(FormIndex.lbIndexes.Items);

			 FormFind.lbFields.Items.Clear;
			 CurrentTable.GetFieldNames(FormFind.lbFields.Items);
			 FormFind.lbFields.ItemIndex := -1;

			 FormFilter.lbFields.Items.Clear;
			 CurrentTable.GetFieldNames(FormFilter.lbFields.Items);
			 FormFilter.lbFields.ItemIndex := -1;
      end;
  3 : begin
       tet_action := 'manage database';
       MainForm.Caption := SetupTitle+'Manage database "'+ExtractFileName(CurrentDb.DatabaseFileName)+'"';
       MainForm.Notebook.Color := clGray;
       UpdateTableList;
			 acCreateTable.Enabled := true;
			 acOpenTable.Enabled := false;
			 acRestructureTable.Enabled := false;
			 acChangePasswordOfTable.Enabled := false;
			 acRepairTable.Enabled := false;
			 acEmptyTable.Enabled := false;
			 acRenameTable.Enabled := false;
			 acCopyTable.Enabled := false;
			 acDeleteTable.Enabled := false;
			 acCloseTable.Enabled := false;
       ViewActionsMenu(False);
       ViewDatabaseActions(true);
      end;
 end;
 Notebook.PageIndex := newPage;
end;

procedure TMainForm.HelpAboutItemClick(Sender: TObject);
begin
 TETManAbout.ShowModal;
end;

procedure TMainForm.FileExitItemClick(Sender: TObject);
begin
 Close;
 Application.Terminate;
end;

procedure TMainForm.NewTableButtonClick(Sender: TObject);
begin
 tet_action := 'create';
 SetNewPage(1);
end;

procedure TMainForm.Close1Click(Sender: TObject);
begin
 tet_action := '';
 CurrentTable.Active := false;
 SetNewPage(0);
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
{$IFDEF MEMCHK}
MemChk;
{$ENDIF}
 FSkipSyntaxHighlighting := false;
 IniFile := TIniFile.Create(ExtractFilePath(ParamStr(0))+'tetmanager.ini');
 DoNotCheckAutoInc := false;
 InitAll;
 CurrentTable.DatabaseName := CurrentDB.DatabaseName;
 CurrentDb.Connected := false;
 {Added by M.Faraone * begin}
  iSQLHistoryIndex := -1;
  oSQLHistory := TStringList.Create;
  QueryRunning := false;
 {Added by M.Faraone * End}
 if (ParamCount > 0) then
 begin
	 CurrentDb.Connected := false;
	 CurrentDb.DatabaseFileName := ParamStr(1);
	 try
	  CurrentDb.Connected := true;
	  SetNewPage(3);
	 except
	  CurrentDB.Connected := false;
    SetNewPage(0);
   end;
 end
 else
  begin
   if (not CurrentDB.Connected) then
    SetNewPage(0);
  end;
end;

procedure TMainForm.EncryptedClick(Sender: TObject);
begin
 if Encrypted.checked then
  begin
   Password.enabled := true;
   Password.Color := clWindow;
  end
 else
  begin
   Password.Color := clSilver;
   Password.enabled := false;
   Password.text := '';
  end;
end;


// init for new table
procedure TMainForm.InitCreateTable;
begin
 tet_action := 'create';
 CreateAutoIndexes.Checked := false;
// fields
 try
  with FieldsTable do
  begin
     Active := false;
     FieldDefs.Clear;
     FieldDefs.Add('id',ftAutoInc,0,false);
     FieldDefs.Add('Name',ftString,253,false);
     FieldDefs.Add('Type',ftString,20,false);
     FieldDefs.Add('Size',ftInteger,0,false);
     FieldDefs.Add('Required',ftBoolean,0,false);
     IndexDefs.Clear;
     IndexDefs.Add('name index','Name',[ixUnique,ixCaseInsensitive]);
     CreateTable;
     Active := true;
{
     Insert;
     FieldByName('Name').AsString := 'ID';
     FieldByName('Type').AsString := 'AutoInc';
     FieldByName('Size').AsInteger := 0;
     FieldByName('Required').AsBoolean := false;
     Post;
}     
     First;
     FieldsGrid.Columns[1].DropDownRows := typeList.Count;
      begin
       FieldsGrid.Columns[1].PickList.Assign(typeNameList);
      end;
  end; //table fields
  with IndexesTable do
  begin
     Active := false;
     FieldDefs.Clear;
     FieldDefs.Add('Index_name',ftString,253,true);
     FieldDefs.Add('Descending',ftBoolean,0,false);
     FieldDefs.Add('Case_insensitive',ftBoolean,0,false);
     FieldDefs.Add('Index_fields',ftString,5000,true);
     FieldDefs.Add('Desc_fields',ftString,5000,false);
     FieldDefs.Add('Case_ins_fields',ftString,5000,false);
     FieldDefs.Add('Primary',ftBoolean,0,false);
     FieldDefs.Add('Unique',ftBoolean,0,false);
     IndexDefs.Clear;
     IndexDefs.Add('name index','Index_name',[ixUnique,ixCaseInsensitive]);
     CreateTable;
     Active := true;
     First;
  end; //table fields
 except
  ShowMessage('Error creating Fields table');
  Application.Terminate;
 end;
 Password.PasswordChar := '*';
 Compression_mode.ItemIndex := 0;
// Primary_key.Text := 'ID';
 Password.Text := '';
 Encrypted.checked := false;
 Password.Color := clSilver;
 Block_size.value := DEFAULT_BLOB_BLOCK_SIZE;
 spAutoInc.Enabled := true;
 spAutoInc.Value := 0;
// CreateAutoIndexes.Enabled := true;
end; //init for create table

procedure TMainForm.FillFieldsTable(SourceTable: TEasyDataset);
var i,j : integer;
    ftype : TFieldType;
    s : string;
begin
 SourceTable.Active := true;
// fields
 CreateAutoIndexes.Checked := False;
 try
  with IndexesTable do
  begin
     Active := false;
     ReadOnly := false;
     FieldDefs.Clear;
     FieldDefs.Add('Index_name',ftString,253,true);
     FieldDefs.Add('Descending',ftBoolean,0,false);
     FieldDefs.Add('Case_insensitive',ftBoolean,0,false);
     FieldDefs.Add('Index_fields',ftString,5000,true);
     FieldDefs.Add('Desc_fields',ftString,5000,false);
     FieldDefs.Add('Case_ins_fields',ftString,5000,false);
     FieldDefs.Add('Primary',ftBoolean,0,false);
     FieldDefs.Add('Unique',ftBoolean,0,false);
     IndexDefs.Clear;
     IndexDefs.Add('name index','Index_name',[ixUnique,ixCaseInsensitive]);
     if (Exists) then
      DeleteTable;
     CreateTable;
     Active := true;
     for i := 0 to SourceTable.IndexDefs.Count-1 do
      begin
       Insert;
       s := SourceTable.IndexDefs.Items[i].Name;
       if s[1] = '@' then continue;
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
  with FieldsTable do
  begin
     Active := false;
     ReadOnly := false;
     FieldDefs.Clear;
     FieldDefs.Add('id',ftAutoInc,0,false);
     FieldDefs.Add('Name',ftString,253,false);
     FieldDefs.Add('Type',ftString,20,false);
     FieldDefs.Add('Size',ftInteger,0,false);
     FieldDefs.Add('Required',ftBoolean,0,false);
     IndexDefs.Clear;
     CreateTable;
     Active := true;
     First;
     FieldsGrid.Columns[1].DropDownRows := typeList.Count;
      begin
       FieldsGrid.Columns[1].PickList.Assign(typeNameList);
      end;
     for i := 0 to SourceTable.FieldDefs.Count-1 do
      begin
// it is not correct!      
//       if (LowerCase(SourceTable.FieldDefs.Items[i].Name) = LowerCase(Primary_key.Text)) then
//        continue;
       Insert;
       FieldByName('Name').AsString := SourceTable.FieldDefs.Items[i].Name;
       ftype := SourceTable.FieldDefs.Items[i].DataType;
{
       if (ftype = ftAutoInc) then
        begin
         Primary_Key.Text := SourceTable.FieldDefs.Items[i].Name;
        end;
}
       s := '';
       for j := 0 to TypeList.Count-1 do
        if (pTETFieldType(typeList.Items[j])^.fieldType = ftype) then
         begin
          s := pTETFieldType(typeList.Items[j])^.name;
          break;
         end;
       FieldByName('Type').AsString := s;
       FieldByName('Size').AsInteger := SourceTable.FieldDefs.Items[i].Size;
       FieldByName('Required').AsBoolean := SourceTable.FieldDefs.Items[i].Required;
       Post;
      end;
     First;
  end; //table fields

 except
  ShowMessage('Error creating Fields table');
  Application.Terminate;
 end;
 case SourceTable.BLOBCompression of
  clNone : Compression_mode.ItemIndex := 0;
  clFastest : Compression_mode.ItemIndex := 1;
  clDefault : Compression_mode.ItemIndex := 2;
  clMax : Compression_mode.ItemIndex := 3;
 end;
 Password.PasswordChar := #0;
 Password.Text := SourceTable.Password;
 MainForm.Encrypted.checked := SourceTable.Encrypted;

 if (MainForm.Encrypted.checked) then
  begin
   Password.Color := clWindow;
   Password.Enabled := true;
  end
 else
  begin
   Password.Color := clSilver;
   Password.Enabled := false;
  end;

 Block_size.value := SourceTable.BLOBBlockSize;
 spAutoInc.Value := SourceTable.LastAutoIncValue;
 if (SourceTable.RecordCount <= 0) then
  spAutoInc.Enabled := true
 else
  spAutoInc.Enabled := false;
 CreateAutoIndexes.Checked := SourceTable.AutoIndexes;
end;

// init for restructure table
procedure TMainForm.InitRestructTable;
begin
 FillFieldsTable(CurrentTable);
end; //init for create table

procedure TMainForm.InitAll;
var s : string;
    i : integer;
begin
 try
  s := ExtractFilePath(Application.ExeName);
  CurrentDB.DatabaseFileName := s;
  FieldsTable.Active := false;
  IndexesTable.Active := false;
  CurrentTable.Active := false;
//  FieldsTable.DatabaseName := s;
//  IndexesTable.DatabaseName := s;
  CurrentTable.DatabaseName := s;
  typeList := TaaList.Create;
  typeNameList := TStringList.Create;
  CurrentTable.GetSupportedFieldTypes(typeList);
  for i := 0 to typeList.Count-1 do
   typeNameList.Add(pTETFieldType(typeList.Items[i])^.name);
  typeNameList.Sort;
 except
  on e: Exception do
   begin
    FieldsTable.Close;
    IndexesTable.Close;
    FieldsTable.EmptyTable;
    IndexesTable.EmptyTable;
    ShowMessage('Error creating definitions tables: '+#13#10+e.Message);
   end;
 end;
end;


procedure TMainForm.FieldsTableNewRecord(DataSet: TDataSet);
begin
// if (tet_action <> 'restruct') then
  begin
   FieldsTable.FieldByName('Name').AsString := '';
   FieldsTable.FieldByName('Type').AsString := 'String';
   FieldsTable.FieldByName('Size').AsInteger := 25;
   FieldsTable.FieldByName('Required').Asboolean := false;
  end;
end;

procedure TMainForm.FieldsTableCalcFields(DataSet: TDataSet);
begin
// FieldsTable.FieldByName('Field Number').AsInteger := FieldsTable.recno;

end;


//------------------------------------------------------------------------------
// creates table
//------------------------------------------------------------------------------
procedure TMainForm.CreateTable;
var i,j,size : integer;
    required,f,f1 : Boolean;
    name,fType,fields,case_ins,desc : string;
    opt : TIndexOptions;
begin
 CurrentTable.Active := false;
 CurrentTable.FieldDefs.Clear;
 CurrentTable.IndexDefs.Clear;
 // general parameters
 // primary key
{
 if (Primary_key.text = '') then
  name := 'ID'
 else
  name := Primary_key.text;
}
// CurrentTable.FieldDefs.Add(name,ftInteger,0,false);
// CurrentTable.IndexDefs.Add(name,name,[ixPrimary]);

 // BLOB fields compression mode
 case Compression_mode.itemIndex of
  1 : CurrentTable.BLOBCompression := clFastest;
  2 : CurrentTable.BLOBCompression := clDefault;
  3 : CurrentTable.BLOBCompression := clMax
 else
  CurrentTable.BLOBCompression := clNone;
 end;
 // BLOB Block size (size of single block, blocks number may be up to 2^31)
 CurrentTable.BLOBBlockSize := Block_Size.Value;
 // encrypted
 if (not Encrypted.checked) then
  CurrentTable.Encrypted := false
 else
  begin
    CurrentTable.Encrypted := true;
    i := 0;
    repeat
     name:= InputBox('Password confirmation', 'Password: ','');
     if (name <> Password.Text) then
      begin
       if (MessageDlg('Invalid password. Do you want to try again?',mtConfirmation,[mbYes,mbNo],0) <> mrYes) then
        i := 2;
      end
     else
      i := 1;
    until (i <> 0);
    if (i = 2) then
     Exit;
    CurrentTable.Password := Password.Text;
  end;
 // loading field descriptions
 FieldsTable.FilterOptions := [foCaseInsensitive,foNoPartialCompare];
 FieldsTable.First;
 while not FieldsTable.Eof do
  begin
   fType := FieldsTable.FieldByName('Type').AsString;
   i := -1;
   j := 0;
   while (j < typeNameList.Count) and (i < 0) do
    begin
     if
       (LowerCase(pTETFieldType(typeList.Items[j])^.name) = LowerCase(fType)) then
      i := j;
     inc(j);
    end;
   if (i < 0)
      then
    begin
     MessageDlg('Invalid field type',mtError,[mbOk],0);
     Exit;
    end;
   name := FieldsTable.FieldByName('Name').AsString;
   size := FieldsTable.FieldByName('Size').AsInteger;
   required := FieldsTable.FieldByName('Required').AsBoolean;
{
   // check for duplicate field names
   if (LowerCase(name) = LowerCase(Primary_key.text)) then
    begin
     MessageDlg('Duplicate field name "'+name+'"!',mtError,[mbOk],0);
     Exit;
    end;
}
   FieldsTable.Filter := 'Name = '+
    AnsiQuotedStr(name,'''');
   if (not FieldsTable.FindFirst) then
    begin
     MessageDlg('Field "'+name+'" not found!',mtError,[mbOk],0);
     Exit;
    end;
   if (FieldsTable.FindNext) then
    begin
     MessageDlg('Duplicate field name "'+name+'"!',mtError,[mbOk],0);
     Exit;
    end;
   CurrentTable.FieldDefs.Add(name,pTETFieldType(typeList.Items[i])^.fieldType,size,required);
   FieldsTable.Next;
  end;

 try
  CurrentTable.CreateTable;
  CurrentTable.Active := true;
  CurrentTable.SetAutoIncValue(spAutoInc.Value+1);
  CurrentTable.FlushBuffers;
 except
  on E: Exception do
   begin
    MessageDlg(E.Message, mtError, [mbOk], 0);
    Exit;
   end;
 end;
 IndexesTable.First;
 while not IndexesTable.Eof do
  begin
   name := IndexesTable.FieldByName('index_name').AsString;
   fields := IndexesTable.FieldByName('Index_fields').AsString;
   f := IndexesTable.FieldByName('Case_insensitive').AsBoolean;
   f1 := IndexesTable.FieldByName('Descending').AsBoolean;
   opt := [];
   if (f and f1) then
    opt := [ixDescending,ixCaseInsensitive]
   else
   if (f) then
    opt := [ixCaseInsensitive]
   else
   if (f1) then
    opt := [ixDescending];
   if (IndexesTable.FieldByName('Primary').AsBoolean) then
    opt := opt + [ixPrimary];
   if (IndexesTable.FieldByName('Unique').AsBoolean) then
    opt := opt + [ixUnique];
   desc := IndexesTable.FieldByName('desc_fields').AsString;
   case_ins := IndexesTable.FieldByName('case_ins_fields').AsString;
   if (name = '') then
    begin
      MessageDlg('You should specify index name',mtError,[mbOk],0);
      Exit;
    end;
   if (fields = '') then
    begin
      MessageDlg('You should specify index fields',mtError,[mbOk],0);
      Exit;
    end;
   try
    CurrentTable.AddIndex(name,fields,opt,desc,case_ins);
   except
    MessageDlg('Invalid index "'+name+'"',mtError,[mbOk],0);
    Exit;
   end;
   IndexesTable.Next;
  end;
 CurrentTable.Active := false;
 acCloseTable.Execute;
end;


//------------------------------------------------------------------------------
// restruct table
//------------------------------------------------------------------------------
function TMainForm.RestructTable: Boolean;
var i,j,size : integer;
    required,f,f1 : Boolean;
    name,fType,fields,case_ins,desc : string;
    opt : TIndexOptions;
    newBLOBCompression : TCompressionLevel;
begin
 Result := True;
 CurrentTable.Active := false;
 CurrentTable.OnProgress := CurrentTableProgress;
 CurrentTable.RestructureFieldDefs.Clear;
 CurrentTable.RestructureIndexDefs.Clear;
 CurrentTable.FieldDefs.Clear;
 CurrentTable.IndexDefs.Clear;
 // general parameters
 // primary key
{
 if (Primary_key.text = '') then
  name := 'ID'
 else
  name := Primary_key.text;
}

// CurrentTable.RestructureFieldDefs.Add(name,ftInteger,0,false);
// CurrentTable.RestructureIndexDefs.Add(name,name,[ixPrimary]);
 // BLOB fields compression mode
 case Compression_mode.itemIndex of
  1 : newBLOBCompression := clFastest;
  2 : newBLOBCompression := clDefault;
  3 : newBLOBCompression := clMax
 else
  newBLOBCompression := clNone;
 end;
 // BLOB Block size (size of single block, blocks number may be up to 2^31)

 // loading field descriptions
 FieldsTable.FilterOptions := [foCaseInsensitive,foNoPartialCompare];
 FieldsTable.First;
 while not FieldsTable.Eof do
  begin
   fType := FieldsTable.FieldByName('Type').AsString;
   i := -1;
   j := 0;
   while (j < typeNameList.Count) and (i < 0) do
    begin
     if
       (LowerCase(pTETFieldType(typeList.Items[j])^.name) = LowerCase(fType)) then
      i := j;
     inc(j);
    end;
   if (i < 0)
      then
    begin
     MessageDlg('Invalid field type',mtError,[mbOk],0);
     Exit;
    end;
   name := FieldsTable.FieldByName('Name').AsString;
   size := FieldsTable.FieldByName('Size').AsInteger;
   required := FieldsTable.FieldByName('Required').AsBoolean;
{
   // check for duplicate field names
   if (LowerCase(name) = LowerCase(Primary_key.text)) then
    begin
     MessageDlg('Duplicate field name "'+name+'"!',mtError,[mbOk],0);
     Exit;
    end;
}
   FieldsTable.Filter := 'Name = '+
    AnsiQuotedStr(name,'''');
   if (not FieldsTable.FindFirst) then
    begin
     MessageDlg('Field "'+name+'" not found!',mtError,[mbOk],0);
     Exit;
    end;
   if (FieldsTable.FindNext) then
    begin
     MessageDlg('Duplicate field name "'+name+'"!',mtError,[mbOk],0);
     Exit;
    end;
   CurrentTable.RestructureFieldDefs.Add(name,pTETFieldType(typeList.Items[i])^.fieldType,size,required);
   FieldsTable.Next;
  end;
 // indexes
  IndexesTable.First;
 while not IndexesTable.Eof do
  begin
   name := IndexesTable.FieldByName('index_name').AsString;
   fields := IndexesTable.FieldByName('Index_fields').AsString;
   f := IndexesTable.FieldByName('Case_insensitive').AsBoolean;
   f1 := IndexesTable.FieldByName('Descending').AsBoolean;
   opt := [];
   if (f and f1) then
    opt := [ixDescending,ixCaseInsensitive]
   else
   if (f) then
    opt := [ixCaseInsensitive]
   else
   if (f1) then
    opt := [ixDescending];
   if (IndexesTable.FieldByName('Primary').AsBoolean) then
    opt := opt + [ixPrimary];
   if (IndexesTable.FieldByName('Unique').AsBoolean) then
    opt := opt + [ixUnique];
   desc := IndexesTable.FieldByName('desc_fields').AsString;
   case_ins := IndexesTable.FieldByName('case_ins_fields').AsString;
   if (name = '') then
    begin
      MessageDlg('You should specify index name',mtError,[mbOk],0);
      Exit;
    end;
   if (fields = '') then
    begin
      MessageDlg('You should specify index fields',mtError,[mbOk],0);
      Exit;
    end;
    CurrentTable.RestructureIndexDefs.Add(name,fields,opt);
    j := CurrentTable.RestructureIndexDefs.Count-1;
    CurrentTable.RestructureIndexDefs.Items[j].DescFields := desc;
    CurrentTable.RestructureIndexDefs.Items[j].CaseInsFields := case_ins;
    CurrentTable.RestructureIndexDefs.Items[j].Options := opt;
   IndexesTable.Next;
  end;

 // restructure
 try
  FormProgress.Caption := 'Restructuring table';
  FormProgress.lbCaption.Caption := CurrentTable.TableName;
  CurrentTable.DisableControls;
  FormProgress.Show;
  CurrentTable.RestructureTable(MainForm.Encrypted.checked,MainForm.Password.Text,
    MainForm.Block_size.value,newBLOBCompression);
  FormProgress.Close;
  CurrentTable.Active := true;
  if (spAutoInc.Enabled) then
  begin
   CurrentTable.SetAutoIncValue(spAutoInc.Value+1);
   CurrentTable.FlushBuffers;
  end;
  CurrentTable.EnableControls;
 except
  on E: Exception do
   begin
    CurrentTable.EnableControls;
    FormProgress.Close;
    MessageDlg(E.Message,mtError,[mbOk],0);
    Result := False;
    Exit;
   end;
 end;
 CurrentTable.Active := false;
// acCloseTable.Execute;
end; //restruct


//------------------------------------------------------------------------------
// opens table
//------------------------------------------------------------------------------
function TMainForm.OpenTable: Boolean;
var f : boolean;
 name : string;
// i : integer;
begin
 result := false;
 CurrentTable.IndexName := '';
 CurrentTable.IndexFieldNames := '';
 CurrentTable.ReadOnly := False;
 if (not CurrentTable.IsTableEncrypted) then
  begin
   CurrentTable.Active := true;
   result := true;
   Exit;
  end;
 name := '';
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
 result := true;
end;


// replace invalid data to correct data
procedure TMainForm.FieldsTableBeforePost(DataSet: TDataSet);
begin
 if (Length(FieldsTable.FieldByName('Name').AsString) > 253) then
  raise Exception.Create('Field name must have no more than 253 chars.');

 if (FieldsTable.FieldByName('Type').asString = 'AutoInc') then
  begin
//   Primary_key.Text := FieldsTable.FieldByName('Name').asString;
   FieldsTable.FieldByName('Size').asInteger := 0;
   Exit;
  end;

 if (FieldsTable.FieldByName('Name').asString = '') then
  FieldsTable.FieldByName('Name').asString := 'Field '+
    FieldsTable.FieldByName('id').AsString;
 if (FieldsTable.FieldByName('Type').asString = '') then
   FieldsTable.FieldByName('Type').asString := 'String';
 if (FieldsTable.FieldByName('Size').asInteger = 0) and
      ((FieldsTable.FieldByName('Type').asString = 'String') or
       (FieldsTable.FieldByName('Type').asString = 'Wide String') or
       (FieldsTable.FieldByName('Type').asString = 'Bytes'))
    then
     FieldsTable.FieldByName('Size').asInteger := 1
    else
     if
      ((FieldsTable.FieldByName('Type').asString <> 'String') and
       (FieldsTable.FieldByName('Type').asString <> 'Wide String') and
       (FieldsTable.FieldByName('Type').asString <> 'Bytes')) then
         FieldsTable.FieldByName('Size').asInteger := 0;
 if (FieldsTable.FieldByName('Required').asString = '') then
      FieldsTable.FieldByName('Required').asBoolean := False;

end;


// extracts path and file name form filename property of OpeDialog or SaveDialog
procedure GetFilePathAndName(pathName : string; var path,name,ext : string);
var i : integer;
    s,s1,s2 : string;
begin
   s := pathName;
   // get filename and path to the file
   i := Length(s);
     while (i > 0) do
      begin
       if (s[i] = '.') then break;
       dec(i);
      end;
     if (i > 0) then
      begin
       s1 := Copy(s,0,i-1);
       s2 := Copy(s,i+1,Length(s)-i);
      end
     else
      s1 := s;
   i := Length(s1);
   while (i > 0) do
    begin
     if (s1[i] = '\') then break;
      dec(i);
    end;
  if (i > 0) then
   path := Copy(s1,0,i-1)
  else
   path := '';
   if (i > 0) then
    s1 := Copy(s1,i+1,Length(s)-i);
  name := s1;
  ext := s2;
end; //path


procedure TMainForm.FileOpenExecute(Sender: TObject);
label M1;
var s : string;
begin
 // open
 OpenDialog.Title := 'Select database file';
// OpenDialog.InitialDir := currentTable.DatabaseName;
 OpenDialog.Options := [ofHideReadOnly,ofFileMustExist,ofPathMustExist];
M1:
 if (not OpenDialog.Execute)
      then Exit;
 s := OpenDialog.FileName;
 SetDatabaseFile(s, False); // mroy
 if (not OpenDatabase(s)) then
  if (MessageDlg('Error opening database file "'+ExtractFileName(s)+
  		'". Do you want to open another database file?',mtError,[mbYes,mbNo],0) = mrYes) then
   goto M1
  else
   Exit;
end;

procedure TMainForm.IndexGridCellClick(Column: TColumn);
var
    fields,case_ins,desc : string;
begin
 if (Column.index <= 4) then Exit;
 if (FieldsTable.RecordCount <= 0) then
  begin
    MessageDlg('You should add some fields before creating secondary index!',mtWarning,[mbOk],0);
    Exit;
  end;
 if (FormAddIndex.ShowModal <> mrOk) then Exit;
 // insert fields
 DialogsTable.First;
 fields := '';
 case_ins := '';
 desc := '';
 while not DialogsTable.Eof do
  begin
   if (fields = '') then
     fields := DialogsTable.FieldByName('Fields').AsString
    else
     fields := fields + ';'+DialogsTable.FieldByName('Fields').AsString;
   if (DialogsTable.FieldByName('Case_insensitive').AsBoolean) then
    begin
     if (case_ins = '') then
       case_ins := DialogsTable.FieldByName('Fields').AsString
      else
       case_ins := case_ins + ';'+DialogsTable.FieldByName('Fields').AsString;
    end;
   if (DialogsTable.FieldByName('Descending').AsBoolean) then
    begin
     if (desc = '') then
       desc := DialogsTable.FieldByName('Fields').AsString
      else
       desc := desc + ';'+DialogsTable.FieldByName('Fields').AsString;
    end;
   DialogsTable.Next;
  end;
 DialogsTable.Active := false;

{ if (IndexesTable.RecordCount <= 0) then
   begin
    IndexesTable.Cancel;
    IndexesTable.Insert;
   end
  else}
 if not (IndexesTable.State in [dsInsert, dsEdit]) then
   IndexesTable.Edit;
 IndexesTable.FieldByName('Index_fields').AsString := fields;
 IndexesTable.FieldByName('desc_fields').AsString := desc;
 IndexesTable.FieldByName('case_ins_fields').AsString := case_ins;
 IndexesTable.Post;

// ShowMessage('insert');
end;

procedure TMainForm.IndexesTableNewRecord(DataSet: TDataSet);
begin
 IndexesTable.FieldByName('Descending').Asboolean := false;
 IndexesTable.FieldByName('Case_insensitive').Asboolean := false;
 IndexesTable.FieldByName('Unique').Asboolean := false;
 IndexesTable.FieldByName('Primary').Asboolean := false;
end;

procedure TMainForm.IndexGridColEnter(Sender: TObject);
begin
IndexGridCellClick(IndexGrid.Columns[IndexGrid.SelectedIndex]);
end;



procedure TMainForm.IndexGridDblClick(Sender: TObject);
begin
IndexGridCellClick(IndexGrid.Columns[IndexGrid.SelectedIndex]);

end;

procedure TMainForm.IndexGridEditButtonClick(Sender: TObject);
begin
IndexGridCellClick(IndexGrid.Columns[IndexGrid.SelectedIndex]);
end;

procedure TMainForm.OpenGridCellClick(Column: TColumn);
begin
// ShowMessage('Col click');
// CurrentTable.IndexName := '@'+Column.FieldName;
end;

// call special editors
procedure TMainForm.OpenGridDblClick(Sender: TObject);
begin
 case OpenGrid.SelectedField.DataType of
  ftMemo : MemoForm.ShowModal;
  ftFmtMemo : FmtMemoForm.ShowModal;
  ftGraphic : GraphicForm.ShowModal;
  ftBlob : BlobForm.ShowModal;
 end;
end;


procedure TMainForm.CurrentTableAfterScroll(DataSet: TDataSet);
begin
  //It Could generate exceptions inside try..finally..end
  //where it has been called. Better to protect
  try
   RecQty.Caption := IntToStr(Dataset.RecNo);
   RecQtyAll.Caption := IntToStr(Dataset.RecordCount);
   seRecNo.Value := Dataset.RecNo;
  except
  end;
end;

procedure TMainForm.acRestructureTableExecute(Sender: TObject);
begin
 CurrentTable.Active := false;
 CurrentTable.TableName := lbTableList.Items.Strings[lbTableList.ItemIndex];
 if OpenTable then
  begin
   tet_action := 'restruct';
   InitRestructTable;
   prevPageNo := Notebook.PageIndex;
   SetNewPage(1);
  end;
end;

procedure TMainForm.acChangePasswordOfTableExecute(Sender: TObject);
var
  NewPassword, curPass, s: string;
  i: integer;
  NewEncrypted, bOK: boolean;
begin
 if not InputQuery('New password','Enter new password: ', newPassword) then exit;
 NewEncrypted := (NewPassword <> '');
 curPass := '';
 bOK := false;
 for i := 0 to lbTableList.Items.Count-1 do
  begin
   if (not lbTableList.Selected[i]) then
    continue;
   s := lbTableList.Items[i];
   CurrentTable.TableName := s;
   CurrentTable.OnProgress := CurrentTableProgress;
   bOK := false;
   repeat
    try
     CurrentTable.Password := curPass;
     CurrentTable.Open;
     CurrentTable.Close;
     FormProgress.Caption := 'Changing table password';
     FormProgress.lbCaption.Caption := CurrentTable.TableName;
     CurrentTable.DisableControls;
     FormProgress.Show;
     CurrentTable.RestructureTable(NewEncrypted, NewPassword,
               CurrentTable.BlobBlockSize, CurrentTable.BLOBCompression);
     CurrentTable.EnableControls;
     FormProgress.Close;
     bOK := true;
    except
     curPass:= InputBox('Table "'+CurrentTable.TableName+'" authentification','Enter password: ', '');
     if (curPass = '') then
      break;
    end;
   until bOK;
   if (not bOK) then
    break;
  end;
  if (bOk) then
   if (NewPassword <> '') then
    ShowMessage('Password is changed for selected tables.')
   else
    ShowMessage('Password is removed for selected tables.')
  else
    ShowMessage('Password change is failed.')
end;

procedure TMainForm.acRepairTableExecute(Sender: TObject);
var s,s1 :  AnsiString;
    i,j,n:  integer;
    bOk:		Boolean;
begin
 CurrentTable.Active := false;
 CurrentTable.OnProgress := CurrentTableProg;
 FormProg.Caption := 'Repair selected tables in "'+
 		ExtractFileName(CurrentDB.DatabaseFileName)+'"';
 FormProg.Indicator.Progress := 0;
 FormProg.Indicator2.Progress := 0;
 n := lbTableList.SelCount;
 FormProg.Indicator2.MaxValue := n;
 FormProg.Show;
 j := 0;
 bOk := true;
 for i := 0 to lbTableList.Items.Count-1 do
  begin
   if (not lbTableList.Selected[i]) then
    continue;
   s := lbTableList.Items[i];
   CurrentTable.TableName := s;
   FormProg.Label1.Caption := s;
   if (CurrentTable.Exists) then
    begin
     // repair table
     if (OpenTable) then
      begin
       CurrentTable.Active := false;
    	 if (not CurrentTable.RepairTable(s1)) then
  	 	  begin
	  	   ShowMessage('Table "'+s+'" repaired with errors. Some data lost. Error log:'+#13#10+s1);
         bOk := false;
		    end
      end;
     end;
   inc(j);
   FormProg.Indicator2.Progress := j;
   Application.ProcessMessages;
//   ShowMessage('ok');
  end;
 FormProg.Close;
 if (bOk) then
  ShowMessage('All selected tables repaired successfully. All data recovered.')
 else
  ShowMessage('Some errors occurs while repairing selected tables.');
 CurrentDB.Connected := false;
 CurrentDB.Connected := true;
 SetNewPage(3);
end;

procedure TMainForm.CurrentTableProgress(Sender: TEasyDataset;
  PercentDone: Double; ProgressProcess: TaaProgressProcess);
begin
 FormProgress.SetIndicator(Round(PercentDone));
 Application.ProcessMessages;
end;

procedure TMainForm.CurrentTableProg(Sender: TEasyDataset;
  PercentDone: Double; ProgressProcess: TaaProgressProcess);
begin
 FormProg.SetIndicator(Sender,PercentDone,ProgressProcess);
 Application.ProcessMessages;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 typeList.Free;
 typeNameList.Free;
 SaveSettings;
 IniFile.Free;
end;

procedure TMainForm.FileNewExecute(Sender: TObject);
var k : integer;
    s,s1,tableExt : string;
begin
 CurrentTable.Active := false;
 CurrentDB.Connected := false;
 s := ExtractFilePath(CurrentDB.DatabaseFileName)+'Database';
 tableExt := EasyTable.DatabaseFileExtension;
 k := 1;
 repeat
  s1 := inttostr(k);
  inc(k);
 until not FileExists(s+s1+tableExt);
 // save dialog
// SaveDialog.Title := 'Select new database file name';
 FormNewDatabase.edDBFileName.Text := s+s1+tableExt;
 if (FormNewDatabase.ShowModal = mrCancel) then
  Exit;
 CurrentDB.DatabaseFileName := FormNewDatabase.edDBFileName.Text;
 if (FormNewDatabase.Encrypted.Checked) then
  CurrentDB.Password := FormNewDatabase.tPassword.Text
 else
  CurrentDB.Password := '';
 if (FormNewDatabase.cmbDBMode.ItemIndex = 1) then
  CurrentDb.DatabaseFileMode := dfmNormal
 else
 if (FormNewDatabase.cmbDBMode.ItemIndex = 2) then
  CurrentDb.DatabaseFileMode := dfmLarge
 else
  CurrentDb.DatabaseFileMode := dfmCompact;

 CurrentDb.CreateDatabase;
 CurrentDB.Connected := true;
 CurrentTable.DatabaseName := CurrentDB.DatabaseName;
 SetNewPage(3);
end;

procedure TMainForm.acCloseTableExecute(Sender: TObject);
begin
 CurrentDB.Connected := false;
 CurrentDB.Connected := true;
 SetNewPage(3);
end;

procedure TMainForm.lbTableListClick(Sender: TObject);
begin
 if (lbTableList.SelCount = 0) then
  begin
   acOpenTable.Enabled := false;
	 acRestructureTable.Enabled := false;
   acChangePasswordOfTable.Enabled := false;
	 acRepairTable.Enabled := false;
   acEmptyTable.Enabled := false;
	 acRenameTable.Enabled := false;
	 acCopyTable.Enabled := false;
	 acDeleteTable.Enabled := false;
  end
 else
 if (lbTableList.SelCount = 1) then
  begin
   acOpenTable.Enabled := true;
	 acRestructureTable.Enabled := true;
   acChangePasswordOfTable.Enabled := true;
	 acRepairTable.Enabled := true;
   acEmptyTable.Enabled := true;
	 acRenameTable.Enabled := true;
	 acCopyTable.Enabled := true;
	 acDeleteTable.Enabled := true;
  end
 else
  begin
   acOpenTable.Enabled := false;
	 acRestructureTable.Enabled := false;
   acChangePasswordOfTable.Enabled := true;
	 acRepairTable.Enabled := true;
	 acEmptyTable.Enabled := true;
	 acRenameTable.Enabled := true;
	 acCopyTable.Enabled := true;
	 acDeleteTable.Enabled := true;
  end;
 lbSelectedTables.Caption := 'Selected tables: '+IntToStr(lbTableList.SelCount)+' of '+
 IntToStr(lbTableList.Items.Count);
end;


procedure TMainForm.acCreateTableExecute(Sender: TObject);
begin
 tet_action := 'create';
 InitCreateTable;
 SetNewPage(1);
end;

procedure TMainForm.acOpenTableExecute(Sender: TObject);
begin
 CurrentTable.Active := false;
 CurrentTable.TableName := lbTableList.Items.Strings[lbTableList.ItemIndex];
 if OpenTable then
  begin
   CurrentTable.Active := true;
   CurrentDataSource.DataSet := CurrentTable;
   CurrentTableAfterScroll(CurrentTable);
   FillFieldsTable(CurrentTable);
   ReopenStructureTables(True);
   SetNewPage(2);
   FieldsTableAfterScroll(FieldsTable);
   if (not mSQL.Modified) or ((mSQL.Lines.Count = 0) and (oSQLHistory.Count = 0)) then
    begin
      mSQL.Text := 'SELECT * FROM ' + CurrentTable.TableName + ';';
      mSQL.Modified := True;
      UpdateSQLHistory;
      lHindex.Caption := IntToStr(oSQLHistory.Count) + '/' +
        IntToStr(oSQLHistory.Count);
    end;
   pcDataSQL.ActivePageIndex := tsData.PageIndex;
  end;
end;

procedure TMainForm.acRenameTableExecute(Sender: TObject);
label M1;
var s,s1:		  string;
    i:  integer;
begin
 CurrentTable.Active := false;
 CurrentTable.OnProgress := CurrentTableProg;
 for i := 0 to lbTableList.Items.Count-1 do
  begin
   if (not lbTableList.Selected[i]) then
    continue;
   s := lbTableList.Items[i];
   CurrentTable.TableName := s;
   if (CurrentTable.Exists) then
    begin
     s1 := s;
    M1:
     if (not InputQuery('Rename selected tables','Enter new table name:',s1)) then
      break;
     CurrentTable.TableName := s1;
     if (CurrentTable.Exists) then
      begin
       if (MessageDlg('Table '+AnsiQuotedStr(s,'"') +
      		' already exists. Do you want to overwrite it?',mtConfirmation,
          [mbYes,mbNo],0) = mrNo) then
        goto M1;
      end;
     CurrentTable.TableName := s;
     // rename table
     CurrentTable.RenameTable(s1);
    end;
  end;
 CurrentDB.Connected := false;
 CurrentDB.Connected := true;
 SetNewPage(3);
end;

procedure TMainForm.acCopyTableExecute(Sender: TObject);
label M1;
var s,s1,newDB:	string;
    i,j,n:  		integer;
    newTable:   TEasyTable;
begin
 OpenDialog.InitialDir := ExtractFilePath(currentDB.DatabaseFileName);
 OpenDialog.FileName := CurrentDB.DatabaseFileName;
 OpenDialog.Options := [ofHideReadOnly,ofFileMustExist,ofPathMustExist,ofNoReadOnlyReturn];
 OpenDialog.Title := 'Select destination database file';
 if (not OpenDialog.Execute)
      then Exit;
 newDB := OpenDialog.FileName;
// if (not FileExists(newDB)) then
//  goto 2;
 newTable := TEasyTable.Create(self);
 newTable.DatabaseFileName := newDB;
 // copy tables
 CurrentTable.Active := false;
 CurrentTable.OnProgress := CurrentTableProg;
 FormProgress.Caption := 'Copy selected tables from "'+
 		ExtractFileName(CurrentDB.DatabaseFileName)+'"';
 FormProgress.Indicator.Progress := 0;
 n := lbTableList.SelCount;
 FormProgress.Indicator.MaxValue := n;
 FormProgress.Show;
 j := 0;
 for i := 0 to lbTableList.Items.Count-1 do
  begin
   if (not lbTableList.Selected[i]) then
    continue;
   s := lbTableList.Items[i];
   CurrentTable.TableName := s;
   FormProgress.lbCaption.Caption := s;
   CurrentTable.TableName := s;
   if (CurrentTable.Exists) then
    begin
     s1 := s;
     newTable.TableName := s;
     // ask table name if table already exists
     if (newTable.Exists) then
      begin
      M1:
       if (not InputQuery('Copy selected tables','Enter new table name:',s1)) then
        break;
       newTable.TableName := s1;
      if (newTable.Exists) then
       begin
        if (MessageDlg('Table '+AnsiQuotedStr(s,'"') +
      		' already exists in destination database file. Do you want to overwrite it?',mtConfirmation,
          [mbYes,mbNo],0) = mrNo) then
        goto M1;
       end;
      end; // ask table name if table already exists
     CurrentTable.CopyTable(s1,newDB);
    end;
   inc(j);
   FormProgress.Indicator.Progress := j;
   Application.ProcessMessages;
  end;
 FormProgress.Indicator.Progress := n;
 Application.ProcessMessages;
 FormProgress.Close;
 newTable.Free;
 CurrentDB.Connected := false;
 CurrentDB.Connected := true;
 SetNewPage(3);
end;

procedure TMainForm.acDeleteTableExecute(Sender: TObject);
var s:		  string;
    i,j,n:  integer;
begin
 if (MessageDlg('Delete all selected tables. Are you sure?',mtConfirmation,[mbYes,mbNo],0) <> mrYes) then
  Exit;
 CurrentTable.Active := false;
 CurrentTable.OnProgress := CurrentTableProg;
 FormProgress.Caption := 'Delete selected tables from "'+
 		ExtractFileName(CurrentDB.DatabaseFileName)+'"';
 FormProgress.Indicator.Progress := 0;
 n := lbTableList.SelCount;
 FormProgress.Indicator.MaxValue := n;
 FormProgress.Show;
 j := 0;
 for i := 0 to lbTableList.Items.Count-1 do
  begin
   if (not lbTableList.Selected[i]) then
    continue;
   s := lbTableList.Items[i];
   CurrentTable.TableName := s;
   FormProgress.lbCaption.Caption := s;
   if (CurrentTable.Exists) then
    begin
     // delete table
//     if (OpenTable) then
//      begin
       CurrentTable.Active := false;
       CurrentTable.DeleteTable;
//      end;
     end;
   inc(j);
   FormProgress.Indicator.Progress := j;
   Application.ProcessMessages;
  end;
 FormProgress.Indicator.Progress := n;
 Application.ProcessMessages;
 FormProgress.Close;
 CurrentDB.Connected := false;
 CurrentDB.Connected := true;
 SetNewPage(3);
end;

procedure TMainForm.FileRepairExecute(Sender: TObject);
var s:		  AnsiString;
begin
 CurrentTable.Active := false;
 CurrentDB.Connected := false;
 FormProgressCancel.Caption := 'Repair database file "'+
 		ExtractFileName(CurrentDB.DatabaseFileName)+'"';
 FormProgressCancel.Indicator.Progress := 0;
 FormProgressCancel.Indicator.MaxValue := 100;
 FormProgressCancel.lbCaption.Caption := 'Repair database ...';
 FormProgressCancel.Indicator.Progress := 0;
 FormProgressCancel.Show;
 try
  if (not CurrentDB.RepairDatabase(s,false)) then
   MessageDlg('Errors occurred while repairing database. Original file restored, use RepairDatabase to fix errors. Error log:'+
              #13#10+s,
              mtError,[mbOk],0);
  FormProgressCancel.Indicator.Progress := 100;
  Application.ProcessMessages;
 finally
  FormProgressCancel.Close;
 end;
 CurrentDB.Connected := true;
 SetNewPage(3);
end;

procedure TMainForm.btnCancelClick(Sender: TObject);
begin
 acCloseTable.Execute;
end;

procedure TMainForm.btnOkClick(Sender: TObject);
label M1;
var s: string;
begin
 CurrentTable.AutoIndexes := CreateAutoIndexes.Checked;
 if (FieldsTable.recordCount <= 0) then
  begin
   MessageDlg('You should specify some field descriptions!',mtWarning,[mbOk],0);
   Exit;
  end;
 if (Encrypted.checked and (Password.Text = '')) then
  begin
   MessageDlg('You should specify password for table encryption!',mtWarning,[mbOk],0);
   Exit;
  end;
   CurrentTable.Active := false;
   if (tet_action = 'create') then
    begin
		M1:
     s := InputBox('Create table','Enter table name','');
     if (s = '') then
      begin
       Exit;
      end;
     CurrentTable.TableName := s;
     if (CurrentTable.Exists) then
      if (MessageDlg('Table '+AnsiQuotedStr(s,'"') +
      		' already exists. Do you want to overwrite it?',mtConfirmation,
          [mbYes,mbNo],0) = mrNo) then
       goto M1;
     CreateTable;
    end
   else
    begin
     CurrentTable.Active := false;
     if (RestructTable) then
      // if table was open before - reopen it
      if (prevPageNo = 2) then
       acOpenTableExecute(self)
      else
       acCloseTable.Execute;
    end;
end;

procedure TMainForm.FileCloseExecute(Sender: TObject);
begin
 CurrentDB.Connected := false;
 CurrentDB.DatabaseFileName := '';
 lbSelectedTables.Caption := 'Selected tables: 0 of 0';
 lbTableList.Clear;
 SetNewPage(0);
end;

procedure TMainForm.acEmptyTableExecute(Sender: TObject);
var s:		  string;
    i,j,n:  integer;
begin
 if (MessageDlg('Empty all selected tables. Are you sure?',mtConfirmation,[mbYes,mbNo],0) <> mrYes) then
  Exit;
 CurrentTable.Active := false;
 CurrentTable.OnProgress := CurrentTableProg;
 FormProgress.Caption := 'Empty selected tables from "'+
 		ExtractFileName(CurrentDB.DatabaseFileName)+'"';
 FormProgress.Indicator.Progress := 0;
 n := lbTableList.SelCount;
 FormProgress.Indicator.MaxValue := n;
 FormProgress.Show;
 j := 0;
 for i := 0 to lbTableList.Items.Count-1 do
  begin
   if (not lbTableList.Selected[i]) then
    continue;
   s := lbTableList.Items[i];
   CurrentTable.TableName := s;
   FormProgress.lbCaption.Caption := s;
   if (CurrentTable.Exists) then
    begin
     // delete table
//     if (OpenTable) then
//      begin
       CurrentTable.Active := false;
       CurrentTable.EmptyTable;
//      end;
     end;
   inc(j);
   FormProgress.Indicator.Progress := j;
   Application.ProcessMessages;
  end;
 FormProgress.Indicator.Progress := n;
 Application.ProcessMessages;
 FormProgress.Close;
 CurrentDB.Connected := false;
 CurrentDB.Connected := true;
 SetNewPage(3);
end;

procedure TMainForm.bnBorrowClick(Sender: TObject);
label M1;
var i,j,k: 		integer;
    ftype: 		TFieldType;
    s:				string;
    opt:   		TIndexOptions;
    bautoInc: Boolean;
begin
 CurrentTable.Active := false;
 OpenDialog.InitialDir := ExtractFilePath(currentDB.DatabaseFileName);
 OpenDialog.FileName := CurrentDB.DatabaseFileName;
 OpenDialog.Options := [ofHideReadOnly,ofFileMustExist,ofPathMustExist,ofNoReadOnlyReturn];
 OpenDialog.Title := 'Select database file for borrow table structure';
M1:
 if (not OpenDialog.Execute)
      then Exit;
 CurrentTable.DatabaseFileName := OpenDialog.FileName;
 FormBorrow.lbBorrow.Items.Clear;
 CurrentTable.GetTableNameList(FormBorrow.lbBorrow.Items);
 if (FormBorrow.lbBorrow.Items.Count <= 0) then
  if (MessageDlg('There is no table in this database file. Do you want to choose another file?',mtWarning,[mbYes,mbNo],0) = mrYes) then
   goto M1
  else
   Exit;
 FormBorrow.lbBorrow.ItemIndex := 0;
 if (FormBorrow.ShowModal <> mrOk) then
  Exit;
 // borrow structure
 CurrentTable.DatabaseFileName := OpenDialog.FileName;
 CurrentTable.TableName := FormBorrow.lbBorrow.Items[FormBorrow.lbBorrow.ItemIndex];
 if (not CurrentTable.Exists) then
  begin
   if (MessageDlg('There is no table "'+
   		FormBorrow.lbBorrow.Items[FormBorrow.lbBorrow.ItemIndex]+
      '" in this database file. Do you want to choose another file?',mtWarning,[mbYes,mbNo],0) = mrYes) then
    goto M1
   else
    begin
     CurrentTable.DatabaseName := 'CurrentDB';
     Exit;
    end;
  end;
 if (not OpenTable) then
  begin
   CurrentTable.DatabaseName := 'CurrentDB';
   Exit;
  end;
 // borrow structure
{
// fields
     FieldDefs.Add('Name',ftString,20,false);
     FieldDefs.Add('Type',ftString,20,false);
     FieldDefs.Add('Size',ftInteger,0,false);
     FieldDefs.Add('Required',ftBoolean,0,false);
}
// Primary_key.Text := '';
 FieldsTable.DisableControls;
 FieldsTable.Active := false;
 FieldsTable.EmptyTable;
 FieldsTable.Active := true;
 bAutoInc := false;
 for i := 0 to CurrentTable.FieldDefs.Count-1 do
  begin
   fType := CurrentTable.FieldDefs.Items[i].DataType;
   if (fType = ftAutoInc) then
    begin
     if (bAutoInc) then
      begin
       fType := ftInteger;
      end
     else
      begin
       bAutoInc := true;
//       Primary_key.Text := CurrentTable.FieldDefs.Items[i].Name;
      end;
    end; // autoinc
   j := 0;
   k := -1;
   while (j < typeNameList.Count) and (k < 0) do
    begin
     if
       (pTETFieldType(typeList.Items[j])^.fieldType = fType) then
      k := j;
     inc(j);
    end;
   if (k < 0)
      then
    begin
     MessageDlg('Invalid field type',mtError,[mbOk],0);
     CurrentTable.DatabaseName := 'CurrentDB';
     Exit;
    end;
{
   if (ftype = ftAutoInc) then
    begin
     Primary_key.Text := FieldsTable.Name;
     continue;
    end;
}    
   FieldsTable.Insert;
   FieldsTable.FieldByName('Name').AsString :=
   	CurrentTable.FieldDefs.Items[i].Name;
   FieldsTable.FieldByName('Type').AsString :=
    pTETFieldType(typeList.Items[k])^.name;
   FieldsTable.FieldByName('Size').AsInteger :=
   	CurrentTable.FieldDefs.Items[i].Size;
   FieldsTable.FieldByName('Required').AsBoolean :=
   	CurrentTable.FieldDefs.Items[i].Required;
   FieldsTable.Post;
  end;
  IndexesTable.Active := false;
  IndexesTable.EmptyTable;
  IndexesTable.Active := true;
{
// indexes
     FieldDefs.Add('Index_name',ftString,20,false);
     FieldDefs.Add('Descending',ftBoolean,0,false);
     FieldDefs.Add('Case_insensitive',ftBoolean,0,false);
     FieldDefs.Add('Index_fields',ftString,500,false);
     FieldDefs.Add('Desc_fields',ftString,500,false);
     FieldDefs.Add('Case_ins_fields',ftString,500,false);
     FieldDefs.Add('Unique',ftBoolean,0,false);
}
 for i := 0 to CurrentTable.IndexDefs.Count-1 do
  begin
   s := CurrentTable.IndexDefs.Items[i].Name;
   if (s[1] = '@') then continue;
   opt := CurrentTable.IndexDefs.Items[i].Options;
   if (ixPrimary in opt) then
    continue;
   IndexesTable.Insert;
   IndexesTable.FieldByName('Index_name').AsString := s;
   IndexesTable.FieldByName('Index_fields').AsString :=
     CurrentTable.IndexDefs.Items[i].Fields;
   // primary
   if (ixPrimary in opt) then
    IndexesTable.FieldByName('Primary').AsBoolean := true
   else
    IndexesTable.FieldByName('Primary').AsBoolean := false;
   // unique
   if (ixUnique in opt) then
    IndexesTable.FieldByName('Unique').AsBoolean := true
   else
    IndexesTable.FieldByName('Unique').AsBoolean := false;
   // descending
   if (ixDescending in opt) then
    IndexesTable.FieldByName('Descending').AsBoolean := true
   else
    IndexesTable.FieldByName('Descending').AsBoolean := false;
   //
   if (ixCaseInsensitive in opt) then
    IndexesTable.FieldByName('Case_insensitive').AsBoolean := true
   else
    IndexesTable.FieldByName('Case_insensitive').AsBoolean := false;
   IndexesTable.FieldByName('Desc_fields').AsString :=
   		CurrentTable.IndexDefs.Items[i].DescFields;
   IndexesTable.FieldByName('Case_ins_fields').AsString :=
   		CurrentTable.IndexDefs.Items[i].CaseInsFields;
   IndexesTable.Post;
  end;
{
 if (Primary_key.Text = '') then
  Primary_key.Text := 'ID';
}  
 FieldsTable.EnableControls;
 CurrentTable.Active := false;
 CurrentTable.DatabaseName := 'CurrentDB';
end;

procedure TMainForm.BitBtn6Click(Sender: TObject);
begin
 CurrentDB.Connected := false;
 SetNewPage(3);
end;

procedure TMainForm.OpenGridTitleClick(Column: TColumn);
var s,s1: string;
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

procedure TMainForm.acUseIndexExecute(Sender: TObject);
begin
 FormFind.Caption := 'Select index to order table "'+CurrentTable.TableName+'"';
 if (CurrentTable.IndexName = '') then
  begin
   FormIndex.lbIndexes.ItemIndex := -1;
   FormIndex.cbDesc.Checked := false;
   FormIndex.cbIns.Checked := false;
   FormIndex.cbUnique.Checked := false;
   FormIndex.cbPrimary.Checked := false;
  end
 else
  begin
   FormIndex.lbIndexes.ItemIndex :=
   	FormIndex.lbIndexes.Items.IndexOf(CurrentTable.IndexName);
  end;
 if (FormIndex.ShowModal = mrOk) then
  if (FormIndex.lbIndexes.ItemIndex = -1) then
   CurrentTable.IndexName := ''
  else
   CurrentTable.IndexName := FormIndex.lbIndexes.Items[FormIndex.lbIndexes.ItemIndex];
end;

procedure TMainForm.acFindExecute(Sender: TObject);
begin
 FormFind.Caption := 'Find records in table "'+CurrentTable.TableName+'"';
 // case insensitive
 if (foCaseInsensitive in CurrentTable.FilterOptions) then
  FormFind.cbCaseIns.Checked := true
 else
  FormFind.cbCaseIns.Checked := false;
 // no partial comparison
 if (foNoPartialCompare in CurrentTable.FilterOptions) then
  FormFind.cbNoComp.Checked := true
 else
  FormFind.cbNoComp.Checked := false;
 // filter
 FormFind.reFilter.Text := CurrentTable.Filter;
 FormFind.ShowModal;
end;

procedure TMainForm.acFilterExecute(Sender: TObject);
begin
 FormFilter.Caption := 'Filter table "'+CurrentTable.TableName+'"';
 // case insensitive
 if (foCaseInsensitive in CurrentTable.FilterOptions) then
  FormFilter.cbCaseIns.Checked := true
 else
  FormFilter.cbCaseIns.Checked := false;
 // no partial comparison
 if (foNoPartialCompare in CurrentTable.FilterOptions) then
  FormFilter.cbNoComp.Checked := true
 else
  FormFilter.cbNoComp.Checked := false;
 // filter
 FormFilter.reFilter.Text := CurrentTable.Filter;
 FormFilter.ShowModal;
 CurrentTableAfterScroll(CurrentTable);
end;

procedure TMainForm.acRecNoExecute(Sender: TObject);
begin
 if (CurrentTable.RecordCount <= 0) then
  begin
   ShowMessage('There is no record in this table.');
   Exit;
  end;
 FormRecNo.seRecNo.MinValue := 1;
 FormRecNo.seRecNo.MaxValue := CurrentTable.RecordCount;
 FormRecNo.seRecNo.Increment := CurrentTable.RecordCount div 10;
 if (FormRecNo.seRecNo.Increment = 0) then
  FormRecNo.seRecNo.Increment := 1;
 FormRecNo.seRecNo.Value := CurrentTable.RecNo;
 FormRecNo.seRecNo.Hint := 'Enter record number (1 - '+
 	IntToStr(FormRecNo.seRecNo.MaxValue)+'):';
 if (FormRecNo.ShowModal = mrOk) then
  begin
   CurrentTable.RecNo := FormRecNo.seRecNo.Value;
  end;
end;

procedure TMainForm.acFindKeyExecute(Sender: TObject);
var i,flds,ind: integer;
    list: TStringList;
    res: Boolean;
begin
 res := true;
 if (CurrentTable.IndexName = '') then
  begin
   ShowMessage('You should select some index. You can either click on column header or use Select index command from Actions menu.');
   Exit;
  end;

 list := TStringList.Create;
 ind := CurrentTable.IndexDefs.IndexOf(CurrentTable.IndexName);
 flds := GetStringParams(CurrentTable.IndexDefs.Items[ind].Fields,list);
 FormFindKey.sgKeys.RowCount := flds+1;
 FormFindKey.sgKeys.Cells[0,0] := 'Field names';
 FormFindKey.sgKeys.Cells[1,0] := 'Key values';
 for i := 0 to flds-1 do
  begin
   FormFindKey.sgKeys.Cells[0,i+1] := list.Strings[i];
   FormFindKey.sgKeys.Cells[1,i+1] := '';
  end;
 if (FormFindKey.ShowModal = mrOk) then
  begin
   CurrentTable.SetKey;
   for i := 0 to flds-1 do
    begin
     try
      CurrentTable.FieldByName(list.Strings[i]).AsString :=
       FormFindKey.sgKeys.Cells[1,i+1];
     except
      CurrentTable.FieldByName(list.Strings[i]).AsString := '';
      MessageDlg('Invalid key value: '+
      	AnsiQuotedStr(FormFindKey.sgKeys.Cells[1,i+1],'"'),mtError,
        [mbOk],0);
      list.free;
      Exit;
     end;
    end;
   if (FormFindKey.cbNearest.Checked) then
    CurrentTable.GoToNearest
   else
    res := CurrentTable.GotoKey;
  end;
 list.Free;
 if (not res) then
  MessageDlg('Record not found',mtWarning,[mbOk],0);
end;

procedure TMainForm.acSetRangeExecute(Sender: TObject);
var i,mr,flds,ind: integer;
    list: TStringList;
begin
 if (CurrentTable.IndexName = '') then
  begin
   ShowMessage('You should select some index. You can either click on column header or use Select index command from Actions menu.');
   Exit;
  end;
 list := TStringList.Create;
 ind := CurrentTable.IndexDefs.IndexOf(CurrentTable.IndexName);
 flds := GetStringParams(CurrentTable.IndexDefs.Items[ind].Fields,list);
 FormRange.sgStart.RowCount := flds+1;
 FormRange.sgStart.Cells[0,0] := 'Field names';
 FormRange.sgStart.Cells[1,0] := 'Key values';
 FormRange.sgEnd.RowCount := flds+1;
 FormRange.sgEnd.Cells[0,0] := 'Field names';
 FormRange.sgEnd.Cells[1,0] := 'Key values';
 for i := 0 to flds-1 do
  begin
   FormRange.sgStart.Cells[0,i+1] := list.Strings[i];
   FormRange.sgEnd.Cells[0,i+1] := list.Strings[i];
   FormRange.sgStart.Cells[1,i+1] := '';
   FormRange.sgEnd.Cells[1,i+1] := '';
  end;
 mr := FormRange.ShowModal;
 if (mr = mrNo) then
  CurrentTable.CancelRange
 else
 if (mr = mrOk) then
  begin
   CurrentTable.SetRangeStart;
   for i := 0 to flds-1 do
    begin
     try
      CurrentTable.FieldByName(list.Strings[i]).AsString :=
       FormRange.sgStart.Cells[1,i+1];
     except
      CurrentTable.FieldByName(list.Strings[i]).AsString := '';
      MessageDlg('Invalid key value: '+
      	AnsiQuotedStr(FormRange.sgStart.Cells[1,i+1],'"'),mtError,
        [mbOk],0);
      list.free;
      Exit;
     end;
    end;
   CurrentTable.KeyExclusive := FormRange.cbStart.Checked;
   CurrentTable.SetRangeEnd;
   for i := 0 to flds-1 do
    begin
     try
      CurrentTable.FieldByName(list.Strings[i]).AsString :=
       FormRange.sgEnd.Cells[1,i+1];
     except
      CurrentTable.FieldByName(list.Strings[i]).AsString := '';
      MessageDlg('Invalid key value: '+
      	AnsiQuotedStr(FormRange.sgEnd.Cells[1,i+1],'"'),mtError,
        [mbOk],0);
      list.free;
      Exit;
     end;
    end;
   CurrentTable.KeyExclusive := FormRange.cbEnd.Checked;
   CurrentTable.ApplyRange;
  end;
 list.Free;
end;

procedure TMainForm.acLocateExecute(Sender: TObject);
var i,n,flds: 					integer;
    res: 								Boolean;
    lopt:								TLocateOptions;
    s,sFields,sValues: 	string;
    v:									Variant;
begin
 lopt := [];
 res := true;
 flds := CurrentTable.FieldDefs.Count;
 FormLocate.sgKeys.RowCount := flds+1;
 FormLocate.sgKeys.Cells[0,0] := 'Field names';
 FormLocate.sgKeys.Cells[1,0] := 'Key values';
 for i := 0 to flds-1 do
  begin
   FormLocate.sgKeys.Cells[0,i+1] := CurrentTable.FieldDefs.Items[i].Name;
   FormLocate.sgKeys.Cells[1,i+1] := '';
  end;
 if (FormLocate.ShowModal = mrOk) then
  begin
   // case insensitive
   if (FormLocate.cbIns.Checked) then
    lopt := lopt + [loCaseInsensitive];
   // partial key
   if (FormLocate.cbPart.Checked) then
    lopt := lopt + [loPartialKey];
   // building locate expression
   sFields := '';
   sValues := '';
   v := VarArrayCreate([0,flds-1],varVariant);
   n := 0;
   for i := 0 to flds-1 do
    begin
     s := FormLocate.sgKeys.Cells[1,i+1];
     if (s = '') then
      continue;
     v[n] := s;
     if (sFields = '') then
      begin
       sFields := FormLocate.sgKeys.Cells[0,i+1];
      end
     else
      begin
       sFields := sFields + ',' + FormLocate.sgKeys.Cells[0,i+1];
      end;
     inc(n);
    end;
   res := CurrentTable.Locate(sFields,v,lopt);
  end;
 if (not res) then
  MessageDlg('Record not found',mtWarning,[mbOk],0);
end;

procedure TMainForm.FileCompactExecute(Sender: TObject);
var s:		  AnsiString;
begin
 CurrentTable.Active := false;
 CurrentDB.Connected := false;
 FormProgressCancel.Caption := 'Compact database file "'+
 		ExtractFileName(CurrentDB.DatabaseFileName)+'"';
 FormProgressCancel.Indicator.Progress := 0;
 FormProgressCancel.Indicator.MaxValue := 100;
 FormProgressCancel.lbCaption.Caption := 'Compacting database ...';
 FormProgressCancel.Indicator.Progress := 0;
 FormProgressCancel.Show;
 try
  if (not CurrentDB.CompactDatabase(s)) then
   MessageDlg('Errors occurred while compacting database. Original file restored, use RepairDatabase to fix errors. Error log:'+
             #13#10+s,
              mtError,[mbOk],0);
  FormProgressCancel.Indicator.Progress := 100;
  Application.ProcessMessages;
 finally
  FormProgressCancel.Close;
 end;
 CurrentDB.Connected := true;
 SetNewPage(3);
end;

procedure TMainForm.CurrentDBProgress(Sender: TComponent;
  PercentDone: Double; ProgressProcess: TaaProgressProcess;
  var Cancel: Boolean);
begin
 FormProgressCancel.Indicator.Progress := round(PercentDone);
 if (FormProgressCancel.bCancel) then
  Cancel := true;
 Application.ProcessMessages;
end;

{
procedure TMainForm.Primary_keyExit(Sender: TObject);
begin
  if (FieldsTable.Locate('Name',Primary_Key.Text,[loCaseInsensitive])) then
   begin
    if (FieldsTable.FieldByName('Type').AsString <> 'AutoInc') then
     begin
      MessageDlg('Field "'+Primary_Key.Text+
      '" already exists. Type another field name.',mtError,[mbOk],0);
      if (FieldsTable.Locate('Type','AutoInc',[loCaseInsensitive])) then
       Primary_Key.Text := FieldsTable.FieldByName('Name').AsString
      else
       Primary_Key.Text := '';
     end;
    Exit;
   end;
  if (FieldsTable.Locate('Type','AutoInc',[loCaseInsensitive])) then
  FieldsTable.Edit
 else
  FieldsTable.Insert;
 FieldsTable.FieldByName('Name').AsString := Primary_Key.Text;
 FieldsTable.Post;
end;
}

procedure TMainForm.FieldsTableAfterPost(DataSet: TDataSet);
var bm: TBookMark;
    name: string;
begin
 SetStructureCaption(Dataset);
if (not DoNotCheckAutoInc) then
 if (FieldsTable.FieldByName('Type').asString = 'AutoInc') then
  begin
   name := FieldsTable.FieldByName('Name').AsString;
   bm := FieldsTable.GetBookmark;
   FieldsTable.Filter := 'Type = ''AutoInc''';
   FieldsTable.Filtered := true;
   FieldsTable.FindFirst;
   repeat
    if (FieldsTable.FieldByName('Name').asString <> name) then
     begin
      FieldsTable.Delete;
      FieldsTable.First;
     end
    else
     FieldsTable.Next;
   until (FieldsTable.recordCount <= 1);
   FieldsTable.Filtered := false;
   FieldsTable.GotoBookmark(bm);
   FieldsTable.FreeBookmark(bm);
  end;
end;


//------------------------------------------------------------------------------
// load settings from INI file
//------------------------------------------------------------------------------
procedure TMainForm.LoadSettings;
var
  s: string;
  xMenu : TMenuItem;
begin
 WindowState := TWindowState(IniFile.ReadInteger('WindowSettings', 'State', Integer(wsNormal)));
 if (CurrentDB.Connected) then
  Exit;
 LoadDatabaseFile;//mroy
 if ReopenDatabaseItem.Enabled then//mroy
  begin
   xMenu := ReopenDatabaseItem.Items[0];
   if Assigned(xMenu) then
    begin
     xMenu.Click;
    end;
  end;
 if (FileExists(s)) then
  OpenDatabase(s);
end;// LoadSettings


//------------------------------------------------------------------------------
// save settings to INI file
//------------------------------------------------------------------------------
procedure TMainForm.SaveSettings;
begin
 IniFile.WriteInteger('WindowSettings', 'State', Integer(WindowState));
end;// SaveSettings


procedure TMainForm.FileDeleteExecute(Sender: TObject);
begin
 if (MessageDlg('Delete database "'+ExtractFileName(CurrentDb.DatabaseFileName)+
 			'". Are you sure?',mtConfirmation,
      [mbYes,mbNo],0) <> mrYes) then
  Exit;
 CurrentDB.Connected := false;
 try
  CurrentDB.DeleteDatabase;
 except
  MessageDlg('Error deleting database!',mtError,[mbOk],0);
 end;
 FileClose.Execute;
end;

procedure TMainForm.FileRenameExecute(Sender: TObject);
begin
 if (SaveDialog.Execute) then
 begin
	 CurrentDB.Connected := false;
	 try
	  CurrentDB.RenameDatabase(SaveDialog.FileName);
    OpenDatabase(SaveDialog.FileName);
	 except
	  MessageDlg('Error renaming database!',mtError,[mbOk],0);
	 end;
 end;
end;

procedure TMainForm.IndexesTableBeforePost(DataSet: TDataSet);
begin
 if (Length(IndexesTable.FieldByName('index_name').AsString) > 253) then
  raise Exception.Create('Index name must have no more than 253 chars.');
end;

procedure TMainForm.FileChangeEncryptionExecute(Sender: TObject);
var pass: string;
begin
 if (not CurrentDB.Connected) then
  FileOpenExecute(self);
 if (not CurrentDB.Connected) then
  Exit;
 pass := CurrentDB.Password;
 if (InputQuery('Set new password for database "'+CurrentDB.DatabaseName+'" authentification','Enter new password: ', pass)) then
 begin
  try
   CurrentDB.Connected := false;
   FormProgressCancel.Caption := 'Change encryption of database file "'+
 	    	ExtractFileName(CurrentDB.DatabaseFileName)+'"';
   FormProgressCancel.Indicator.Progress := 0;
   FormProgressCancel.Indicator.MaxValue := 100;
   FormProgressCancel.lbCaption.Caption := 'Changing database encryption ...';
   FormProgressCancel.Indicator.Progress := 0;
   FormProgressCancel.Show;
   if (not CurrentDB.ChangeEncryption(pass)) then
    MessageDlg('Errors occurred while changing database encryption. Original file restored.',
             mtError,[mbOk],0)
   else
 	  MessageDlg('New password was set successfully. Password = "'+pass+'"',
  	  mtInformation,[mbOk],0);
   FormProgressCancel.Indicator.Progress := 100;
   Application.ProcessMessages;
   FormProgressCancel.Close;
   CurrentDB.Connected := true;
  except
	 MessageDlg('Error on changing password "'+CurrentDB.DatabaseName+'". Origninal database restored.',
	  mtInformation,[mbOk],0);
  end;
 end;
end;

procedure TMainForm.SetDatabaseFile(DBFileName: string;
                                      bOpenLastFile: Boolean);//mroy
var
  sFile : TStrings;
  i: Integer;
  sFileCurrentPath: String;
  sFileReplacePath: String;
  iCurrentIndex: Integer;
  bFileExists: Boolean;
begin
  iCurrentIndex :=0;
  sFile := TStringList.Create;
  try
   IniFile.ReadSectionValues('Databases', sFile);
   if bOpenLastFile then
    begin
     for i := 0 to sFile.Count - 1 do
      begin
       if IniFile.ReadString('Databases','File' + IntToStr(i),'') = DBFileName then
        begin
         iCurrentIndex := i;
         Break;
        end;
      end;

     for i := 0 to sFile.Count - 1 do
      begin
       if i < iCurrentIndex then
        begin
         if sFileReplacePath = '' then
          sFileCurrentPath := IniFile.ReadString('Databases','File' + IntToStr(i),'')
         else
          sFileCurrentPath := sFileReplacePath;
         sFileReplacePath := IniFile.ReadString('Databases','File' + IntToStr(i + 1),'');
         IniFile.WriteString('Databases','File' + IntToStr(i + 1),sFileCurrentPath);
        end;
      end;
     IniFile.WriteString('Databases','File0',DBFileName);
    end
   else
    begin
     bFileExists := False;
     for i := 0 to sFile.Count - 1 do
      begin
       if IniFile.ReadString('Databases','File' + IntToStr(i),'') = DBFileName then
        begin
         bFileExists := True;
         Break;
        end;
      end;
     if bFileExists then
      begin
       SetDatabaseFile(DBFileName, True);
      end
     else
      begin
       for i := sFile.Count - 1 downto 0 do
        begin
         if i <= 3 then
          begin
           sFileCurrentPath := IniFile.ReadString('Databases','File' + IntToStr(i),'');
           IniFile.WriteString('Databases','File' + IntToStr(i + 1),sFileCurrentPath);
          end;
        end;
       IniFile.WriteString('Databases','File0',DBFileName);
      end;
    end;
  finally
    sFile.Free;
    LoadDatabaseFile; // mroy
    OpenDialog.InitialDir := ExtractFilePath(DBFileName);
  end;
end;

procedure TMainForm.LoadDatabaseFile; //mroy
var
  sFile : TStrings;
  i: Integer;
  sFilePath: String;
  NewMenuItem: TMenuItem;
begin
  sFile := TStringList.Create;
  try
   IniFile.ReadSectionValues('Databases', sFile);
   ReopenDatabaseItem.Enabled := sFile.Count > 0;
   for i := 0 to ReopenDatabaseItem.Count - 1 do
    begin
     ReopenDatabaseItem.Delete(0);
    end;
   for i := 0 to sFile.Count - 1 do
    begin
     sFilePath := IniFile.ReadString('Databases','File'+IntToStr(i),'');
     NewMenuItem := TMenuItem.Create(MainMenu1);
     ReopenDatabaseItem.Add(NewMenuItem);
     NewMenuItem.Caption := IntToStr(i) + ' ' + sFilePath;
     NewMenuItem.OnClick := ReopenDatabaseItemClick;
    end;
  finally
   sFile.Free;
  end;
end;

procedure TMainForm.ReopenDatabaseItemClick(Sender: TObject); //mroy
var
  sDatabaseFile: String;
begin
  sDatabaseFile := (Sender as TMenuItem).Caption;
  sDatabaseFile := StringReplace(sDatabaseFile, '&', '',[rfreplaceAll]);
  sDatabaseFile := Copy(sDatabaseFile, 3, Length(sDatabaseFile));
  SetDatabaseFile(sDatabaseFile, True);
  if FileExists(sDatabaseFile) then
  begin
    OpenDatabase(sDatabaseFile);
    SetDatabaseFile(sDatabaseFile, True);
  end;
end;

procedure TMainForm.acAddRecordsExecute(Sender: TObject);
begin
 AddRecordsForm.ShowModal;
end;


procedure TMainForm.SpinButton1UpClick(Sender: TObject);
var
    req:     Boolean;
    sz:      Integer;
    sn,st:   String;
    bm:      TBookmark;
    req1:    Boolean;
    sz1:     Integer;
    sn1,st1: String;
    bm1:     TBookmark;
begin
 DoNotCheckAutoInc := true;
 if (FieldsTable.RecNo > 1) then
  begin
    FieldsTable.DisableControls;
    sn := FieldsTable.FieldByName('Name').AsString;
    st := FieldsTable.FieldByName('Type').AsString;
    sz := FieldsTable.FieldByName('Size').AsInteger;
    req := FieldsTable.FieldByName('Required').AsBoolean;
    bm := FieldsTable.GetBookmark;
    FieldsTable.Prior;
    bm1 := FieldsTable.GetBookmark;
    sn1 := FieldsTable.FieldByName('Name').AsString;
    st1 := FieldsTable.FieldByName('Type').AsString;
    sz1 := FieldsTable.FieldByName('Size').AsInteger;
    req1 := FieldsTable.FieldByName('Required').AsBoolean;
    FieldsTable.Edit;
    FieldsTable.FieldByName('Name').AsString := GetTemporaryName('TempField ');
    FieldsTable.FieldByName('Type').AsString := st;
    FieldsTable.FieldByName('Size').AsInteger := sz;
    FieldsTable.FieldByName('Required').AsBoolean := req;
    FieldsTable.Post;
    FieldsTable.GotoBookmark(bm);
    FieldsTable.Edit;
    FieldsTable.FieldByName('Name').AsString := sn1;
    FieldsTable.FieldByName('Type').AsString := st1;
    FieldsTable.FieldByName('Size').AsInteger := sz1;
    FieldsTable.FieldByName('Required').AsBoolean := req1;
    FieldsTable.Post;
    FieldsTable.GotoBookmark(bm1);
    FieldsTable.FreeBookmark(bm);
    FieldsTable.Edit;
    FieldsTable.FieldByName('Name').AsString := sn;
    FieldsTable.Post;
    FieldsTable.FreeBookmark(bm1);
    FieldsTable.EnableControls;
  end;
 DoNotCheckAutoInc := false;
end;

procedure TMainForm.SpinButton1DownClick(Sender: TObject);
var
    req:     Boolean;
    sz:      Integer;
    sn,st:   String;
    bm:      TBookmark;
    req1:    Boolean;
    sz1:     Integer;
    sn1,st1: String;
    bm1:     TBookmark;
begin
 DoNotCheckAutoInc := true;
 if (FieldsTable.RecNo < FieldsTable.RecordCount) then
  begin
    FieldsTable.DisableControls;
    sn := FieldsTable.FieldByName('Name').AsString;
    st := FieldsTable.FieldByName('Type').AsString;
    sz := FieldsTable.FieldByName('Size').AsInteger;
    req := FieldsTable.FieldByName('Required').AsBoolean;
    bm := FieldsTable.GetBookmark;
    FieldsTable.Next;
    bm1 := FieldsTable.GetBookmark;
    sn1 := FieldsTable.FieldByName('Name').AsString;
    st1 := FieldsTable.FieldByName('Type').AsString;
    sz1 := FieldsTable.FieldByName('Size').AsInteger;
    req1 := FieldsTable.FieldByName('Required').AsBoolean;
    FieldsTable.Edit;
    FieldsTable.FieldByName('Name').AsString := GetTemporaryName('TempField ');
    FieldsTable.FieldByName('Type').AsString := st;
    FieldsTable.FieldByName('Size').AsInteger := sz;
    FieldsTable.FieldByName('Required').AsBoolean := req;
    FieldsTable.Post;
    FieldsTable.GotoBookmark(bm);
    FieldsTable.Edit;
    FieldsTable.FieldByName('Name').AsString := sn1;
    FieldsTable.FieldByName('Type').AsString := st1;
    FieldsTable.FieldByName('Size').AsInteger := sz1;
    FieldsTable.FieldByName('Required').AsBoolean := req1;
    FieldsTable.Post;
    FieldsTable.GotoBookmark(bm1);
    FieldsTable.FreeBookmark(bm);
    FieldsTable.Edit;
    FieldsTable.FieldByName('Name').AsString := sn;
    FieldsTable.Post;
    FieldsTable.FreeBookmark(bm1);
    FieldsTable.EnableControls;
  end;
 DoNotCheckAutoInc := false;
end;

procedure TMainForm.FormActivate(Sender: TObject);
begin
 LoadSettings;
end;

procedure TMainForm.Panel5CanResize(Sender: TObject; var NewWidth,
  NewHeight: Integer; var Resize: Boolean);
begin
 Resize := True;
 if (NewWidth < 130) then
  NewWidth := 130;
end;

procedure TMainForm.Button1Click(Sender: TObject);
var capt: String;
begin
 capt := 'definitions (fields and indexes)';
 if (CreateTableControl.ActivePageIndex = IndexesTab.PageIndex) then
  capt := 'indexes';

 if (MessageDlg('Delete all '+capt+'. Are you sure?',mtConfirmation,
      [mbYes,mbNo],0) = mrYes) then
  begin
   if (capt = 'indexes') then
    begin
     IndexesTable.Close;
     IndexesTable.EmptyTable;
     IndexesTable.Open;
     IndexesTable.Refresh;
     SetStructureCaption(IndexesTable);
    end
   else
    begin
     IndexesTable.Close;
     IndexesTable.EmptyTable;
     IndexesTable.Open;
     IndexesTable.Refresh;
     FieldsTable.Close;
     FieldsTable.EmptyTable;
     FieldsTable.Open;
     FieldsTable.Refresh;
     SetStructureCaption(FieldsTable);
    end;
  end;
end;

procedure TMainForm.SetStructureCaption(Dataset: TDataset);
begin
 if (not Dataset.Active) then
  Exit;
 lbStructureQty.Caption := IntToStr(Dataset.RecNo)+'/'+IntToStr(Dataset.RecordCount);
 lbCreateQty.Caption := IntToStr(Dataset.RecNo)+' / '+IntToStr(Dataset.RecordCount);
 if (Dataset = FieldsTable) then
  lbCreateQty.Hint := 'Fields'
 else
  lbCreateQty.Hint := 'Indexes'
end;

procedure TMainForm.ReopenStructureTables(ReadOnly: Boolean; Save: Boolean);
//var s: String;
//fs: TFileStream;
begin
 FieldsTable.Close;
 IndexesTable.Close;
 FieldsTable.ReadOnly := ReadOnly;
 IndexesTable.ReadOnly := ReadOnly;
{
 if (Save) then
  begin
   s := '';
   s := FieldsTable.ExportTableToSQL(True,True,True,False,True,True,False);
   s := s+#13#10+IndexesTable.ExportTableToSQL(True,True,True,False,True,True,False);
   s := s+#13#10+ForeignKeysTable.ExportTableToSQL(True,True,True,False,True,True,False);
   fs := TFileStream.Create('export.sql',fmCreate);
   try
     if (Length(s) > 0) then
      fs.WriteBuffer(s[1],Length(s));
   finally
     fs.Free;
   end;
  end;
}
 FieldsTable.Open;
 IndexesTable.Open;
end;

procedure TMainForm.StructureTabShow(Sender: TObject);
begin
  dbnCreateTable.DataSource := FieldsDataSource;
  SetStructureCaption(FieldsTable);
end;

procedure TMainForm.IndexesTabShow(Sender: TObject);
begin
  dbnCreateTable.DataSource := IndexDataSource;
  SetStructureCaption(IndexesTable);
end;

procedure TMainForm.FieldsTableAfterScroll(DataSet: TDataSet);
begin
 if (pcDataSQL.ActivePageIndex = tsViewFields.PageIndex) or
    (CreateTableControl.ActivePageIndex = StructureTab.PageIndex) then
     SetStructureCaption(Dataset);
end;


procedure TMainForm.IndexesTableAfterScroll(DataSet: TDataSet);
begin
 if (pcDataSQL.ActivePageIndex = tsViewIndexes.PageIndex) or
    (CreateTableControl.ActivePageIndex = IndexesTab.PageIndex) then
  SetStructureCaption(Dataset);
end;

procedure TMainForm.IndexesTableAfterPost(DataSet: TDataSet);
begin
  SetStructureCaption(Dataset);
end;


//--------------------------------------------------------
//* Added by M.Faraone ...
// SQL History Implementation...
// All Database Tables Document Printer...
//--------------------------------------------------------


   //RX From...
   function TMainForm.LeftStr(const S: string; N: Integer): string;
   begin
     Result := AddCharR(' ', S, N);
   end;
   //RX From...
   function TMainForm.MakeStr(C: Char; N: Integer): string;
   begin
   if N < 1 then Result := ''
   else begin
    if N > 255 then N := 255;
    SetLength(Result, N);
    FillChar(Result[1], Length(Result), C);
    end;
   end;
   //RX From...
   function TMainForm.AddCharR(C: Char; const S: string; N: Integer): string;
   begin
    if Length(S) < N then
    Result := S + MakeStr(C, N - Length(S))
    else Result := S;
   end;


procedure TMainForm.SaveSQLHistory;
var
  i: integer;
  hl: TStringList;
begin
  if (sdSaveSQL.Execute) then begin
    hl := TStringList.Create;
    try
      try
        for i := 0 to Pred(oSQLHistory.Count) do begin
          hl.Add(TStrings(oSQLHistory.Objects[i]).text);
        end;
        hl.SaveToFile(sdSaveSQL.FileName);
      except
        MessageDlg('Error saving SQL History: ' + sdSaveSQL.FileName, mtError,
          [mbOK], 0);
      end;
    finally
      hl.Free;
    end;
  end;
end;

procedure TMainForm.PopupSQLMenuClick(Sender: TObject);
begin
  case TMenuItem(Sender).Tag of
    1: if mSQL.Perform(EM_CANUNDO, 0, 0) <> 0 then
        mSQL.Perform(EM_UNDO, 0, 0);
    2: mSQL.CutToClipboard;
    3: mSQL.CopyToClipboard;
    4: mSQL.PasteFromClipboard;
    5: mSQL.SelectAll;
    6: SaveSQLscript1Click(Sender);
    7: begin
        LoadSQLscript1Click(Sender);
        mSQL.Modified := True;
        UpdateSQLHistory;
      end;
    8: ExecuteSQLscript1Click(Sender); //RunSQLClick(Sender);
    9: NavigSQLClick(PriorSQL);
    10: NavigSQLClick(NextSQL);
    11: OpenQuery1Click(Sender);
    12: mSQL.Clear;
    13: begin
        mSQL.Clear;
        oSQLHistory.Clear;
        iSQLHistoryIndex := -1;
        lHindex.Caption := '0/0';
      end;
    14: begin
        SaveSQLHistory;
      end;
  end;
end;

procedure TMainForm.PopupSQLMenuPopup(Sender: TObject);
var
  EnableCopy: Boolean;
begin
  EnableCopy := mSQL.SelLength <> 0;
  Undo1.Enabled := (mSQL.Perform(EM_CANUNDO, 0, 0) <> 0);
  Cut1.Enabled := EnableCopy;
  Clear1.Enabled := mSQL.Lines.Count > 0;
  Copy1.Enabled := EnableCopy;
  Paste1.Enabled := Clipboard.HasFormat(CF_TEXT);
  SelectAll1.Enabled := mSQL.Lines.Count > 0;
  Saveas1.Enabled := mSQL.Lines.Count > 0;
  OpenQuery2.Enabled := ((mSQL.Lines.Count > 0) and (QueryRunning = False));
  ExecSQL1.Enabled := ((mSQL.Lines.Count > 0) and (QueryRunning = False));
  EnableSQLHistoryItems;
end;

procedure TMainForm.UpdateSQLHistory;
begin
  if (mSQL.Modified) and (mSQL.Lines.Count > 0) then begin
    while oSQLHistory.Count >= SQLHistoryCapacity do
      if oSQLHistory.Count > 0 then oSQLHistory.Delete(0);
    if (SQLHistoryCapacity > 0) then begin
      iSQLHistoryIndex := oSQLHistory.AddObject('',
        TStringList.Create);
      TStrings(oSQLHistory.Objects[iSQLHistoryIndex]).Assign(mSQL.Lines);
      mSQL.Modified := False;
    end;
  end;
  EnableSQLHistoryItems;
end;

procedure TMainForm.EnableSQLHistoryItems;
begin
  PriorSQL.Enabled := ((iSQLHistoryIndex > 0) or (iSQLHistoryIndex = -1)) and
    (oSQLHistory.Count > 0);
  NextSQL.Enabled := (iSQLHistoryIndex <> -1);
  HistoryClear.Enabled := (oSQLHistory.Count > 0);
  HistorySave.Enabled := (oSQLHistory.Count > 0);
end;

procedure TMainForm.NavigSQLClick(Sender: TObject);
var
  NewSQL: Boolean;
  s: string;
  i: integer;
begin
  if (oSQLHistory = nil) or (oSQLHistory.Count = 0) then Exit;
  NewSQL := False;
  if Sender = PriorSQL then begin
    NewSQL := False;
    if iSQLHistoryIndex > 0 then Dec(iSQLHistoryIndex)
    else if iSQLHistoryIndex = -1 then begin
      iSQLHistoryIndex := oSQLHistory.Count - 1;
    end;
  end
  else if Sender = NextSQL then begin
    if iSQLHistoryIndex = -1 then UpdateSQLHistory;
    if iSQLHistoryIndex < oSQLHistory.Count - 1 then
      Inc(iSQLHistoryIndex)
    else begin
      NewSQL := True;
    end;
  end;
  if NewSQL then begin
    iSQLHistoryIndex := -1;
    mSQL.Clear;
    mSQL.Modified := False;
    lHindex.Caption := IntToStr(Succ(oSQLHistory.Count)) + '/' +
      IntToStr(Succ(oSQLHistory.Count));
  end
  else begin
    s := '';
    mSQL.Lines.Assign(TStrings(oSQLHistory.Objects[iSQLHistoryIndex]));
    mSQL.Modified := False;
    for i := 0 to pred(mSQL.Lines.Count) do
      s := s + mSQL.Lines[i] + #13 + #10;
    mSQL.text := s;
    lHindex.Caption := IntToStr(Succ(iSQLHistoryIndex)) + '/' +
      IntToStr(oSQLHistory.Count);
  end;
  EnableSQLHistoryItems;
end;

procedure TMainForm.acSwitchPansExecute(Sender: TObject);
begin
  if (pcDataSQL.Visible = true) then
   begin
    if (pcDataSQL.ActivePageIndex < pcDataSQL.PageCount-1) then
      pcDataSQL.ActivePageIndex := pcDataSQL.ActivePageIndex+1
    else
     pcDataSQL.ActivePageIndex := 0;
    if (pcDataSQL.ActivePage = tsSQL) then
     if (mSQL.CanFocus) then
      mSQL.SetFocus;
   end;
end;

procedure TMainForm.DocStructure(Table: TEasyDataset);
var
  i: integer;
  DFD: TFieldDefs; //Fields Def
  DID: TIndexDefs; //Indexs Def

  function GetFieldTypeAsString(fType: TFieldType): string;
  begin
    Result := GetEnumName(TypeInfo(TFieldType), integer(ftype));
  end;

  function BuildBooleanString(Options: TIndexOptions): string;
  var
    o: string;
  begin
    o := '[';
    if ixPrimary in Options then o := o + 'ixPrimary, ';
    if ixUnique in Options then o := o + 'ixUnique, ';
    if ixDescending in Options then o := o + 'ixDescending, ';
    if ixCaseInsensitive in Options then o := o + 'ixCaseInsensitive, ';
    if ixExpression in Options then o := o + 'ixExpression';
    if Copy(o, length(o) - 1, 2) = ', ' then o := Copy(o, 1, length(o) - 2);
    o := o + ']';
    Result := o;
  end;

  procedure DocFields(DFieldIt: TFieldDef);
  begin
    mSQL.Lines.Add(LeftStr(DFieldIt.Name, 16) +
      LeftStr(GetFieldTypeAsString(DFieldIt.Datatype), 16) +
      LeftStr(IntToStr(DFieldIt.Size), 12) +
      (IntToStr(DFieldIt.Precision)));
  end;

  procedure DocIndex(SindeIt: TIndexDef);
  begin
    mSQL.Lines.Add('');
    mSQL.Lines.Add(LeftStr('IndexName', 16) + SIndeIt.Name);
    mSQL.Lines.Add(LeftStr('Options', 16) +
      BuildBooleanString(SindeIt.Options));
    mSQL.Lines.Add(LeftStr('DisplayName', 16) + SIndeIt.DisplayName);
    mSQL.Lines.Add(LeftStr('Fields', 16) + SIndeIt.Fields);
    mSQL.Lines.Add(LeftStr('DescFields', 16) + SIndeIt.DescFields);
    mSQL.Lines.Add(LeftStr('CaseInsFields', 16) + SIndeIt.CaseInsFields);
    mSQL.Lines.Add(LeftStr('Expression', 16) + SIndeIt.FieldExpression);
  end;

begin
  try
    mSQL.Lines.Add('');
    mSQL.Lines.Add('[ ' + Uppercase(Table.TableName) + ' ]');
    mSQL.Lines.Add('');
    DFD := Table.FieldDefs;
    DID := Table.IndexDefs;
    mSQL.Lines.Add(LeftStr('Fields', 10) + IntToStr(DFD.Count));
    mSQL.Lines.Add(LeftStr('Indexes', 10) + IntToStr(DID.Count));
    mSQL.Lines.Add('');
    mSQL.Lines.Add(LeftStr('FieldName', 16) +
      LeftStr('Type', 16) +
      LeftStr('Size', 8) +
      'Precision');
    mSQL.Lines.Add(MakeStr('-', 64));
    for i := 0 to Pred(DFD.Count) do begin
      DocFields(DFD.Items[i]);
      if i = Pred(DFD.Count) then begin
        mSQL.Lines.Add(MakeStr('-', 64));
      end;
    end;
    DID := Table.IndexDefs;
    for i := 0 to Pred(DID.Count) do begin
      DocIndex(DID.Items[i]);
    end;
    mSQL.Lines.Add('');
    mSQL.Lines.Add('');
  except
    //
  end;
end;

procedure TMainForm.FilePrintStructureExecute(Sender: TObject);
var
  i: integer;
begin
  mSQL.Lines.Clear;
  mSQL.Lines.Add('Data structures documented on ' +
    FormatDateTime('dd/mm/yyyy - hh:nn:ss', Now));
  mSQL.Lines.Add('Database File ' +
    ExtractFileName(CurrentDB.DatabaseFileName));
  for i := 0 to Pred(lbTableList.Items.Count) do begin
    CurrentTable.Active := false;
    CurrentTable.TableName := lbTableList.Items.Strings[i];
    if OpenTable then begin
      CurrentTable.Active := true;
      CurrentDataSource.DataSet := CurrentTable;
      DocStructure(CurrentTable);
    end;
    CurrentTable.Active := False;
  end;
  EditSQLScript1Click(self);
  Notebook.PageIndex := 2;
  pcDataSQL.ActivePageIndex := 3;
  if (mSQL.CanFocus) then
   mSQL.SetFocus;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  oSQLHistory.Free;
  oSQLHistory := nil;
end;

{Added by M.Faraone * End}


procedure TMainForm.OpenQuery1Click(Sender: TObject);
var
  a: Boolean;
begin
  if ((QueryRunning = true) or (mSQL.Text = '')) then Exit;
  a := CurrentTable.Active;
  CurrentTable.Close;
  try
    try
      //Queries... could take some time to be executed...
      Screen.Cursor := crHourGlass;
      mSQL.Modified := True;
      QueryRunning := true;
      CurrentQuery.SQL.Text := mSQL.Text;
      CurrentQuery.RequestLive := cbLiveQuery.Checked;
      CurrentDataSource.DataSet := nil;
      CurrentQuery.Open;
      UpdateTableList;
      seRecNo.MinValue := 1;
      seRecNo.MaxValue := MaxInt;
      seRecNo.Value := 1;
      CurrentDataSource.DataSet := CurrentQuery;
      RecQty.Caption := IntToStr(CurrentQuery.RecNo);
      RecQtyAll.Caption := IntToStr(CurrentQuery.RecordCount);
      FillFieldsTable(CurrentQuery);
      ReopenStructureTables(True);
      pcDataSQL.ActivePageIndex := tsData.PageIndex;
      FieldsTableAfterScroll(FieldsTable);
      CurrentQuery.First;
    except
      on e: Exception do begin
        RecQty.Caption := '';
        RecQtyAll.Caption := '';
        MessageDlg('Error opening query: ' + e.Message, mtError, [mbOK], 0);
      end;
    end;
  finally
    CurrentTable.Active := a;
    CurrentTableAfterScroll(CurrentQuery);
    UpdateSQLHistory;
    QueryRunning := false;
    Screen.Cursor := crDefault;
    if (CurrentQuery.Active = False) then
     if (mSQL.CanFocus) then
      mSQL.SetFocus;
    lHindex.Caption := IntToStr(oSQLHistory.Count) + '/' +
      IntToStr(oSQLHistory.Count);
  end;
end;

procedure TMainForm.ExecuteSQLscript1Click(Sender: TObject);
var
  a: Boolean;
begin
  if ((QueryRunning = true) or (mSQL.Text = '')) then Exit;
  a := CurrentTable.Active;
  CurrentTable.Close;
  try
    try
      //Queries... could take some time to be executed...
      Screen.Cursor := crHourGlass;
      mSQL.Modified := True;
      QueryRunning := True;
      CurrentQuery.SQL.Text := mSQL.Text;
      CurrentQuery.ExecSQL;
      UpdateTableList;
      MessageDlg('Rows affected = ' + IntToStr(CurrentQuery.RowsAffected),
        mtInformation, [mbOK],
        0);
      //RecQty.Caption := 'Rows affected = '+IntToStr(CurrentQuery.RowsAffected);
    except
      on e: Exception do begin
        RecQty.Caption := 'Error';
        MessageDlg('Error executing SQL script: ' + e.Message, mtError, [mbOK],
          0);
      end;
    end;
  finally
    CurrentTable.Active := a;
    UpdateSQLHistory;
    QueryRunning := False;
    Screen.Cursor := crDefault;
    lHindex.Caption := IntToStr(oSQLHistory.Count) + '/' +
      IntToStr(oSQLHistory.Count);
    if (mSQL.CanFocus) then
     mSQL.SetFocus;
  end;
end;

procedure TMainForm.LoadSQLscript1Click(Sender: TObject);
var b: Boolean;
begin
 b := FSkipSyntaxHighlighting;
 FSkipSyntaxHighlighting := True;
 try
   if (odLoadSQL.Execute) then
    begin
     mSQL.Lines.Clear;
     try
       mSQL.Lines.LoadFromFile(odLoadSQL.FileName);
     except
       mSQL.Lines.Clear;
       MessageDlg('Error loading SQL script: '+odLoadSQL.FileName,mtError,[mbOK],0);
     end;
    end;
 finally
  FSkipSyntaxHighlighting := b;
  if (not b) then
   ParseSQL;
 end;
end;

procedure TMainForm.SaveSQLScript1Click(Sender: TObject);
begin
 if (sdSaveSQL.Execute) then
  begin
   try
     mSQL.Lines.SaveToFile(sdSaveSQL.FileName);
   except
     MessageDlg('Error saving SQL script: '+sdSaveSQL.FileName,mtError,[mbOK],0);
   end;
  end;
end;

procedure TMainForm.EditSQLScript1Click(Sender: TObject);
begin
 Notebook.PageIndex := 2;
 pcDataSQL.ActivePageIndex := tsSQL.PageIndex;
end;

procedure TMainForm.bnPrintClick(Sender: TObject);
begin
 pcDataSQL.ActivePageIndex := tsSQL.PageIndex;
 mSQL.Print('Accuracer SQL script');
end;

procedure TMainForm.PaintSQLWord(pos: Integer; length: Integer;
                ToBold: Boolean = False; ToUPPER: Boolean = False; col: TColor = clBlue);
begin
 mSQL.SelStart := pos;
 mSQL.SelLength := length+1;
 mSQL.SelAttributes.Color := col;
 if (ToBold) then
  mSQL.SelAttributes.Style := mSQL.SelAttributes.Style + [fsBold];
 if (ToUPPER) then
  mSQL.SelText := AnsiUpperCase(mSQL.SelText);
end;

procedure TMainForm.ParseSQL;
var
     pos: Integer;
     lex: TEasyLexer;
     t:   TToken;
     l,c,i,j: Integer;
     old: TPoint;
     bTable: Boolean;
begin
 if (FSkipSyntaxHighlighting) then
  Exit;
 try

  if (pcDataSQL.ActivePageIndex <> tsSQL.PageIndex) then
    pcDataSQL.ActivePageIndex := tsSQL.PageIndex;
//  if (mSQL.CanFocus) then
//   mSQL.SetFocus;
  old := mSQL.CaretPos;
  lex := TEasyLexer.Create(mSQL.Lines.Text,CurrentQuery.Params);
  FSkipSyntaxHighlighting := True;
  try
    lex.CurrentCommandNo := 0;
    if (lex.NumCommands > 0) then
    repeat
     lex.Commands[lex.CurrentCommandNo].CurrentTokenNo := 0;
     if (lex.GetCurrentToken(t)) then
      repeat
        if (t.TokenType = tktString) or
           (t.TokenType = tktQuotedString) or
           (t.TokenType = tktBracketedString) or
           (t.TokenType = tktReservedWord) then
         begin
          l := t.LineNum-1;
          c := t.ColumnNum-1;
          pos := 0;
          for i := 0 to l do
           if (i < l) then
            pos := pos  + Length(mSQL.Lines[i]) + 2
           else
            pos := pos + c;
          if (t.TokenType = tktReservedWord) then
           PaintSQLWord(pos,Length(t.Text),False,True,clBlue)
          else
           begin
            bTable := False;
            for j := 0 to lbTableList.Items.Count-1 do
             if (AnsiUpperCase(lbTableList.Items[j]) = AnsiUpperCase(t.Text)) then
              begin
               bTable := True;
               break;
              end;
             if (bTable) then
              PaintSQLWord(pos,Length(t.Text),False,False,clGreen)
             else
              if (t.TokenType <> tktString) then
               PaintSQLWord(pos,Length(t.Text),False,False,clMaroon);
           end;

         end;
      until (not lex.GetNextToken(t));
    until (not lex.GetNextCommand);
  finally
    lex.Free;
    FSkipSyntaxHighlighting := False;
    mSQL.SelLength := 0;
    mSQL.SelStart := 0;
{$IFDEF D6H}
    mSQL.CaretPos := old;
{$ENDIF}
    mSQL.SelAttributes.Color := clWindowText;
    mSQL.SelAttributes.Style := [];
  end;
 except
 end;
end;


procedure TMainForm.bnSQLClick(Sender: TObject);
begin
 ParseSQL;
{
  s := '-- Date: '+DateTimeToStr(Now)+#13#10;
  if (CurrentQuery.Active) then
   s := s+TACRCursor(CurrentQuery.Handle).ExportTableToSQL(True,True,True,False,False,False,True)
  else
   s := s+'-- Table: '+CurrentTable.TableName+#13#10+CurrentTable.ExportTableToSQL(True,True,True,False,False,False,True);
  mSQL.Text := s;
  pcDataSQL.ActivePageIndex := tsSQL.PageIndex;
}
end;

procedure TMainForm.tsDataShow(Sender: TObject);
begin
 dbnView.DataSource := CurrentDataSource;
end;

procedure TMainForm.tsViewFieldsShow(Sender: TObject);
begin
  SetStructureCaption(FieldsTable);
  dbnView.DataSource := FieldsDataSource;
end;

procedure TMainForm.tsViewIndexesShow(Sender: TObject);
begin
  SetStructureCaption(IndexesTable);
  dbnView.DataSource := IndexDataSource;
end;

procedure TMainForm.tsSQLShow(Sender: TObject);
begin
 dbnView.DataSource := nil;
end;

procedure TMainForm.bnSetRecNoClick(Sender: TObject);
begin
 try
   if (CurrentQuery.Active) then
    CurrentQuery.RecNo := seRecNo.Value
   else
    CurrentTable.RecNo := seRecNo.Value;
 except
   on e: Exception do
    MessageDlg('Cannot set RecNo to '+IntToStr(seRecNo.Value)+'. Error: '+#13#10+
     e.Message,mtError,[mbOK],0);
 end;
end;

procedure TMainForm.FormCanResize(Sender: TObject; var NewWidth,
  NewHeight: Integer; var Resize: Boolean);
begin
 Resize := True;
 if (NewHeight < 595) then
  NewHeight := 595;
 if (NewWidth < 790) then
  NewWidth := 790;

end;

procedure TMainForm.mSQLChange(Sender: TObject);
begin
  ParseSQL;
end;

procedure TMainForm.miSQLSyntaxClick(Sender: TObject);
begin
 FSkipSyntaxHighlighting := not FSkipSyntaxHighlighting;
 if (FSkipSyntaxHighlighting) then
  begin
   miSQLSyntax.Caption := 'Enable Syntax Highliting';
   mSQL.SelectAll;
   mSQL.SelAttributes.Color := clWindowText;
   mSQL.SelAttributes.Style := [];
   mSQL.SelLength := 0;
  end
 else
  begin
   miSQLSyntax.Caption := 'Disable Syntax Highliting';
   ParseSQL;
  end;
end;

procedure TMainForm.UpdateTableList;
var sl:  TStringList;
    sel: array of Boolean;
    i,j: Integer;
begin
 sl := TStringList.Create;
 sel := nil;
 try
   sl.Clear;
   sl.Assign(lbTableList.Items);
   SetLength(sel,sl.Count);
   for i := 0 to sl.Count-1 do
     sel[i] := lbTableList.Selected[i];
   lbTableList.Items.Clear;
   CurrentTable.GetTableNameList(lbTableList.Items);
   for i := 0 to sl.Count-1 do
    begin
     j := lbTableList.Items.IndexOf(sl.Strings[i]);
     if (j >= 0) then
      lbTableList.Selected[j] := sel[i];
    end;
 finally
  sl.Free;
  sel := nil;
 end;
 lbSelectedTables.Caption := 'Selected tables: ' +
       IntToStr(lbTableList.SelCount) + ' of ' +
        IntToStr(lbTableList.Items.Count);
end;

end.
