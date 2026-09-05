unit MainUnit;

interface

{$I SFSManVer.Inc}

uses Windows, Classes, Graphics, Forms, Controls, Menus,
  IniFiles,
  Dialogs, StdCtrls, Buttons, ExtCtrls, ComCtrls, ImgList, StdActns,
  ActnList, ToolWin, AboutUnit, FileCtrl, SingleFileSystem, sysUtils,
  ShlObj, ProgressIndicator,
  ProgressCancel2,
  PassUnit, QuestUnit, CryptoUnit, CompLevel, System.ImageList, System.Actions
  ;

var bReadStarted: Boolean = false;
var bWriteStarted: Boolean = false;
var bReadStarted1: Boolean = false;
var bWriteStarted1: Boolean = false;

const BackupFileExt = '.sfs';
const imgFolder = 1;
const imgText = 6;
const imgBMP = 0;
const imgUnknown = 9;
  levelValue: array [0..9] of TSFSCompressionLevel =
              (sfsNone, zlibFastest, zlibNormal, zlibMax, bzipFastest,
               bzipNormal, bzipMax, ppmFastest, ppmNormal, ppmMax);
  levelText: array [0..9] of string =
              ('sfsNone', 'zlibFastest', 'zlibNormal', 'zlibMax', 'bzipFastest',
               'bzipNormal', 'bzipMax', 'ppmFastest', 'ppmNormal', 'ppmMax');
  levelDesc: array [0..9] of string =
              ('There is no compression.',
               'ZLIB algorithm, fastest compresssion',
               'ZLIB algorithm, normal compresssion',
               'ZLIB algorithm, max compresssion',
               'BZIP algorithm, fastest compresssion',
               'BZIP algorithm, normal compresssion',
               'BZIP algorithm, max compresssion',
               'PPM algorithm, fastest compresssion',
               'PPM algorithm, normal compresssion',
               'PPM algorithm, max compresssion');

type
  PFSItem = ^TFSItem;
  TFSItem = record
    DisplayName,
    FileName,
    TypeName: string;
    ImageIndex,
    Attributes: Integer;
    Size: Int64;
    ModDate: string;
    isFolder: Boolean;
  end;

   FileHeader = record
    size            : Int64;
    attr            : Integer;
    name            : string;
    path            : string;
    BackupPath      : string;
    IsFolder				:	Boolean;
   end;
 pFileHeader = ^FileHeader;

 type

  TMainForm = class(TForm)
    OpenDialog: TOpenDialog;
    ToolBar1: TToolBar;
    ToolButton9: TToolButton;
    ToolButton1: TToolButton;
    ToolButton3: TToolButton;
    ActionList: TActionList;
    FileNew1: TAction;
    FileOpen1: TAction;
    FileExit1: TAction;
    HelpAbout1: TAction;
    StatusBar: TStatusBar;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    FileNewItem: TMenuItem;
    FileOpenItem: TMenuItem;
    N1: TMenuItem;
    FileExitItem: TMenuItem;
    Help1: TMenuItem;
    HelpAboutItem: TMenuItem;
    MainNotebook: TNotebook;
    Panel1: TPanel;
    DirBox: TDirectoryListBox;
    DriveBox: TDriveComboBox;
    bnCancel: TBitBtn;
    bnOk: TBitBtn;
    Answer: TEdit;
    Label5: TLabel;
    ControlQuestion: TMemo;
    Label3: TLabel;
    Label2: TLabel;
    Encrypted: TCheckBox;
    Label1: TLabel;
    BackupFileName: TEdit;
    Password: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    ViewNotebook: TNotebook;
    RichEdit: TRichEdit;
    Splitter1: TSplitter;
    ImageList1: TImageList;
    ToolButton4: TToolButton;
    FileImport: TAction;
    FileRemove: TAction;
    ToolButton5: TToolButton;
    OpenDialog1: TOpenDialog;
    CreateFolder: TAction;
    RemoveFolder: TAction;
    FileExport: TAction;
    ToolButton2: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    ToolButton8: TToolButton;
    ToolBar2: TToolBar;
    btnBack: TToolButton;
    cbPath: TComboBox;
    ToolButton12: TToolButton;
    Image: TImage;
    ListView: TListView;
    ImportFolder: TAction;
    ToolButton10: TToolButton;
    ToolButton11: TToolButton;
    ExportFolder: TAction;
    Backup1: TMenuItem;
    N2: TMenuItem;
    Importfile1: TMenuItem;
    Removefilefrombackup1: TMenuItem;
    Exportfilefrombackup1: TMenuItem;
    Createfolder1: TMenuItem;
    RemoveFolder1: TMenuItem;
    Importfolder1: TMenuItem;
    Exportfolder1: TMenuItem;
    FileCompactRepair: TAction;
    FileClose: TAction;
    Close1: TMenuItem;
    Label6: TLabel;
    CompLevel: TComboBox;
    Info: TMemo;
    Label7: TLabel;
    ToolButton14: TToolButton;
    ToolButton15: TToolButton;
    Compactandrepairbackupfile1: TMenuItem;
    SaveDialog: TSaveDialog;
    FileChangeEncryption: TAction;
    FileChangeCompLevel: TAction;
    ToolButton13: TToolButton;
    ToolButton16: TToolButton;
    Changeencryption1: TMenuItem;
    Changedefaultcompressionlevel1: TMenuItem;
    Changeencryption2: TMenuItem;
    PopupMenu1: TPopupMenu;
    Changefileencryption1: TMenuItem;
    Createfolder3: TMenuItem;
    RemoveFolder2: TMenuItem;
    N3: TMenuItem;
    Exportfolder2: TMenuItem;
    Exportfile1: TMenuItem;
    FileCopy: TAction;
    Copyfile1: TMenuItem;
    ToolButton17: TToolButton;
    ChangeFilesEncryption: TAction;

		// get file tree, returns files number
		function GetBackupFileTree(startDirectory : string; fileList : TList) : integer;

    procedure FileNew1Execute(Sender: TObject);
    procedure FileOpen1Execute(Sender: TObject);
    procedure FileExit1Execute(Sender: TObject);
    procedure HelpAbout1Execute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure LoadSettings;
    procedure SaveSettings;
    procedure EncryptedClick(Sender: TObject);
    procedure bnCancelClick(Sender: TObject);
    procedure bnOkClick(Sender: TObject);

		procedure ExportFile(srcName, destName: string);
    procedure FileImportExecute(Sender: TObject);
    procedure FileRemoveExecute(Sender: TObject);
    procedure CreateFolderExecute(Sender: TObject);
    procedure RemoveFolderExecute(Sender: TObject);
    procedure FileExportExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ListViewCompare(Sender: TObject; Item1, Item2: TListItem;
      Data: Integer; var Compare: Integer);
    procedure ListViewDblClick(Sender: TObject);
    procedure btnBackClick(Sender: TObject);
    procedure cbPathChange(Sender: TObject);
    procedure cbPathKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure cbPathClick(Sender: TObject);
    procedure ListViewKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ListViewSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure ImportFolderExecute(Sender: TObject);
    procedure ExportFolderExecute(Sender: TObject);
    procedure ShowOverwritePrompt(
                             Sender:   TObject;
                              // file being overwritten
                              ExistsingFileName: AnsiString;
                              // with:
                              NewFileName: AnsiString;
                              // set to true to overwrite
                              var bOverwrite: Boolean
                             		);
    procedure FileCloseExecute(Sender: TObject);
    procedure FileCompactRepairExecute(Sender: TObject);
    procedure CompLevelChange(Sender: TObject);
    procedure FileChangeEncryptionExecute(Sender: TObject);
    procedure FileChangeCompLevelExecute(Sender: TObject);
    procedure ChangeFileEncryptionExecute(Sender: TObject);
    procedure FileCopyExecute(Sender: TObject);
  private
    bOverwriteAll: Boolean;
    procedure OpenBackupFile;
    function  GetSelectedFileName: string;
    procedure FillListView;
    procedure SetPath(path: string);
    procedure ViewImage(FileName: string);
    procedure ViewText(FileName: string);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;
  BackupFile: TSingleFileSystem = nil;
  curPath,curFileName: string;
