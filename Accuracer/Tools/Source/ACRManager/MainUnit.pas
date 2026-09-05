//==============================================================================
// Unit name: MainUnit
// Copyright AidAim Software, 2000-2022. All rights reserved.
// Description: Accuracer Manager
// Version: 5.11
// History:
//==============================================================================
unit MainUnit;

interface

{$I ACRManager.Inc}
{$HINTS OFF}
uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, CheckLst, ExtCtrls, StdActns, ActnList, ComCtrls, IniFiles,
  ToolWin, Menus, ImgList, Grids, DBGrids, Db, Spin,
  Buttons, DBCtrls,
  ProgressCancel,
  TableProgressCancel,
  ExportToSQL,
  Math,
//  ACRDebug,
  ACRMain,
  ACRComMain, // v.5.10 and higher
  ACRClient,
  ACRDecFmt,
  ACRVariant,
  ACRLexer,
  ACRBase,
  ACRBaseEngine,
  ACRConst,
  ACRExcept,
  ACRCompression,
  ACRConverts,
  ACRTypes,
  ACRTypesNetwork,
  ACRDecUtil,

  WorkGrids,
{$IFDEF MEMCHK}
  MemCheck,
{$ENDIF}
  {$IFDEF D6H}
  Variants,
  {$ENDIF}
  Borrow,
  UseIndex, Find, Filter, RecNo, FindKey, Locate, NewDatabase, Mask
  , OpenDatabase, MakeExecutableDatabase, System.Actions, System.ImageList
  ;

type
  TMainForm = class(TForm)
    Panel2: TPanel;
    Notebook: TNotebook;
    Bevel1: TBevel;
    StatusBar: TStatusBar;
    ImageList1: TImageList;
    ActionList: TActionList;
    FileNew: TAction;
    FileOpen: TAction;
    FileExit: TAction;
    HelpAbout1: TAction;
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
    FileClose: TAction;
    CreateTableControl: TPageControl;
    StructureTab: TTabSheet;
    IndexesTab: TTabSheet;
    Panel1: TPanel;
    FieldsGrid: TDBGrid;
    CurrentDataSource: TDataSource;
    IndexGrid: TDBGrid;
    DialogDataSource: TDataSource;
    Panel4: TPanel;
    dbnView: TDBNavigator;
    RecQty: TLabel;
    acRestructureTable: TAction;
    ToolsMenu: TMenuItem;
    Restructuretable1: TMenuItem;
    RepairButton: TToolButton;
    acCloseTable: TAction;
    acCreateTable: TAction;
    acOpenTable: TAction;
    FileRepair: TAction;
    Repairdatabase1: TMenuItem;
    Createtable1: TMenuItem;
    Opentable1: TMenuItem;
    Closetable1: TMenuItem;
    N2: TMenuItem;
    Exporttables1: TMenuItem;
    acRenameTable: TAction;
    acCopyTable: TAction;
    acDeleteTable: TAction;
    N4: TMenuItem;
    Renametables1: TMenuItem;
    Copytables1: TMenuItem;
    Deletetables1: TMenuItem;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    ToolButton10: TToolButton;
    ToolButton11: TToolButton;
    ToolButton12: TToolButton;
    ToolButton13: TToolButton;
    ToolButton14: TToolButton;
    ToolButton15: TToolButton;
    acEmptyTable: TAction;
    Label4: TLabel;
    BitBtn6: TBitBtn;
    acUseIndex: TAction;
    pmActions: TMenuItem;
    Selectindex1: TMenuItem;
    acFind: TAction;
    acFilter: TAction;
    Findrecord1: TMenuItem;
    Filterexpression1: TMenuItem;
    acRecNo: TAction;
    acSetRange: TAction;
    acFindKey: TAction;
    Findkey1: TMenuItem;
    Setrange1: TMenuItem;
    Gotorecord1: TMenuItem;
    acLocate: TAction;
    Locate1: TMenuItem;
    FileCompact: TAction;
    Compactdatabase1: TMenuItem;
    ToolButton9: TToolButton;
    pLeftPanel: TPanel;
    Splitter1: TSplitter;
    FileCopy: TAction;
    FileRename: TAction;
    FileDelete: TAction;
    Renametables2: TMenuItem;
    Deletetables2: TMenuItem;
    FileChangeSettings: TAction;
    Changedatabasesettings1: TMenuItem;
    ReopenDatabaseItem: TMenuItem;
    acAddRecords: TAction;
    Panel6: TPanel;
    SpinButton1: TSpinButton;
    IndexesTable: TACRTable;
    DialogsTable: TACRTable;
    CurrentTable: TACRTable;
    FieldsTable: TACRTable;
    gbFieldPArams: TGroupBox;
    Label2: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    dbmDefaultValue: TDBMemo;
    dbmMinimumValue: TDBMemo;
    dbmMaxiumValue: TDBMemo;
    AdvOptions: TNotebook;
    rgCompressionAlgorithm: TRadioGroup;
    cbCompressionMode: TComboBox;
    Label1: TLabel;
    Label3: TLabel;
    seBLOBBlockSize: TSpinEdit;
    Label5: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    seAIInit: TDBEdit;
    seAIMin: TDBEdit;
    seAIMax: TDBEdit;
    seAIInc: TDBEdit;
    cbAICycled: TCheckBox;
    ToolButton16: TToolButton;
    ToolButton8: TToolButton;
    FileInfo: TAction;
    Databaseinformation1: TMenuItem;
    acRepairTable: TAction;
    ToolButton17: TToolButton;
    FileMakeExeDatabase: TAction;
    Copydatabase1: TMenuItem;
    MakeExeDatabase1: TMenuItem;
    ToolButton18: TToolButton;
    ToolButton19: TToolButton;
    ToolButton20: TToolButton;
    ToolButton21: TToolButton;
    pcDataSQL: TPageControl;
    tsData: TTabSheet;
    tsSQL: TTabSheet;
    OpenGrid: TDBGrid;
    bnOpenQuery: TButton;
    CurrentQuery: TACRQuery;
    pmSQL: TMenuItem;
    OpenQuery1: TMenuItem;
    LoadSQLscript1: TMenuItem;
    SaveSQLScript1: TMenuItem;
    odLoadSQL: TOpenDialog;
    sdSaveSQL: TSaveDialog;
    EditSQLScript1: TMenuItem;
    mSQL: TRichEdit;
    ToolButton22: TToolButton;
    FileExportDatabaseToSQL: TAction;
    acExportTableToSQL: TAction;
    ToolButton23: TToolButton;
    FileExportDatabaseToSQL1: TMenuItem;
    acExportTableToSQL1: TMenuItem;
    tsForeignKeys: TTabSheet;
    ForeignKeysTable: TACRTable;
    FKDataSource: TDataSource;
    DBGrid1: TDBGrid;
    FKMatchType: TACRTable;
    FKDeleteActionType: TACRTable;
    TableNames: TACRTable;
    FKUpdateActionType: TACRTable;
    {20060308_Added by M.Faraone * Begin}
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
    N8: TMenuItem;
    OpenQuery2: TMenuItem;
    Clear1: TMenuItem;
    N9: TMenuItem;
    acSwitchPans: TAction;
    FilePrintStructure: TAction;
    FilePrintStructure1: TMenuItem;
    HistoryClear: TMenuItem;
    HistorySave: TMenuItem;
    {20060308_Added by M.Faraone * End}
    cbLiveQuery: TCheckBox;
    tsViewFields: TTabSheet;
    dbgViewFields: TDBGrid;
    RecQtyAll: TLabel;
    lbStructureQty: TLabel;
    Panel7: TPanel;
    Label11: TLabel;
    dbmDefault: TDBMemo;
    dbmMin: TDBMemo;
    lbMinimum: TLabel;
    dbmMax: TDBMemo;
    Label13: TLabel;
    tsViewIndexes: TTabSheet;
    tsViewForeignKeys: TTabSheet;
    Panel8: TPanel;
    Button1: TButton;
    dbnCreateTable: TDBNavigator;
    btnOk: TBitBtn;
    btnCancel: TBitBtn;
    bnBorrow: TButton;
    lbCreateQty: TLabel;
    DBGrid2: TDBGrid;
    DBGrid3: TDBGrid;
    bnSQL: TButton;
    bnPrint: TBitBtn;
    Label12: TLabel;
    seRecNo: TSpinEdit;
    bnSetRecNo: TSpeedButton;
    miSQLSyntax: TMenuItem;
    Label14: TLabel;
    eRecordSize: TEdit;
    Label15: TLabel;
    eOptimalPageSize: TEdit;
    Updatetableslist1: TMenuItem;
    pcLeftPanel: TPageControl;
    tsTables: TTabSheet;
    lbSelectedTables: TLabel;
    lbTableList: TListBox;
    tsStoredFunctions: TTabSheet;
    lbSelectedFunctions: TLabel;
    lbStoredFunctions: TListBox;
    acDropFunction: TAction;
    acAlterStoredFunction: TAction;
    acCreateStoredFunction: TAction;
    ToolButton24: TToolButton;
    ToolButton25: TToolButton;
    ToolButton26: TToolButton;
    ToolButton27: TToolButton;
    StoredFunctions1: TMenuItem;
    CreateStoredFunction1: TMenuItem;
    DropStoredFunction1: TMenuItem;
    AlterStoredFunction1: TMenuItem;
    CurrentDB: TACRDatabase;
    ForeignKeysTableName: TWideStringField;
    ForeignKeysTableIntReferencedTableName: TWideStringField;
    ForeignKeysTableFields: TWideStringField;
    ForeignKeysTableIntMatchType: TSmallintField;
    ForeignKeysTableIntDeleteAction: TSmallintField;
    ForeignKeysTableIntUpdateAction: TSmallintField;
    ForeignKeysTableReferencedTableName: TWideStringField;
    ForeignKeysTableMatchType: TStringField;
    ForeignKeysTableDeleteAction: TStringField;
    ForeignKeysTableUpdateAction: TStringField;
    cbIgnoreCase: TCheckBox;
    {20071108_Added by M.Faraone * Start}
    procedure pcDataSQLChange(Sender: TObject);
    procedure DisableSQLParsingTextAttributes;
    {20071108_Added by M.Faraone * End}
    procedure ConvertFieldsTableToFieldParams;
    procedure ConvertFieldParamsToFieldsTable;
    procedure ConvertDataParamsToDataSettings( Options: TACROptionsEditor = nil;
                                               CryptoParams: TACRCryptoParamsEditor = nil);
    procedure ConvertDataSettingsToDataParams;
    procedure SetEnabledForFieldParams;
    procedure HelpAboutItemClick(Sender: TObject);
    procedure FileExitItemClick(Sender: TObject);
    procedure NewTableButtonClick(Sender: TObject);
    procedure Close1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FieldsTableNewRecord(DataSet: TDataSet);
    procedure FieldsTableBeforePost(DataSet: TDataSet);
    function DoOpenDatabase(DB: TACRDatabase): Boolean;
    procedure FileOpenExecute(Sender: TObject);
    procedure IndexGridCellClick(Column: TColumn);
    procedure IndexesTableNewRecord(DataSet: TDataSet);
    procedure IndexGridColEnter(Sender: TObject);
    procedure IndexGridDblClick(Sender: TObject);
    procedure OpenGridDblClick(Sender: TObject);
    procedure CurrentTableAfterScroll(DataSet: TDataSet);
    procedure acRestructureTableExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FileNewExecute(Sender: TObject);
    procedure acCloseTableExecute(Sender: TObject);
    procedure lbTableListClick(Sender: TObject);
    procedure acCreateTableExecute(Sender: TObject);
    procedure acOpenTableExecute(Sender: TObject);
    procedure acRenameTableExecute(Sender: TObject);
    procedure acCopyTableExecute(Sender: TObject);
    procedure acDeleteTableExecute(Sender: TObject);
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
    procedure FileDeleteExecute(Sender: TObject);
    procedure FileRenameExecute(Sender: TObject);
    procedure IndexesTableBeforePost(DataSet: TDataSet);
    procedure ChangeFieldsTableRecords(bm1,bm2: TBookmark);
    procedure SpinButton1UpClick(Sender: TObject);
    procedure SpinButton1DownClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FileRepairExecute(Sender: TObject);
    procedure FileCompactExecute(Sender: TObject);
    procedure CurrentDBProgress(Sender: TComponent; Progress: Double;
      Operation: TACRDatabaseOperation; var Abort: Boolean);
    procedure CurrentDBTableProgress(Sender: TComponent; Progress: Double;
      Operation: TACRTableOperation; var Abort: Boolean);
    procedure CurrentTableProgress(Sender: TComponent; Progress: Double;
      Operation: TACRTableOperation; var Abort: Boolean);
    procedure rgCompressionAlgorithmClick(Sender: TObject);
    procedure FieldsGridColExit(Sender: TObject);
    procedure FieldsTableAfterPost(DataSet: TDataSet);
    procedure FieldsTableAfterDelete(DataSet: TDataSet);
    procedure FieldsTableAfterScroll(DataSet: TDataSet);
    procedure seBLOBBlockSizeChange(Sender: TObject);
    procedure cbAICycledClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FileChangeSettingsExecute(Sender: TObject);
    procedure FileInfoExecute(Sender: TObject);
    procedure acRepairTableExecute(Sender: TObject);
    procedure File1Click(Sender: TObject);
    procedure FileMakeExeDatabaseExecute(Sender: TObject);
    procedure FileCopyExecute(Sender: TObject);
    procedure bnOpenQueryClick(Sender: TObject);
    procedure OpenQuery1Click(Sender: TObject);
    procedure LoadSQLscript1Click(Sender: TObject);
    procedure SaveSQLScript1Click(Sender: TObject);
    procedure EditSQLScript1Click(Sender: TObject);
    procedure acExportTableToSQLExecute(Sender: TObject);
    procedure FileExportDatabaseToSQLExecute(Sender: TObject);
    procedure ClearClick(Sender: TObject);
    procedure CurrentDBAfterServerShutdown(Sender: TObject);
    procedure NetworkDownError;
    procedure bnFKClearClick(Sender: TObject);
    procedure ForeignKeysTableAfterInsert(DataSet: TDataSet);
    {20060308_Added by M.Faraone * Begin}
    procedure acSwitchPansExecute(Sender: TObject);
    procedure PopupSQLMenuPopup(Sender: TObject);
    procedure PopupSQLMenuClick(Sender: TObject);
    procedure NavigSQLClick(Sender: TObject);
    procedure EnableSQLHistoryItems;
    procedure UpdateSQLHistory;
    procedure FilePrintStructureExecute(Sender: TObject);
    procedure DocStructure(Table: TACRTable);
    procedure FormDestroy(Sender: TObject);
    procedure SaveSQLHistory;
    //These three functions come from library RX...
    //{         Copyright (c) 1995, 1996 AO ROSNO             }
    //{         Copyright (c) 1997, 1998 Master-Bank          }
    function LeftStr(const S: string; N: Integer): string;
    function MakeStr(C: Char; N: Integer): string;
    function AddCharR(C: Char; const S: string; N: Integer): string;
    {20060308_Added by M.Faraone * End}
    procedure IndexesTableAfterScroll(DataSet: TDataSet);
    procedure ForeignKeysTableAfterScroll(DataSet: TDataSet);
    procedure tsViewFieldsShow(Sender: TObject);
    procedure tsViewForeignKeysShow(Sender: TObject);
    procedure tsViewIndexesShow(Sender: TObject);
    procedure tsDataShow(Sender: TObject);
    procedure tsSQLShow(Sender: TObject);
    procedure StructureTabShow(Sender: TObject);
    procedure IndexesTabShow(Sender: TObject);
    procedure tsForeignKeysShow(Sender: TObject);
    procedure IndexesTableAfterPost(DataSet: TDataSet);
    procedure ForeignKeysTableAfterPost(DataSet: TDataSet);
    procedure bnSQLClick(Sender: TObject);
    procedure bnPrintClick(Sender: TObject);
    procedure PaintSQLWord(pos: Integer; length: Integer;
                ToBold: Boolean = False; ToUPPER: Boolean = False; col: TColor = clBlue);
    procedure ParseSQL;
    procedure pLeftPanelCanResize(Sender: TObject; var NewWidth,
      NewHeight: Integer; var Resize: Boolean);
    procedure bnSetRecNoClick(Sender: TObject);
    procedure FormCanResize(Sender: TObject; var NewWidth,
      NewHeight: Integer; var Resize: Boolean);
    procedure miSQLSyntaxClick(Sender: TObject);
    procedure mSQLChange(Sender: TObject);
    procedure lbTableListDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure Updatetableslist1Click(Sender: TObject);
    procedure lbStoredFunctionsDblClick(Sender: TObject);
    procedure acCreateStoredFunctionExecute(Sender: TObject);
    procedure acDropFunctionExecute(Sender: TObject);
    procedure acAlterStoredFunctionExecute(Sender: TObject);
    procedure lbStoredFunctionsClick(Sender: TObject);
    procedure mSQLShowLineColumn;
    procedure mSQLSelectionChange(Sender: TObject);
    procedure cbIgnoreCaseClick(Sender: TObject);
  private
    { Private declarations }
    prevPageNo: integer;
    FSkipSyntaxHighlighting: Boolean;
    {20060308_Added by M.Faraone * Start}
    iSQLHistoryIndex: Integer;
    oSQLHistory: TStrings;
    QueryRunning: Boolean;
    FTablesInfo:  TACRTableInfoArray;
    {20060308_Added by M.Faraone * End}
    function OpenDatabase(
                          DB:            TACRDatabase;
                          out ErrMsg:    String;
                          DBFileName:    String;
                          LocalDatabase: Boolean = True;
                          DatabaseName:  String = '';
                          Protocol:      String = 'UDP';
                          RemoteHost:    String = '';
                          RemotePort:    Integer = 0;
                          LocalPort:     Integer = 0
                          ): Boolean;
    procedure ViewActionsMenu(Show: Boolean);
    procedure SetNewPage(newPage : integer);
    procedure CreateFieldsTable;
    procedure CreateIndexesTable;
    procedure CreateForeignKeysTable(skipNameCheck: Boolean = false);
    procedure InitCreateTable;
    procedure FillFieldsTable(SourceTable: TACRDataset);
    procedure InitRestructTable(SourceTable: TACRTable);
    procedure InitAll;
    procedure CreateTable;
    function RestructTable: Boolean;
    function OpenTable: Boolean;
    procedure LoadSettings;
    procedure SaveSettings;
    procedure SetDatabaseFile(DBFileName: string;
                                bOpenLastFile: Boolean);
    procedure LoadDatabaseFile;
    procedure SetStructureCaption(Dataset: TDataset);
    procedure ReopenStructureTables(ReadOnly: Boolean; Save: Boolean = False);
    procedure UpdateTableList;
    procedure ShowTableListHint;
  public
    { Public declarations }
  end;
