unit uMain;

interface

{$I ver.inc}

uses
  ACRTypes,ACRMain,ACRComMain,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Grids, StdCtrls, ExtCtrls, Buttons, ComCtrls, ACRConst;

type
  TfmMain = class(TForm)
    tPassword: TEdit;
    edKeyfile: TEdit;
    edInitVectorfile: TEdit;
    Button2: TButton;
    Button3: TButton;
    Label6: TLabel;
    Label5: TLabel;
    Label2: TLabel;
    OpenDialog1: TOpenDialog;
    InitVectorGrid: TStringGrid;
    Label14: TLabel;
    KeyGrid: TStringGrid;
    Label13: TLabel;
    IsInitVector: TCheckBox;
    bnRestore: TButton;
    bnExit: TButton;
    Data: TACRDatabase;
    Label1: TLabel;
    Label8: TLabel;
    edDBFileName: TEdit;
    edBackupFileName: TEdit;
    Button1: TButton;
    Button6: TButton;
    OpenDialog2: TOpenDialog;
    SaveDialog1: TSaveDialog;
    Label3: TLabel;
    bnGetBackupInfo: TButton;
    reDesc: TRichEdit;
    Label4: TLabel;
    lbTables: TListBox;
    cbEncrypted: TCheckBox;
    Label7: TLabel;
    edFileSize: TEdit;
    Label9: TLabel;
    edFileDate: TEdit;
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure KeyGridGetEditMask(Sender: TObject; ACol, ARow: Integer;
      var Value: String);
    procedure InitVectorGridGetEditMask(Sender: TObject; ACol,
      ARow: Integer; var Value: String);
    procedure IsInitVectorClick(Sender: TObject);
    procedure InitVectorGridEnter(Sender: TObject);
    procedure edInitVectorfileEnter(Sender: TObject);
    procedure KeyGridEnter(Sender: TObject);
    procedure edKeyfileEnter(Sender: TObject);
    procedure bnExitClick(Sender: TObject);
    procedure bnRestoreClick(Sender: TObject);
    procedure EnableEncryptionControls(Encrypted,ByPassword: Boolean);
    procedure bnGetBackupInfoClick(Sender: TObject);
    procedure DataProgress(Sender: TComponent; Progress: Double;
      Operation: TACRDatabaseOperation; var Abort: Boolean);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }

  end;

var
  fmMain: TfmMain;
  FormsVisible : boolean;
  place : byte;

implementation

uses WorkGrids, ProgressCancel;

{$R *.dfm}


procedure TfmMain.Button2Click(Sender: TObject);
begin
 OpenDialog1.InitialDir := ExtractFilePath(edBackupFileName.Text);
 OpenDialog1.DefaultExt := '.key';
 OpenDialog1.Filter := 'Key file(*.key)|*.key|Any file(*.*)|*.*';
 if (OpenDialog1.Execute) then
  edKeyfile.Text := OpenDialog1.FileName;
end;

procedure TfmMain.Button3Click(Sender: TObject);
begin
 OpenDialog1.InitialDir := ExtractFilePath(edBackupFileName.Text);
 OpenDialog1.DefaultExt := '.iv';
 OpenDialog1.Filter := 'InitVector file(*.iv)|*.iv|Any file(*.*)|*.*';
 if (OpenDialog1.Execute) then
  edInitVectorfile.Text := OpenDialog1.FileName;
end;

procedure TfmMain.KeyGridGetEditMask(Sender: TObject; ACol,
  ARow: Integer; var Value: String);
begin
 Value := 'AA';
end;

procedure TfmMain.InitVectorGridGetEditMask(Sender: TObject; ACol,
  ARow: Integer; var Value: String);
begin
 Value := 'AA';
end;

procedure TfmMain.IsInitVectorClick(Sender: TObject);
begin
 if IsInitVector.Checked then
  begin
   Label14.Enabled := true;
   InitVectorGrid.Enabled := true;
   edInitVectorfile.Enabled := true;
   Label6.Enabled := true;
   Button3.Enabled := true
  end
 else
  begin
   Label14.Enabled := false;
   InitVectorGrid.Enabled := false;
   edInitVectorfile.Enabled := false;
   Label6.Enabled := false;
   Button3.Enabled := false
  end;
