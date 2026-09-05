unit MainUnit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, FileCtrl, Buttons, Db, EasyTable, ProgressIndicator;

type
  TMainForm = class(TForm)
    srcTable: TEasyTable;
    destTable: TEasyTable;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    bnOK: TBitBtn;
    BitBtn2: TBitBtn;
    GroupBox3: TGroupBox;
    DriveList: TDriveComboBox;
    DirList: TDirectoryListBox;
    FileList: TFileListBox;
    cbOverwrite: TCheckBox;
    Label1: TLabel;
    bnOpen: TButton;
    DatabaseFile: TEdit;
    bnCreate: TButton;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    DestDB: TEasyDatabase;
    GroupBox4: TGroupBox;
    Label8: TLabel;
    AidAimHLink: TLabel;
    hyperlink: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    procedure BitBtn2Click(Sender: TObject);
    procedure AidAimHLinkMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure HyperlinkMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure bnOKClick(Sender: TObject);
    procedure bnCreateClick(Sender: TObject);
    procedure bnOpenClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.DFM}

Function ShellExecute(hWnd:HWND;lpOperation:Pchar;lpFile:Pchar;lpParameter:Pchar;
                      lpDirectory:Pchar;nShowCmd:Integer):Thandle; Stdcall;
External 'Shell32.Dll' name 'ShellExecuteA';

procedure TMainForm.BitBtn2Click(Sender: TObject);
begin
 Close;
end;

procedure TMainForm.AidAimHLinkMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
 commandline : string;
begin
 commandline:='http://'+AidAimHLink.caption;
 ShellExecute(Handle,'Open',pchar(commandline),Nil,nil,SW_SHOWNORMAL);
end;

procedure TMainForm.HyperlinkMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
 commandline : string;
begin
 commandline:='mailto:'+hyperlink.caption;
 ShellExecute(Handle,'Open',pchar(commandline),Nil,nil,SW_SHOWNORMAL);
end;

procedure TMainForm.bnOKClick(Sender: TObject);
var i,j: Integer;
 		fileName,tableName: string;
    bPrompt: Boolean;
    res: Word;
    log: string;
begin
 if (not FileExists(DatabaseFile.Text)) then
  begin
   MessageDlg('You should specify existing database file before start converting.',mtWarning,[mbOk],0);
   Exit;
  end;
 if (FileList.SelCount <= 0) then
  begin
   MessageDlg('You should select some tables for converting.',mtWarning,[mbOk],0);
   Exit;
  end;
   try
    DestDB.Connected := true;
   except
    MessageDlg('Error opening database file '+
	   AnsiQuotedStr(DatabaseFile.Text,'''')+'.',mtError,[mbOk],0);
    DatabaseFile.Text := '';
   end;
 FormProgress.Indicator.Progress := 0;
 FormProgress.Indicator2.Progress := 0;
 FormProgress.Indicator2.MaxValue := FileList.SelCount;
 FormProgress.Show;
 log := '';
 srcTable.Active := false;
 srcTable.OnProgress := FormProgress.SetIndicator;
 srcTable.DatabaseName := DirList.Directory;
 destTable.Active := false;
 bPrompt := true;
 if (cbOverwrite.Checked) then
  bPrompt := false;
 j := 0;
 // converting tabled
 for i := 0 to FileList.Items.Count-1 do
  begin
   if (not FileList.Selected[i]) then continue;
   fileName := DirList.Directory+'\'+FileList.Items.Strings[i];
   tableName := FileList.Items.Strings[i];
   srcTable.Active := false;
   srcTable.TableName := tableName;
   destTable.TableName := tableName;
   if (bPrompt) then
    if (destTable.Exists) then
     begin
      res := MessageDlg('Table '+AnsiQuotedStr(tableName,'''')+
      			' already exists. Do you want to overwrite it?',
      			mtConfirmation,[mbYes,mbNo,mbAll],0);
      if (res = mrNo) then
       begin
        inc(j);
		    FormProgress.Indicator2.Progress := j;
		    Application.ProcessMessages;
        continue;
       end
      else
       if (res = mrAll) then
        bPrompt := false;
      destTable.DeleteTable;
     end; // propmt
   // copy table from srcTable to destTable
   try
    FormProgress.Label1.Caption := tableName;
    srcTable.CopyTable(tableName,destTable.DatabaseName);
   except
    try
     destTable.DeleteTable;
    finally
     log := log + 'Table '+AnsiQuotedStr(tableName,'''')+
    				' was not converted due to errors.'+#13#10;
    end;
   end;
   inc(j);
   FormProgress.Indicator2.Progress := j;
   Application.ProcessMessages;
  end;
 FormProgress.Close;
 if (log <> '') then
    MessageDlg('Errors occured while converting table to database file '+
	   AnsiQuotedStr(DatabaseFile.Text,'''')+': '+#13#10+log,mtWarning,[mbOk],0)
 else
    MessageDlg('All tables converted successfully.',mtInformation,[mbOk],0);
end;

procedure TMainForm.bnCreateClick(Sender: TObject);
begin
 SaveDialog1.InitialDir := DirList.Directory;
 if (SaveDialog1.Execute) then
  begin
   DatabaseFile.Text := SaveDialog1.FileName;
   DestTable.Active := false;
   DestDB.Connected := false;
   DestDB.DatabaseFileName := DatabaseFile.Text;
   try
    DestDB.CreateDatabase;
   except
    MessageDlg('Error creating database file '+
	   AnsiQuotedStr(DatabaseFile.Text,'''')+'.',mtError,[mbOk],0);
    DatabaseFile.Text := '';
   end;
  end;
end;

procedure TMainForm.bnOpenClick(Sender: TObject);
begin
 OpenDialog1.InitialDir := DirList.Directory;
 if (OpenDialog1.Execute) then
  begin
   DatabaseFile.Text := OpenDialog1.FileName;
   DestTable.Active := false;
   DestDB.Connected := false;
   DestDB.DatabaseFileName := DatabaseFile.Text;
   try
    DestDB.Connected := true;
   except
    MessageDlg('Error opening database file '+
	   AnsiQuotedStr(DatabaseFile.Text,'''')+'.',mtError,[mbOk],0);
    DatabaseFile.Text := '';
   end;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
 Caption := 'Converter from EasyTable 2.xx to 3.0, AidAim Software, 2002';
end;

end.
