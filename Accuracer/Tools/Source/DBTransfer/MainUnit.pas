unit MainUnit;

interface

{$I ver.inc}

uses
  Windows, db, DBTables, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, StdCtrls,  ACRMain, ACRComMain, FileCtrl, ProgressIndicator, ACRTypes
  ,DBLogDlg;

type
  TMainForm = class(TForm)
    Bevel1: TBevel;
    btnCancel: TButton;
    btnPrev: TButton;
    btnNext: TButton;
    Panel2: TPanel;
    Notebook1: TNotebook;
    ACRtable: TACRTable;
    dsACR: TDataSource;
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
    ACRDB: TACRDatabase;
    DriveComboBox1: TDriveComboBox;
    ACRDestDir: TDirectoryListBox;
    Label4: TLabel;
    ACRDest: TFileListBox;
    SaveDialog1: TSaveDialog;
    Label12: TLabel;
    Label13: TLabel;
    hyperlink: TLabel;
    Label14: TLabel;
    AidAimHLink: TLabel;
    ACRSourceTables: TListBox;
    Label5: TLabel;
    rbDestDir: TRadioButton;
    rbDestAlias: TRadioButton;
    BDEDestAlias: TListBox;
    BDEDestDrive: TDriveComboBox;
    BDEDestDir: TDirectoryListBox;
    Label6: TLabel;
    ACRSourceDir: TDirectoryListBox;
    ACRSourceDrive: TDriveComboBox;
    Label1: TLabel;
    ACRSource: TFileListBox;
    Label7: TLabel;
    Label9: TLabel;
    Label8: TLabel;
    Label10: TLabel;
    cbTransaction: TCheckBox;
    Label11: TLabel;
    cbCreateNewDB: TCheckBox;
    ACRDestFileName: TEdit;
    BDETable: TTable;
    BDEdb: TDatabase;
    procedure FormCreate(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnPrevClick(Sender: TObject);
    procedure btnNextClick(Sender: TObject);
    procedure rbAliasClick(Sender: TObject);
    procedure rbDirClick(Sender: TObject);
    procedure BDESourceDirChange(Sender: TObject);
    procedure BDESourceAliasClick(Sender: TObject);
    procedure BDESourceTablesClick(Sender: TObject);
    procedure ACRDestChange(Sender: TObject);
    procedure ACRDestDirChange(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure hyperlinkMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure AidAimHLinkMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure BDEDestDirChange(Sender: TObject);
    procedure ACRSourceTablesClick(Sender: TObject);
    procedure rbDestAliasClick(Sender: TObject);
    procedure rbDestDirClick(Sender: TObject);
    procedure ACRSourceDirChange(Sender: TObject);
    procedure ACRSourceChange(Sender: TObject);
    procedure BDEDestAliasClick(Sender: TObject);
    procedure ACRtableProgress(Sender: TComponent; Progress: Double;
      Operation: TACRTableOperation; var Abort: Boolean);
    procedure cbCreateNewDBClick(Sender: TObject);
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
   ACRDestChange(nil);
  end;
 3:
  begin
   btnNext.Caption := '&Finish';
   btnPrev.Enabled := true;
   btnNext.Visible := true;
   btnNext.Enabled := false;
   ImportLog.Clear;
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
   if (FileExists(ACRSource.FileName)) and (ACRSourceTables.SelCount > 0) then
    btnNext.Enabled := true
   else
    btnNext.Enabled := false;
  end;
 end;
 Notebook1.PageIndex := pageNo;
end;


procedure TMainForm.FormCreate(Sender: TObject);
begin
 // read in the alias names from the default BDE session object
 BDEdb.Session.GetAliasNames(BDESourceAlias.Items);
 BDEdb.Session.GetAliasNames(BDEDestAlias.Items);
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
  begin
    BDETable.DatabaseName := BDESourceDir.Directory;
    DBTables.Session.GetTableNames(BDETable.DatabaseName,
                           '',True,True,BDESourceTables.Items);
  end;
 BDESourceTablesClick(nil);
end;

procedure TMainForm.BDESourceAliasClick(Sender: TObject);
begin
 if (rbAlias.Checked) then
  begin
   BDEdb.Close;
   BDEDb.AliasName := BDESourceAlias.Items[BDESourceAlias.ItemIndex];
   BDEdb.Open;
   BDETable.DatabaseName := BDEdb.DatabaseName;
//   BDEdb.GetTableNames(BDESourceTables.Items,True);

  BDEdb.Session.GetTableNames(BDEdb.AliasName,'',True,True,BDESourceTables.Items);
{
    DBTables.Session.GetTableNames(BDESourceAlias.Items[BDESourceAlias.ItemIndex],
                           '',True,True,BDESourceTables.Items);
}
  end;
 BDESourceTablesClick(nil);
end;

procedure TMainForm.BDESourceTablesClick(Sender: TObject);
begin
 if (BDESourceTables.SelCount > 0) then
  begin
   ACRDestDir.Directory := BDESourceDir.Directory;
   btnNext.Enabled := true;
  end
 else
  btnNext.Enabled := false;
end;

procedure TMainForm.ACRDestChange(Sender: TObject);
begin
 btnNext.Enabled := false;
 if (FileExists(ACRDest.FileName)) then
 begin
  ACRDB.Connected := false;
  ACRDB.DatabaseFileName := ACRDest.FileName;
  try
   if (cbCreateNewDB.Checked) then
    ACRDB.CreateDatabase;
   ACRDB.Connected := true;
   ACRDB.Connected := false;
   btnNext.Enabled := true;
  except
   MessageDlg('Invalid file selected.',mtError,[mbOk],0);
   ACRDB.Connected := false;
  end;
 end;
end;

procedure TMainForm.ACRDestDirChange(Sender: TObject);
begin
 ACRDestChange(nil);
end;

procedure TMainForm.Button2Click(Sender: TObject);
begin
 SaveDialog1.InitialDir := ExtractFilePath(Application.Exename);
 if (SaveDialog1.Execute) then
  ImportLog.Lines.SaveToFile(SaveDialog1.FileName);
end;

   procedure CreateBDETable;
   begin
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
begin
 result := false;
{
 if (not ACRTable.IsTableEncrypted) then
  begin
}
   try
    ACRTable.Active := true;
   except
    Exit;
   end;
   result := true;
   Exit;
{
  end;
 name := '';
 repeat
  try
   name:= InputBox('Table "'+ACRTable.TableName+'" authentification','Enter password: ', '');
   if (name = '') then Exit;
   ACRTable.Password := name;
   ACRTable.Active := true;
   f := true;
  except
   f := false;
   if (MessageDlg('Invalid password. Do you want to try again?',mtConfirmation,[mbYes,mbNo],0) <> mrYes) then
    begin
     ACRTable.Active := false;
     Exit;
    end;
  end;
 until f;
 result := true;
}
end;


 procedure ImportIndexes;
 var i:    Integer;
     d:    Double;
     name: String;
 begin
   for i := 0 to BDETable.IndexDefs.Count-1 do
    begin
     try
       name := BDETable.IndexDefs[i].Name;
       if (name = '') then
        name := 'Primary_Key';
       ACRtable.IndexDefs.Update;
       while (ACRtable.IndexDefs.IndexOf(name) >= 0) do
        name := GetTemporaryName(name);
       ACRtable.AddIndex(name,BDETable.IndexDefs[i].Fields,BDETable.IndexDefs[i].Options,BDETable.IndexDefs[i].DescFields,BDETable.IndexDefs[i].CaseInsFields);
     except
      ;
     end;
     d := (i+1) * 100 / BDETable.IndexDefs.Count;
     FormProgress.SetIndicator(ACRTable,d);
    end;
 end; // ImportIndexes

begin
 ImportLog.Lines.Clear;
 ImportLog.Lines.Add('System date: '+DateTimeToStr(now)+#13#10);
if (rgAction.ItemIndex = 0) then
begin
// import
 if (rbAlias.Checked) then
   ImportLog.Lines.Add('Importing tables from BDE alias "'+
	    BDESourceAlias.Items[BDESourceAlias.ItemIndex]+'" ...')
 else
   ImportLog.Lines.Add('Importing tables from BDE directory "'+
	    BDESourceDir.Directory+'" ...');

 log := '';
 if (cbCreateNewDB.Checked) then
  begin
   ACRDB.DatabaseFileName := ACRDestDir.Directory + '\' + ACRDestFileName.Text;
   if (ACRDB.Exists) then
    begin
     MessageDlg('Error creating database file '+
      AnsiQuotedStr(ACRDB.DatabaseFileName,'"')+' - file already exists.',mtError,[mbOk],0);
     SetNewPage(2);
     Exit;
    end;
   try
     ACRDB.CreateDatabase;
     ACRDB.Open;
   except
     on e: Exception do
      begin
       MessageDlg('Error creating database file '+
        AnsiQuotedStr(ACRDB.DatabaseFileName,'"')+': '+e.Message,mtError,[mbOk],0);
       SetNewPage(2);
       Exit;
      end;
   end;
  end
 else
  try
   ACRDB.DatabaseFileName := ACRDest.FileName;
   ACRDB.Connected := true;
  except
   MessageDlg('Error opening database file '+
    AnsiQuotedStr(ACRDest.FileName,'"')+'.',mtError,[mbOk],0);
    ACRDest.FileName := '';
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
 ACRTable.Active := false;
{
 if (rbAlias.Checked) then
  begin
   if (not BDEdb.Connected) or (BDEdb.AliasName <> BDESourceAlias.Items[BDESourceAlias.ItemIndex]) then
    begin
     BDEdb.Close;
     BDEDb.AliasName := BDESourceAlias.Items[BDESourceAlias.ItemIndex];
     BDEdb.Open;
    end;
  end
 else
  if (not BDEdb.Connected) then
   begin
    BDEdb.Directory := BDESourceDir.Directory;
    BDEdb.Open;
//   BDETable.DatabaseName := BDESourceDir.Directory;
   end;
}
// ACRTable.OnProgress := FormProgress.SetIndicator;
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
   ACRTable.Active := false;
   tableName := BDESourceTables.Items.Strings[i];
   BDETable.tableName := tableName;
   // SQL Server: dbo.table -> table
   if (Pos('dbo.', LowerCase(tableName)) = 1) then
    ACRTable.tableName := Copy(tableName, 5, Length(tableName)-4)
   else
   // table.db -> table
   if (Pos('.dbf', LowerCase(tableName)) > 0) then
    ACRTable.tableName := Copy(tableName, 1, Length(tableName)-4)
   else
   // table.db -> table
   if (Pos('.db', LowerCase(tableName)) > 0) then
    ACRTable.tableName := Copy(tableName, 1, Length(tableName)-3)
   else
    ACRTable.tableName := tableName;
   if (ACRTable.Exists) then
    begin
      res := mrAll;
      if (bPrompt) then
       res := MessageDlg('Table '+AnsiQuotedStr(ACRTable.tableName,'"')+
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
      ACRTable.DeleteTable;
     end; // propmt

   // importtable from BDETable to ACRTable
   try
    BDETable.Exclusive := False;
    BDETable.Active := true;
    FormProgress.Label1.Caption := tableName;
    log := '';
    if (cbTransaction.Checked) then
     ACRDB.StartTransaction;
    try
      ACRTable.ImportTable(BDETable,log);
    finally
     if (cbTransaction.Checked) then
      ACRDB.Commit;
    end;
    ACRTable.Active := true;
    ImportLog.Lines.Add('System date: '+DateTimeToStr(now)+#13#10);
    if (BDETable.IndexDefs.Count > 0) then
     begin
      ImportLog.Lines.Add('Importing indexes from table '+AnsiQuotedStr(tableName,'"')+' ...');
      Application.ProcessMessages;
      ImportIndexes;
      ACRtable.IndexDefs.Update;
      ImportLog.Lines.Add('Indexes imported: '+IntToStr(ACRtable.IndexDefs.Count)+' from '+IntToStr(BDETable.IndexDefs.Count));
      ImportLog.Lines.Add('System date: '+DateTimeToStr(now)+#13#10);
      Application.ProcessMessages;
     end;
    ImportLog.Lines.Add('Table '+AnsiQuotedStr(tableName,'"')+
    				' imported sucessfully. '+#13#10+
            'Record count in source BDE table: '+
            IntToStr(BDETable.recordCount)+#13#10+
            'Record count in destination ACRTable table: '+
            IntToStr(ACRTable.recordCount)+#13#10);
    if (log <> '') then
     ImportLog.Lines.Add(log);
    ACRTable.Active := false;
    BDETable.Active := false;
   except
    on e: Exception do
     begin
      bOk := false;
      FormProgress.Hide;
      ImportLog.Lines.Add(log);
      try
       ACRTable.DeleteTable;
      finally
       ImportLog.Lines.Add('Table '+AnsiQuotedStr(tableName,'"')+
              ' was not imported due to errors. Destination table deleted.'
              +'Error message: '+e.Message+#13#10+'Error log: '+log+#13#10);
      end;
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
   ACRDB.DatabaseFileName := ACRSource.FileName;
   ACRDB.Connected := true;
 except
   MessageDlg('Error opening database file '+
    AnsiQuotedStr(ACRSource.FileName,'"')+'.',mtError,[mbOk],0);
    ACRSource.FileName := '';
   SetNewPage(5);
   Exit;
 end;
 // show progress
 FormProgress.Indicator.Progress := 0;
 FormProgress.Indicator2.Progress := 0;
 FormProgress.Indicator2.MaxValue := ACRSourceTables.SelCount;
 FormProgress.Caption := 'Exporting tables to BDE ... ';
 FormProgress.Show;
 BDETable.Active := false;
 ACRTable.Active := false;
{
 if (rbDestAlias.Checked) then
  begin
   if (not BDEdb.Connected) or (BDEdb.AliasName <> BDEDestAlias.Items[BDEDestAlias.ItemIndex]) then
    begin
     BDEdb.Close;
     BDEdb.AliasName := BDEDestAlias.Items[BDEDestAlias.ItemIndex];
     BDEdb.Open;
    end;
  end
 else
  begin
   BDEdb.Close;
   BDEdb.Directory := BDEDestDir.Directory;
   BDEdb.Open;
  end;
}  
// ACRTable.OnProgress := FormProgress.SetIndicator;
 bPrompt := true;
 bOk := true;
 j := 0;
 bRun := true;
 bStop := false;
 // converting tabled
 for i := 0 to ACRSourceTables.Items.Count-1 do
  begin
   if (not ACRSourceTables.Selected[i]) then continue;
   if (bStop) then
    begin
     ImportLog.Lines.Add('Export operation cancelled by user.');
     Application.ProcessMessages;
     bRun := false;
     Exit;
    end;

   BDETable.Active := false;
   ACRTable.Active := false;
   tableName := ACRSourceTables.Items.Strings[i];
   BDETable.tableName := tableName;
   ACRTable.tableName := tableName;
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
      try
       BDETable.Exclusive := True;
       BDETable.DeleteTable;
       BDETable.Exclusive := False;
      except
       BDETable.Exclusive := False;
      end;
     end; // propmt

   // export table from ACRTable to BDE Table
//   ACRTable.Password := '';
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
//    ACRTable.ExportTable(dsBDE, BDETable.IndexDefs,CreateBDETable, log, (BDETable.TableType = ttDefault));
//    BDETable.Active := true;
    ACRTable.ExportTable(BDETable, CreateBDETable, log);
    BDETable.First;
    ImportLog.Lines.Add('Table '+AnsiQuotedStr(tableName,'"')+
    				' exported sucessfully. '+#13#10+
            'Record count in source ACRTable table: '+
            IntToStr(ACRTable.recordCount)+#13#10+
            'Record count in destination BDE table: '+
            IntToStr(BDETable.recordCount)+#13#10);
    ACRTable.Active := false;
    BDETable.Active := false;
   except
    on e: Exception do
     begin
      bOk := false;
      FormProgress.Hide;
      try
       if (BDETable.Exists) then
        begin
         BDETable.Active := false;
         BDETable.DeleteTable;
        end;
      finally
       ImportLog.Lines.Add('Table '+AnsiQuotedStr(tableName,'"')+
              ' was not exported due to errors. Destination table deleted. Error message: '
              +#13#10+e.Message+#13#10+'Error log: '+log+#13#10);
      end;
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
   begin
    btnNext.Enabled := true;
    BDETable.DatabaseName := BDEDestDir.Directory;
   end
  else
   btnNext.Enabled := false;
end;

procedure TMainForm.ACRSourceTablesClick(Sender: TObject);
begin
 if (ACRSourceTables.SelCount > 0) then
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

procedure TMainForm.ACRSourceDirChange(Sender: TObject);
begin
 ACRSourceChange(nil);
end;

procedure TMainForm.ACRSourceChange(Sender: TObject);
begin
 btnNext.Enabled := false;
 ACRSourceTables.Items.Clear;
 if (FileExists(ACRSource.FileName)) then
 begin
  ACRDB.Connected := false;
  ACRDB.DatabaseFileName := ACRSource.FileName;
  try
   ACRDB.Connected := true;
//   ACRTable.GetTableNameList(ACRSourceTables.Items);
   ACRDB.GetTablesList(ACRSourceTables.Items);
   ACRDB.Connected := false;
  except
   MessageDlg('Invalid file selected.',mtError,[mbOk],0);
   ACRDB.Connected := false;
  end;
 end;
 ACRSourceTablesClick(nil);
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
  BDEdb.Close;
  BDEdb.AliasName := BDEDestAlias.Items[BDEDestAlias.ItemIndex];
  BDEdb.Open;
  BDETable.DatabaseName := BDEdb.DatabaseName;
//   BDEdb.GetTableNames(sl,True);
{
  DBTables.Session.GetTableNames(BDEDestAlias.Items[BDEDestAlias.ItemIndex],
												 '',True,True,sl);
}
  btnNext.Enabled := true;
  sl.Free;
 except
  MessageDlg('Can not connect to alias "'+BDEDestAlias.Items[BDEDestAlias.ItemIndex]+'"',mtError,
  	[mbOk],0);
  sl.Free;
 end;
end;

procedure TMainForm.ACRtableProgress(Sender: TComponent; Progress: Double;
  Operation: TACRTableOperation; var Abort: Boolean);
begin
 FormProgress.Indicator.Progress := Round(Progress);
 FormProgress.Label1.Caption := TACRTable(Sender).TableName;
 Application.ProcessMessages;
end;

procedure TMainForm.cbCreateNewDBClick(Sender: TObject);
begin
 if (cbCreateNewDB.Checked) then
  btnNext.Enabled := True
 else
  if (not FileExists(ACRDest.FileName)) then
   btnNext.Enabled := False;
end;

end.