//  itemList:	TList;

implementation

uses ShellAPI, ActiveX, ComObj, CommCtrl, ProgressCancel;

{$R *.DFM}

function IsFolder(FSItem: pFSItem): Boolean;
begin
 result := false;
 if (FSItem = nil) then
  Exit;
 if (FSItem^.Attributes = faDirectory) then
  result := true;
end;

function ValidFileTime(FileTime: TFileTime): Boolean;
begin
   Result := (FileTime.dwLowDateTime <> 0) or (FileTime.dwHighDateTime <> 0);
end;


//------------------------------------------------------------------------------
// allocates memory for FileHeader and fills FileHeader with TSearchRec values
//------------------------------------------------------------------------------
function GetFileHeader(sr : TSearchRec; path : string)
          : pFileHeader;
var pHeader : pFileHeader;
begin
 new(pHeader);
 if (pHeader = nil) then
  raise Exception.Create('GetFileHeader: pHeader = nil!');

 pHeader^.name := sr.Name;
 pHeader^.path := path;
 pHeader^.BackupPath := Copy(path,3,Length(path)-2);
 pHeader^.size := Int64(Int64(sr.FindData.nFileSizeHigh) shl 32) +
                  Int64(sr.FindData.nFileSizeLow);
 pHeader^.attr := sr.Attr;
 if (sr.Attr and faDirectory <> 0) then
  pHeader^.IsFolder := true
 else
  pHeader^.IsFolder := false;
 result := pHeader;
end; //GetFileHeader

//------------------------------------------------------------------------------
// allocates memory for FileHeader and fills FileHeader with TSearchRec values
//------------------------------------------------------------------------------
function GetBackupFileHeader(sr : TSearchRec; path : string)
          : pFileHeader;
var pHeader : pFileHeader;
begin
 new(pHeader);
 if (pHeader = nil) then
  raise Exception.Create('GetFileHeader: pHeader = nil!');

 pHeader^.name := sr.Name;
// if (path[1] = '\') or (path[1] = '/') then
//  pHeader^.path := Copy(path,2,Length(path)-1)
// else
 pHeader^.BackupPath := path;
 pHeader^.path := path;
// pHeader^.Path := Copy(path,2,Length(path)-1);
 pHeader^.size := Int64(sr.FindData.nFileSizeHigh shl 32) + sr.FindData.nFileSizeLow;
 pHeader^.attr := sr.Attr;
 if (sr.Attr and faDirectory <> 0) then
  pHeader^.IsFolder := true
 else
  pHeader^.IsFolder := false;
 result := pHeader;
end; //GetFileHeader

//------------------------------------------------------------------------------
// get file tree, returns files number
//------------------------------------------------------------------------------
function GetFileTree(startDirectory : string; fileList : TList) : integer;
var sr : TSearchRec;
begin
 if (FindFirst(startDirectory+'\*.*',faAnyFile,sr) <> 0) then
