unit DSNsetup;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, Buttons, ComCtrls, //Spin,
// added in v.3 for encrypted database support ********************************
  ACRTypes,
  ACRConst,
  ACRMemory,
// ****************************************************************************
  ACRMain;

type

  TaodbcInitVector = array [0..ACR_MAX_VECTOR] of Byte;

  TDSNManager = class (TComponent)
   public
    function GetIV(var IV: TaodbcInitVector; FileName: String): Boolean;
    function GetKey(var Key: TACRCryptoKey; FileName: String): Boolean;
    function ReadFromFile(var Buffer:PChar; FileName, Descript: String; CheckOnly: Boolean = False): Integer;
  end;

  TDSNsetupForm = class(TForm)
    OK: TBitBtn;
    Cancel: TBitBtn;
    Help: TBitBtn;
    DSN: TEdit;
    Description: TEdit;
    Dir: TBitBtn;
    DatabaseFile: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    SelectDatabase: TOpenDialog;
    Mode: TRadioGroup;
    ConnectParams: TGroupBox;
    Label4: TLabel;
    RemoteHost: TEdit;
    Label5: TLabel;
    RemotePort: TEdit;
    Label6: TLabel;
    LocalPort: TEdit;
    Label7: TLabel;
    DatabaseName: TEdit;
NetworkParams: TGroupBox;
DatabaseSettings: TGroupBox;
Label114: TLabel;
Label113: TLabel;
IsInitVector: TCheckBox;
cbMode: TComboBox;
cbAlgorithm: TComboBox;
EncryptPageControl: TPageControl;
BasicEncr: TTabSheet;
IsInitVector2: TCheckBox;
cbMode2: TComboBox;
cbAlgorithm2: TComboBox;
EncryptPageControl2: TPageControl;
BasicEncr2: TTabSheet;
Label112: TLabel;
Label117: TLabel;
tPassword: TEdit;
tRPassword: TEdit;
tPassword2: TEdit;
tRPassword2: TEdit;
AdvEncr: TTabSheet;
AdvEncr2: TTabSheet;
Label1111: TLabel;
    KeyFileName: TEdit;
    SelectKey: TButton;
    IVFileName: TEdit;
    SelectInitVector: TButton;
    SelectInitFile: TOpenDialog;
    SelectKeyFile: TOpenDialog;
    ACRDatabase1: TACRDatabase;
    KeyFileName2: TEdit;
    SelectKey2: TButton;
    IVFileName2: TEdit;
    SelectInitVector2: TButton;
    SelectInitFile2: TOpenDialog;
    SelectKeyFile2: TOpenDialog;
    Label8: TLabel;
    Label9: TLabel;
    CompressionAlgorithm: TComboBox;
    CompressionMode: TComboBox;
    procedure FormCreate(Sender: TObject);
    procedure DirClick(Sender: TObject);
    procedure CancelClick(Sender: TObject);
    procedure OKClick(Sender: TObject);
    procedure HelpClick(Sender: TObject);
    procedure ModeClick(Sender: TObject);
///////////////////////////////////////////////////////////////////////////////
    procedure IsInitVectorClick(Sender: TObject);
    procedure EncryptPageControlChange(Sender: TObject);
    procedure SelectKeyClick(Sender: TObject);
    procedure SelectInitVectorClick(Sender: TObject);
    procedure cbAlgorithmChange(Sender: TObject);
    function CheckPwd: Boolean;
    function CheckPwd2: Boolean;
    procedure IsInitVector2Click(Sender: TObject);
    procedure SelectKey2Click(Sender: TObject);
    procedure SelectInitVector2Click(Sender: TObject);
    procedure cbAlgorithm2Change(Sender: TObject);
  private
    FManager: TDSNManager;
  public
    Button: (btnOK, btnCancel);
  end;

var
  DSNsetupForm:   TDSNsetupForm;
  DSNManager:     TDSNManager;

implementation
{$R *.DFM}

///////////////////////////////////////////////////////////////////////////////
//
// TDSNManager
//
///////////////////////////////////////////////////////////////////////////////

function TDSNManager.GetKey(var Key: TACRCryptoKey; FileName: String): Boolean;
var
 buf:   PChar;
 size:  Integer;
begin
 Result := False;
 Key.KeySize := 0;
 if (FileName = '') then
   Exit;
 try
  size := ReadFromFile(buf, FileName, 'key');
  if (size = -1) then // error already shown
    Exit;
  if (size = 0) then // show error
   begin
    MessageDlg('Cannot create a key from empty file '+FileName+'!', mtWarning,[mbOk],0);
    Exit;
   end;
  try
   if (size > ACR_MAX_KEY) then
     size := ACR_MAX_KEY;
//WriteToLog('    TDSNManager.GetKey> Move...');
   move(buf^,Key.Key,size);
//WriteToLog('    OK');
   Key.KeySize := size;
   Result := True;
  finally
   MemoryManager.FreeAndNilMem(buf);
  end;
 except
  MessageDlg('Cannot create a key from file '+FileName+'!', mtWarning,[mbOk],0);
 end;
end;