procedure GetFilePathAndName(pathName : string; var path,name,ext : string);

var
  MainForm: TMainForm;
  pageNo : integer = 0;
  acr_action : string = '';
  SetupTitle : string='Accuracer Manager - ';
  bdeExt : string;
  IniFile : TIniFile;

{20060308_Added by M.Faraone * Start}
const
  SQLHistoryCapacity: Integer = 40;
{20060308_Added by M.Faraone * End}



implementation

uses AddIndex, EditMemo, EditFmtMemo,
  EditGraphic, EditBlob, AboutUnit, SetRange, Security, uDatabaseInfo,
  //20060308_Added by M.Faraone * Start
  ClipBrd, TypInfo;
  //20060308_Added by M.Faraone * End

{$R *.DFM}

Function ShellExecute(hWnd:HWND;lpOperation:Pchar;lpFile:Pchar;lpParameter:Pchar;
                      lpDirectory:Pchar;nShowCmd:Integer):Thandle; Stdcall;
External 'Shell32.Dll' name 'ShellExecuteA';


//------------------------------------------------------------------------------
// convert database settings to components values
//------------------------------------------------------------------------------
procedure TMainForm.ConvertDataSettingsToDataParams;
var
 keyHEX, invHEX :string;
 fm: TFormat_HEX;
begin
 with FormNewDatabase do
  begin
   sePageSize.Value := CurrentDB.Options.PageSize;
   seMaxConnections.Value := CurrentDB.Options.MaxSessionCount;
   if CurrentDB.IsDatabaseEncrypted then
    begin
     Encrypted.Checked := true;
     EncryptedClick(MainForm);
     case CurrentDB.CryptoParams.CryptoAlgorithm of
      craRijndael_128 : cbAlgorithm.ItemIndex := 0;
	    craRijndael_256 : cbAlgorithm.ItemIndex := 1;
	    craBlowfish : cbAlgorithm.ItemIndex := 2;
	    craTwofish_128 : cbAlgorithm.ItemIndex := 3;
	    craTwofish_256 : cbAlgorithm.ItemIndex := 4;
	    craSquare : cbAlgorithm.ItemIndex := 5;
	    craDES_Single_8 : cbAlgorithm.ItemIndex := 6;
	    craDES_Double_8 : cbAlgorithm.ItemIndex := 7;
	    craDES_Double_16 : cbAlgorithm.ItemIndex := 8;
      craDES_Triple_8 : cbAlgorithm.ItemIndex := 9;
	    craDES_Triple_16 : cbAlgorithm.ItemIndex := 10;
	    craDES_Triple_24 : cbAlgorithm.ItemIndex := 11;
     end;
     cbMode.ItemIndex := Integer(CurrentDB.CryptoParams.CryptoMode);
     if CurrentDB.CryptoParams.UseInitVector then
      begin
       IsInitVector.Checked := True;
       IsInitVectorClick(MainForm);
       fm := TFormat_HEX.Create;
       try
        invHEX := fm.Encode(CurrentDB.CryptoParams.GetInitVector^,
                             CurrentDB.CryptoParams.MaxInitVectorSize);
       finally
        fm.Free;
       end;
       FillGrid(InitVectorGrid,invHEX);
      end;
     if CurrentDB.IsDatabaseEncryptedByPassword then
      begin
       EncryptPageControl.TabIndex := 0;
       tPassword.Text := CurrentDB.CryptoParams.Password;
       tRPassword.Text := tPassword.Text;
      end
     else
      begin
       EncryptPageControl.TabIndex := 1;
       seKeySize.Value := CurrentDB.CryptoParams.KeySize;
       fm := TFormat_HEX.Create;
       try
        keyHEX := fm.Encode(CurrentDB.CryptoParams.GetKey^,
                             CurrentDB.CryptoParams.KeySize);
       finally
        fm.Free;
       end;
       FillGrid(KeyGrid,keyHEX);
      end;
    end
   else
    begin
     Encrypted.Checked := false;
     EncryptedClick(MainForm);
    end;
  end;
end;//onvertDataSettingsToDataParams


//------------------------------------------------------------------------------
// convert components values to database settings
//------------------------------------------------------------------------------
procedure TMainForm.ConvertDataParamsToDataSettings( Options: TACROptionsEditor = nil;
                                                     CryptoParams: TACRCryptoParamsEditor = nil);
var
    keyfile,invfile: TFileStream;
    key, inv : PChar;
    keyHEX, invHEX :string;
begin
 with FormNewDatabase do
  begin
   if Options <> nil then
    begin
     Options.PageSize := sePageSize.Value;
     Options.MaxSessionCount := seMaxConnections.Value;
    end
   else
    begin
     CurrentDB.DatabaseFileName := edDBFileName.Text;
     CurrentDB.Options.PageSize := sePageSize.Value;
     CurrentDB.Options.MaxSessionCount := seMaxConnections.Value;
    end;
   if CryptoParams <> nil then
    begin
     if (Encrypted.Checked) then
      begin
       case cbAlgorithm.ItemIndex of
        0:CryptoParams.CryptoAlgorithm := craRijndael_128;
        1:CryptoParams.CryptoAlgorithm := craRijndael_256;
        2:CryptoParams.CryptoAlgorithm := craBlowfish;
        3:CryptoParams.CryptoAlgorithm := craTwofish_128;
        4:CryptoParams.CryptoAlgorithm := craTwofish_256;
        5:CryptoParams.CryptoAlgorithm := craSquare;
        6:CryptoParams.CryptoAlgorithm := craDES_Single_8;
        7:CryptoParams.CryptoAlgorithm := craDES_Double_8;
        8:CryptoParams.CryptoAlgorithm := craDES_Double_16;
        9:CryptoParams.CryptoAlgorithm := craDES_Triple_8;
        10:CryptoParams.CryptoAlgorithm := craDES_Triple_16;
        11:CryptoParams.CryptoAlgorithm := craDES_Triple_24;
       end;
       CryptoParams.CryptoMode := TACRCryptoMode(FormNewDatabase.cbMode.ItemIndex);
       if IsInitVector.Checked then
        begin
         CryptoParams.UseInitVector := true;
         invHEX := GetString(InitVectorGrid);
         inv := AllocMem(length(invHEX) div 2);
         HexToBin(PChar(LowerCase(invHEX)),inv,length(invHEX) div 2);
         CryptoParams.SetInitVector(inv,length(invHEX) div 2);
         if VectorSave.Checked then
          begin
           invfile := TFileStream.Create(edInvFileName.Text, fmCreate);
           invfile.WriteBuffer(inv^,CryptoParams.MaxInitVectorSize);
           invfile.Free;
          end;
         FreeMem(inv);
        end;
       if (EncryptPageControl.TabIndex = 0)
        then
         CryptoParams.Password := tPassword.Text
        else
         if (EncryptPageControl.TabIndex = 1)
          then
           begin
            keyHEX := GetString(KeyGrid);
            key := AllocMem(length(keyHEX) div 2);
            HexToBin(PChar(LowerCase(keyHEX)),key,length(keyHEX) div 2);
            CryptoParams.SetKey(key,length(keyHEX) div 2);
            if KeySave.Checked then
             begin
              keyfile := TFileStream.Create(edKeyFileName.Text, fmCreate);
              keyfile.WriteBuffer(key^,CryptoParams.KeySize);
              keyfile.Free;
             end;
            FreeMem(key);
           end
      end
     else
      CryptoParams.CryptoAlgorithm := craNone;
    end
   else
    begin
     if (Encrypted.Checked) then
      begin
       case cbAlgorithm.ItemIndex of
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
       if IsInitVector.Checked then
        begin
         CurrentDB.CryptoParams.UseInitVector := true;
         invHEX := GetString(InitVectorGrid);
         inv := AllocMem(length(invHEX) div 2);
         HexToBin(PChar(LowerCase(invHEX)),inv,length(invHEX) div 2);
         CurrentDB.CryptoParams.SetInitVector(inv,length(invHEX) div 2);
         if VectorSave.Checked then
          begin
           invfile := TFileStream.Create(edInvFileName.Text, fmCreate);
           invfile.WriteBuffer(inv^,CurrentDB.CryptoParams.MaxInitVectorSize);
           invfile.Free;
          end;
         FreeMem(inv);
        end;
       if (EncryptPageControl.TabIndex = 0)
        then
         CurrentDB.CryptoParams.Password := tPassword.Text
        else
         if (EncryptPageControl.TabIndex = 1)
          then
           begin
            keyHEX := GetString(KeyGrid);
            key := AllocMem(length(keyHEX) div 2);
            HexToBin(PChar(LowerCase(keyHEX)),key,length(keyHEX) div 2);
            CurrentDB.CryptoParams.SetKey(key,length(keyHEX) div 2);
            if KeySave.Checked then
             begin
              keyfile := TFileStream.Create(edKeyFileName.Text, fmCreate);
              keyfile.WriteBuffer(key^,CurrentDB.CryptoParams.KeySize);
              keyfile.Free;
             end;
            FreeMem(key);
           end
      end
     else
      CurrentDB.CryptoParams.CryptoAlgorithm := craNone;
    end;
  end;
end; //ConvertDataParamsToDataSettings


//------------------------------------------------------------------------------
// Open database
//------------------------------------------------------------------------------
function TMainForm.OpenDatabase(
                          DB:            TACRDatabase;
                          out ErrMsg:    String;
                          DBFileName:    String;
                          LocalDatabase: Boolean = True;
                          DatabaseName:  String = '';
                          Protocol:      String = 'UDP';
                          RemoteHost:    String = '';
                          RemotePort:    Integer = 0;
                          LocalPort:     Integer = 0
                          ): Boolean;

