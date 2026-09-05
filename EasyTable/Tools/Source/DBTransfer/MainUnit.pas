unit MainUnit;

interface

{$I TETManager.inc}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, StdCtrls, Db, DBTables, EasyTable, FileCtrl, ProgressIndicator;

type
  TMainForm = class(TForm)
    Bevel1: TBevel;
    btnCancel: TButton;
    btnPrev: TButton;
    btnNext: TButton;
    Panel2: TPanel;
    Notebook1: TNotebook;
    TETtable: TEasyTable;
    dsTET: TDataSource;
    dsBDE: TDataSource;
    rgAction: TRadioGroup;
    rbAlias: TRadioButton;
    rbDir: TRadioButton;
    Label2: TLabel;
    BDESourceAlias: TListBox;
    BDESourceDrive: TDriveComboBox;
    BDESourceDir: TDirectoryListBox;
    BDESourceTables: TListBox;
    Label3: TLabel;
    ImportLog: TMemo;
    Button1: TButton;
    Button2: TButton;
    EasyDB: TEasyDatabase;
    DriveComboBox1: TDriveComboBox;
    DirectoryListBox1: TDirectoryListBox;
    Label4: TLabel;
    TETDest: TFileListBox;
    SaveDialog1: TSaveDialog;
    Label12: TLabel;
    Label13: TLabel;
    hyperlink: TLabel;
    Label14: TLabel;
    AidAimHLink: TLabel;
    TETSourceTables: TListBox;
    Label5: TLabel;
    rbDestDir: TRadioButton;
    rbDestAlias: TRadioButton;
    BDEDestAlias: TListBox;
    BDEDestDrive: TDriveComboBox;
    BDEDestDir: TDirectoryListBox;
    Label6: TLabel;
    TETSourceDir: TDirectoryListBox;
    TETSourceDrive: TDriveComboBox;
    Label1: TLabel;
    TETSource: TFileListBox;
    Label7: TLabel;
    Label9: TLabel;
    Label8: TLabel;
    Label10: TLabel;
    cbAutoIndexes: TCheckBox;
    Label11: TLabel;
    BDETable: TTable;
    procedure FormCreate(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnPrevClick(Sender: TObject);
    procedure btnNextClick(Sender: TObject);
    procedure rbAliasClick(Sender: TObject);
    procedure rbDirClick(Sender: TObject);
    procedure BDESourceDirChange(Sender: TObject);
    procedure BDESourceAliasClick(Sender: TObject);
    procedure BDESourceTablesClick(Sender: TObject);
    procedure TETDestChange(Sender: TObject);
    procedure DirectoryListBox1Change(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure hyperlinkMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure AidAimHLinkMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure BDEDestDirChange(Sender: TObject);
    procedure TETSourceTablesClick(Sender: TObject);
    procedure rbDestAliasClick(Sender: TObject);
    procedure rbDestDirClick(Sender: TObject);
    procedure TETSourceDirChange(Sender: TObject);
    procedure TETSourceChange(Sender: TObject);
    procedure BDEDestAliasClick(Sender: TObject);
  private
    { Private declarations }
    pageNo: Integer;
    bRun: Boolean;
    bStop: Boolean;
    procedure SetNewPage(newPageNo: integer);
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;
const pageNum = 6;

implementation

{$R *.DFM}

Function ShellExecute(hWnd:HWND;lpOperation:Pchar;lpFile:Pchar;lpParameter:Pchar;
                      lpDirectory:Pchar;nShowCmd:Integer):Thandle; Stdcall;
External 'Shell32.Dll' name 'ShellExecuteA';

procedure TMainForm.SetNewPage(newPageNo :integer);
begin
 if (newPageNo < 0) then PageNo := 0;
 if (newPageNo >= pageNum) then PageNo := pageNum-1;
 pageNo := newPageNo;
 btnNext.Enabled := true;
 btnNext.Caption := '&Next >';
 case PageNo of
 0:
  begin
   btnPrev.Enabled := false;
   btnNext.Visible := true;
  end;
 1:
  begin
   btnPrev.Enabled := true;
   btnNext.Visible := true;
   if (BDESourceTables.SelCount > 0) then
    btnNext.Enabled := true
   else
    btnNext.Enabled := false;
  end;
 2:
  begin
   btnPrev.Enabled := true;
   btnNext.Visible := true;
   TETDestChange(nil);
  end;
 3:
  begin
   btnNext.Caption := '&Finish';
   btnPrev.Enabled := true;
   btnNext.Visible := true;
   btnNext.Enabled := false;
   ImportLog.Clear;
   if (rgAction.ItemIndex = 0) then
    cbAutoIndexes.Enabled := True
   else
    cbAutoIndexes.Enabled := False;
  end;
 4:
  begin
   btnPrev.Enabled := true;
   btnNext.Visible := true;
   btnNext.Enabled := false;
   if (rbDestDir.Checked) then
    BDEDestDirChange(nil)
   else
    BDEDestAliasClick(nil);
  end;
 5:
  begin
   btnPrev.Enabled := true;
   btnNext.Visible := true;
   btnNext.Enabled := false;
   if (FileExists(TETSource.FileName)) and (TETSourceTables.SelCount > 0) then
    btnNext.Enabled := true
   else
    btnNext.Enabled := false;
  end;
 end;
 Notebook1.PageIndex := pageNo;
end;


procedure TMainForm.FormCreate(Sender: TObject);
begin
 MainForm.Caption := 'EasyTable Database Transfer Utility. (c) AidAim Software, 2004-2020.';
 // read in the alias names from the default BDE session object
 DBTables.Session.GetAliasNames(BDESourceAlias.Items);
 DBTables.Session.GetAliasNames(BDEDestAlias.Items);
 bRun := false;
 bStop := false;
 SetNewPage(0);
end;

procedure TMainForm.btnCancelClick(Sender: TObject);
begin
 if (not bRun) then
  begin
   if (MessageDlg('Transfer is not complete. If you quit now, the tables will not be copied.'+#13+
                'You may run the Program again next time to complete the operation.'+#13+
                'Exit Program?', mtConfirmation, [mbYes, mbNo],0) = mrYes) then
   Application.Terminate;
   Close;
  end
 else
  bStop := true;
end;

procedure TMainForm.btnPrevClick(Sender: TObject);
begin
 if (Pageno = 3) then
 begin
   if (rgAction.ItemIndex = 0) then
    SetNewpage(2)
   else
    SetNewpage(5)
 end
 else
 if (Pageno = 4) then
 begin
  SetNewpage(0);
 end
 else
  SetNewPage(pageNo-1);
end;

procedure TMainForm.btnNextClick(Sender: TObject);
begin
 if (Pageno = 0) then
  begin
 	 // import / export finished
   if (rgAction.ItemIndex = 0) then
    SetNewpage(1)
   else
    SetNewpage(4);
  end
 else
 if (Pageno = 3) then
  begin
 	 // import / export finished
   Application.Terminate;
   Close;
  end
 else
 if (Pageno = 5) then
  begin
   // starting export
   SetNewpage(3);
  end
 else
 begin
  SetNewPage(pageNo+1);
 end;
end;

procedure TMainForm.rbAliasClick(Sender: TObject);
begin
 if (rbAlias.Checked) then
  begin
   rbDir.Checked := false;
   BDESourceDir.Enabled := false;
   BDESourceDrive.Enabled := false;
   BDESourceAlias.Enabled := true;
  end
 else
  begin
   BDESourceDir.Enabled := true;
   BDESourceDrive.Enabled := true;
   BDESourceAlias.Enabled := false;
   rbDir.Checked := true;
  end;

end;

procedure TMainForm.rbDirClick(Sender: TObject);
begin
 if (rbDir.Checked) then
  begin
   rbAlias.Checked := false;
   BDESourceDir.Enabled := true;
   BDESourceDrive.Enabled := true;
   BDESourceAlias.Enabled := false;
  end
 else
  begin
   BDESourceDir.Enabled := false;
   BDESourceDrive.Enabled := false;
   BDESourceAlias.Enabled := true;
   rbAlias.Checked := true;
  end;
end;

procedure TMainForm.BDESourceDirChange(Sender: TObject);
begin
 if (rbDir.Checked) then
  DBTables.Session.GetTableNames(BDESourceDir.Directory,
												 '',True,True,BDESourceTables.Items);
 BDESourceTablesClick(nil);
end;

procedure TMainForm.BDESourceAliasClick(Sender: TObject);
begin
 if (rbAlias.Checked) then
  DBTables.Session.GetTableNames(BDESourceAlias.Items[BDESourceAlias.ItemIndex],
												 '',True,True,BDESourceTables.Items);
 BDESourceTablesClick(nil);
end;

procedure TMainForm.BDESourceTablesClick(Sender: TObject);
begin
 if (BDESourceTables.SelCount > 0) then
  btnNext.Enabled := true
 else
  btnNext.Enabled := false;
end;

procedure TMainForm.TETDestChange(Sender: TObject);
begin
 btnNext.Enabled := false;
 if (FileExists(TETDest.FileName)) then
 begin
  EasyDB.Connected := false;
  EasyDB.DatabaseFileName := TETDest.FileName;
  try
   EasyDB.Connected := true;
   EasyDB.Connected := false;
   btnNext.Enabled := true;
  except
   MessageDlg('Invalid file selected.',mtError,[mbOk],0);
   EasyDB.Connected := false;
  end;
 end;
end;

procedure TMainForm.DirectoryListBox1Change(Sender: TObject);
begin
 TETDestChange(nil);
end;

procedure TMainForm.Button2Click(Sender: TObject);
begin
 SaveDialog1.InitialDir := ExtractFilePath(Application.Exename);
 if (SaveDialog1.Execute) then
  ImportLog.Lines.SaveToFile(SaveDialog1.FileName);
end;

   procedure CreateBDETable;
   begin
   {
    b := false;
    for i := 0 to MainForm.BDETable.IndexDefs.Count-1 do
    begin
     if (ixPrimary in MainForm.BDETable.IndexDefs.Items[i].Options) then
      begin
       b := true;
      end;
    end;
    i := MainForm.TETtable.FieldDefs.Count-1;
    if (not b) then
     MainForm.BDETable.IndexDefs.Add('',MainForm.TETtable.FieldDefs.Items[i].Name,
                                     [ixPrimary]);
    }
    MainForm.BDETable.CreateTable;
   end;

procedure TMainForm.Button1Click(Sender: TObject);
var i,j: Integer;
 		tableName: string;
    bPrompt,bOk: Boolean;
    res: Word;
    log: AnsiString;

//------------------------------------------------------------------------------
// opens table
//------------------------------------------------------------------------------
function OpenTable: Boolean;
var f : boolean;
 name : AnsiString;
begin
 result := false;
 if (not TETTable.IsTableEncrypted) then
  begin
   try
    TETTable.Active := true;
   except
    Exit;
   end;
   result := true;
   Exit;
  end;
 name := '';
 repeat
  try
   name:= InputBox('Table "'+TETTable.TableName+'" authentification','Enter password: ', '');
   if (name = '') then Exit;
   TETTable.Password := name;
   TETTable.Active := true;
   f := true;
  except
   f := false;
   if (MessageDlg('Invalid password. Do you want to try again?',mtConfirmation,[mbYes,mbNo],0) <> mrYes) then
    begin
     TETTable.Active := false;
     Exit;
    end;
  end;
 until f;
 result := true;
end;


begin
 ImportLog.Lines.Clear;
 ImportLog.Lines.Add('System date: '+DateTimeToStr(now)+#13#10);
if (rgAction.ItemIndex = 0) then
begin
// import
 if (rbAlias.Checked) then
   ImportLog.Lines.Add('Importing tables from BDE alias "'+
	    BDESourceAlias.Items[BDESourceAlias.ItemIndex]+'" ...'+#13#10)
 else
   ImportLog.Lines.Add('Importing tables from BDE directory "'+
	    BDESourceDir.Directory+'" ...'+#13#10);

 log := '';
 try
   EasyDB.DatabaseFileName := TETDest.FileName;
   EasyDB.Connected := true;
 except
   MessageDlg('Error opening database file '+
    AnsiQuotedStr(TETDest.FileName,'"')+'.',mtError,[mbOk],0);
    TETDest.FileName := '';
   SetNewPage(2);
   Exit;
 end;
 // show progress
 FormProgress.Indicator.Progress := 0;
 FormProgress.Indicator2.Progress := 0;
 FormProgress.Indicator2.MaxValue := BDESourceTables.SelCount;
 FormProgress.Caption := 'Importing tables from BDE ... ';
 FormProgress.Show;
 BDETable.Active := false;
 TETTable.Active := false;
 if (rbAlias.Checked) then
  BDETable.DatabaseName := BDESourceAlias.Items[BDESourceAlias.ItemIndex]
 else
  BDETable.DatabaseName := BDESourceDir.Directory;
 TETTable.OnProgress := FormProgress.SetIndicator;
 bPrompt := true;
 bOk := true;
 j := 0;
 bRun := true;
 bStop := false;
 // converting tabled
 for i := 0 to BDESourceTables.Items.Count-1 do
  begin
   if (not BDESourceTables.Selected[i]) then continue;
   if (bStop) then
    begin
     ImportLog.Lines.Add('Import operation cancelled by user.');
     Application.ProcessMessages;
     bRun := false;
     Exit;
    end;

   BDETable.Active := false;
   TETTable.Active := false;
   tableName := BDESourceTables.Items.Strings[i];
   BDETable.tableName := tableName;
   // SQL Server: dbo.table -> table
   if (Pos('dbo.', LowerCase(tableName)) = 1) then
    TETTable.tableName := Copy(tableName, 5, Length(tableName)-4)
   else
   // table.db -> table
   if (Pos('.db', LowerCase(tableName)) > 0) then
    TETTable.tableName := Copy(tableName, 1, Length(tableName)-3)
   else
    TETTable.tableName := tableName;
   if (TETTable.Exists) then
    begin
      res := mrAll;
      if (bPrompt) then
       res := MessageDlg('Table '+AnsiQuotedStr(tableName,'"')+
      			' already exists. Do you want to overwrite it?',
      			mtConfirmation,[mbYes,mbNo,mbAll],0);
      if (res = mrNo) then
       begin
        ImportLog.Lines.Add('Table "'+tableName+'" skipped.'+#13#10);
        inc(j);
		    FormProgress.Indicator2.Progress := j;
		    Application.ProcessMessages;
        continue;
       end
      else
       if (res = mrAll) then
        bPrompt := false;
      TETTable.DeleteTable;
     end; // propmt

   // importtable from BDETable to TETTable
   try
    BDETable.Active := true;
    FormProgress.Label1.Caption := tableName;
    log := '';
    TETTable.AutoIndexes := cbAutoIndexes.Checked;
    TETTable.ImportTable(dsBDE,BDETable.IndexDefs,log);
    TETTable.Active := true;
    ImportLog.Lines.Add('Table '+AnsiQuotedStr(tableName,'"')+
    				' imported sucessfully. '+#13#10+
            'Record count in source BDE table: '+
            IntToStr(BDETable.recordCount)+#13#10+
            'Record count in destination EasyTable table: '+
            IntToStr(TETTable.recordCount)+#13#10);
    if (log <> '') then
     ImportLog.Lines.Add(log);
    TETTable.Active := false;
    BDETable.Active := false;
   except
    bOk := false;
    ImportLog.Lines.Add(log);
    try
     TETTable.DeleteTable;
    finally
     ImportLog.Lines.Add('Table '+AnsiQuotedStr(tableName,'"')+
    				' was not imported due to errors. Destination table deleted. Error log: '+log+#13#10);
    end;
   end;
   inc(j);
   FormProgress.Indicator2.Progress := j;
   Application.ProcessMessages;
  end;
 FormProgress.Close;
 if (not bOk) then
    ImportLog.Lines.Add('Errors occured while importing tables.')
 else
    ImportLog.Lines.Add('All tables imported successfully.');
end
else
begin
// export
 if (rbDestAlias.Checked) then
   ImportLog.Lines.Add('Exporting tables to BDE alias "'+
	    BDEDestAlias.Items[BDEDestAlias.ItemIndex]+'" ...'+#13#10)
 else
   ImportLog.Lines.Add('Exporting tables to BDE directory "'+
	    BDEDestDir.Directory+'" ...'+#13#10);

 log := '';
 try
   EasyDB.DatabaseFileName := TETSource.FileName;
   EasyDB.Connected := true;
 except
   MessageDlg('Error opening database file '+
    AnsiQuotedStr(TETSource.FileName,'"')+'.',mtError,[mbOk],0);
    TETSource.FileName := '';
   SetNewPage(5);
   Exit;
 end;
 // show progress
 FormProgress.Indicator.Progress := 0;
 FormProgress.Indicator2.Progress := 0;
 FormProgress.Indicator2.MaxValue := TETSourceTables.SelCount;
 FormProgress.Caption := 'Exporting tables to BDE ... ';
 FormProgress.Show;
 BDETable.Active := false;
 TETTable.Active := false;
 if (rbDestAlias.Checked) then
  BDETable.DatabaseName := BDEDestAlias.Items[BDEDestAlias.ItemIndex]
 else
  BDETable.DatabaseName := BDEDestDir.Directory;
 TETTable.OnProgress := FormProgress.SetIndicator;
 bPrompt := true;
 bOk := true;
 j := 0;
 bRun := true;
 bStop := false;
 // converting tabled
 for i := 0 to TETSourceTables.Items.Count-1 do
  begin
   if (not TETSourceTables.Selected[i]) then continue;
   if (bStop) then
    begin
     ImportLog.Lines.Add('Export operation cancelled by user.');
     Application.ProcessMessages;
     bRun := false;
     Exit;
    end;

   BDETable.Active := false;
   TETTable.Active := false;
   tableName := TETSourceTables.Items.Strings[i];
   BDETable.tableName := tableName;
   TETTable.tableName := tableName;
   if (BDETable.Exists) then
    begin
      res := mrAll;
      if (bPrompt) then
       res := MessageDlg('Table '+AnsiQuotedStr(tableName,'"')+
      			' already exists. Do you want to overwrite it?',
      			mtConfirmation,[mbYes,mbNo,mbAll],0);
      if (res = mrNo) then
       begin
        ImportLog.Lines.Add('Table "'+tableName+'" skipped.'+#13#10);
        inc(j);
		    FormProgress.Indicator2.Progress := j;
		    Application.ProcessMessages;
        continue;
       end
      else
       if (res = mrAll) then
        bPrompt := false;
      BDETable.DeleteTable;
     end; // propmt

   // export table from TETTable to BDE Table
   TETTable.Password := '';
   if (not OpenTable) then
   begin
    bOk := false;
    ImportLog.Lines.Add('Table '+AnsiQuotedStr(tableName,'"')+
    				' was not exported due to open failure. Destination table was not created. '+log+#13#10);
   end
   else
   try
    FormProgress.Label1.Caption := tableName;
    log := '';
    TETTable.ExportTable(dsBDE, BDETable.IndexDefs,CreateBDETable, log, (BDETable.TableType = ttDefault));
    BDETable.Active := true;
    ImportLog.Lines.Add('Table '+AnsiQuotedStr(tableName,'"')+
    				' exported sucessfully. '+#13#10+
            'Record count in source EasyTable table: '+
            IntToStr(TETTable.recordCount)+#13#10+
            'Record count in destination BDE table: '+
            IntToStr(BDETable.recordCount)+#13#10);
    TETTable.Active := false;
    BDETable.Active := false;
   except
    bOk := false;
    try
     BDETable.DeleteTable;
    finally
     ImportLog.Lines.Add('Table '+AnsiQuotedStr(tableName,'"')+
    				' was not exported due to errors. Destination table deleted. Error log: '+log+#13#10);
    end;
   end;
   inc(j);
   FormProgress.Indicator2.Progress := j;
   Application.ProcessMessages;
  end;
 FormProgress.Close;
 if (not bOk) then
    ImportLog.Lines.Add('Errors occured while exporting tables.')
 else
    ImportLog.Lines.Add('All tables exported successfully.');
end; // export

 btnNext.Enabled := true;
 bRun := false;
end;

procedure TMainForm.hyperlinkMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
 commandline : string;
begin
 commandline:='mailto:'+hyperlink.caption;
 ShellExecute(Handle,'Open',pchar(commandline),Nil,nil,SW_SHOWNORMAL);

end;

procedure TMainForm.AidAimHLinkMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
 commandline : string;
begin
 commandline:='http://'+AidAimHLink.caption;
 ShellExecute(Handle,'Open',pchar(commandline),Nil,nil,SW_SHOWNORMAL);
end;

procedure TMainForm.BDEDestDirChange(Sender: TObject);
begin
 if (rbDestDir.Checked) then
  if  (DirectoryExists(BDEDestDir.Directory))  then
   btnNext.Enabled := true
  else
   btnNext.Enabled := false;
end;

procedure TMainForm.TETSourceTablesClick(Sender: TObject);
begin
 if (TETSourceTables.SelCount > 0) then
  btnNext.Enabled := true
 else
  btnNext.Enabled := false;
end;

procedure TMainForm.rbDestAliasClick(Sender: TObject);
begin
 if (rbDestAlias.Checked) then
  begin
   rbDestDir.Checked := false;
   BDEDestDir.Enabled := false;
   BDEDestDrive.Enabled := false;
   BDEDestAlias.Enabled := true;
   BDEDestAliasClick(nil);
  end
 else
  begin
   BDEDestDir.Enabled := true;
   BDEDestDrive.Enabled := true;
   BDEDestAlias.Enabled := false;
   rbDir.Checked := true;
   BDEDestDirChange(nil);
  end;
end;

procedure TMainForm.rbDestDirClick(Sender: TObject);
begin
 if (rbDestDir.Checked) then
  begin
   rbDestAlias.Checked := false;
   BDEDestDir.Enabled := true;
   BDEDestDrive.Enabled := true;
   BDEDestAlias.Enabled := false;
   BDEDestDirChange(nil);
  end
 else
  begin
   BDEDestDir.Enabled := false;
   BDEDestDrive.Enabled := false;
   BDEDestAlias.Enabled := true;
   rbAlias.Checked := true;
   BDEDestAliasClick(nil);
  end;
end;

procedure TMainForm.TETSourceDirChange(Sender: TObject);
begin
 TETSourceChange(nil);
end;

procedure TMainForm.TETSourceChange(Sender: TObject);
begin
 btnNext.Enabled := false;
 TETSourceTables.Items.Clear;
 if (FileExists(TETSource.FileName)) then
 begin
  EasyDB.Connected := false;
  EasyDB.DatabaseFileName := TETSource.FileName;
  try
   EasyDB.Connected := true;
   TETTable.GetTableNameList(TETSourceTables.Items);
   EasyDB.Connected := false;
  except
   MessageDlg('Invalid file selected.',mtError,[mbOk],0);
   EasyDB.Connected := false;
  end;
 end;
 TETSourceTablesClick(nil);
end;

procedure TMainForm.BDEDestAliasClick(Sender: TObject);
var sl: TStringList;
begin
 if (BDEDestAlias.ItemIndex < 0)  then
  begin
   if (rbDestAlias.Checked) then
    btnNext.Enabled := false;
   Exit;
  end;

 sl := TStringList.Create;
 btnNext.Enabled := false;
 try
  BDETable.Active := false;
  DBTables.Session.GetTableNames(BDEDestAlias.Items[BDEDestAlias.ItemIndex],
												 '',True,True,sl);
  btnNext.Enabled := true;
  sl.Free;
 except
  MessageDlg('Can not connect to alias "'+BDEDestAlias.Items[BDEDestAlias.ItemIndex]+'"',mtError,
  	[mbOk],0);
  sl.Free;
 end;
end;

end.