// if (FindFirst(startDirectory+'*.*',faAnyFile,sr) <> 0) then
  begin
   FindClose(sr);
   result := fileList.Count;
   exit;
  end;
 repeat
   if (((sr.Name = '..') or (sr.Name = '.')) and
      ((sr.Attr and faDirectory) <> 0)) then continue;
   // append both files and directories
   fileList.Add(GetFileHeader(sr,startDirectory));
   // directory
   if ((sr.Attr and faDirectory) <> 0) then
    begin
     GetFileTree(startDirectory+'\'+sr.Name,fileList);
     continue;
    end;
  until (FindNext(sr) <> 0);
 result := fileList.Count;
 FindClose(sr);
end;


// MainForm

//------------------------------------------------------------------------------
// get file tree, returns files number
//------------------------------------------------------------------------------
function TMainForm.GetBackupFileTree(startDirectory : string; fileList : TList) : integer;
var sr : TSearchRec;
begin
 result := 0;
 if (BackupFile = nil) then
  Exit;
 if (BackupFile.FindFirst(startDirectory+'*.*',faAnyFile,sr) <> 0) then
  begin
   FindClose(sr);
   result := fileList.Count;
   exit;
  end;
 repeat
   if (((sr.Name = '..') or (sr.Name = '.')) and
      ((sr.Attr and faDirectory) <> 0)) then continue;
   // append both files and directories
   fileList.Add(GetBackupFileHeader(sr,startDirectory));
   // directory
   if ((sr.Attr and faDirectory) <> 0) then
    begin
     GetBackupFileTree(startDirectory+sr.Name+'\',fileList);
     continue;
    end;
  until (BackupFile.FindNext(sr) <> 0);
 result := fileList.Count;
 BackupFile.FindClose(sr);
end;

procedure TMainForm.FileNew1Execute(Sender: TObject);
begin
  { Do nothing }
  MainNotebook.Color := clBtnShadow;
  MainNotebook.ActivePage := 'CreateBackup';
end;

procedure TMainForm.FileOpen1Execute(Sender: TObject);
begin
  OpenDialog.FilterIndex := 0;
  OpenDialog.DefaultExt := BackupFileExt;
  OpenDialog.Title := 'Open backup file';
  if (OpenDialog.Execute) then
   begin
    if (not IsSFSFile(OpenDialog.FileName)) then
     begin
      MessageDlg('Could not open file '''+
        OpenDialog.FileName+'''. Invalid file format or file corrupted.',
        mtError,[mbOk],0);
      Exit;
     end;
    curFileName := OpenDialog.FileName;
    OpenBackupFile;
   end;
end;


procedure TMainForm.FileExit1Execute(Sender: TObject);
begin
 Close;
end;

procedure TMainForm.HelpAbout1Execute(Sender: TObject);
begin
  SFSManagerAbout.ShowModal;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var i:    integer;
    name: string;
begin
  for i := 0 to 9 do
   CompLevel.Items.Add(levelText[i]);
  CompLevel.ItemIndex := 0;
  Info.Text := levelDesc[0];
{$IFDEF MEM_CHECK}
MemChk;
{$ENDIF}

 BackupFile := nil;
 curFileName := ExtractFilePath(Application.ExeName)+'Backup.sfs';

 CompLevel.ItemIndex := 0;
 MainNotebook.ActivePage := 'Default';
 MainNotebook.Color := clBtnShadow;
 if (ParamCount > 0) then
  begin
   name := ParamStr(1);
   if (IsSFSFile(name)) then
    begin
     curFileName := name;
     OpenBackupFile;
    end;
  end;
 LoadSettings;
end;

//------------------------------------------------------------------------------
// load settings from INI file
//------------------------------------------------------------------------------
procedure TMainForm.LoadSettings;
var
  IniFile : TIniFile;
  s: string;
begin
 IniFile := TIniFile.Create(ExtractFilePath(ParamStr(0))+'sfsmanager.ini');
 WindowState := TWindowState(IniFile.ReadInteger('WindowSettings', 'State', Integer(wsNormal)));
 s := IniFile.ReadString('AppSettings', 'SFSFileName', '');
 if (BackupFile = nil) then
  if (IsSFSFile(s)) then
   begin
    curFileName := s;
    OpenBackupFile;
   end;
 IniFile.Free;
end;// LoadSettings


//------------------------------------------------------------------------------
// save settings to INI file
//------------------------------------------------------------------------------
procedure TMainForm.SaveSettings;
var
  IniFile : TIniFile;
begin
   IniFile := TIniFile.Create(ExtractFilePath(ParamStr(0))+'sfsmanager.ini');
   IniFile.WriteInteger('WindowSettings', 'State', Integer(WindowState));
   IniFile.WriteString('AppSettings', 'SFSFileName', curFileName);
   IniFile.Free;
end;// SaveSettings


procedure TMainForm.EncryptedClick(Sender: TObject);
begin
 if (Encrypted.Checked) then
  begin
   Password.Color := clWindow;
   ControlQuestion.Color := clWindow;
   Answer.Color := clWindow;
   Password.Enabled := true;
   ControlQuestion.Enabled := true;
   Answer.Enabled := true;
  end
 else
  begin
   Password.Color := clSilver;
   ControlQuestion.Color := clSilver;
   Answer.Color := clSilver;
   Password.Enabled := false;
   ControlQuestion.Enabled := false;
   Answer.Enabled := false;
  end;
end;

procedure TMainForm.bnCancelClick(Sender: TObject);
begin
 MainNotebook.ActivePage := 'Default';
 MainNotebook.Color := clBtnShadow;
end;

procedure TMainForm.bnOkClick(Sender: TObject);
var SFS: TSingleFileSystem;
    Pass,Quest,Ans: string;
begin
 if (Encrypted.Checked) then
  begin
   Pass := Password.Text;
   Quest := ControlQuestion.Text;
   Ans := Answer.Text;
  end
 else
  begin
   Pass := '';
   Quest := '';
   Ans := '';
  end;

 curFileName := DirBox.Directory+'\'+BackupFileName.Text+BackupFileExt;
 SFS := TSingleFileSystem.Create(curFileName,fmCreate,
 				false,
 				Pass,Quest,Ans,
        levelValue[CompLevel.ItemIndex]
 				);
 if (SFS = nil) then
  raise Exception.Create('Error creating file '+AnsiQuotedStr(curFileName,'"'));
 // create file
 SFS.Free;
 OpenBackupFile;
end;



procedure TMainForm.OpenBackupFile;
var bOk: 			  Boolean;
    s,quest: 	  AnsiString;
    password: 	String;
begin
 // enable actions
 FileImport.Enabled := true;
 FileRemove.Enabled := true;
 FileCopy.Enabled := true;
 FileExport.Enabled := true;
 ChangeFilesEncryption.Enabled := true;
 CreateFolder.Enabled := true;
 RemoveFolder.Enabled := true;
 ImportFolder.Enabled := true;
 ExportFolder.Enabled := true;
 FileCompactRepair.Enabled := true;
 FileChangeEncryption.Enabled := true;
 FileChangeCompLevel.Enabled := true;
 FileClose.Enabled := true;
 bOk := false;
 s := '';
 if (IsSingleFileEncrypted(curFileName)) then
  begin
   quest := GetControlQuestion(curFileName);
   FormPass.Caption := 'Enter password for file '+
   	AnsiQuotedStr(ExtractFileName(curFileName),'"');
   while (not bOk) do
    begin
     // ask password
     if (FormPass = nil) then
      begin
       if (not InputQuery('Enter password', 'Password: ', password)) then
        break;
      end
     else
      begin
       if (FormPass.ShowModal <> mrOk) then
        break;
       password := FormPass.Password.Text;
      end;
     if (not IsPasswordValid(curFileName,password)) then
      begin
       // there is no control question
       if (quest = '') or (FormQuest = nil) then
        continue;
       // if invalid password was entered ask to recover it
       if (MessageDlg('Invalid password. Did you forget your password?',
       			mtWarning,
       			[mbYes,mbNo],0) = mrNo) then
        continue;
       while (true) do
        begin
         // recover password
         FormQuest.Quest.Text := quest;
	       if (FormQuest.ShowModal <> mrOk) then
  	      break;
         if (not RestorePasswordByControlAnswer(curFileName,
       					FormQuest.Answer.Text,s)) then
          continue;
         MessageDlg('Password = '+AnsiQuotedStr(s,'"'),
         	mtInformation,[mbOk],0);
         bOk := true;
         break;
        end;
       // ask password
       continue;
      end;
     s := Password;
     bOk := true;
    end; // while password not entered
  end // encrypted file
 else
  bOk := true;
 if (not bOk) then
  begin
   FileClose.Execute;
   Exit;
  end;
 GroupBox1.Caption := ' '+ExtractFileName(curFileName)+ ' contents ';
 MainNotebook.Color := clBtnFace;
 MainNotebook.ActivePage := 'EditBackup';
try
 if (BackupFile <> nil) then
  BackupFile.Free;
 BackupFile := TSingleFileSystem.Create(curFileName,fmOpenReadWrite,s);
except
 ShowMessage('Error opening file '+curFileName);
 BackupFile := nil;
end;
 SetPath('\');
end;



function TMainForm.GetSelectedFileName: string;
begin
 result := '';
 if (ListView.Selected = nil) then Exit;
 if (ListView.Selected.Data = nil) then Exit;
 result := PFSItem(ListView.Selected.Data)^.FileName;
end;


procedure TMainForm.FillListView;
var sr: 		TSearchRec;
    FSItem: pFSItem;
		LocalFileTime: TFILETIME;
    i:			 Integer;
		SysTime: TSystemTime;
    ListItem: TListItem;
    s:        String;
    ex:       extended;

 procedure AppendItem;
 var Attrs: string;
 begin
  new(FSItem);
  FSItem.FileName := sr.Name;
  FSItem.DisplayName := sr.Name;
  FSItem.TypeName := ExtractFileExt(sr.Name);
  FSItem.Attributes := sr.FindData.dwFileAttributes;
  FSItem.Size := Int64(sr.FindData.nFileSizeHigh shl 32) + sr.FindData.nFileSizeLow;
  FSItem.isFolder := false;
  if (isFolder(FSItem)) then
   begin
    FSItem.ImageIndex := imgFolder;
    FSItem.isFolder := true;
   end
  else
   begin
    if (LowerCase(FSItem.TypeName) = '.txt') then
	   FSItem.ImageIndex := imgText
    else
    if (LowerCase(FSItem.TypeName) = '.bmp') then
	   FSItem.ImageIndex := imgBMP
    else
	   FSItem.ImageIndex := imgUnknown;
   end;
  // add item to tree
  with sr.FindData do
        if ValidFileTime(ftLastWriteTime)
        and FileTimeToLocalFileTime(ftLastWriteTime, LocalFileTime)
        and FileTimeToSystemTime(LocalFileTime, SysTime) then
        try
          FSItem.ModDate := DateTimeToStr(SystemTimeToDateTime(SysTime))
        except
          on EConvertError do FSItem.ModDate := '';
        end
        else
          FSItem.ModDate := '';
//	  i := itemList.Add(FSItem);
	  Attrs := '';
	  ListItem := ListView.Items.Add;
    ListItem.Caption := FSItem.DisplayName;
    ListItem.ImageIndex := FSItem.ImageIndex;
    ListItem.Data := FSItem;
    if (not FSItem.isFolder) then
     begin
      ex := FSItem.Size;
      s := FormatFloat('#,##0',ex);
      ListItem.SubItems.Add(s);
     end
    else
      ListItem.SubItems.Add('');

    try
      ListItem.SubItems.Add(FSItem.ModDate);
    except
    end;

    if Bool(FSItem.Attributes and FILE_ATTRIBUTE_READONLY) then
     Attrs := Attrs + 'r'
    else
     Attrs := Attrs + '-';
    if Bool(FSItem.Attributes and FILE_ATTRIBUTE_ARCHIVE) then
     Attrs := Attrs + 'a'
    else
     Attrs := Attrs + '-';
    if Bool(FSItem.Attributes and FILE_ATTRIBUTE_HIDDEN) then
     Attrs := Attrs + 'h'
    else
     Attrs := Attrs + '-';
    if Bool(FSItem.Attributes and FILE_ATTRIBUTE_SYSTEM) then
     Attrs := Attrs + 's'
    else
     Attrs := Attrs + '-';
 		ListItem.SubItems.Add(Attrs);
  Attrs := '';
 end;

begin
 for i := 0 to ListView.Items.Count-1 do
  if (ListView.Items[i].Data <> nil) then
   dispose(ListView.Items[i].Data);
 ListView.Items.Clear;
 ListView.SortType := stNone;
 if (BackupFile = nil) then
  Exit;
 // fill list view
// for i := 0 to itemList.Count-1 do
//  dispose(itemList.Items[i]);
// itemList.Clear;
 if (curPath <> '\') then
  begin
   // add '..' element
   new(FSItem);
   FSItem.DisplayName := '..';
   FSItem.FileName := '..';
   FSItem.Attributes := faDirectory;
   FSItem.isFolder := true;
   FSItem.ImageIndex := imgFolder;
//   i := ItemList.Add(FSItem);
   ListItem := ListView.Items.Add;
   ListItem.Data := FSItem;
   ListItem.Caption := '..';
   ListItem.ImageIndex := FSItem.ImageIndex;
  end;
 if (BackupFile.FindFirst('*.*',faAnyFile,sr) = 0) then
  begin
	  repeat
  	 AppendItem;
	  until BackupFile.FindNext(sr) <> 0;
  end;
 FindClose(sr);
 ListView.SortType := stData;
end;

procedure TMainForm.SetPath(path: string);
var  Index: Integer;
begin
  if (BackupFile = nil) then Exit;
  RemoveFolder.Enabled := false;
  FileRemove.Enabled := false;
  FileCopy.Enabled := false;
  ViewNoteBook.Visible := false;

  BackupFile.SetCurrentDir(Path);
  curPath := BackupFile.GetCurrentDir;
  if (curPath <> '\') then
   curPath := curPath+'\';
  Index := cbPath.Items.IndexOf(curPath);
    if (Index < 0) then
    begin
      cbPath.Items.Insert(0,curPath);
      cbPath.Text := cbPath.Items[0];
    end
    else begin
      cbPath.ItemIndex := Index;
      cbPath.Text := cbPath.Items[cbPath.ItemIndex];
    end;
 FillListView;
end;

procedure TMainForm.ViewImage(FileName: string);
var fs: TSFSFileStream;
    bMap: TBitmap;
//    fs1:TFileStream;
begin
 if (BackupFile = nil) then
  Exit;
 ViewNoteBook.PageIndex := 1;
 bReadStarted := True;
 fs := TSFSFileStream.Create(BackupFile,FileName,fmOpenRead);
 try
   bMap := TBitmap.Create;
   try
     bMap.LoadFromStream(TStream(fs));
     Image.Picture.Bitmap := bMap;
   finally
     bMap.Free;
   end;
 finally
   fs.Free;
   bReadStarted := False;
   ViewNoteBook.Visible := true;
 end;
end;

procedure TMainForm.ViewText(FileName: string);
var fs: TSFSFileStream;
begin
 if (BackupFile = nil) then
  Exit;
 try
   ViewNoteBook.PageIndex := 0;
   RichEdit.Lines.Clear;
   bReadStarted := True;
   fs := TSFSFileStream.Create(BackupFile,FileName,fmOpenRead);
   RichEdit.Lines.LoadFromStream(TStream(fs));
   fs.Free;
   bReadStarted := False;
   ViewNoteBook.Visible := true;
 except
 end;
end;

procedure AddFile(srcName: string);
var fs: TSFSFileStream;
    destName: string;
    attr: DWORD;
    bOK:  Boolean;
begin
    if (BackupFile = nil) then
      Exit;
    bOK := False;
    attr := FileGetAttr(srcName);
    destName := ExtractFileName(srcName);
    bWriteStarted := True;
    fs := TSFSFileStream.Create(BackupFile,destName,fmCreate);
    try
      fs.OnProgress := FormProgress.SetIndicator2;
      FormProgress.InitProgressForm('Importing file',srcName);
      FormProgress.Show;
      try
       fs.LoadFromFile(srcName);
       bOK := True;
      finally
       FormProgress.Close;
      end;
    finally
      fs.Free;
      if (not bOK) then
       BackupFile.DeleteFile(destName)
      else
       BackupFile.FileSetAttr(destName,attr);
      bWriteStarted := False;
    end;
end;

procedure TMainForm.ExportFile(srcName, destName: string);
var fs: TSFSFileStream;
    attr: DWORD;
begin
    if (BackupFile = nil) then
      Exit;
    attr := BackupFile.FileGetAttr(srcName);
    bReadStarted := True;
    fs := TSFSFileStream.Create(BackupFile,srcName,fmOpenRead);
    try
      FormProgress.Label1.Caption := srcName;
      FormProgress.Indicator.Progress := 0;
      fs.OnProgress := FormProgress.SetIndicator2;
      FormProgress.InitProgressForm('Exporting file',srcName);
      FormProgress.Show;
      try
       fs.SaveToFile(destName);
      finally
       FormProgress.Close;
      end;
    finally
     fs.Free;
     bReadStarted := False;
     FileSetAttr(destName,attr);
    end;
end;

procedure TMainForm.FileImportExecute(Sender: TObject);
begin
  OpenDialog1.Title := 'Import file';
  if (OpenDialog1.Execute) then
   begin
    AddFile(OpenDialog1.FileName);
		FillListView;
   end;
end;

procedure TMainForm.FileRemoveExecute(Sender: TObject);
var fileName,capt: string;
    i: integer;
begin
 if (BackupFile = nil) then
  Exit;
 FileName := GetSelectedFileName;
 if (FileName = '') or (FileName = '..') then Exit;
 if (ListView.SelCount < 1) then
  Exit
 else
  if (ListView.SelCount = 1) then
   begin
    if (ListView.Selected.Caption = '..') then
       Exit;
    // delete single file
    capt := 'Are you sure you want to delete file ' +
    				AnsiQuotedStr(FileName,'"') + ' ?';
		if (MessageDlg(capt,mtConfirmation,[mbYes,mbNo],0) <> mrYes) then
		  Exit;
    if (not BackupFile.DeleteFile(FileName)) then
       begin
        capt := 'Error deleting file ' +
    						AnsiQuotedStr(FileName,'"') + '!';
        MessageDlg(capt,mtError,[mbOk],0);
        ListView.Selected := nil;
        Exit;
       end;
   end
  else
   begin
    // multiple files delete
    capt := 'Are you sure you want to delete selected files ?';
		if (MessageDlg(capt,mtConfirmation,[mbYes,mbNo],0) <> mrYes) then
		  Exit;
    for i := 0 to ListView.Items.Count-1 do
     begin
      if (not ListView.Items[i].Selected) then
       continue;
      if (ListView.Items[i].Caption = '..') then
       continue;
      if (ListView.Items[i].Data = nil) then
       continue;
      FileName := PFSItem(ListView.Items[i].Data)^.FileName;
      if (not BackupFile.DeleteFile(FileName)) then
       begin
        capt := 'Error deleting file ' +
    						AnsiQuotedStr(FileName,'"') + '!';
        MessageDlg(capt,mtError,[mbOk],0);
        ListView.Selected := nil;
        Exit;
       end;
     end; // selected items
   end; // multiple files delete
 ListView.Selected := nil;
 FillListView;
end;

procedure TMainForm.CreateFolderExecute(Sender: TObject);
var FileName: string;
begin
 if (BackupFile = nil) then
  Exit;
 FileName := '';
 FileName := InputBox('Create folder','Enter folder name:',FileName);
 if (FileName = '') then Exit;
 if (not BackupFile.CreateDir(FileName)) then
   MessageDlg('Error creating folder '+AnsiQuotedStr(FileName,'"'),mtError,
    	[mbOk],0)
  else
   FillListView;
end;

procedure TMainForm.RemoveFolderExecute(Sender: TObject);
var Dir: string;
begin
  if (BackupFile = nil) then
   Exit;
  if (ListView.SelCount = 1) then
   if (ListView.Selected.Caption = '..') then
    Exit
   else
    begin
     Dir := curPath+ListView.Selected.Caption+'\';
     if (BackupFile.IsFolderEmpty(Dir)) then
      begin
       if (not BackupFile.RemoveDir(Dir)) then
        MessageDlg('Error deleting folder '+AnsiQuotedStr(ListView.Selected.Caption,'"')+
                '.', mtError, [mbOk], 0)
       else
        FillListView;
      end
     else
      begin
       if (MessageDlg('Delete folder '''+
          Dir+'''. This folder is not empty. Are you sure?',
          mtConfirmation,[mbYes,mbNo],0) = mrYes) then
        begin
         BackupFile.DeleteFolder(Dir);
         FillListView;
        end;
      end;
    end;
end;

procedure TMainForm.FileExportExecute(Sender: TObject);
var
    FileName: string;
begin
 if (BackupFile = nil) then
  Exit;
 FileName := GetSelectedFileName;
 if (FileName = '') then Exit;
 SaveDialog.Title := 'Export file';
 SaveDialog.FileName := FileName;
 if (SaveDialog.Execute) then
   ExportFile(FileName, SaveDialog.FileName);
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
var i: integer;
begin
 if (bReadStarted) then
  begin
   ShowMessage('Reading file have been started. You should wait until the operation will be finished to avoid abnormal program termination.');
   Action := caNone;
   FormProgress.Show;
   Exit;
  end;
 if (bWriteStarted) then
  begin
   ShowMessage('Writing file have been started. You should wait until the operation will be finished to avoid abnormal program termination and backup file corruption.');
   Action := caNone;
   FormProgress.Show;
   Exit;
  end;
 if (bReadStarted1) then
  begin
   ShowMessage('Exporting folder have been started. You should wait until the operation will be finished to avoid abnormal program termination.');
   Action := caNone;
   FormProgressCancel2.Show;
   Exit;
  end;
 if (bWriteStarted1) then
  begin
   ShowMessage('Importing folder have been started. You should wait until the operation will be finished to avoid abnormal program termination and backup file corruption.');
   Action := caNone;
   FormProgressCancel2.Show;
   Exit;
  end;
 SaveSettings;
 for i := 0 to ListView.Items.Count-1 do
  if (ListView.Items[i].Data <> nil) then
   dispose(ListView.Items[i].Data);
 if (BackupFile <> nil) then
  BackupFile.Free;
 BackupFile := nil;
end;

procedure TMainForm.ListViewCompare(Sender: TObject; Item1,
  Item2: TListItem; Data: Integer; var Compare: Integer);
begin
 if (Item1.Data <> nil) and (Item2.Data <> nil) then
  begin
	 if (pFSItem(Item1.Data)^.isFolder and (not pFSItem(Item2.Data)^.isFolder)) then
    begin
  	  Compare := -1;
      Exit;
    end
	 else
	  if (not (pFSItem(Item1.Data)^.isFolder) and pFSItem(Item2.Data)^.isFolder) then
     begin
      Compare := 1;
      Exit;
     end;
  end;
    Compare := 0;
    if (LowerCase(Item1.Caption) <
								   LowerCase(Item2.Caption)) then
     Compare := -1
    else
    if (LowerCase(Item1.Caption) >
								   LowerCase(Item2.Caption)) then
     Compare := 1;
end;

procedure TMainForm.ListViewDblClick(Sender: TObject);
begin
 if ListView.Selected <> nil then
  if ListView.Selected.Data <> nil then
   begin
    if (pFSItem(ListView.Selected.Data)^.isFolder) then
     SetPath(curPath+pFSItem(ListView.Selected.Data)^.FileName+'\');
   end;
end;

procedure TMainForm.btnBackClick(Sender: TObject);
begin
 SetPath(curPath+'..\');
end;

procedure TMainForm.cbPathChange(Sender: TObject);
begin
 SetPath(cbPath.Text);
end;

procedure TMainForm.cbPathKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    if cbPath.Text[Length(cbPath.Text)] <> '\' then
      cbPath.Text := cbPath.Text + '\';
    SetPath(cbPath.Text);
    Key := 0;
  end;
end;

procedure TMainForm.cbPathClick(Sender: TObject);
begin
 SetPath(cbPath.Text);
end;

procedure TMainForm.ListViewKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_RETURN:
      ListViewDblClick(Sender);
    VK_DELETE:
		 if ListView.Selected <> nil then
		  if ListView.Selected.Data <> nil then
	     if (pFSItem(ListView.Selected.Data)^.isFolder) then
        RemoveFolderExecute(Sender)
       else
        FileRemoveExecute(Sender);
    VK_BACK:
      btnBackClick(Sender);
  end;
end;

procedure TMainForm.ListViewSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
begin
 RemoveFolder.Enabled := false;
 FileRemove.Enabled := false;
 FileCopy.Enabled := false;
 ViewNoteBook.Visible := false;
 FileChangeEncryption.Enabled := false;
 if (Selected = false) then Exit;

 if ListView.Selected <> nil then
  if ListView.Selected.Data <> nil then
   if ListView.Selected.Caption <> '..' then
    begin
     if (pFSItem(ListView.Selected.Data)^.isFolder)
      then
      begin
       RemoveFolder.Enabled := true;
      end
     else
      begin
       FileRemove.Enabled := true;
       FileCopy.Enabled := true;
       FileChangeEncryption.Enabled := true;
       if (LowerCase(pFSItem(ListView.Selected.Data)^.TypeName) = '.bmp') then
        ViewImage(pFSItem(ListView.Selected.Data)^.FileName)
       else
       if (LowerCase(pFSItem(ListView.Selected.Data)^.TypeName) = '.txt') then
        ViewText(pFSItem(ListView.Selected.Data)^.FileName);
      end;
    end;
end;

procedure TMainForm.ImportFolderExecute(Sender: TObject);
var s: string;
    i: integer;
begin
 //s := 'e:\1';
 if (BackupFile = nil) then
  Exit;
 s := '';
 if (SelectDirectory('Select folder for importing... ', '', s)) then
 begin
  FormProgressCancel2.InitProgressForm('Import folder '+s,'');
  FormProgressCancel2.Show;
  bOverwriteAll := false;
  BackupFile.OnOverwritePrompt := ShowOverwritePrompt;
  BackupFile.OnProgress := FormProgressCancel2.SetIndicator;
  BackupFile.OnFileProgress := FormProgressCancel2.SetIndicator22;
  bWriteStarted1 := True;
  i := BackupFile.ImportFolder(s);
  bWriteStarted1 := False;
  FormProgressCancel2.Hide;
	FillListView;
  MessageDlg(IntToStr(i)+' files imported successfully.',mtInformation,[mbOk],0);
 end;
end; // ImportFolderExecute

procedure TMainForm.ExportFolderExecute(Sender: TObject);
var s,fileName:   string;
    i:            integer;
begin
 if (BackupFile = nil) then
  Exit;
 s := '';
 if (ListView.Selected = nil) then
   fileName := curPath
 else
   begin
	  if (ListView.Selected.Caption <> '..') then
     fileName := curPath + ListView.Selected.Caption+'\';
   end;
 if (SelectDirectory('Select folder for exporting... ', '', s)) then
 begin
  try
   BackupFile.SetCurrentDir(fileName);
   FormProgressCancel2.InitProgressForm('Export folder '+fileName,'');
   FormProgressCancel2.Show;
   try
    bOverwriteAll := false;
    BackupFile.OnOverwritePrompt := ShowOverwritePrompt;
    BackupFile.OnProgress := FormProgressCancel2.SetIndicator;
    BackupFile.OnFileProgress := FormProgressCancel2.SetIndicator22;
    bReadStarted1 := True;
    i := BackupFile.ExportFolder(fileName,s);
    bReadStarted1 := False;
   finally
    FormProgressCancel2.Hide;
   end;
  finally
   SetPath(curPath);
  end;
  MessageDlg(IntToStr(i)+' files exported successfully.',mtInformation,[mbOk],0);
 end;
end; // ExportFileExecute


procedure TMainForm.ShowOverwritePrompt(
                             Sender:   TObject;
                              // file being overwritten
                              ExistsingFileName: AnsiString;
                              // with:
                              NewFileName: AnsiString;
                              // set to true to overwrite
                              var bOverwrite: Boolean
                             		);
 var res: Integer;
 begin
  if (bOverwriteAll) then
   begin
    bOverwrite := true;
    Exit;
   end;

  res := MessageDlg('File '''+ExistsingFileName+
                    ''' already exists. Do you want replace it with file '''+
                    NewFileName+''' ?',mtConfirmation,[mbYes,mbNo,mbAll],0);
  if (res = mrAll) then
   bOverwriteAll:= true;
  if (res <> mrNo) then
   bOverwrite := true;
end; // ShowOverwritePrompt

procedure TMainForm.FileCloseExecute(Sender: TObject);
var i: integer;
begin
 if (BackupFile <> nil) then
  BackupFile.Free;
 BackupFile := nil;
 for i := 0 to ListView.Items.Count-1 do
  if (ListView.Items[i].Data <> nil) then
   dispose(ListView.Items[i].Data);
 ListView.Items.Clear;
 ViewNotebook.Visible := false;

 // disable actions
 FileImport.Enabled := false;
 FileRemove.Enabled := false;
 FileCopy.Enabled := false;
 FileExport.Enabled := false;
 ChangeFilesEncryption.Enabled := false;
 CreateFolder.Enabled := false;
 RemoveFolder.Enabled := false;
 ImportFolder.Enabled := false;
 ExportFolder.Enabled := false;
 FileCompactRepair.Enabled := false;
 FileChangeEncryption.Enabled := false;
 FileChangeCompLevel.Enabled := false;
 FileClose.Enabled := false;

 MainNotebook.ActivePage := 'Default';
 MainNotebook.Color := clBtnShadow;
end;

procedure TMainForm.FileCompactRepairExecute(Sender: TObject);
var log: AnsiString;
begin
//
 if (BackupFile = nil) then
  Exit;
 FormProgressCancel.InitProgressForm('Repair file','Repairing...');
 BackupFile.OnProgress :=  FormProgressCancel.SetIndicator;
 FormProgressCancel.Show;
 log := '';
 BackupFile.Repair(log,True);
 if (log <> '') then
  begin
   FormProgressCancel.Close;
   MessageDlg('Error occurred while repairing file! Error log: '+#13#10+log,mtError,
   [mbOk],0)
  end
 else
  FormProgressCancel.Close;
 SetPath(cbPath.Text);
end;

procedure TMainForm.CompLevelChange(Sender: TObject);
begin
 Info.Text := levelDesc[CompLevel.ItemIndex];
end;

procedure TMainForm.FileChangeEncryptionExecute(Sender: TObject);
var res: Boolean;
begin
 if (BackupFile = nil) then
  Exit;
 FormCrypto.UserFileName.Text := ExtractFileName(BackupFile.FileName);
 FormCrypto.Encrypted.Checked := BackupFile.Encrypted;
 FormCrypto.Password.Text := BackupFile.Password;
 FormCrypto.ControlQuestion.Text := BackupFile.ControlQuestion;
 FormCrypto.Answer.Text := '';
 if (FormCrypto.ShowModal = mrOk) then
  begin
   FormProgressCancel.InitProgressForm('Change encryption','Processing...');
   BackupFile.OnProgress :=  FormProgressCancel.SetIndicator;
   FormProgressCancel.Show;

   if (FormCrypto.Encrypted.Checked) then
    res := BackupFile.ChangeEncryption(FormCrypto.Password.Text,
                        FormCrypto.ControlQuestion.Text,
                        FormCrypto.Answer.Text)
   else
    res := BackupFile.ChangeEncryption('','','');
   FormProgressCancel.Close;
   if (not res) then
     MessageDlg('Error occurred while changing file encryption! Probably file needs repairing.',
        mtError,[mbOk],0)
    else
     MessageDlg('File encryption changed successfully. File password = "'+
                BackupFile.Password+'"',mtInformation, [mbOk],0);
  end;
end;


function GetCompressionLevelIndex(compLevel: TSFSCompressionLevel): Integer;
var i: integer;
begin
 result := 0;
 for i := 0 to 9 do
  if (levelValue[i] = compLevel) then
   begin
    result := i;
    break;
   end;
end;

procedure TMainForm.FileChangeCompLevelExecute(Sender: TObject);
begin
 if (BackupFile = nil) then
  Exit;
 FormCompLevel.CompLevel.ItemIndex :=
    GetCompressionLevelIndex(BackupFile.DefaultCompressionLevel);
 FormCompLevel.CompLevelChange(FormCompLevel);
 if (FormCompLevel.ShowModal = mrOk) then
  begin
   BackupFile.DefaultCompressionLevel := levelValue[FormCompLevel.CompLevel.ItemIndex];
  end;
end;

procedure TMainForm.ChangeFileEncryptionExecute(Sender: TObject);
label m1;
var
  FileName: string;
  OldPassword: String;
  i: integer;
begin
 if (BackupFile = nil) then
  Exit;

 FileName := GetSelectedFileName;
 if (FileName = '') or (FileName = '..') then Exit;
 if (ListView.SelCount < 1) then
  Exit
 else
   begin
m1:
    for i := 0 to ListView.Items.Count-1 do
     begin
      if (not ListView.Items[i].Selected) then
       continue;
      if (ListView.Items[i].Caption = '..') then
       continue;
      if (ListView.Items[i].Data = nil) then
       continue;
      FileName := PFSItem(ListView.Items[i].Data)^.FileName;

      OldPassword:='';

      while not BackupFile.IsPasswordValid(FileName, OldPassword) do
       begin
        if (not InputQuery('Enter password for file: "'+ FileName +'"', 'Password: ', OldPassword)) then
          goto m1;
       end;

      FormCrypto.UserFileName.Text := FileName;
      FormCrypto.Encrypted.Checked := (OldPassword <> '');
      FormCrypto.Password.Text := OldPassword;
      FormCrypto.ControlQuestion.Text := '';//BackupFile.GetControlQuestion(FileName);
      FormCrypto.Answer.Text := '';
      if (FormCrypto.ShowModal = mrOk) then
       begin
        if not BackupFile.ChangeFilesEncryption(FileName,OldPassword,
                                                FormCrypto.Password.Text,
                                                FormCrypto.ControlQuestion.Text,
                                                FormCrypto.Answer.Text) then
          MessageDlg('Error occurred while changing file encryption!', mtError,[mbOk],0);
       end;
     end; // selected items
   end; // multiple files delete
 ListView.Selected := nil;
 FillListView;
end;

procedure TMainForm.FileCopyExecute(Sender: TObject);
var FileName, NewFileName: String;
begin
 if (BackupFile = nil) then
   Exit;
 FileName := GetSelectedFileName;
 NewFileName := FileName;

 if (InputQuery('Copy file '+FileName,'New file name:',NewFileName)) then
  begin
   if (not BackupFile.CopyFile(FileName,NewFileName)) then
    MessageDlg('Error while copying file '+FileName+' to file '+NewFileName,
      mtError,[mbOk],0)
   else
     FillListView;
  end;
end; // FileCopyExecute

end.