function TDSNManager.GetIV(var IV: TaodbcInitVector; FileName: String): Boolean;
var
 buf:   PChar;
 size:  Integer;
begin
 Result := False;
 if (FileName = '') then
   Exit;
 try
  size := ReadFromFile(buf, FileName, 'initial vector');
  if (size = -1) then // error already shown
    Exit;
  try
   if (size > ACR_MAX_VECTOR) then
     size := ACR_MAX_VECTOR;
//WriteToLog('    TDSNManager.GetIV> Move...');
   move(buf^,IV,size);
//WriteToLog('    TDSNManager.GetIV> OK');
   Result := True;
  finally
   MemoryManager.FreeAndNilMem(buf);
  end;
 except
  MessageDlg('Cannot create an initial vector from file '+FileName+'!', mtWarning,[mbOk],0);
 end;
end;

function TDSNManager.ReadFromFile(var Buffer:PChar; FileName, Descript: String; CheckOnly: Boolean = False): Integer;
var
 f: Integer;
begin
 f := FileOpen(FileName,fmOpenRead+fmShareDenyWrite);
 if (f = -1) then
  begin
   Result := -1;
   MessageDlg('Cannot open '+Descript+' file '+FileName+'!', mtWarning,[mbOk],0);
   Exit;
  end;
 try
  if (CheckOnly) then
    Exit;
  Result := FileSeek(f,0,2);
  if (Result = 0) then // show error
   begin
    MessageDlg('Cannot create a '+Descript+' from the empty file '+FileName+'!', mtWarning,[mbOk],0);
    Exit;
   end
  else
  if (Result > 0) then
   begin
    Buffer := MemoryManager.AllocMem(Result);
    FileSeek(f,0,0);
    FileRead(f, Buffer^, Result);
   end;
 finally
  FileClose(f);
 end;
end;


///////////////////////////////////////////////////////////////////////////////
//
// TDSNsetupForm
//
///////////////////////////////////////////////////////////////////////////////

procedure TDSNsetupForm.FormCreate(Sender: TObject);
begin
  FManager := TDSNManager(Sender);
  Button:=BtnCancel;
end;

procedure TDSNsetupForm.DirClick(Sender: TObject);
begin
  if SelectDatabase.Execute then DatabaseFile.Text:=SelectDatabase.FileName;
end;

procedure TDSNsetupForm.CancelClick(Sender: TObject);
begin
  DSNsetupForm.Close;
end;

procedure TDSNsetupForm.OKClick(Sender: TObject);
begin
  case DSNsetupForm.Mode.ItemIndex of
  0: // Client/server
   begin
    if (RemoteHost.Text='')
    or (RemotePort.Text='')
    or (LocalPort.Text='')
    or (DatabaseName.Text='')
    or (DSN.Text='') then
     begin
      MessageDlg('You must enter Data Source Name, Database Name, Remote Host, Remote Port and Local Port!', mtWarning,[mbOk],0);
      Exit;
     end;
   end;
  1: // file-server
   begin
    if (DatabaseFile.Text='')
    or (DSN.Text='') then
     begin
      MessageDlg('You must enter Data Source Name and select your database file to specify Datasource Path!', mtWarning,[mbOk],0);
      Exit;
     end;
   end;
  end; // case
  if (cbAlgorithm.ItemIndex > 0) then
    if not CheckPwd then
      Exit;
  Button:=btnOK;
  DSNsetupForm.Close;
end;

procedure TDSNsetupForm.HelpClick(Sender: TObject);
begin
  MessageDlg('Enter your Data Source Name and select Mode, then specify Connection parameters.'+#10+#13+
  'Also you may edit a Description.', mtInformation,[mbOk],0)
end;

procedure TDSNsetupForm.ModeClick(Sender: TObject);
begin
  if Mode.ItemIndex = 0 then // Client/server
   begin
    Label3.Visible := False;
    DatabaseFile.Visible := False;
    Dir.Visible := False;
    Label4.Visible := True;
    RemoteHost.Visible := True;
    Label5.Visible := True;
    RemotePort.Visible := True;
    Label6.Visible := True;
    LocalPort.Visible := True;
    Label7.Visible := True;
    DatabaseName.Visible := True;
    ConnectParams.Height := DatabaseName.Top + DatabaseName.Height + RemoteHost.Top - 5;
    NetworkParams.Visible := True;
    NetworkParams.Top := ConnectParams.Top + ConnectParams.Height + 10;          // 13
    DatabaseSettings.Top := NetworkParams.Top + NetworkParams.Height + 10;       // 13
    DSNSetupForm.Height := DatabaseSettings.Top + DatabaseSettings.Height + 50;  // 52
   end
  else                       // File-server
   begin
    Label3.Visible := True;
    DatabaseFile.Visible := True;
    Dir.Visible := True;
    Label4.Visible := False;
    RemoteHost.Visible := False;
    Label5.Visible := False;
    RemotePort.Visible := False;
    Label6.Visible := False;
    LocalPort.Visible := False;
    Label7.Visible := False;
    DatabaseName.Visible := False;
    ConnectParams.Height := DatabaseFile.Top * 2 + DatabaseFile.Height - 4;
    NetworkParams.Visible := False;
    DatabaseSettings.Top := ConnectParams.Top + ConnectParams.Height + 10;       // 9
    DSNSetupForm.Height := DatabaseSettings.Top + DatabaseSettings.Height + 50;  // 51
   end;