end;

procedure TfmMain.InitVectorGridEnter(Sender: TObject);
begin
 edInitVectorfile.Text := '';
end;

procedure TfmMain.edInitVectorfileEnter(Sender: TObject);
begin
 EmptyGrid(InitVectorGrid);
end;

procedure TfmMain.KeyGridEnter(Sender: TObject);
begin
 edKeyfile.Text := '';
end;

procedure TfmMain.edKeyfileEnter(Sender: TObject);
begin
 EmptyGrid(KeyGrid);
end;

procedure TfmMain.bnExitClick(Sender: TObject);
begin
 Close;
 Application.Terminate;
end;

procedure TfmMain.bnRestoreClick(Sender: TObject);
begin
 if (not Data.IsAccuracerBackupFile(edBackupFileName.Text)) then
  begin
   MessageDlg('Select correct backup file name',mtError,[mbOK],0);
   Exit;
  end;
 Data.DatabaseFileName := edDBFileName.Text;
 bnGetBackupInfoClick(Sender);
 if (cbEncrypted.Checked) then
  if not (Data.IsAccuracerBackupFileCryptoParamsValid(edBackupFileName.Text)) then
   begin
    MessageDlg('Incorrect encryption key, password or initial vector !',mtError,[mbOk],0);
    Exit;
   end;
 FormProgressCancel.Show;
 FormProgressCancel.Caption := 'Restore from backup file "'+
 		ExtractFileName(edBackupFileName.Text)+'"';
 FormProgressCancel.lbCaption.Caption := 'Processing restore ...';
 FormProgressCancel.bCancel := False;
 try
   Data.Restore(edBackupFileName.Text);
   MessageDlg('File '''+edBackupFileName.Text+''' was successfully restored',mtInformation,[mbOK],0);
   FormProgressCancel.Indicator.Progress := 100;
   Application.ProcessMessages;
   FormProgressCancel.Hide;
   EmptyGrid(InitVectorGrid);
   EmptyGrid(KeyGrid);
   tPassword.Text := '';
   edInitVectorfile.Text := '';
   edKeyfile.Text := '';
 except
  on E: Exception do
   begin
     FormProgressCancel.Hide;
     MessageDlg('Error during restore from backup file: '+e.Message,mtError,[mbOk],0);
     Exit;
   end;
 end;
end;

procedure TfmMain.EnableEncryptionControls(Encrypted,ByPassword: Boolean);
begin
 if (not Encrypted) or (ByPassword) then
  begin
   KeyGrid.Enabled := False;
   Label5.Enabled := False;
   Label13.Enabled := False;
   edKeyfile.Enabled := False;
   Button2.Enabled := False;
   tPassword.Enabled := Encrypted;
   Label2.Enabled := Encrypted;
  end; // disable key
 if (Encrypted) and (not ByPassword) then
  begin
   KeyGrid.Enabled := True;
   Label5.Enabled := True;
   Label13.Enabled := True;
   edKeyfile.Enabled := True;
   Button2.Enabled := True;
   tPassword.Enabled := False;
   Label2.Enabled := False;
  end; // enable key
 // init vector
 Label14.Enabled := Encrypted;
 Label6.Enabled := Encrypted;
 IsInitVector.Enabled := Encrypted;
 InitVectorGrid.Enabled := Encrypted;
 Button3.Enabled := Encrypted;
 edInitVectorfile.Enabled := Encrypted;
end;

procedure TfmMain.bnGetBackupInfoClick(Sender: TObject);
var BackupInfo: TACRBackupInfo;
  keyfile,invfile:TFileStream;
  key,inv: PChar;
  invS,keyS: string;
  sl:   TACRWideStringList;
  i: Integer;
begin
 sl := TACRWideStringList.Create();
 try
   BackupInfo := Data.GetBackupInfo(edBackupFileName.Text,sl);
   lbTables.Clear;
   for i := 0 to sl.Count-1 do
    lbTables.AddItem(sl[i],nil);
 finally
  sl.Free;
 end;
 cbEncrypted.Checked := BackupInfo.Encrypted;
 if (not cbEncrypted.Checked) then
  begin
   EnableEncryptionControls(False,False);
  end
 else
  begin
   if (BackupInfo.EncryptedByPassword) then
    EnableEncryptionControls(True,True)
   else
    EnableEncryptionControls(True,False);
  end;

 keyfile := nil;
 invfile := nil;
 if IsInitVector.Checked then
  begin
   Data.BackupParams.CryptoParams.UseInitVector := True;
   if edInitVectorfile.Text <> '' then
    begin
     try
      invfile := TFileStream.Create(edInitVectorfile.Text,fmOpenRead);
     except
      MessageDlg('InitVector file not found or corrupted',mtError,[mbOK],0);
      Exit;
     end;
     if invfile <> nil then
      begin
       inv := AllocMem(invfile.Size);
       invfile.ReadBuffer(inv^,invfile.Size);
       Data.BackupParams.CryptoParams.SetInitVector(inv,invfile.Size);
       invfile.Free;
       FreeMem(inv);
      end;
    end;
   if (InitVectorGrid.Cells[0,0] <> '') and (invfile = nil) then
    begin
     invS := GetString(InitVectorGrid);
     inv := AllocMem(length(InvS) div 2);
     HexToBin(PChar(LowerCase(invS)),inv,length(InvS) div 2);
     Data.BackupParams.CryptoParams.UseInitVector := True;
     Data.BackupParams.CryptoParams.SetInitVector(inv,length(InvS) div 2);
     FreeMem(inv);
    end;
  end;
 if tPassword.Enabled then
  begin
   Data.BackupParams.CryptoParams.Password := tPassword.Text;
  if not (Data.IsAccuracerBackupFileCryptoParamsValid(edBackupFileName.Text)) then
    begin
     MessageDlg('Incorrect password or initial vector !',mtError,[mbOk],0);
     Exit;
    end
  end
 else
  begin
   if edKeyfile.Text <> '' then
    begin
     try
      keyfile := TFileStream.Create(edKeyfile.Text,fmOpenRead);
     except
      MessageDlg('Key file not found or corrupted',mtError,[mbOK],0);
      edKeyfile.Text := '';
      Exit;
     end;
     if keyfile <> nil then
      begin
       key := AllocMem(keyfile.Size);
       keyfile.ReadBuffer(key^,keyfile.Size);
       Data.BackupParams.CryptoParams.SetKey(key,keyfile.Size);
       keyfile.Free;
       FreeMem(key);
       edKeyfile.Text := '';
      end;
    end;
   if (KeyGrid.Cells[0,0] <> '') and (keyfile = nil) then
    begin
     keyS := GetString(KeyGrid);
     key := AllocMem(length(KeyS) div 2);
     HexToBin(PChar(LowerCase(keyS)),key,length(keyS) div 2);
     Data.BackupParams.CryptoParams.SetKey(key,length(keyS) div 2);
     FreeMem(key);
    end;
  end;
 sl := TACRWideStringList.Create();
 try
   BackupInfo := Data.GetBackupInfo(edBackupFileName.Text,sl);
   lbTables.Clear;
   for i := 0 to sl.Count-1 do
    lbTables.AddItem(sl[i],nil);
 finally
  sl.Free;
 end;
 Label4.Caption := 'Tables: '+IntToStr(BackupInfo.TableCount);
 edFileSize.Text := IntToStr(BackupInfo.FileSize);
 edFileDate.Text := DateTimeToStr(BackupInfo.Date);
 reDesc.Text := BackupInfo.Description;
end;

procedure TfmMain.DataProgress(Sender: TComponent; Progress: Double;
  Operation: TACRDatabaseOperation; var Abort: Boolean);
begin
 FormProgressCancel.Indicator.Progress := round(Progress);
 Application.ProcessMessages;
 Abort := FormProgressCancel.bCancel;
end;

procedure TfmMain.Button1Click(Sender: TObject);
begin
 if (OpenDialog2.Execute) then
  begin
   edBackupFileName.Text := OpenDialog2.FileName;
   edDBFileName.Text := ChangeFileExt(edBackupFileName.Text,ACRDatabaseFileExtension);
   bnGetBackupInfoClick(Sender);
  end;
end;

end.