begin
 ErrMsg := '';
 DB.Connected := false;
 DB.ReadOnly := False;
 DB.DatabaseFileName := DBFileName;
 DB.LocalDatabase := LocalDatabase;
 if (not DB.LocalDatabase) then
  begin
   DB.ConnectionParams.DatabaseName := DatabaseName;
   if Protocol = 'UDP' then
     DB.ConnectionParams.Protocol := acrUDP
   else
     DB.ConnectionParams.Protocol := acrTCP;
   DB.ConnectionParams.RemoteHost := RemoteHost;
   DB.ConnectionParams.RemotePort := RemotePort;
   DB.ConnectionParams.LocalPort := LocalPort;
  end;
 Result := False;

 if (DB.LocalDatabase) then
  begin
   if (not DB.Exists) then
    begin
     Result := False;
     MessageDlg('Database file does not exist.'+#13#10+DBFileName,mtError,[mbOK],0);
     Exit;
    end;
   if (not DB.IsAccuracerDatabaseFile) then
    begin
     Result := False;
     MessageDlg('Not an Accuracer database file or incompatible Accuracer version.'+#13#10+DBFileName,mtError,[mbOK],0);
     Exit;
    end;
  end;
 if DB.IsDatabaseEncrypted then
  begin
   if FormSecurity = nil then
    FormSecurity := TFormSecurity.Create(Application);
   FormSecurity.Caption := 'Database "'+DBFileName+'" authentification';
   adbFileName := DBFileName;
   Security.Data := DB;
   if DB.IsDatabaseEncryptedByPassword then
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
   if DB.IsCryptoParamsValid then
     try
       DB.Connected := true;
     except
       Result := False;
       Exit;
     end;
  end
 else
   try
     DB.Connected := true;
   except
    on e: Exception do
     begin
        ErrMsg := e.Message;
        Result := False;
        Exit;
     end;
   end;
 Result := True;
 if (DB = CurrentDB) then
  if (DB.Connected) then
   begin
    CurrentTable.DatabaseName := DB.DatabaseName;
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
end; // ViewActionsMenu


//------------------------------------------------------------------------------
// Set new notebook page
//------------------------------------------------------------------------------
procedure TMainForm.SetNewPage(newPage : integer);
var s: String;
begin
 if (CurrentDB.LocalDatabase) then
  s := ExtractFileName(CurrentDb.DatabaseFileName)
 else
  s := CurrentDB.ConnectionParams.DatabaseName;
 case newPage of
  0 : begin
       lbTableList.Items.Clear;
       CurrentDb.Connected := false;
       MainForm.Caption := SetupTitle+'Welcome';
       MainForm.Notebook.Color := clGray;
       // actions
       FileNew.Enabled := true;
       FileOpen.Enabled := true;
       FileChangeSettings.Enabled := false;
       FileClose.Enabled := false;
       FileRepair.Enabled := false;
       FileCompact.Enabled := false;
       FileDelete.Enabled := false;
       FileInfo.Enabled := false;
       FileCopy.Enabled := false;
       FileRename.Enabled := false;
       FileExportDatabaseToSQL.Enabled := False;
       FileMakeExeDatabase.Enabled := False;
       acExportTableToSQL.Enabled := False;
		   acCreateTable.Enabled := false;
		   acOpenTable.Enabled := false;
			 acRestructureTable.Enabled := false;
       acRepairTable.Enabled := false;
			 acEmptyTable.Enabled := false;
			 acRenameTable.Enabled := false;
			 acCopyTable.Enabled := false;
			 acDeleteTable.Enabled := false;
			 acCloseTable.Enabled := false;
       ViewActionsMenu(False);
       OpenQuery1.Enabled := false;
       LoadSQLscript1.Enabled := false;
       SaveSQLScript1.Enabled := false;
       EditSQLScript1.Enabled := false;
       {20060308_Added by M.Faraone * Start}
       FilePrintStructure.Enabled := false;
       {20060308_Added by M.Faraone * End}
      end;
  1 : begin
       if (acr_action = 'create') then
        MainForm.Caption := SetupTitle+'Create new table'+
       			' in database "'+ s +'"'
       else
        MainForm.Caption := SetupTitle+'Restructure table "'+CurrentTable.TableName+
       			'" in database "'+ s +'"';
       MainForm.Notebook.Color := clBtnFace;
		   acCreateTable.Enabled := false;
       acExportTableToSQL.Enabled := False;
		   acOpenTable.Enabled := false;
			 acRestructureTable.Enabled := false;
       acRepairTable.Enabled := false;
			 acEmptyTable.Enabled := false;
			 acRenameTable.Enabled := false;
			 acCopyTable.Enabled := false;
			 acDeleteTable.Enabled := false;
			 acCloseTable.Enabled := true;
       ViewActionsMenu(False);
       {20060308_Added by M.Faraone * Start}
       FilePrintStructure.Enabled := (lbTableList.Count > 0);
       {20060308_Added by M.Faraone * End}
      end;
  2 : begin
       MainForm.Caption := SetupTitle+'Manage table "'+CurrentTable.TableName+
       			'" in database "'+ s +'"';
       MainForm.Notebook.Color := clBtnFace;
       UpdateTableList;
		   acCreateTable.Enabled := false;
		   acOpenTable.Enabled := false;
			 acRestructureTable.Enabled := true;
       acExportTableToSQL.Enabled := True;
       acRepairTable.Enabled := true;
			 acEmptyTable.Enabled := true;
			 acRenameTable.Enabled := true;
			 acCopyTable.Enabled := true;
			 acDeleteTable.Enabled := true;
			 acCloseTable.Enabled := true;
       ViewActionsMenu(True);

			 FormIndex.lbIndexes.Items.Clear;

			 CurrentTable.GetIndexNames(FormIndex.lbIndexes.Items);

			 FormFind.lbFields.Items.Clear;
			 CurrentTable.GetFieldNames(FormFind.lbFields.Items);
			 FormFind.lbFields.ItemIndex := -1;

			 FormFilter.lbFields.Items.Clear;
			 CurrentTable.GetFieldNames(FormFilter.lbFields.Items);
			 FormFilter.lbFields.ItemIndex := -1;
       {20060308_Added by M.Faraone * Start}
       FilePrintStructure.Enabled := (lbTableList.Count > 0);
       {20060308_Added by M.Faraone * End}
       bnPrint.Enabled := True;
      end;
  3 : begin
       acr_action := 'manage database';
       MainForm.Caption := SetupTitle+'Manage database "'+s+'"';
       MainForm.Notebook.Color := clGray;
       UpdateTableList;
			 acCreateTable.Enabled := true;
			 acOpenTable.Enabled := false;
			 acRestructureTable.Enabled := false;
       acRepairTable.Enabled := false;
			 acEmptyTable.Enabled := false;
			 acRenameTable.Enabled := false;
			 acCopyTable.Enabled := false;
			 acDeleteTable.Enabled := false;
       FileChangeSettings.Enabled := true;
			 FileRepair.Enabled := true;
       FileCompact.Enabled := true;
			 FileClose.Enabled := true;
       FileDelete.Enabled := true;
       FileCopy.Enabled := true;
       FileRename.Enabled := true;
       FileInfo.Enabled := true;
       FileExportDatabaseToSQL.Enabled := True;
       FileMakeExeDatabase.Enabled := True;
       acExportTableToSQL.Enabled := True;
			 acCloseTable.Enabled := false;
       ViewActionsMenu(False);
       OpenQuery1.Enabled := true;
       LoadSQLscript1.Enabled := true;
       SaveSQLScript1.Enabled := true;
       EditSQLScript1.Enabled := true;
       {20060308_Added by M.Faraone * Start}
       FilePrintStructure.Enabled := (lbTableList.Count > 0);
       {20060308_Added by M.Faraone * End}
       bnPrint.Enabled := False;
      end;
 end;
 Notebook.PageIndex := newPage;
end;

procedure TMainForm.ConvertFieldsTableToFieldParams;
begin
 if (FieldsTable.ReadOnly) then
  Exit;
 rgCompressionAlgorithm.OnClick := nil;
 seBLOBBlockSize.OnChange := nil;
 try
   rgCompressionAlgorithm.ItemIndex :=
    FieldsTable.FieldByName('CompressionAlgorithm').AsInteger;
   if (rgCompressionAlgorithm.ItemIndex = 0) then
    cbCompressionMode.Enabled := False
   else
    cbCompressionMode.Enabled := True;
   cbCompressionMode.ItemIndex :=
     FieldsTable.FieldByName('CompressionMode').AsInteger-1;
   seBLOBBlockSize.Value := FieldsTable.FieldByName('BLOBBlockSize').AsInteger;
   cbAICycled.Checked := FieldsTable.FieldByName('AICycled').AsBoolean;
 finally
   rgCompressionAlgorithm.OnClick := rgCompressionAlgorithmClick;
   seBLOBBlockSize.OnChange := seBLOBBlockSizeChange;
 end;
end;


procedure TMainForm.ConvertFieldParamsToFieldsTable;
begin
 if (not (AdvOptions.ActivePage = 'BLOBs')) then
  begin
   FieldsTable.FieldByName('CompressionAlgorithm').AsInteger := 0;
   FieldsTable.FieldByName('CompressionMode').AsInteger := 0;
   FieldsTable.FieldByName('BLOBBlockSize').AsInteger := 0;
  end
 else
  begin
   FieldsTable.FieldByName('CompressionAlgorithm').AsInteger := rgCompressionAlgorithm.ItemIndex;
   FieldsTable.FieldByName('CompressionMode').AsInteger := cbCompressionMode.ItemIndex;
   if (not seBLOBBlockSize.Enabled) then
    begin
     FieldsTable.FieldByName('BLOBBlockSize').AsInteger := 0;
    end
   else
    begin
     FieldsTable.FieldByName('BLOBBlockSize').AsInteger := seBLOBBlockSize.Value;
    end;
  end;
 if (not (AdvOptions.ActivePage = 'AutoInc'))
  then
   FieldsTable.FieldByName('AICycled').AsBoolean := false
 else
  FieldsTable.FieldByName('AICycled').AsBoolean := cbAICycled.Checked;
end;

procedure TMainForm.SetEnabledForFieldParams;
var AdvType:  TACRAdvancedFieldType;
    i:        Integer;
begin
// if (not (FieldsTable.State in [dsInsert,dsEdit])) then
//  Exit;
 AdvType := aftUnknown;
 for i := Low(ACRFieldTypes) to High(ACRFieldTypes) do
  if (UpperCase(ACRFieldTypes[i].Name) = UpperCase(FieldsTable.FieldByName('Type').AsString)) then
   AdvType := ACRFieldTypes[i].AdvancedFieldType;
 if (FieldsTable.State in [dsEdit,dsInsert]) then
  if (not IsStringFieldType(AdvType)) then
   FieldsTable.FieldByName('Size').AsInteger := 0;
 if (IsBLOBFieldType(AdvType)) then
  begin
    AdvOptions.ActivePage := 'BLOBs';
    seBLOBBlockSize.Enabled := True;
  end
 else
  if (IsVarcharFieldType(AdvType)) then
   begin
    AdvOptions.ActivePage := 'BLOBs';
    seBLOBBlockSize.Enabled := False
   end
  else
   if (IsAutoincFieldType(AdvType)) then
    AdvOptions.ActivePage := 'AutoInc'
   else
    AdvOptions.ActivePage := 'Empty';
  ConvertFieldsTableToFieldParams;
end;

procedure TMainForm.HelpAboutItemClick(Sender: TObject);
begin
 ACRManAbout.ShowModal;
end;

procedure TMainForm.FileExitItemClick(Sender: TObject);
begin
 Close;
 Application.Terminate;
end;

procedure TMainForm.NewTableButtonClick(Sender: TObject);
begin
 acr_action := 'create';
 SetNewPage(1);
end;

procedure TMainForm.Close1Click(Sender: TObject);
begin
 acr_action := '';
 CurrentTable.Active := false;
 SetNewPage(0);
end;

procedure TMainForm.FormCreate(Sender: TObject);
var Res: Boolean;
    s: string;
begin
{$IFDEF MEMCHK}
MemChk;
{$ENDIF}
 FTablesInfo := nil;
 FSkipSyntaxHighlighting := false;
 miSQLSyntaxClick(Self);
 IniFile := TIniFile.Create(ExtractFilePath(ParamStr(0))+'acrmanager.ini');
 InitAll;
 CurrentTable.DatabaseName := CurrentDB.DatabaseName;
 CurrentDb.Connected := false;
 {20060308_Added by M.Faraone * begin}
  iSQLHistoryIndex := -1;
  oSQLHistory := TStringList.Create;
  QueryRunning := false;
 {20060308_Added by M.Faraone * End}
 if (ParamCount > 0) then
  begin
   Res := OpenDatabase(CurrentDB,s,ParamStr(1),True);
   if (not Res) then
    SetNewPage(0);
  end
 else
  begin
    SetNewPage(0);
  end;
 CreateTableControl.ActivePage := StructureTab;
 pcLeftPanel.ActivePage := tsTables;
end;


procedure TMainForm.CreateFieldsTable;
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
     FieldDefs.Add('Name',ftWideString,256,false);
     FieldDefs.Add('Type',ftWideString,50,false);
     FieldDefs.Add('Size',ftInteger,0,false);
     FieldDefs.Add('Required',ftBoolean,0,false);
     FieldDefs.Add('CompressionAlgorithm',ftInteger,0,false);
     FieldDefs.Add('CompressionMode',ftInteger,0,false);
     FieldDefs.Add('BLOBBlockSize',ftInteger,0,false);
     FieldDefs.Add('DefaultValue',ftWideMemo,0,false);
     FieldDefs.Add('MinimumValue',ftWideMemo,0,false);
     FieldDefs.Add('MaximumValue',ftWideMemo,0,false);
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
     FieldsGrid.Columns[1].DropDownRows := 10;
     FieldsGrid.Columns[1].PickList.Clear;
     for i := Low(ACRFieldTypes) to High(ACRFieldTypes) do
      if (FieldsGrid.Columns[1].PickList.IndexOf(ACRFieldTypes[i].Name) = -1) then
       FieldsGrid.Columns[1].PickList.Add(ACRFieldTypes[i].Name);
   end; //table fields
end;

procedure TMainForm.CreateIndexesTable;
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
     FieldDefs.Add('Index_name',ftWideString,256,true);
     FieldDefs.Add('Descending',ftBoolean,0,false);
     FieldDefs.Add('Case_insensitive',ftBoolean,0,false);
     FieldDefs.Add('Index_fields',ftWideString,1000,true);
     FieldDefs.Add('Desc_fields',ftWideString,1000,false);
     FieldDefs.Add('Case_ins_fields',ftWideString,1000,false);
     FieldDefs.Add('Primary',ftBoolean,0,false);
     FieldDefs.Add('Unique',ftBoolean,0,false);
     IndexDefs.Clear;
//     IndexDefs.Add('name index','Index_name',[ixUnique,ixCaseInsensitive]);
     CreateTable;
     Active := true;
     First;
   end; //table indexes
end;


procedure TMainForm.CreateForeignKeysTable(skipNameCheck: Boolean = false);
var i:  Integer;
    sl: TACRWideStringList;
begin
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
   sl := TACRWideStringList.Create;
   try
     CurrentDB.GetTablesList(sl);
     for i := 0 to sl.Count-1 do
      begin
       TableNames.Insert;
       TableNames.FieldByName('Name').AsWideString := sl.Strings[i];
       TableNames.Post;
      end;
   finally
     sl.Free;
   end;

   ForeignKeysTable.Close;
   ForeignKeysTable.ReadOnly := false;
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
   ForeignKeysTable.CreateTable;
   ForeignKeysTable.Open;
   ForeignKeysTable.First;
end;// table foreign keys

// init for new table
procedure TMainForm.InitCreateTable;
begin
 acr_action := 'create';
// fields
 try
  CreateFieldsTable;
  CreateIndexesTable;
  CreateForeignKeysTable;
 except
  ShowMessage('Error creating internal tables');
  Application.Terminate;
 end;
end; //init for create table


procedure TMainForm.FillFieldsTable(SourceTable: TACRDataset);
var i,j : integer;
    s : string;
begin
 if ((SourceTable = CurrentTable) or (SourceTable = CurrentQuery)) then
  begin
   eRecordSize.Text := IntToStr(TACRDataset(SourceTable).GetDiskRecordSize);
   eOptimalPageSize.Text := IntToStr(TACRDataset(SourceTable).GetOptimalPageSize);
  end;
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
    ForeignKeysTable.FieldByName('Name').AsWideString := SourceTable.ForeignKeyDefs.Items[i].Name;
    ForeignKeysTable.FieldByName('IntReferencedTableName').AsWideString := SourceTable.ForeignKeyDefs.Items[i].ReferencedTableName;
    ForeignKeysTable.FieldByName('Fields').AsWideString := SourceTable.ForeignKeyDefs.Items[i].Columns;
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
end;

// init for restructure table
procedure TMainForm.InitRestructTable(SourceTable: TACRTable);
begin
// fields
 SourceTable.Active := true;
 FillFieldsTable(SourceTable);
end; //init for create table

procedure TMainForm.InitAll;
var
 s : string;
begin
 s := ExtractFilePath(Application.ExeName);
 CurrentDB.DatabaseFileName := s;
 FieldsTable.Active := false;
 IndexesTable.Active := false;
 ForeignKeysTable.Active := false;
 CurrentTable.Active := false;
end;


procedure TMainForm.FieldsTableNewRecord(DataSet: TDataSet);
begin
  FieldsTable.FieldByName('Name').AsString := 'Field_'+IntToStr(FieldsTable.RecordCount+1);
  FieldsTable.FieldByName('Type').AsString := 'Char';
  FieldsTable.FieldByName('Size').AsInteger := 25;
  FieldsTable.FieldByName('Required').Asboolean := false;
  FieldsTable.FieldByName('CompressionAlgorithm').AsInteger := 0;
  FieldsTable.FieldByName('CompressionMode').AsInteger := 0;
  FieldsTable.FieldByName('BLOBBlockSize').AsInteger := DefaultBLOBBlockSize;
  FieldsTable.FieldByName('AICycled').AsBoolean := false;
  FieldsTable.FieldByName('AIMinValue').AsInteger := 0;
  FieldsTable.FieldByName('AIMaxValue').AsInteger := High(Integer);
  FieldsTable.FieldByName('AIInitValue').AsInteger := 0;
  FieldsTable.FieldByName('AIIncValue').AsInteger := 1;
  AdvOptions.ActivePage := 'Empty';
  ConvertFieldsTableToFieldParams;
end;



//------------------------------------------------------------------------------
// creates table
//------------------------------------------------------------------------------
procedure TMainForm.CreateTable;
var i,j:                          Integer;
    f,f1:                         Boolean;
    name,fields,case_ins,desc:    String;
    opt:              TIndexOptions;
    AdvType:          TACRAdvancedFieldType;
    AdvField:         TACRAdvFieldDef;
    FKName,FKColumns,FKReferencedTableName: String;
    MatchType: TACRForeignKeyMatchType;
    DeleteAction,UpdateAction : TACRForeignKeyAction;
begin
 CurrentTable.Active := false;
 CurrentTable.AdvFieldDefs.Clear;
 CurrentTable.FieldDefs.Clear;
 CurrentTable.ForeignKeyDefs.Clear;
 CurrentTable.IndexDefs.Clear;
 CurrentTable.AdvIndexDefs.Clear;
 // loading field descriptions
 FieldsTable.FilterOptions := [foCaseInsensitive,foNoPartialCompare];
 FieldsTable.First;
 while not FieldsTable.Eof do
  begin
   name := FieldsTable.FieldByName('Name').AsString;
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

   AdvType := aftUnknown;
   for i := Low(ACRFieldTypes) to High(ACRFieldTypes) do
    if (UpperCase(ACRFieldTypes[i].Name) = UpperCase(FieldsTable.FieldByName('Type').AsString)) then
     AdvType := ACRFieldTypes[i].AdvancedFieldType;

   AdvField := CurrentTable.AdvFieldDefs.AddFieldDef;
   AdvField.Name := name;
   AdvField.DataType := AdvType;
   AdvField.Size := FieldsTable.FieldByName('Size').AsInteger;
   AdvField.Required := FieldsTable.FieldByName('Required').AsBoolean;
   AdvField.BLOBCompressionAlgorithm :=
    TCompressionAlgorithm(FieldsTable.FieldByName('CompressionAlgorithm').AsInteger);
   AdvField.BLOBCompressionMode :=
    FieldsTable.FieldByName('CompressionMode').AsInteger;
   AdvField.BLOBBlockSize :=
    FieldsTable.FieldByName('BLOBBlockSize').AsInteger;
   AdvField.AutoincCycled :=
    FieldsTable.FieldByName('AICycled').AsBoolean;
   if (not FieldsTable.FieldByName('AIMinValue').IsNull) then
    begin
     AdvField.AutoincMinValue :=
      FieldsTable.FieldByName('AIMinValue').AsInteger;
    end;
   if (not FieldsTable.FieldByName('AIMaxValue').IsNull) then
    begin
     AdvField.AutoincMaxValue :=
      FieldsTable.FieldByName('AIMaxValue').AsInteger;
    end;
   if (not FieldsTable.FieldByName('AIInitValue').IsNull) then
    begin
     AdvField.AutoincInitialValue :=
      FieldsTable.FieldByName('AIInitValue').AsInteger;
    end;
   if (not FieldsTable.FieldByName('AIIncValue').IsNull) then
    begin
     AdvField.AutoincIncrement :=
      FieldsTable.FieldByName('AIIncValue').AsInteger;
    end;
   if (not FieldsTable.FieldByName('DefaultValue').IsNull) then
    begin
     AdvField.DefaultValue.AsString :=
      FieldsTable.FieldByName('DefaultValue').AsString;
     AdvField.DefaultValue.Cast(AdvancedFieldTypeToBaseFieldType(AdvField.DataType));
    end;
   if (not FieldsTable.FieldByName('MinimumValue').IsNull) then
    begin
     AdvField.MinValue.AsString :=
      FieldsTable.FieldByName('MinimumValue').AsString;
     AdvField.MinValue.Cast(AdvancedFieldTypeToBaseFieldType(AdvField.DataType));
    end;
   if (not FieldsTable.FieldByName('MaximumValue').IsNull) then
    begin
     AdvField.MaxValue.AsString :=
      FieldsTable.FieldByName('MaximumValue').AsString;
     AdvField.MaxValue.Cast(AdvancedFieldTypeToBaseFieldType(AdvField.DataType));
    end;
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
    CurrentTable.IndexDefs.Add(name,fields,opt);
    j := CurrentTable.IndexDefs.Count-1;
    CurrentTable.IndexDefs.Items[j].DescFields := desc;
    CurrentTable.IndexDefs.Items[j].CaseInsFields := case_ins;
    CurrentTable.IndexDefs.Items[j].Options := opt;
   IndexesTable.Next;
  end;


 ForeignKeysTable.First;
 while not ForeignKeysTable.Eof do
  begin
   FKName := ForeignKeysTable.FieldByName('Name').AsString;
   FKColumns := ForeignKeysTable.FieldByName('Fields').AsString;
   FKReferencedTableName := ForeignKeysTable.FieldByName('IntReferencedTableName').AsString;
   MatchType := TACRForeignKeyMatchType(ForeignKeysTable.FieldByName('IntMatchType').AsInteger);
   DeleteAction := TACRForeignKeyAction(ForeignKeysTable.FieldByName('IntDeleteAction').AsInteger);
   UpdateAction := TACRForeignKeyAction(ForeignKeysTable.FieldByName('IntUpdateAction').AsInteger);
   CurrentTable.ForeignKeyDefs.Add(FKName,FKColumns,FKReferencedTableName,MatchType,DeleteAction,UpdateAction);
   ForeignKeysTable.Next;
  end;
 try
  CurrentTable.Exclusive := True;
  CurrentTable.CreateTable;
  CurrentTable.Active := true;

 except
  on E: Exception do
   begin
    MessageDlg(E.Message, mtError, [mbOk], 0);
    Exit;
   end;
 end;
 CurrentTable.Active := false;
 acCloseTable.Execute;
end;


//------------------------------------------------------------------------------
// restruct table
//------------------------------------------------------------------------------
function TMainForm.RestructTable: Boolean;
var i,j  : integer;
    f,f1 : Boolean;
    log: AnsiString;
    name,fields,case_ins,desc : string;
    opt : TIndexOptions;
    AdvType: TACRAdvancedFieldType;
    AdvField: TACRAdvFieldDef;
    Res,b: Boolean;
    FKName,FKColumns: String;
    FKReferencedTableName : WideString;
    MatchType: TACRForeignKeyMatchType;
    DeleteAction,UpdateAction : TACRForeignKeyAction;
begin
 Res := true;
 Result := True;
 CurrentTable.Active := false;
 CurrentTable.Exclusive := True;
 CurrentTable.FieldDefs.Clear;
 CurrentTable.IndexDefs.Clear;
 CurrentTable.AdvFieldDefs.Clear;
 CurrentTable.AdvIndexDefs.Clear;
 CurrentTable.ForeignKeyDefs.Clear;
 CurrentTable.RestructureFieldDefs.Clear;
 CurrentTable.RestructureIndexDefs.Clear;
 CurrentTable.RestructureForeignKeyDefs.Clear;
 // loading field descriptions
 FieldsTable.FilterOptions := [foCaseInsensitive,foNoPartialCompare];
 FieldsTable.First;
 while not FieldsTable.Eof do
  begin
   name := FieldsTable.FieldByName('Name').AsString;
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
   AdvType := aftUnknown;
   for i := Low(ACRFieldTypes) to High(ACRFieldTypes) do
    if (UpperCase(ACRFieldTypes[i].Name) = UpperCase(FieldsTable.FieldByName('Type').AsString)) then
     AdvType := ACRFieldTypes[i].AdvancedFieldType;

   AdvField := CurrentTable.RestructureFieldDefs.AddFieldDef;
   AdvField.Name := name;
   AdvField.DataType := AdvType;
   AdvField.Size := FieldsTable.FieldByName('Size').AsInteger;
   AdvField.Required := FieldsTable.FieldByName('Required').AsBoolean;
   AdvField.BLOBCompressionAlgorithm :=
    TCompressionAlgorithm(FieldsTable.FieldByName('CompressionAlgorithm').AsInteger);
   AdvField.BLOBCompressionMode :=
    FieldsTable.FieldByName('CompressionMode').AsInteger;
   AdvField.BLOBBlockSize :=
    FieldsTable.FieldByName('BLOBBlockSize').AsInteger;
   AdvField.AutoincCycled :=
    FieldsTable.FieldByName('AICycled').AsBoolean;
   if (not FieldsTable.FieldByName('AIMinValue').IsNull) then
    begin
     AdvField.AutoincMinValue :=
      FieldsTable.FieldByName('AIMinValue').AsInteger;
    end;
   if (not FieldsTable.FieldByName('AIMaxValue').IsNull) then
    begin
     AdvField.AutoincMaxValue :=
      FieldsTable.FieldByName('AIMaxValue').AsInteger;
    end;
   if (not FieldsTable.FieldByName('AIInitValue').IsNull) then
    begin
     AdvField.AutoincInitialValue :=
      FieldsTable.FieldByName('AIInitValue').AsInteger;
    end;
   if (not FieldsTable.FieldByName('AIIncValue').IsNull) then
    begin
     AdvField.AutoincIncrement :=
      FieldsTable.FieldByName('AIIncValue').AsInteger;
    end;
   if (not FieldsTable.FieldByName('DefaultValue').IsNull) then
    begin
     AdvField.DefaultValue.AsString :=
      FieldsTable.FieldByName('DefaultValue').AsString;
     AdvField.DefaultValue.Cast(AdvancedFieldTypeToBaseFieldType(AdvField.DataType));
    end;
   if (not FieldsTable.FieldByName('MinimumValue').IsNull) then
    begin
     AdvField.MinValue.AsString :=
      FieldsTable.FieldByName('MinimumValue').AsString;
     AdvField.MinValue.Cast(AdvancedFieldTypeToBaseFieldType(AdvField.DataType));
    end;
   if (not FieldsTable.FieldByName('MaximumValue').IsNull) then
    begin
     AdvField.MaxValue.AsString :=
      FieldsTable.FieldByName('MaximumValue').AsString;
     AdvField.MaxValue.Cast(AdvancedFieldTypeToBaseFieldType(AdvField.DataType));
    end;

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

 ForeignKeysTable.First;
 while not ForeignKeysTable.Eof do
  begin
   FKName := ForeignKeysTable.FieldByName('Name').AsString;
   FKColumns := ForeignKeysTable.FieldByName('Fields').AsString;
   FKReferencedTableName := ForeignKeysTable.FieldByName('IntReferencedTableName').AsString;
   MatchType := TACRForeignKeyMatchType(ForeignKeysTable.FieldByName('IntMatchType').AsInteger);
   DeleteAction := TACRForeignKeyAction(ForeignKeysTable.FieldByName('IntDeleteAction').AsInteger);
   UpdateAction := TACRForeignKeyAction(ForeignKeysTable.FieldByName('IntUpdateAction').AsInteger);
   CurrentTable.RestructureForeignKeyDefs.Add(FKName,FKColumns,FKReferencedTableName,MatchType,DeleteAction,UpdateAction);
   ForeignKeysTable.Next;
  end;

 // restructure
 try
   CurrentTable.DisableControls;
   FormTableProgressCancel.Caption := 'Restructuring table';
   FormTableProgressCancel.bCancel := False;
   FormTableProgressCancel.Show;
   b := CurrentTable.Exclusive;
   CurrentTable.Exclusive := True;
   try
    Res := CurrentTable.RestructureTable(log);
   finally
    CurrentTable.Exclusive := b;
    FormTableProgressCancel.Hide;
    if (FormTableProgressCancel.bCancel) then
     MessageDlg('Restructure process was aborted.',mtInformation,[mbOK],0)
    else
     begin
      if (Res) then
       MessageDlg('Restructure process was completed successfully.',mtInformation,[mbOK],0)
      else
       MessageDlg('Restructure process failed due to error:'+#13#10+log+'.',mtError,[mbOK],0);
     end;
   end;

  CurrentTable.Active := true;
  CurrentTable.EnableControls;
 except
  on E: Exception do
   begin
    CurrentTable.EnableControls;
    FormTableProgressCancel.Hide;
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
begin
 CurrentTable.Close;
 CurrentTable.Exclusive := False;
 CurrentTable.IndexName := '';
 CurrentTable.IndexFieldNames := '';
 CurrentTable.ReadOnly := False;
 CurrentTable.Open;
 {20060308_Modified by M.Faraone}
 RecQty.Caption := IntToStr(CurrentTable.RecNo);
 RecQtyAll.Caption := IntToStr(CurrentTable.RecordCount);
 Result := true;
end;


// replace invalid data to correct data
procedure TMainForm.FieldsTableBeforePost(DataSet: TDataSet);
begin
 if (Length(FieldsTable.FieldByName('Name').AsString) > 255) then
  raise Exception.Create('Field name must have no more than 255 chars.');

 if (FieldsTable.FieldByName('Size').asInteger = 25) then
  if (FieldsTable.FieldByName('Type').asString <> 'Char') and
     (FieldsTable.FieldByName('Type').asString <> 'WideChar') and
     (FieldsTable.FieldByName('Type').asString <> 'Varchar') and
     (FieldsTable.FieldByName('Type').asString <> 'WideVarchar') then
    FieldsTable.FieldByName('Size').asInteger := 0;


 if (FieldsTable.FieldByName('Name').asString = '') then
  FieldsTable.FieldByName('Name').asString := 'Field '+ IntToStr(Random(MaxInt) mod 100000);
 if (FieldsTable.FieldByName('Type').asString = '') then
   FieldsTable.FieldByName('Type').asString := 'Char';
 if (FieldsTable.FieldByName('Required').asString = '') then
   FieldsTable.FieldByName('Required').asBoolean := False;

 if (AdvOptions.ActivePage = 'BLOBs') then
  begin
   FieldsTable.FieldByName('CompressionAlgorithm').AsInteger :=
    rgCompressionAlgorithm.ItemIndex;
   if (rgCompressionAlgorithm.ItemIndex = 0) then
    FieldsTable.FieldByName('CompressionMode').AsInteger := 0
   else
    FieldsTable.FieldByName('CompressionMode').AsInteger := cbCompressionMode.ItemIndex + 1;
  end;

 if (seBLOBBlockSize.Enabled) then
  begin
   FieldsTable.FieldByName('BLOBBlockSize').AsInteger :=
    seBLOBBlockSize.Value;
  end;

 if (AdvOptions.ActivePage = 'AutoInc')
  then
   FieldsTable.FieldByName('AICycled').AsBoolean := cbAICycled.Checked;
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


function TMainForm.DoOpenDatabase(DB: TACRDatabase): Boolean;
var ErrMsg,s:       string;
    LocalDatabase:  Boolean;
    RemotePort:     Integer;
    LocalPort:      Integer;
begin
 Result := False;
 // open
 fmOpenDatabase.OpenDialog.Options := [ofHideReadOnly,ofFileMustExist,ofPathMustExist];
 fmOpenDatabase.edDatabaseFile.Text := CurrentDB.DatabaseFileName;
 while (True) do
  begin
   if (fmOpenDatabase.ShowModal = mrCancel) then
    Exit;

   s := fmOpenDatabase.edDatabaseFile.Text;
   LocalDatabase := (fmOpenDatabase.rgLocalDatabase.ItemIndex = 0);
   if (LocalDatabase) and (DB = CurrentDB) then
    begin
     SetDatabaseFile(s, False); // mroy
     RemotePort := 0;
     LocalPort := 0;
    end
   else
    begin
     RemotePort := StrToInt(fmOpenDatabase.edRemotePort.Text);
     LocalPort := StrToInt(fmOpenDatabase.edLocalPort.Text);
    end;
   if (not OpenDatabase(DB,ErrMsg,s,LocalDatabase,
                        fmOpenDatabase.edDBName.Text,
                        fmOpenDatabase.cbProtocol.Items[fmOpenDatabase.cbProtocol.ItemIndex],
                        fmOpenDatabase.edRemoteHost.Text,
                        RemotePort, LocalPort)) then
   begin
    if (MessageDlg('Error opening database: '+#13#10+ErrMsg+#13#10+'Do you want to open another database?',mtError,[mbYes,mbNo],0) = mrYes) then
     Continue
    else
     begin
      Result := True;
      break;
     end;
   end
  else
   begin
    Result := True;
    break;
   end;
  end;
end; // DoOpenDatabase


procedure TMainForm.FileOpenExecute(Sender: TObject);
begin
  DoOpenDatabase(CurrentDB);
end;

procedure TMainForm.IndexGridCellClick(Column: TColumn);
var
    fields,case_ins,desc : string;
begin
 if (Column.index <> 5) then Exit;
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

 if not (IndexesTable.State in [dsInsert, dsEdit]) then
   IndexesTable.Edit;
 if (IndexesTable.FieldByName('Index_name').IsNull) then
  IndexesTable.FieldByName('Index_name').AsString := 'Index_'+IntToStr(Random(MaxInt) mod 10000);
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
{
 if (FieldsTable.RecordCount > 0) then
  IndexesTable.FieldByName('Index_fields').AsString :=
   FieldsTable.FieldByName('Name').AsString;
}   
end;

procedure TMainForm.IndexGridColEnter(Sender: TObject);
begin
 IndexGridCellClick(IndexGrid.Columns[IndexGrid.SelectedIndex]);
end;



procedure TMainForm.IndexGridDblClick(Sender: TObject);
begin
 IndexGridCellClick(IndexGrid.Columns[IndexGrid.SelectedIndex]);
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

//original
//procedure TMainForm.CurrentTableAfterScroll(DataSet: TDataSet);
//begin
// RecQty.Caption := 'Record '+inttostr(DataSet.RecNo)+
//                    ' of '+inttostr(DataSet.RecordCount);
//
//end;

{20060308_Revision by M.Faraone * Start}
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
{20060308_Revision by M.Faraone * End}

procedure TMainForm.acRestructureTableExecute(Sender: TObject);
begin
 CurrentTable.Active := false;
 CurrentTable.TableName := lbTableList.Items.Strings[lbTableList.ItemIndex];
 if OpenTable then
  begin
   acr_action := 'restruct';
   InitRestructTable(CurrentTable);
   prevPageNo := Notebook.PageIndex;
   SetNewPage(1);
  end;
end;


procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
var
 RectSmall, RectNormal: TRect;
begin
 SaveSettings;
 IniFile.Free;
 RectSmall := Rect(0, 0, 0, 0);
 RectNormal := MainForm.BoundsRect;
 DrawAnimatedRects(GetDesktopWindow, IDANI_CAPTION, RectNormal, RectSmall);
end;

procedure TMainForm.FileNewExecute(Sender: TObject);
var
    k : integer;
    s,s1,tableExt : string;
begin
 CurrentTable.Active := false;
 CurrentDB.Connected := false;
 s := ExtractFilePath(CurrentDB.DatabaseFileName)+'Database';
 tableExt := ACRDatabaseFileExtension;
 k := 1;
 repeat
  s1 := inttostr(k);
  inc(k);
 until not FileExists(s+s1+tableExt);
 // save dialog
// SaveDialog.Title := 'Select new database file name';
 FormNewDatabase.Caption := 'Create new database';
 FormNewDatabase.edDBFileName.Text := s+s1+tableExt;
 if (FormNewDatabase.ShowModal = mrCancel) then
  Exit;
 ConvertDataParamsToDataSettings;
 FormNewDatabase.Encrypted.Checked := false;
 FormNewDatabase.EncryptedClick(MainForm);
 CurrentDB.CreateDatabase;
 CurrentDB.Connected := true;
 CurrentTable.DatabaseName := CurrentDB.DatabaseName;
 SetNewPage(3);
end;

procedure TMainForm.acAlterStoredFunctionExecute(Sender: TObject);
var fn,s:   WideString;
    i,n:    Integer;
begin
  n := -1;
  for i := 0 to lbStoredFunctions.Count - 1 do
   if (lbStoredFunctions.Selected[i]) then
    begin
      n := i;
      break;
    end;
  if (n < 0) then
   begin
    MessageDlg('The stored function is not selected - click on the function name in the stroed functions list.',mtInformation,[mbOK],0);
   end
  else
   begin
    fn := lbStoredFunctions.Items[n];
    s := mSQL.Text;
    if (MessageDlg('Alter stored function '+fn+'. Are you sure?',mtConfirmation,[mbYes,mbNo],0) <> mrYes) then
     Exit;
    try
      CurrentDB.AlterStoredFunction(fn,s);
      UpdateTableList;
    except on E: Exception do
      MessageDlg('Error altering stored function '+fn+': '+#13#10+e.Message,mtError,[mbOK],0);
    end;
   end;
end;

procedure TMainForm.acCloseTableExecute(Sender: TObject);
begin
 CurrentDB.Connected := false;
 CurrentDB.Connected := true;
 SetNewPage(3);
end;

procedure TMainForm.lbStoredFunctionsClick(Sender: TObject);
var i,n: Integer;
begin
  n := 0;
  for i := 0 to lbStoredFunctions.Count - 1 do
   if (lbStoredFunctions.Selected[i]) then
    Inc(n);
 lbSelectedFunctions.Caption := 'Selected Functions: '+IntToStr(n)+' of '+
  IntToStr(lbStoredFunctions.Items.Count);
end;

procedure TMainForm.lbStoredFunctionsDblClick(Sender: TObject);
var fn,s: WideString;
    i,n:  Integer;
begin
  n := 0;
  for I := 0 to lbStoredFunctions.Count - 1 do
   if (lbStoredFunctions.Selected[i]) then
    begin
      Inc(n);
      fn := lbStoredFunctions.Items[i];
      s := CurrentDB.FindStoredFunction(fn);
      if (s = '') then
       begin
        MessageDlg('Function does not exist: '+#13#10+fn,mtError,[mbOK],0);
        UpdateTableList;
       end
      else
       begin
        Notebook.ActivePage := 'EditTableData';
        mSQL.Text := s;
        pcDataSQL.ActivePage := tsSQL;
       end;
    end;
 lbSelectedFunctions.Caption := 'Selected Functions: '+IntToStr(n)+' of '+
  IntToStr(lbStoredFunctions.Items.Count);
end;

procedure TMainForm.lbTableListClick(Sender: TObject);
begin
 ShowTableListHint;
 if (lbTableList.SelCount = 0) then
  begin
   acOpenTable.Enabled := false;
	 acRestructureTable.Enabled := false;
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
   acRepairTable.Enabled := true;
	 acEmptyTable.Enabled := true;
	 acRenameTable.Enabled := true;
	 acCopyTable.Enabled := true;
	 acDeleteTable.Enabled := true;
  end;
 lbSelectedTables.Caption := 'Selected tables: '+IntToStr(lbTableList.SelCount)+' of '+
 IntToStr(lbTableList.Items.Count);
end;


procedure TMainForm.acCreateStoredFunctionExecute(Sender: TObject);
var s: WideString;
begin
 try
  s := mSQL.Text;
  CurrentDB.CreateStoredFunction(s);
  UpdateTableList;
 except on E: Exception do
  MessageDlg('Error creating stored function: '+#13#10+e.Message,mtError,[mbOK],0);
 end;
end;

procedure TMainForm.acCreateTableExecute(Sender: TObject);
begin
 acr_action := 'create';
 InitCreateTable;
 SetNewPage(1);
end;

//original
//procedure TMainForm.acOpenTableExecute(Sender: TObject);
//begin
// CurrentTable.Active := false;
// CurrentTable.TableName := lbTableList.Items.Strings[lbTableList.ItemIndex];
// if OpenTable then
//  begin
//   CurrentTable.Active := true;
//   CurrentDataSource.DataSet := CurrentTable;
//   SetNewPage(2);
//   pcDataSQL.ActivePageIndex := 0;
//   mSQL.Text := 'SELECT * FROM '+CurrentTable.TableName+';';
//  end;
//end;

procedure TMainForm.acOpenTableExecute(Sender: TObject);
begin
  CurrentTable.Active := false;
  CurrentQuery.Active := false;
  CurrentTable.TableName := lbTableList.Items.Strings[lbTableList.ItemIndex];
  if OpenTable then
   begin
    CurrentTable.Active := true;
    seRecNo.MinValue := 1;
    seRecNo.MaxValue := MaxInt;
    seRecNo.Value := 1;
    CurrentDataSource.DataSet := CurrentTable;
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
    pcDataSQL.ActivePageIndex := 0;
  end;
end;

procedure TMainForm.acRenameTableExecute(Sender: TObject);
label M1;
var s,s1:		  string;
    i:  integer;
begin
 CurrentTable.Active := false;
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
var s,s1 :	string;
    i,j,n:  		integer;
    newTable:   TACRTable;
    newDB: TACRDatabase;
begin
 OpenDialog.InitialDir := ExtractFilePath(currentDB.DatabaseFileName);
 OpenDialog.FileName := CurrentDB.DatabaseFileName;
 OpenDialog.Options := [ofHideReadOnly,ofFileMustExist,ofPathMustExist,ofNoReadOnlyReturn];
 OpenDialog.Title := 'Select destination database file';
 if (not OpenDialog.Execute)
      then Exit;
 newDB := TACRDatabase.Create(nil);
 newDB.DatabaseName := 'CopyDB_12345';
 newDB.DatabaseFileName := OpenDialog.FileName;
 newTable := TACRTable.Create(self);
 newTable.DatabaseName := newDB.DatabaseName;
 FormTableProgressCancel.Caption := 'Copy selected tables';
 FormTableProgressCancel.bCancel := False;
 FormTableProgressCancel.Show;
 NewTable.OnProgress := CurrentTable.OnProgress;
// if (not FileExists(newDB)) then
//  goto 2;
 if newDB.IsDatabaseEncrypted then
  begin
   if FormSecurity = nil then
    FormSecurity := TFormSecurity.Create(Application);
   FormSecurity.Caption := 'Database "'+newDB.DatabaseFileName+'" authentification';
   adbFileName := newDB.DatabaseFileName;
   Security.Data := newDB;
   if newDB.IsDatabaseEncryptedByPassword then
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
    begin
     FormTableProgressCancel.Hide;
     newTable.Free;
     newDB.Free;
     Exit;
    end
  end;
 if (newDB.IsCryptoParamsValid) or (not newDB.IsDatabaseEncrypted) then
  begin
   CurrentTable.DisableControls;
   try
   // copy tables
    n := lbTableList.SelCount;
    newTable.OnProgress := CurrentTable.OnProgress;
    j := 0;
    for i := 0 to lbTableList.Items.Count-1 do
     begin
      if (not lbTableList.Selected[i]) then
       continue;
      s := lbTableList.Items[i];
      CurrentTable.Close;
      CurrentTable.TableName := s;
      CurrentTable.TableName := s;
      newTable.Close;
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
         NewTable.TableName := s1;
         CurrentTable.Open;
         NewTable.ImportTable(CurrentTable);
         CurrentTable.Close;
       end;
      inc(j);
      Application.ProcessMessages;
     end;
   finally
    FormTableProgressCancel.Hide;
    CurrentTable.EnableControls;
    newTable.Free;
    newDB.Free;
   end;
  end;
 Application.ProcessMessages;
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
 n := lbTableList.SelCount;
 j := 0;
 for i := 0 to lbTableList.Items.Count-1 do
  begin
   if (not lbTableList.Selected[i]) then
    continue;
   s := lbTableList.Items[i];
   CurrentTable.TableName := s;
   if (CurrentTable.Exists) then
    begin
     // delete table
       CurrentTable.Active := false;
       CurrentTable.DeleteTable(True);
     end;
   inc(j);
   Application.ProcessMessages;
  end;
 Application.ProcessMessages;
 CurrentDB.Connected := false;
 CurrentDB.Connected := true;
 SetNewPage(3);
end;

procedure TMainForm.acDropFunctionExecute(Sender: TObject);
var fn:   WideString;
    i,n:  Integer;
begin
  n := -1;
  for i := 0 to lbStoredFunctions.Count - 1 do
   if (lbStoredFunctions.Selected[i]) then
    begin
      n := i;
      break;
    end;
  if (n < 0) then
   begin
    MessageDlg('The stored function is not selected - click on the function name in the stroed functions list.',mtInformation,[mbOK],0);
   end
  else
   begin
    fn := lbStoredFunctions.Items[n];
    if (MessageDlg('Delete stored function '+fn+'. Are you sure?',mtConfirmation,[mbYes,mbNo],0) <> mrYes) then
     Exit;
    try
      CurrentDB.DropStoredFunction(fn);
      UpdateTableList;
    except on E: Exception do
      MessageDlg('Error dropping stored function '+fn+': '+#13#10+e.Message,mtError,[mbOK],0);
    end;
   end;
end;

procedure TMainForm.btnCancelClick(Sender: TObject);
begin
 acCloseTable.Execute;
end;

procedure TMainForm.btnOkClick(Sender: TObject);
label M1;
var s: string;
begin
 if (FieldsTable.recordCount <= 0) then
  begin
   MessageDlg('You should specify some field descriptions!',mtWarning,[mbOk],0);
   Exit;
  end;
   CurrentTable.Active := false;
   if (acr_action = 'create') then
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
 n := lbTableList.SelCount;
 j := 0;
 for i := 0 to lbTableList.Items.Count-1 do
  begin
   if (not lbTableList.Selected[i]) then
    continue;
   s := lbTableList.Items[i];
   CurrentTable.TableName := s;
   if (CurrentTable.Exists) then
    begin
     // delete table
       CurrentTable.Active := false;
       CurrentTable.EmptyTable;
     end;
   inc(j);
   Application.ProcessMessages;
  end;
 Application.ProcessMessages;
 CurrentDB.Connected := false;
 CurrentDB.Connected := true;
 SetNewPage(3);
end;

procedure TMainForm.bnBorrowClick(Sender: TObject);
var i,j: 		      integer;
    s:				    string;
    opt:   		    TIndexOptions;
    BorrowDB:     TACRDatabase;
    BorrowTable:  TACRTable;
begin
 BorrowDB := TACRDatabase.Create(nil);
 try
   BorrowDB.DatabaseName := 'BorrowDB';
   BorrowDB.DatabaseFileName := CurrentDB.DatabaseFileName;
   BorrowDB.LocalDatabase := CurrentDB.LocalDatabase;
   BorrowDB.ConnectionParams.Assign(CurrentDB.ConnectionParams);
   BorrowDB.CryptoParams.Assign(CurrentDB.CryptoParams);
   while (true) do
    begin
     if (DoOpenDatabase(BorrowDB)) then
      begin
       FormBorrow.lbBorrow.Items.Clear;
       BorrowDB.GetTablesList(FormBorrow.lbBorrow.Items);
       if (FormBorrow.ShowModal <> mrOk) then
        Exit;
       if (FormBorrow.lbBorrow.ItemIndex < 0) or
          (FormBorrow.lbBorrow.ItemIndex >= FormBorrow.lbBorrow.Count) then
         Exit;
       BorrowTable := TACRTable.Create(nil);
       try
         BorrowTable.DatabaseName := BorrowDB.DatabaseName;
         BorrowTable.TableName := FormBorrow.lbBorrow.Items[FormBorrow.lbBorrow.ItemIndex];
         if (not BorrowTable.Exists) then
          begin
           if (MessageDlg('There is no table "'+  BorrowTable.TableName+
            '" in this database. Do you want to choose another database?',mtWarning,[mbYes,mbNo],0) = mrYes) then
            continue
           else
            break;
          end;
         BorrowTable.Open;
         InitRestructTable(BorrowTable);
       finally
         BorrowTable.Free;
       end;
       break;
      end
     else
      break;
    end;
 finally
   BorrowDB.Free;
 end;
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
 RecQty.Caption := IntToStr(CurrentTable.RecNo);
 RecQtyAll.Caption := IntToStr(CurrentTable.RecordCount);
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
    list: TACRWideStringList;
    res: Boolean;
begin
 res := true;
 if (CurrentTable.IndexName = '') then
  begin
   ShowMessage('You should select some index. You can either click on column header or use Select index command from Actions menu.');
   Exit;
  end;

 list := TACRWideStringList.Create;
 ind := CurrentTable.IndexDefs.IndexOf(CurrentTable.IndexName);

 ACRMain.GetNamesList(list,CurrentTable.IndexDefs.Items[ind].Fields);
 flds := list.Count;
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
    list: TACRWideStringList;
begin
 if (CurrentTable.IndexName = '') then
  begin
   ShowMessage('You should select some index. You can either click on column header or use Select index command from Actions menu.');
   Exit;
  end;
 list := TACRWideStringList.Create;
 ind := CurrentTable.IndexDefs.IndexOf(CurrentTable.IndexName);
 GetNamesList(list,CurrentTable.IndexDefs.Items[ind].Fields);
 flds := list.Count;
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
var i,n,j,flds: 				integer;
    res: 								Boolean;
    lopt:								TLocateOptions;
    s,sFields,sValues: 	string;
    v:									Variant;
    fieldnums:          array of integer;
    fieldCount:         Integer;
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
   SetLength(fieldNums,flds);
   fieldCount := 0;
   for i := 0 to flds-1 do
    if (FormLocate.sgKeys.Cells[1,i+1] <> '') then
     begin
      fieldNums[fieldCount] := i;
      inc(fieldCount);
     end;
   if (fieldCount <= 0) then
    begin
     fieldNums := nil;
     ShowMessage('You have not specified any search condition');
     Exit;
    end;

   // case insensitive
   if (FormLocate.cbIns.Checked) then
    lopt := lopt + [loCaseInsensitive];
   // partial key
   if (FormLocate.cbPart.Checked) then
    lopt := lopt + [loPartialKey];
   // building locate expression
   sFields := '';
   sValues := '';
   n := 0;
   if (fieldCount = 1) then
    begin
     i := fieldNums[0];
     v := FormLocate.sgKeys.Cells[1,i+1];
     sFields := FormLocate.sgKeys.Cells[0,i+1];
    end
   else
    begin
     v := VarArrayCreate([0,fieldCount-1],varVariant);
     for j := 0 to fieldCount-1 do
      begin
       i := fieldNums[j];
       s := FormLocate.sgKeys.Cells[1,i+1];
       v[n] := s;
       if (sFields = '') then
        begin
         sFields := FormLocate.sgKeys.Cells[0,i+1];
        end
       else
        begin
         sFields := sFields + ';' + FormLocate.sgKeys.Cells[0,i+1];
        end;
       inc(n);
      end;
    end;
   res := CurrentTable.Locate(sFields,v,lopt);
  end;
 if (not res) then
  MessageDlg('Record not found',mtWarning,[mbOk],0);
end;



//------------------------------------------------------------------------------
// load settings from INI file
//------------------------------------------------------------------------------
procedure TMainForm.LoadSettings;
var
  {20060308_Fixed by M.Faraone * Begin}
  //Useless
  //s: string;
  {20060308_Fixed by M.Faraone * End}
  xMenu : TMenuItem;
begin
 WindowState := TWindowState(IniFile.ReadInteger('WindowSettings', 'State', Integer(wsNormal)));
 if (CurrentDB.Connected) then
  Exit;
 if (ParamCount >= 1) then Exit;
 LoadDatabaseFile;//mroy
 if ReopenDatabaseItem.Enabled then//mroy
  begin
   xMenu := ReopenDatabaseItem.Items[0];
   if Assigned(xMenu) then
    begin
     xMenu.Click;
    end;
  end;
 {20060308_Fixed by M.Faraone * Begin}
 //Useless
 //if (FileExists(s)) then
 // OpenDatabase(CurrentDB,s);
 {20060308_Fixed by M.Faraone * End}
 {20071108_Added by M.Faraone * Begin}
 //Recover disablesyntaxhilite_userchoice
 FSkipSyntaxHighLighting := not(IniFile.ReadBool('SQL Script Settings','Disable Syntax HighLiting', true));
 if FSkipSyntaxHighLighting=true then
 miSQLSyntax.Caption := 'Enable Syntax Highliting'
 else miSQLSyntax.Caption := 'Disable Syntax Highliting';
 miSQLSyntaxClick(miSQLSyntax);
 {20071108_Added by M.Faraone * End}
 odLoadSQL.InitialDir := IniFile.ReadString('SQL Script Settings','Initial Directory','');
 if (odLoadSQL.InitialDir = '') then
  odLoadSQL.InitialDir := ExtractFilePath(Application.ExeName);
 sdSaveSQL.InitialDir := odLoadSQL.InitialDir;
end;// LoadSettings


//------------------------------------------------------------------------------
// save settings to INI file
//------------------------------------------------------------------------------
procedure TMainForm.SaveSettings;
begin
 IniFile.WriteInteger('WindowSettings', 'State', Integer(WindowState));
 {20071108_Added by M.Faraone * Begin}
 IniFile.WriteBool('SQL Script Settings','Disable Syntax HighLiting',FSkipSyntaxHighLighting);
 {20071108_Added by M.Faraone * End}
 IniFile.WriteString('SQL Script Settings','Initial Directory',ExtractFilePath(odLoadSQL.FileName));
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
var s: string;
begin
 if (not CurrentDB.LocalDatabase) then
  MessageDlg('Cannot rename a remote database!',mtError,[mbOK],0)
 else
  if (SaveDialog.Execute) then
  begin
	 CurrentDB.Connected := false;
	 try
	  CurrentDB.RenameDatabase(SaveDialog.FileName);
    OpenDatabase(CurrentDB,s,SaveDialog.FileName);
    if (s <> '') then
  	  MessageDlg('Error opening database: '+#13#10+s,mtError,[mbOk],0);
	 except
	  MessageDlg('Error renaming database!',mtError,[mbOk],0);
	 end;
  end;
end;

procedure TMainForm.IndexesTableBeforePost(DataSet: TDataSet);
begin
 if (Length(IndexesTable.FieldByName('index_name').AsString) > 255) then
  raise Exception.Create('Index name must have no more than 255 chars.');
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
     NewMenuItem.OnClick := File1Click;
    end;
  finally
   sFile.Free;
  end;
end;


procedure TMainForm.ChangeFieldsTableRecords(bm1,bm2: TBookmark);
var id,id1: Integer;
begin
 FieldsTable.GotoBookmark(bm2);
 id := FieldsTable.FieldByName('id').AsInteger;
 FieldsTable.GotoBookmark(bm1);
 id1 := FieldsTable.FieldByName('id').AsInteger;
 FieldsTable.Edit;
 FieldsTable.FieldByName('id').AsInteger := id;
 FieldsTable.Post;
 FieldsTable.GotoBookmark(bm2);
 FieldsTable.Edit;
 FieldsTable.FieldByName('id').AsInteger := id1;
 FieldsTable.Post;
end;


procedure TMainForm.SpinButton1UpClick(Sender: TObject);
var
    bm:      TBookmark;
    bm1:     TBookmark;
begin
 if (FieldsTable.RecNo > 1) then
  begin
    FieldsTable.DisableControls;
    bm := FieldsTable.GetBookmark;
    FieldsTable.Prior;
    bm1 := FieldsTable.GetBookmark;
    try
      ChangeFieldsTableRecords(bm1,bm);
    finally
      FieldsTable.FreeBookmark(bm);
      FieldsTable.FreeBookmark(bm1);
      FieldsTable.EnableControls;
    end;
  end;
end;

procedure TMainForm.SpinButton1DownClick(Sender: TObject);
var
    bm:           TBookmark;
    bm1:          TBookmark;
begin
 if (FieldsTable.RecNo < FieldsTable.RecordCount) then
  begin
    FieldsTable.DisableControls;
    bm := FieldsTable.GetBookmark;
    FieldsTable.Next;
    bm1 := FieldsTable.GetBookmark;
    try
      ChangeFieldsTableRecords(bm1,bm);
    finally
      FieldsTable.FreeBookmark(bm);
      FieldsTable.FreeBookmark(bm1);
      FieldsTable.EnableControls;
    end;
  end;
end;

procedure TMainForm.FormShow(Sender: TObject);
var
 RectSmall, RectNormal: TRect;
begin
 RectSmall := Rect(0, 0, 0, 0);
 RectNormal := MainForm.BoundsRect;
 DrawAnimatedRects(GetDesktopWindow, IDANI_CAPTION, RectSmall, RectNormal);
end;

procedure TMainForm.FileRepairExecute(Sender: TObject);
 var s:		  AnsiString;
      res: Boolean;
begin
 if (not CurrentDB.LocalDatabase) then
  begin
   MessageDlg('RepairDatabase is not supported with remote database!',mtError,[mbOK],0);
   Exit;
  end;

 res := true;
 CurrentTable.Active := false;
 CurrentDB.Connected := false;
 CurrentDB.Exclusive := true;
 FormProgressCancel.Show;
 FormProgressCancel.Caption := 'Repair database file "'+
 		ExtractFileName(CurrentDB.DatabaseFileName)+'"';
 FormProgressCancel.lbCaption.Caption := 'Repair database ...';
 FormProgressCancel.Indicator.Progress := 0;
 FormProgressCancel.bCancel := False;
 try
  res := CurrentDB.RepairDatabase(s,True);
 finally
  FormProgressCancel.Indicator.Progress := 100;
  Application.ProcessMessages;
  FormProgressCancel.Hide;
  if (FormProgressCancel.bCancel) then
   MessageDlg('RepairDatabase operation aborted.',mtInformation,[mbOk],0)
  else
   begin
    if (not res) then
     MessageDlg('Errors occurred while repairing database. Database file cannot be repaired. Error log:'+
                #13#10+s,
                mtError,[mbOk],0)
    else
     begin
      if (s = '') then
       MessageDlg('Database file was sucessfully repaired without any errors',
                mtInformation,[mbOk],0)
      else
       MessageDlg('Database file was repaired with errors. Error log:'+
                #13#10+s,
                mtWarning,[mbOk],0);

     end;
   end;
 end;
 CurrentDB.Exclusive := false;
 CurrentDB.Connected := true;
 SetNewPage(3);
end;

procedure TMainForm.FileCompactExecute(Sender: TObject);
begin
 if (not CurrentDB.LocalDatabase) then
  begin
   MessageDlg('RepairDatabase is not supported with remote database!',mtError,[mbOK],0);
   Exit;
  end;
 CurrentTable.Active := false;
 CurrentDB.Connected := false;
 CurrentDB.Exclusive := true;
 FormProgressCancel.Show;
 FormProgressCancel.Caption := 'Compact database file "'+
 		ExtractFileName(CurrentDB.DatabaseFileName)+'"';
 FormProgressCancel.lbCaption.Caption := 'Compacting database ...';
 FormProgressCancel.bCancel := False;
 try
  CurrentDB.CompactDatabase;
  FormProgressCancel.Indicator.Progress := 100;
  Application.ProcessMessages;
 except
  if (not FormProgressCancel.bCancel) then
   MessageDlg('Errors occurred while compacting database. Original file restored, use RepairDatabase to fix errors.',
              mtError,[mbOk],0)
  else
   MessageDlg('Compact operation aborted.',mtInformation,[mbOk],0)
 end;
 FormProgressCancel.Hide;
 CurrentDB.Exclusive := false;
 CurrentDB.Connected := true;
 SetNewPage(3);
end;

procedure TMainForm.CurrentDBProgress(Sender: TComponent; Progress: Double;
  Operation: TACRDatabaseOperation; var Abort: Boolean);
begin
 FormProgressCancel.Indicator.Progress := round(Progress);
 Application.ProcessMessages;
 Abort := FormProgressCancel.bCancel;
end;

procedure TMainForm.CurrentDBTableProgress(Sender: TComponent;
  Progress: Double; Operation: TACRTableOperation; var Abort: Boolean);
begin
 FormProgressCancel.TableIndicator.Progress := Round(Progress);
 FormProgressCancel.lbTableName.Caption := TACRTable(Sender).TableName;
 Application.ProcessMessages;
 Abort := FormProgressCancel.bCancel;
end;

procedure TMainForm.CurrentTableProgress(Sender: TComponent;
  Progress: Double; Operation: TACRTableOperation; var Abort: Boolean);
var s: string;
begin
 FormTableProgressCancel.TableIndicator.Progress := Round(Progress);
 case Operation of
  tbopRestructure: s := 'Restructuring table '
 else
  s := 'Copying table ';
 end;
 FormTableProgressCancel.lbTableName.Caption := s + TACRTable(Sender).TableName;
 Application.ProcessMessages;
 Abort := FormTableProgressCancel.bCancel;
end;

procedure TMainForm.rgCompressionAlgorithmClick(Sender: TObject);
begin
 if  (not (FieldsTable.State in [dsInsert,dsEdit])) then
  FieldsTable.Edit;
 if (rgCompressionAlgorithm.ItemIndex = 0) then
  begin
   cbCompressionMode.Enabled := False;
  end
 else
  begin
   cbCompressionMode.Enabled := True;
   cbCompressionMode.ItemIndex := 0;
  end;
end;

procedure TMainForm.FieldsGridColExit(Sender: TObject);
begin
 SetEnabledForFieldParams;
end;

procedure TMainForm.FieldsTableAfterPost(DataSet: TDataSet);
begin
 SetEnabledForFieldParams;
 SetStructureCaption(Dataset);
end;

procedure TMainForm.FieldsTableAfterDelete(DataSet: TDataSet);
begin
 SetEnabledForFieldParams;
end;

procedure TMainForm.FieldsTableAfterScroll(DataSet: TDataSet);
begin
 SetEnabledForFieldParams;
 if (pcDataSQL.ActivePageIndex <> tsViewIndexes.PageIndex) and
    (pcDataSQL.ActivePageIndex <> tsViewForeignKeys.PageIndex) and
    (CreateTableControl.ActivePageIndex <> IndexesTab.PageIndex) and
    (CreateTableControl.ActivePageIndex <> tsForeignKeys.PageIndex) then
     SetStructureCaption(Dataset);
end;

procedure TMainForm.seBLOBBlockSizeChange(Sender: TObject);
begin
 if  (not (FieldsTable.State in [dsInsert,dsEdit])) then
  FieldsTable.Edit;
end;

procedure TMainForm.cbAICycledClick(Sender: TObject);
begin
 if  (not (FieldsTable.State in [dsInsert,dsEdit])) then
  FieldsTable.Edit;
end;

procedure TMainForm.cbIgnoreCaseClick(Sender: TObject);
begin
 CurrentDB.CaseInsensitive := cbIgnoreCase.Checked;
end;

procedure TMainForm.FormActivate(Sender: TObject);
begin
 LoadSettings;
end;

procedure TMainForm.FileChangeSettingsExecute(Sender: TObject);
var
 Options : TACROptionsEditor;
 CryptoParams : TACRCryptoParamsEditor;
begin
 CurrentTable.Active := false;
 CurrentDB.Connected := false;
 CurrentDB.Exclusive := true;
 FormNewDatabase.edDBFileName.Text := CurrentDB.DatabaseFileName;
 FormNewDatabase.edDBFileName.Enabled := false;
 FormNewDatabase.Button1.Visible := false;
 FormNewDatabase.Caption := 'Change settings of database "'+
 		ExtractFileName(CurrentDB.DatabaseFileName)+'"';
 if (FormNewDatabase.ShowModal = mrCancel) then
  Exit;
 if not IsChange then
  begin
   FormNewDatabase.edDBFileName.Enabled := true;
   FormNewDatabase.Button1.Visible := true;
   CurrentDB.Exclusive := false;
  // CurrentDB.CryptoParams.Assign(CryptoParams);
   CurrentDB.Connected := true;
   SetNewPage(3);
   Exit;
  end;
 Options := TACROptionsEditor.Create;
 CryptoParams := TACRCryptoParamsEditor.Create;
 ConvertDataParamsToDataSettings(Options,CryptoParams);
 FormProgressCancel.Show;
 FormProgressCancel.Caption := 'Change settings of database "'+
 		ExtractFileName(CurrentDB.DatabaseFileName)+'"';
 FormProgressCancel.lbCaption.Caption := 'Changing settings ...';
 FormProgressCancel.bCancel := False;
 try
  if not (CurrentDB.ChangeDatabaseSettings(Options,CryptoParams))
   then
    begin
     MessageDlg('Errors occurred while changing database settings. Original file restored, use RepairDatabase to fix errors.',
              mtError,[mbOk],0);
     FormProgressCancel.Hide;
     Exit;
    end;
  FormProgressCancel.Indicator.Progress := 100;
  Application.ProcessMessages;
 except
  if (not FormProgressCancel.bCancel) then
   MessageDlg('Errors occurred while changing database settings. Original file restored, use RepairDatabase to fix errors.',
              mtError,[mbOk],0)
  else
   MessageDlg('Change database settings operation aborted.',mtInformation,[mbOk],0)
 end;

 FormNewDatabase.edDBFileName.Enabled := true;
 FormNewDatabase.Button1.Visible := true;
 CurrentDB.Exclusive := false;
 CurrentDB.CryptoParams.Assign(CryptoParams);
 CurrentDB.Connected := true;
 FormProgressCancel.Hide;
 Options.Destroy;
 CryptoParams.Destroy;
 SetNewPage(3);
end;

procedure TMainForm.FileInfoExecute(Sender: TObject);
begin
 DatabaseInfo.ShowModal;
end;

procedure TMainForm.acRepairTableExecute(Sender: TObject);
var s,s1:		  AnsiString;
    i:  integer;
    Res: Boolean;
begin
 if (not CurrentDB.LocalDatabase) then
  begin
   MessageDlg('RepairTable is not supported with remote database!',mtError,[mbOK],0);
   Exit;
  end;

 for i := 0 to lbTableList.Items.Count-1 do
  begin
   if (not lbTableList.Selected[i]) then
    continue;
   s := lbTableList.Items[i];
   CurrentTable.TableName := s;
   if (CurrentTable.Exists) then
    begin
     s1 := '';
     CurrentTable.DisableControls;
     FormTableProgressCancel.Caption := 'Repairing table';
     FormTableProgressCancel.bCancel := False;
     FormTableProgressCancel.Show;
     CurrentTable.Active := false;
     try
       Res := CurrentTable.RepairTable(s1,True);
       FormTableProgressCancel.Hide;
       if (FormTableProgressCancel.bCancel) then
         MessageDlg('Repair process was aborted.',mtInformation,[mbOK],0)
       else
        begin
         if (not Res) then
           MessageDlg('Table '+AnsiQuotedStr(s,'"') +
              ' cannot be repaired. Error log: '+s1,mtError,
              [mbOk],0)
         else
          if (s1 <> '') then
           MessageDlg('Table '+AnsiQuotedStr(s,'"') +
              ' was repaired with data losses. Error log: '+s1,mtWarning,
              [mbOk],0);
        end;
     finally

     end;
    end;
  end;
 CurrentDB.Connected := false;
 CurrentDB.Connected := true;
 SetNewPage(3);
end;

procedure TMainForm.File1Click(Sender: TObject);
var
  s,sDatabaseFile: String;
begin
 sDatabaseFile := (Sender as TMenuItem).Caption;
 sDatabaseFile := StringReplace(sDatabaseFile, '&', '',[rfreplaceAll]);
 sDatabaseFile := Copy(sDatabaseFile, 3, Length(sDatabaseFile));
 SetDatabaseFile(sDatabaseFile, True);
  if FileExists(sDatabaseFile) then
  begin
    OpenDatabase(CurrentDB,s,sDatabaseFile,True);
    SetDatabaseFile(sDatabaseFile, True);
  end;
end;

procedure TMainForm.FileMakeExeDatabaseExecute(Sender: TObject);
var dbConnected: Boolean;
    res:         Integer;
begin
 if (not CurrentDB.LocalDatabase) then
  begin
   MessageDlg('CopyDatabase is not supported with remote database!',mtError,[mbOK],0);
   Exit;
  end;
 if (not CurrentDB.Exists) then
  begin
   MessageDlg('Database file does not exists!',mtError,[mbOK],0);
   Exit;
  end;
 res := fmMakeExeDatabase.ShowModal;
 if (not fmMakeExeDatabase.bCancel) then
  begin
   CurrentTable.Active := false;
   dbConnected := CurrentDB.Connected;
   CurrentDB.Connected := false;
   CurrentDB.Exclusive := true;
   try
     try
      CurrentDB.MakeExeDatabase(fmMakeExeDatabase.edDBfile.Text,fmMakeExeDatabase.edExeDBFile.Text);
      MessageDlg('Executable database '+fmMakeExeDatabase.edExeDBFile.Text+' successfully created',mtInformation,[mbOK],0);
     except
      on e: Exception do
        MessageDlg('Error creating executable database '+fmMakeExeDatabase.edExeDBFile.Text+' : '+e.Message,mtError,[mbOK],0);
     end;
   finally
     CurrentDB.Exclusive := false;
     CurrentDB.Connected := dbConnected;
     SetNewPage(3);
   end;
  end;
end;

procedure TMainForm.FileCopyExecute(Sender: TObject);
var Log: String;
begin
 if (not CurrentDB.LocalDatabase) then
  begin
   MessageDlg('CopyDatabase is not supported with remote database!',mtError,[mbOK],0);
   Exit;
  end;
 if (SaveDialog.Execute) then
  begin
   CurrentTable.Active := false;
   CurrentDB.Connected := false;
   CurrentDB.Exclusive := true;
   FormProgressCancel.Show;
   FormProgressCancel.Caption := 'Copy database file "'+
      ExtractFileName(CurrentDB.DatabaseFileName)+'"';
   FormProgressCancel.lbCaption.Caption := 'Copying database ...';
   FormProgressCancel.bCancel := False;
   try
    if (not CurrentDB.CopyDatabase(Log,SaveDialog.FileName)) then
     begin
      MessageDlg('Errors occurred while copying database. Error log: '+Log,
                mtError,[mbOk],0);
       FormProgressCancel.Hide;
       CurrentDB.Exclusive := false;
       CurrentDB.Connected := true;
       SetNewPage(3);
      Exit;
     end;
    FormProgressCancel.Indicator.Progress := 100;
    Application.ProcessMessages;
   except
    if (not FormProgressCancel.bCancel) then
     MessageDlg('Errors occurred while copying database.',
                mtError,[mbOk],0)
    else
     MessageDlg('Copy operation aborted.',mtInformation,[mbOk],0)
   end;
   FormProgressCancel.Hide;
   CurrentDB.Exclusive := false;
   CurrentDB.Connected := true;
   SetNewPage(3);
  end;
end; // CopyDatabase

//original code
//procedure TMainForm.bnExecuteSQLClick(Sender: TObject);
//var a: Boolean;
//begin
// a := CurrentTable.Active;
// CurrentTable.Close;
// try
//   CurrentQuery.SQL.Text := mSQL.Text;
//   try
//     CurrentQuery.ExecSQL;
//     lbTableList.Items.Clear;
//     CurrentTable.GetTableNames(lbTableList.Items);
//     lbSelectedTables.Caption := 'Selected tables: '+IntToStr(lbTableList.SelCount)+' of '+
//      IntToStr(lbTableList.Items.Count);
//     RecQty.Caption := 'Rows affected = '+IntToStr(CurrentQuery.RowsAffected)
//   except
//    on e: Exception do
//     begin
//       RecQty.Caption := 'Error';
//       MessageDlg('Error executing SQL script: '+e.Message,mtError,[mbOK],0);
//     end;
//   end;
// finally
//  CurrentTable.Active := a;
// end;
//end;

{20060308_Revision by M.Faraone * Start}
{20060308_Revision by M.Faraone * End}

//original code
//procedure TMainForm.bnOpenQueryClick(Sender: TObject);
//var a: Boolean;
//begin
// a := CurrentTable.Active;
// CurrentTable.Close;
// try
//   CurrentQuery.SQL.Text := mSQL.Text;
//   CurrentDataSource.DataSet := nil;
//   try
//     CurrentQuery.Open;
//     CurrentDataSource.DataSet := CurrentQuery;
//     pcDataSQL.ActivePageIndex := 0;
//     CurrentQuery.First;
//     lbTableList.Items.Clear;
//     CurrentTable.GetTableNames(lbTableList.Items);
//     lbSelectedTables.Caption := 'Selected tables: '+IntToStr(lbTableList.SelCount)+' of '+
//      IntToStr(lbTableList.Items.Count);
//   except
//    on e: Exception do
//     begin
//       RecQty.Caption := 'Error';
//       MessageDlg('Error opening query: '+e.Message,mtError,[mbOK],0);
//     end;
//   end;
// finally
//  CurrentTable.Active := a;
//  CurrentTableAfterScroll(CurrentQuery);
// end;
//end;

{20060308_Revision by M.Faraone * Start}
procedure TMainForm.bnOpenQueryClick(Sender: TObject);
var
  a:    Boolean;
  t:    Cardinal;
  d,d1: Double;
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
      CurrentDataSource.DataSet := nil;
      t := GetTickCount;
      CurrentQuery.SQL.Text := mSQL.Text;
      CurrentQuery.RequestLive := cbLiveQuery.Checked;
      CurrentQuery.Open;
      t := GetTickCount - t;
      d := t / 1000.0;
      d1 := CurrentQuery.RecordCount;
      bnOpenQuery.Hint := 'Query execution time, seconds: '+
       FormatFloat('#,##0.000',d)+'. Record count: '+FormatFloat('#,##0',d1);
      pcDataSQL.ActivePageIndex := 0;
      seRecNo.MinValue := 1;
      seRecNo.MaxValue := MaxInt;
      seRecNo.Value := 1;
    except
      on e: EACRException do begin
       t := GetTickCount - t;
       d := t / 1000.0;
       d1 := 0;
       QueryRunning := false;
       if (E.NativeError <> 20001) then
       begin
         CurrentQuery.Active := false;
         MessageDlg('Error opening query: ' + e.Message, mtError, [mbOK], 0);
       end
       else
       begin
          d1 := CurrentQuery.RowsAffected;
          bnOpenQuery.Hint := 'Query execution time, seconds: '+
           FormatFloat('#,##0.000',d)+'. Record count: '+FormatFloat('#,##0',d1);
          CurrentDataSource.DataSet := nil;
       end;
       RecQty.Caption := '';
       RecQtyAll.Caption := '';
      end;
    end;
  finally
    UpdateTableList;
    try
     CurrentTable.Active := a;
    except on E: Exception do
    end;
    try
     if (CurrentQuery.Active) then
     begin
      CurrentDataSource.DataSet := CurrentQuery;
      RecQty.Caption := IntToStr(CurrentQuery.RecNo);
      RecQtyAll.Caption := IntToStr(CurrentQuery.RecordCount);
      FillFieldsTable(CurrentQuery);
      ReopenStructureTables(True);
      pcDataSQL.ActivePageIndex := 0;
      FieldsTableAfterScroll(FieldsTable);
      CurrentQuery.First;
      CurrentTableAfterScroll(CurrentQuery);
     end;
    except on E: Exception do
    end;
    UpdateSQLHistory;
    QueryRunning := false;
    Screen.Cursor := crDefault;
    if (CurrentQuery.Active = False) then mSQL.SetFocus;
    lHindex.Caption := IntToStr(oSQLHistory.Count) + '/' +
      IntToStr(oSQLHistory.Count);
  end;
end;
{20060308_Revision by M.Faraone * End}

procedure TMainForm.OpenQuery1Click(Sender: TObject);
begin
 bnOpenQueryClick(Sender);
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

procedure TMainForm.acExportTableToSQLExecute(Sender: TObject);
var s:      String;
    i:      Integer;
    table:  TACRTable;
    {20071108_Added by M.Faraone * End}
    b:      boolean;
    {20071108_Added by M.Faraone * Start}
begin
 {20071108_Added by M.Faraone * Start}
 //Table could be not selected by user
 if not(lbTableList.SelCount>0) then begin
  MessageDlg('Select a table, please!', mtWarning, [mbOK], 0);
  exit;
 end;
 {20071108_Added by M.Faraone * End}
 fmExportToSQL.Caption := 'Export tables to SQL Script';
 if (fmExportToSQL.ShowModal = mrOk) then
  begin
   s := '';
   table := TACRTable.Create(self);
   try
    {20071108_Revision by M.Faraone * Start}
    b:= FSkipSyntaxHighlighting;
    FSkipSyntaxHighlighting := True;
    Screen.Cursor := crHourGlass;
    mSQL.OnChange := nil;
    {20071108_Revision by M.Faraone * End}
    table.DatabaseName := CurrentDB.DatabaseName;
    for i := 0 to lbTableList.Items.Count - 1 do
     if (lbTableList.Selected[i]) then
      begin
       if (i > 0) then
        s := s + crlf;
       table.TableName := lbTableList.Items[i];
       s := s + table.ExportTableToSQL(fmExportToSQL.cbExportStructure.Checked,
                                       fmExportToSQL.cbAddDROPTable.Checked,
                                       fmExportToSQL.cbExportIndexes.Checked,
                                       fmExportToSQL.cbAddDROPIndex.Checked,
                                       fmExportToSQL.cbExportData.Checked,
                                       fmExportToSQL.cbExportBLOBFields.Checked,
                                       fmExportToSQL.cbUseBrackets.Checked,
                                       fmExportToSQL.cbExportForeignKeys.Checked
                                       );

      end;
   finally
    table.Free;
   end;
   Notebook.PageIndex := 2;
   {20071108_Revision by M.Faraone * Start}
   pcDataSQL.ActivePageIndex := tsSQL.PageIndex;
   mSQL.Text := s;
   DisableSQLParsingTextAttributes;
   FSkipSyntaxHighlighting := b;
   mSQL.OnChange := mSQLChange;
   pcDaTaSQL.OnChange(pcDataSQL);
   Screen.Cursor := crDefault;
   {20071108_Revision by M.Faraone * End}
  end;
end;

procedure TMainForm.FileExportDatabaseToSQLExecute(Sender: TObject);
var s:      String;
    i:      Integer;
    {20071108_Added by M.Faraone * End}
    b:      boolean;
    {20071108_Added by M.Faraone * Start}
begin
 b := FSkipSyntaxHighlighting;
 fmExportToSQL.Caption := 'Export database to SQL Script';
 if (fmExportToSQL.ShowModal = mrOk) then
  begin
   {20071108_Revision by M.Faraone * Start}
  try
    FSkipSyntaxHighlighting := True;
    Screen.Cursor := crHourGlass;
    mSQL.OnChange := nil;
    s := CurrentDB.ExportDatabaseToSQL(fmExportToSQL.cbExportStructure.Checked,
                                       fmExportToSQL.cbAddDROPTable.Checked,
                                       fmExportToSQL.cbExportIndexes.Checked,
                                       fmExportToSQL.cbAddDROPIndex.Checked,
                                       fmExportToSQL.cbExportData.Checked,
                                       fmExportToSQL.cbExportBLOBFields.Checked,
                                       fmExportToSQL.cbUseBrackets.Checked,
                                       fmExportToSQL.cbExportForeignKeys.Checked,
                                       fmExportToSQL.cbStoredFunctions.Checked
                                       );

  finally
   Notebook.PageIndex := 2;
   pcDataSQL.ActivePageIndex := tsSQL.PageIndex;
   mSQL.Text := s;
   DisableSQLParsingTextAttributes;
   FSkipSyntaxHighlighting := b;
   mSQL.OnChange := mSQLChange;
   pcDaTaSQL.OnChange(pcDataSQL);
   Screen.Cursor := crDefault;
  end;
   {20071108_Revision by M.Faraone * End}
  end;
end;

procedure TMainForm.ClearClick(Sender: TObject);
var capt: String;
begin
 capt := 'definitions (fields, indexes and foreign keys)';
 if (CreateTableControl.ActivePageIndex = IndexesTab.PageIndex) then
  capt := 'indexes';
 if (CreateTableControl.ActivePageIndex = tsForeignKeys.PageIndex) then
  capt := 'foreign keys';

 if (MessageDlg('Delete all '+capt+'. Are you sure?',mtConfirmation,
      [mbYes,mbNo],0) = mrYes) then
  begin
   if (capt = 'indexes') then
    begin
     IndexesTable.DeleteVisibleRecords;
     IndexesTable.Refresh;
     SetStructureCaption(IndexesTable);
    end
   else
   if (capt = 'foreign keys') then
    begin
     ForeignKeysTable.DeleteVisibleRecords;
     ForeignKeysTable.Refresh;
     SetStructureCaption(ForeignKeysTable);
    end
   else
    begin
     FieldsTable.DeleteVisibleRecords;
     IndexesTable.DeleteVisibleRecords;
     ForeignKeysTable.DeleteVisibleRecords;
     FieldsTable.Refresh;
     SetStructureCaption(FieldsTable);
    end;
  end;
end;

procedure TMainForm.CurrentDBAfterServerShutdown(Sender: TObject);
begin
 if (not (csDestroying in Self.ComponentState)) then
   NetworkDownError;
end;

procedure TMainForm.NetworkDownError;
begin
   repeat
   until (MainForm.Canvas.TryLock);
   try
     SetNewPage(0);
  	 lbSelectedTables.Caption := 'Selected tables: '+IntToStr(0)+' of '+
        IntToStr(0);
   finally
     MainForm.Canvas.Unlock;
   end;
{
   MessageDlg('Remote database has been closed. '+#13#10+
      'Either server was shut down or network connection lost. '+#13#10+
      'Try to reopen database later.',mtWarning,[mbOK],0);
}
end;

procedure TMainForm.bnFKClearClick(Sender: TObject);
begin
 if (MessageDlg('Delete all foreign keys. Are you sure?',mtConfirmation,
      [mbYes,mbNo],0) = mrYes) then
  begin
   ForeignKeysTable.DeleteVisibleRecords;
   ForeignKeysTable.Refresh;
  end;
end;

procedure TMainForm.ForeignKeysTableAfterInsert(DataSet: TDataSet);
begin
  Dataset.FieldByName('Name').AsString := 'FK_'+Format('%6.6d',[Dataset.RecordCount+1]);
  Dataset.FieldByName('IntMatchType').AsInteger := 0;
  Dataset.FieldByName('IntDeleteAction').AsInteger := 0;
  Dataset.FieldByName('IntUpdateAction').AsInteger := 0;
end;

//--------------------------------------------------------
// 20060308_Added by M.Faraone * Start
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
    8: bnOpenQueryClick(Sender); //RunSQLClick(Sender);
    9: NavigSQLClick(PriorSQL);
    10: NavigSQLClick(NextSQL);
    11: bnOpenQueryClick(Sender);
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
      mSQL.SetFocus;
    {20081108_Added by M.Faraone * Start}
    pcDataSQL.OnChange(pcDataSQL);
    {20081108_Added by M.Faraone * End}
   end;
end;

procedure TMainForm.DocStructure(Table: TACRTable);
var
  i: integer;
  DFD: TFieldDefs; //Fields Def
  DID: TIndexDefs; //Indexs Def
  DFK: TACRForeignKeyDefs; //Def for FK
  canproceed: boolean;
  geterr: integer;

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

  procedure DocFKey(FK: TACRForeignKeyDef);

    function DetectMType: string;
    begin
      case FK.MatchType of
        fkmtDefault: Result := 'Default';
        fkmtFull: Result := 'Full';
        fkmtPartial: Result := 'Partial';
      end;
    end;

    function detectAType(cAction: string): string;
    var
      FKA: TACRForeignKeyAction;
    begin
      if (cAction = 'D') then FKA := FK.DeleteAction
      else FKA := FK.UpdateAction;
      case FKA of
        fkaDefault: Result := 'Default';
        fkaCascade: Result := 'Cascade';
        fkaSetNull: Result := 'SetNull';
        fkaSetDefault: Result := 'SetDefault';
        fkaNoAction: Result := 'NoAction';
      end;
    end;

  begin
    mSQL.Lines.Add('');
    mSQL.Lines.Add(LeftStr('FKName', 16) + FK.Name);
    mSQL.Lines.Add(LeftStr('TableRef', 16) + FK.ReferencedTableName);
    mSQL.Lines.Add(LeftStr('Columns', 16) + FK.Columns);
    mSQL.Lines.Add(LeftStr('MatchType', 16) + DetectMType);
    mSQL.Lines.Add(LeftStr('DeleteAction', 16) + detectAType('D'));
    mSQL.Lines.Add(LeftStr('UpdateAction', 16) + detectAType('U'));
  end;

begin
  try
    mSQL.Lines.Add('');
    mSQL.Lines.Add('[ ' + Uppercase(Table.TableName) + ' ]');
    mSQL.Lines.Add('');
    DFD := Table.FieldDefs;
    DID := Table.IndexDefs;
    DFK := Table.ForeignKeyDefs;
    mSQL.Lines.Add(LeftStr('Fields', 10) + IntToStr(DFD.Count));
    mSQL.Lines.Add(LeftStr('Indexes', 10) + IntToStr(DID.Count));
    mSQL.Lines.Add(LeftStr('ForeKeys', 10) + IntToStr(DFK.Count));
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
    for i := 0 to Pred(DFK.Count) do begin
      DocFKey(DFK.Items[i]);
    end;
    mSQL.Lines.Add('');
    mSQL.Lines.Add('');
  except
    //
  end;
end;

//20071108_Revision by MF
//Fixed to handle mSQL OnChange Event implemented on V4.30
procedure TMainForm.FilePrintStructureExecute(Sender: TObject);
var
  b: boolean;
  i: integer;
begin
 b := FSkipSyntaxHighlighting;
 try
  FSkipSyntaxHighlighting := True;
  mSQL.OnChange := nil;
  Screen.Cursor := crHourGlass;
  mSQL.Lines.BeginUpdate;
  mSQL.Lines.Clear;
  mSQL.Lines.Add('Data structures documented on ' +
    FormatDateTime('dd/mm/yyyy - hh:nn:ss', Now));
  mSQL.Lines.Add('Database File ' +
    ExtractFileName(CurrentDB.DatabaseFileName));
  for i := 0 to Pred(lbTableList.Items.Count) do begin
    CurrentTable.Active := false;
    CurrentTable.TableName := lbTableList.Items.Strings[i];
    if OpenTable then begin
      {Cosmetics...}
      StatusBar.SimpleText := 'Documenting structure - Table: ' +
      CurrentTable.TableName;
      CurrentTable.Active := true;
      CurrentDataSource.DataSet := CurrentTable;
      DocStructure(CurrentTable);
    end;
    CurrentTable.Active := False;
  end;
 finally
  mSQL.Lines.EndUpdate;
  Notebook.PageIndex := 2;
  pcDataSQL.ActivePageIndex := tsSQL.PageIndex;
  DisableSQLParsingTextAttributes;
  FSkipSyntaxHighlighting := b;
  mSQL.OnChange := mSQLChange;
  pcDaTaSQL.OnChange(pcDataSQL);
  mSQL.SetFocus;
  StatusBar.SimpleText := '';
  Screen.Cursor := crDefault;
 end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FTablesInfo := nil;
  oSQLHistory.Free;
  oSQLHistory := nil;
end;

//--------------------------------------------------------
// 20060308_Added by M.Faraone * End
//--------------------------------------------------------

procedure TMainForm.IndexesTableAfterScroll(DataSet: TDataSet);
begin
 if (pcDataSQL.ActivePageIndex = tsViewIndexes.PageIndex) or
    (CreateTableControl.ActivePageIndex = IndexesTab.PageIndex) then
  SetStructureCaption(Dataset);
end;

procedure TMainForm.ForeignKeysTableAfterScroll(DataSet: TDataSet);
begin
 if (pcDataSQL.ActivePageIndex = tsViewForeignKeys.PageIndex) or
    (CreateTableControl.ActivePageIndex = tsForeignKeys.PageIndex) then
  SetStructureCaption(Dataset);
end;

procedure TMainForm.tsViewFieldsShow(Sender: TObject);
begin
  SetStructureCaption(FieldsTable);
  dbnView.DataSource := FieldsDataSource;
end;

procedure TMainForm.tsViewForeignKeysShow(Sender: TObject);
begin
  SetStructureCaption(ForeignKeysTable);
  dbnView.DataSource := FKDataSource;
end;

procedure TMainForm.tsViewIndexesShow(Sender: TObject);
begin
  SetStructureCaption(IndexesTable);
  dbnView.DataSource := IndexDataSource;
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
 if (Dataset = IndexesTable) then
  lbCreateQty.Hint := 'Indexes'
 else
  lbCreateQty.Hint := 'Foreign keys';
end;

procedure TMainForm.tsDataShow(Sender: TObject);
begin
 dbnView.DataSource := CurrentDataSource;
end;

procedure TMainForm.ReopenStructureTables(ReadOnly: Boolean; Save: Boolean);
var s: String;
fs: TFileStream;
begin
 FieldsTable.Close;
 IndexesTable.Close;
 ForeignKeysTable.Close;
 FieldsTable.ReadOnly := ReadOnly;
 IndexesTable.ReadOnly := ReadOnly;
 ForeignKeysTable.ReadOnly := ReadOnly;
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
 FieldsTable.Open;
 IndexesTable.Open;
 ForeignKeysTable.Open;
end;

procedure TMainForm.tsSQLShow(Sender: TObject);
begin
 dbnView.DataSource := nil;
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

procedure TMainForm.tsForeignKeysShow(Sender: TObject);
begin
  dbnCreateTable.DataSource := FKDataSource;
  SetStructureCaption(ForeignKeysTable);
end;

procedure TMainForm.IndexesTableAfterPost(DataSet: TDataSet);
begin
  SetStructureCaption(Dataset);
end;

procedure TMainForm.ForeignKeysTableAfterPost(DataSet: TDataSet);
begin
  SetStructureCaption(Dataset);
end;



procedure TMainForm.bnSQLClick(Sender: TObject);
var
  s: string;
begin
  s := '-- Date: '+DateTimeToStr(Now)+#13#10;
  if (CurrentQuery.Active) then
   s := s+TACRCursor(CurrentQuery.Handle).ExportTableToSQL(True,True,True,False,False,False,True)
  else
   s := s+'-- Table: '+CurrentTable.TableName+#13#10+CurrentTable.ExportTableToSQL(True,True,True,False,False,False,True);
  mSQL.Text := s;
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

{20071108_Revision by M.Faraone}
procedure TMainForm.ParseSQL;
var  s,s1: WideString;
     {Name changed pos->posit to avoid conflict with function pos}
     posit : Integer; //pos: Integer;
     lex: TACRLexer;
     t:   TToken;
     l,c,i,j: Integer;
     old: TPoint;
     bTable: Boolean;
     SQLParams: TACRSQLParams;
begin
 if (FSkipSyntaxHighlighting) then
  Exit;
 try
  if (pcDataSQL.ActivePageIndex <> tsSQL.PageIndex) then
    pcDataSQL.ActivePageIndex := tsSQL.PageIndex;
//  if (mSQL.CanFocus) then
//   mSQL.SetFocus;
  old := mSQL.CaretPos;
//  SQLParams := TACRSQLParams.Create;
  lex := TACRLexer.Create(mSQL.Lines.Text,nil);
  FSkipSyntaxHighlighting := True;
  try
  {20071108_Revision by M.Farone * Start}
  Screen.Cursor := crHourGlass;
  mSQL.Lines.beginUpdate;
  {20071108_Revision by M.Farone * End}
//    lex.CurrentCommand. := 0;
//    if (lex.NumCommands > 0) then
    while (lex.GetNextCommand) do
     begin
//     lex.SetCurrentTokenNo(0,t);
     if (lex.GetCurrentToken(t)) then
       repeat
        if (t.TokenType = tktString) or
           (t.TokenType = tktQuotedString) or
           (t.TokenType = tktBracketedString) or
           (t.TokenType = tktReservedWord) then
         begin
          l := t.LineNum-1;
          c := t.ColumnNum-1;
          {20071108_Revision by M.Faraone * Start}
          s1 := mSQL.Lines.Text;
          posit := Pred(pos(t.Text,s1)); //pos := 0;
          {20071108_Revision by M.Faraone * End}
          for i := 0 to l do
           if (i < l) then

           //----------------------------------------------
           //original code
           //----------------------------------------------
           // pos := pos  + Length(mSQL.Lines[i]) + 2
           //else
           // pos := pos + c;
           //----------------------------------------------

           //----------------------------------------------
           //1. User can write his sql text starting from
           //a column-line position different from 0,0;
           //2. User (Your Export Functions too) can format
           //his text on multiple lines...
           //Example:
           //   SELECT
           //        fieldname1,fieldname2,
           //   FROM
           //        tablename
           //   WHERE
           //        condition=conditionvalue etc.
           //----------------------------------------------

           posit := posit  + Length(mSQL.Lines[i]) + 2;

          if (t.TokenType = tktReservedWord) then
           PaintSQLWord(posit,Length(t.Text),False,True,clBlue)
          else
           begin
            bTable := False;
            for j := 0 to lbTableList.Count-1 do
             if (AnsiUpperCase(lbTableList.Items[j]) = AnsiUpperCase(t.Text)) then
              begin
               bTable := True;
               break;
              end;
             if (bTable) then
              PaintSQLWord(posit,Length(t.Text),False,False,clGreen)
             else
              if (t.TokenType <> tktString) then
               PaintSQLWord(posit,Length(t.Text),False,False,clMaroon);
           end;

         end;
      until (not lex.GetNextToken(t));
    end;
  finally
    {20071108_Revision by M.Farone * Start}
    mSQL.Lines.EndUpdate;
    {20071108_Revision by M.Farone * End}
    lex.Free;
    FSkipSyntaxHighlighting := False;
    mSQL.SelLength := 0;
    mSQL.SelStart := 0;
    mSQL.CaretPos := old;
    mSQL.SelAttributes.Color := clWindowText;
    mSQL.SelAttributes.Style := [];
    Screen.Cursor := crDefault;
  end;
 except
 end;
end;


procedure TMainForm.pLeftPanelCanResize(Sender: TObject; var NewWidth,
  NewHeight: Integer; var Resize: Boolean);
begin
 Resize := True;
 if (NewWidth < 130) then
  NewWidth := 130;
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

procedure TMainForm.mSQLChange(Sender: TObject);
begin
  ParseSQL;
end;

procedure TMainForm.mSQLSelectionChange(Sender: TObject);
begin
  mSQLShowLineColumn;
end;

procedure TMainForm.mSQLShowLineColumn;
var l,c: Integer;
begin
  l := mSQL.CaretPos.Y+1;
  c := mSQL.CaretPos.X+1;
  mSQL.Hint := 'LineNum: '+IntToStr(l)+ ' ColumnNum: '+IntToStr(c)+'. Click on right mouse button to open SQL History menu';
end;

procedure TMainForm.UpdateTableList;
var i,n1,n2:  Integer;
    selNames: TACRWideStringList;
begin
  n1 := 0;
  n2 := 0;
  selNames := TACRWideStringList.Create;
  try
    for i := 0 to lbTableList.Count-1 do
     if (lbTableList.Selected[i]) then
      begin
       selNames.Add(lbTableList.Items[i]);
       Inc(n1);
      end;
    FTablesInfo := nil;
    FTablesInfo := CurrentDB.GetTablesInfo(True);
    lbTableList.Clear;
    for i := 0 to Length(FTablesInfo)-1 do
     begin
       lbTableList.Items.Add(FTablesInfo[i].TableName);
       if (selNames.IndexOf(FTablesInfo[i].TableName) >= 0) then
        lbTableList.Selected[i] := True;
     end;
    // stored functions
    selNames.Clear;
    lbStoredFunctions.Clear;
    if (CurrentDB.IsStoredFunctionManagerExists) then
     begin
       tsStoredFunctions.Enabled := True;
       for i := 0 to lbStoredFunctions.Count-1 do
        if (lbStoredFunctions.Selected[i]) then
         begin
          selNames.Add(lbStoredFunctions.Items[i]);
          Inc(n2);
         end;
       lbStoredFunctions.Clear;
       CurrentDB.GetStoredFunctions(lbStoredFunctions.Items);
       for i := 0 to lbStoredFunctions.Count-1 do
         begin
           if (selNames.IndexOf(lbStoredFunctions.Items[i]) >= 0) then
            lbStoredFunctions.Selected[i] := True;
         end;
     end
    else
     begin
       lbStoredFunctions.Clear;
       tsStoredFunctions.Enabled := False;
     end;
  finally
    selNames.Free;
  end;
 lbSelectedTables.Caption := 'Selected Tables: '+IntToStr(n1)+' of '+
  IntToStr(lbTableList.Items.Count);
 lbSelectedFunctions.Caption := 'Selected Functions: '+IntToStr(n2)+' of '+
  IntToStr(lbStoredFunctions.Items.Count);
end;

procedure TMainForm.ShowTableListHint;
var i:                            Integer;
    op,modDate,crDate,status,s:   String;

begin
 lbTableList.Hint := 'No tables selected - you can select single table by left mouse button click or select multiple tables with CTRL + click';
 if (lbTableList.SelCount = 1) then
  begin
   for i := 0 to lbTableList.Count-1 do
    if (lbTableList.Selected[i]) then
     begin
      if (i < Length(FTablesInfo)) then
       begin
        if (ACRGetTableFlag(FTablesInfo[i].TableState,tffWriteFailed)) then
         status := 'WRITE FAILED - NEEDS REPAIR'
        else
         status := 'OK';
        crDate := DateTimeToStr(FTablesInfo[i].CreationDate);
        modDate := DateTimeToStr(FTablesInfo[i].TableState.LastModificationDate);
        op := ACRGetLastTableOpertaion(FTablesInfo[i].TableState.LastTableOperation);
        s :=
                     'Name:              '+FTablesInfo[i].TableName
             +#13#10+'Status:            '+status
             +#13#10+'Last operation:    '+op
             +#13#10+'Modification Date: '+modDate
             +#13#10+'Creation Date:     '+crDate
             +#13#10+'Comment:           '+FTablesInfo[i].Comment
             ;
        lbTableList.Hint := s;
       end;
      break;
     end;
  end
 else
 if (lbTableList.SelCount > 1) then
  lbTableList.Hint := IntToStr(lbTableList.SelCount) + ' table selected';
 lbStoredFunctions.Hint := IntToStr(lbStoredFunctions.SelCount) + ' table selected';
end;

{20071108_Added by M.Faraone * Start}
procedure TMainForm.pcDataSQLChange(Sender: TObject);
begin
 //Disable Change notifications to SQLPage when
 //we don't need them
 if pcDataSQL.ActivePageIndex=tsSQL.PageIndex then
 mSQL.OnChange := mSQLChange
 else  mSQL.OnChange := nil; //case
 //Disable SetRecNo Blocks when whe are outside Data TabSheet
 Label12.Enabled :=  pcDataSQL.ActivePageIndex = tsData.PageIndex;
 seRecNo.Enabled :=  pcDataSQL.ActivePageIndex = tsData.PageIndex;
 bnSetRecNo.Enabled := pcDataSQL.ActivePageIndex = tsData.PageIndex;
end;
{20071108_Added by M.Faraone * End}

procedure TMainForm.DisableSQLParsingTextAttributes;
begin
   mSQL.Lines.BeginUpdate;
   mSQL.SelectAll;
   mSQL.SelAttributes.Color := clWindowText;
   mSQL.SelAttributes.Style := [];
   mSQL.SelLength := 0;
   mSQL.Lines.EndUpdate;
end;

procedure TMainForm.lbTableListDrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
begin
  if (Index < Length(FTablesInfo)) then
   begin
    if (ACRGetTableFlag(FTablesInfo[Index].TableState,tffWriteFailed)) then
     begin
      lbTableList.Font.Color := clRed;
     end
    else
     begin
      lbTableList.Font.Color := clGreen;
     end;
   end;
end;

procedure TMainForm.Updatetableslist1Click(Sender: TObject);
begin
 UpdateTableList;
end;

end.