end;

///////////////////////////////////////////////////////////////////////////////
procedure TDSNsetupForm.IsInitVectorClick(Sender: TObject);
begin
 if IsInitVector.Checked then
  begin
   IVFileName.Enabled := true;
   SelectInitVector.Enabled := true;
  end
 else
  begin
   IVFileName.Enabled := false;
   SelectInitVector.Enabled := false;
  end;
end;

procedure TDSNsetupForm.EncryptPageControlChange(Sender: TObject);
begin
{
 if EncryptPageControl.TabIndex=0 then
  begin
   for i := 0 to EncryptPageControl.Pages[0].ControlCount - 1 do
     EncryptPageControl.Pages[0].Controls[i].Enabled := true;
   for i := 0 to EncryptPageControl.Pages[1].ControlCount - 1 do
     EncryptPageControl.Pages[1].Controls[i].Enabled := false;
  end
 else
  begin
   for i := 0 to EncryptPageControl.Pages[1].ControlCount - 1 do
     EncryptPageControl.Pages[1].Controls[i].Enabled := true;
   for i := 0 to EncryptPageControl.Pages[0].ControlCount - 1 do
     EncryptPageControl.Pages[0].Controls[i].Enabled := false;
  end
}
end;

procedure TDSNsetupForm.SelectKeyClick(Sender: TObject);
var
 buf:  PChar;
 size: Integer;
begin
 SelectKeyFile.FileName := ExtractFileName(KeyFileName.Text);
 if SelectKeyFile.Execute then
  begin
   KeyFileName.Text:=SelectKeyFile.FileName;
   FManager.ReadFromFile(buf, KeyFileName.Text, 'key', true);
  end;
end;

procedure TDSNsetupForm.SelectInitVectorClick(Sender: TObject);
var
 buf:  PChar;
 size: Integer;
begin
 SelectInitFile.FileName := ExtractFileName(IVFileName.Text);
 if SelectInitFile.Execute then
  begin
   IVFileName.Text:=SelectInitFile.FileName;
   size := FManager.ReadFromFile(buf, IVFileName.Text, 'initial vector', true);
  end;
end;

procedure TDSNsetupForm.cbAlgorithmChange(Sender: TObject);
begin
 if (cbAlgorithm.ItemIndex = 0) then
  begin
   EncryptPageControl.Enabled := False;
   cbMode.Enabled := False;
   IsInitVector.Enabled := False;
  end
 else
  begin
   EncryptPageControl.Enabled := True;
   cbMode.Enabled := True;
   IsInitVector.Enabled := True;
  end;
end;

function TDSNsetupForm.CheckPwd: Boolean;
begin
 if (tPassword.Text <> tRPassword.Text) then
  begin
   Result := False;
   MessageDlg('Incorrect database password!', mtWarning,[mbOk],0);
  end
 else
   Result := True;
end;

function TDSNsetupForm.CheckPwd2: Boolean;
begin
 if (tPassword2.Text <> tRPassword2.Text) then
  begin
   Result := False;
   MessageDlg('Incorrect traffic encryption password!', mtWarning,[mbOk],0);
  end
 else
   Result := True;
end;

procedure TDSNsetupForm.cbAlgorithm2Change(Sender: TObject);
begin
 if (cbAlgorithm2.ItemIndex = 0) then
  begin
   EncryptPageControl2.Enabled := False;
   cbMode2.Enabled := False;
   IsInitVector2.Enabled := False;
  end
 else
  begin
   EncryptPageControl2.Enabled := True;
   cbMode2.Enabled := True;
   IsInitVector2.Enabled := True;
  end;
end;

procedure TDSNsetupForm.SelectKey2Click(Sender: TObject);
var
 buf:  PChar;
 size: Integer;
begin
 SelectKeyFile2.FileName := ExtractFileName(KeyFileName2.Text);
 if SelectKeyFile2.Execute then
  begin
   KeyFileName2.Text:=SelectKeyFile2.FileName;
   FManager.ReadFromFile(buf, KeyFileName2.Text, 'key', true);
  end;
end;

procedure TDSNsetupForm.SelectInitVector2Click(Sender: TObject);
var
 buf:  PChar;
 size: Integer;
begin
 SelectInitFile2.FileName := ExtractFileName(IVFileName2.Text);
 if SelectInitFile2.Execute then
  begin
   IVFileName2.Text:=SelectInitFile2.FileName;
   size := FManager.ReadFromFile(buf, IVFileName2.Text, 'initial vector', true);
  end;
end;

procedure TDSNsetupForm.IsInitVector2Click(Sender: TObject);
begin
 if IsInitVector2.Checked then
  begin
   IVFileName2.Enabled := true;
   SelectInitVector2.Enabled := true;
  end
 else
  begin
   IVFileName2.Enabled := false;
   SelectInitVector2.Enabled := false;
  end;
end;

end.

