unit MainUnit;

interface

{$I ver.inc}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, FileCtrl, Buttons, Db, ProgressIndicator, ACRMain, ACRConst,
  EasyTable;

type
  TMainForm = class(TForm)
    eTable: TEasyTable;
    eDB: TEasyDatabase;
    aTable: TACRTable;
    aDB: TACRDatabase;
    bnSelect: TBitBtn;
    OpenDialog1: TOpenDialog;
    eDBFile: TEdit;
    bnConvert: TBitBtn;
    GroupBox4: TGroupBox;
    Label8: TLabel;
    AidAimHLink: TLabel;
    hyperlink: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label2: TLabel;
    procedure AidAimHLinkMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure HyperlinkMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure bnSelectClick(Sender: TObject);
    procedure bnConvertClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    function OpenTable: Boolean;
    procedure aTableProgress(Sender: TComponent; Progress: Double;
      Operation: TACRTableOperation; var Abort: Boolean);
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

procedure TMainForm.bnSelectClick(Sender: TObject);
begin
 if (OpenDialog1.Execute) then
  begin
   eDBFile.Text := OpenDialog1.FileName;
   eDB.Connected := false;
  end;
end;

procedure TMainForm.bnConvertClick(Sender: TObject);
var i,j,n: Integer;
 		tableName: WideString;
    res: Word;
    log,s: AnsiString;
    bPrompt: Boolean;
    TablesList: TStringList;
begin
 eDB.Close;
 if (not FileExists(eDBFile.Text)) then
  begin
   MessageDlg('EasyTable database file '+
     AnsiQuotedStr(eDBFile.Text,'''')+' does not exist.',mtError,[mbOk],0);
   Exit;
  end;
 eDB.DatabaseFileName := eDBFile.Text;
 try
   eDB.Connected := true;
 except
   MessageDlg('Error opening EasyTable database file '+
     AnsiQuotedStr(eDB.DatabaseFileName,'''')+'.',mtError,[mbOk],0);
   Exit;
 end;

 aTable.Active := false;
 aDB.Connected := false;
 aDB.DatabaseFileName := ChangeFileExt(eDB.DatabaseFileName,ACRDatabaseFileExtension);
 try

   if aDB.Exists then
     aDB.DeleteDatabase;
   aDB.CreateDatabase;  
 except
   MessageDlg('Error creating Accuracer database file '+
     AnsiQuotedStr(aDB.DatabaseFileName,'''')+'.',mtError,[mbOk],0);
   Exit;
 end;
 try
   aDB.Connected := true;
 except
   MessageDlg('Error opening Accuracer database file '+
     AnsiQuotedStr(aDB.DatabaseFileName,'''')+'.',mtError,[mbOk],0);
   Exit;
 end;
 FormProgress.Indicator.Progress := 0;
 FormProgress.Indicator2.Progress := 0;
 TablesList := TStringList.Create;
 eDB.GetTablesList(TablesList);
 FormProgress.Indicator2.MaxValue := TablesList.Count;
 FormProgress.FCancel := False;
 FormProgress.Show;
 log := '';
 eTable.Active := false;
 aTable.Active := false;
 j := 0;
 bPrompt := True;
 // converting tabled
 for i := 0 to TablesList.Count-1 do
  begin
   Application.ProcessMessages;
   if (FormProgress.FCancel) then
    begin
     log := log + #13#10 + 'Convertation aborted.';
     break;
    end;
   tableName := TablesList.Strings[i];
   eTable.Active := false;
   eTable.TableName := tableName;
   aTable.TableName := tableName;
   if (bPrompt) then
    if (aTable.Exists) then
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
        bPrompt := False;
      aTable.DeleteTable;
     end; // propmt
   // copy table from eTable to aTable
   FormProgress.Label1.Caption := tableName;
   try
    if (OpenTable) then
     begin
      eTable.Open;
      if (aTable.ImportTable(eTable,s)) then
       begin
        aTable.Open;
        for n := 0 to eTable.IndexDefs.Count - 1 do
         begin
          if (eTable.IndexDefs.Items[n].Name[1] = '@') then
           if (Pos(';',eTable.IndexDefs.Items[n].Fields) = 0) then
            if (aTable.FieldDefs.IndexOf(eTable.IndexDefs.Items[n].Fields) = -1) then
             continue;
          aTable.AddIndex(eTable.IndexDefs.Items[n].Name,
            eTable.IndexDefs.Items[n].Fields,
            eTable.IndexDefs.Items[n].Options,
            eTable.IndexDefs.Items[n].DescFields,
            eTable.IndexDefs.Items[n].CaseInsFields);
         end;
        aTable.Close;
       end
      else
       log := log + 'Table '+AnsiQuotedStr(eTable.tableName,'''')+' was skipped ';

      eTable.Close;
     end
    else
     log := log + 'Table '+AnsiQuotedStr(eTable.tableName,'''')+' was skipped ';
   except
    try
     aTable.DeleteTable;
    finally
     log := log + 'Table '+AnsiQuotedStr(eTable.tableName,'''')+
    				' was not converted due to errors:'+s+#13#10;
    end;
   end;
   inc(j);
   FormProgress.Indicator2.Progress := j;
   Application.ProcessMessages;
  end;
 aDB.Close;
 eDB.DatabaseFileName := '';
 eDB.Close;
 FormProgress.Close;
 TablesList.Free;
 if (log <> '') then
    MessageDlg('Errors occured while converting table to database file '+
	   AnsiQuotedStr(eDBFile.Text,'''')+': '+#13#10+log,mtWarning,[mbOk],0)
 else
    MessageDlg('All the tables were converted successfully.',mtInformation,[mbOk],0);
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
 EDB.DatabaseFileName := '';
end;


function TMainForm.OpenTable: Boolean;
var s: string;
begin
 if (eTable.IsTableEncrypted) then
  begin
   s := '';
   repeat
    eTable.Password := InputBox(
                      'Open encrypted table',
                      'Enter password for table '+AnsiQuotedStr(eTable.TableName,''''),
                      s);
    if (eTable.Password = s) then
     break;
    try
      eTable.Open;
    except
      ;
    end;
   until (eTable.Active);
  end
 else
  eTable.Open; 
 Result := eTable.Active;
end;

procedure TMainForm.aTableProgress(Sender: TComponent; Progress: Double;
  Operation: TACRTableOperation; var Abort: Boolean);
begin
 Abort := FormProgress.FCancel;
 FormProgress.Label1.Caption := TACRTable(Sender).TableName;
 FormProgress.Indicator.Progress := Round(Progress);
 Application.ProcessMessages;
end;

end.
