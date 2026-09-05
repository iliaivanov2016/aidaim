unit uMain;

interface

{$I ver.inc}

uses
  Windows, ACRMain, ACRComMain, Messages, SysUtils, {Variants,} Classes, Graphics, Controls, Forms,
  Dialogs, Buttons, StdCtrls, ExtCtrls, Grids, Spin, ComCtrls, ACRConst, ACRTypes, ACRDecFmt;

type
  TfmMain = class(TForm)
    Label1: TLabel;
    edDBFileName: TEdit;
    Button1: TButton;
    Encrypted: TCheckBox;
    Panel1: TPanel;
    IsInitVector: TCheckBox;
    Label4: TLabel;
    cbMode: TComboBox;
    cbAlgorithm: TComboBox;
    Label3: TLabel;
    EncryptPageControl: TPageControl;
    BasicEncr: TTabSheet;
    Label2: TLabel;
    Label7: TLabel;
    tPassword: TEdit;
    tRPassword: TEdit;
    AdvEncr: TTabSheet;
    Label13: TLabel;
    Label11: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    KeyGrid: TStringGrid;
    edKeyFileName: TEdit;
    Button2: TButton;
    seKeySize: TSpinEdit;
    KeySave: TCheckBox;
    Panel2: TPanel;
    InitVectorGrid: TStringGrid;
    Label14: TLabel;
    VectorSave: TCheckBox;
    edInvFileName: TEdit;
    Label12: TLabel;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Label8: TLabel;
    edBackupFileName: TEdit;
    Button6: TButton;
    CurrentDB: TACRDatabase;
    bnBackup: TButton;
    bnExit: TButton;
    rgCompressionAlgorithm: TRadioGroup;
    Label9: TLabel;
    Label10: TLabel;
    cbCompressionMode: TComboBox;
    seBlockSize: TSpinEdit;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    SaveDialog2: TSaveDialog;
    Label15: TLabel;
    reDesc: TRichEdit;
    procedure FormShow(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure bnOkClick(Sender: TObject);
    procedure EncryptedClick(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure InitVectorGridGetEditMask(Sender: TObject; ACol,
      ARow: Integer; var Value: String);
    procedure KeyGridGetEditMask(Sender: TObject; ACol, ARow: Integer;
      var Value: String);
    procedure EncryptPageControlChange(Sender: TObject);
    procedure IsInitVectorClick(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure VectorSaveClick(Sender: TObject);
    procedure KeySaveClick(Sender: TObject);
    procedure cbAlgorithmSelect(Sender: TObject);
    procedure cbModeSelect(Sender: TObject);
    procedure tPasswordChange(Sender: TObject);
    procedure seKeySizeChange(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure bnExitClick(Sender: TObject);
    procedure rgCompressionAlgorithmClick(Sender: TObject);
    procedure ConvertDataParamsToDataSettings(CryptoParams: TACRCryptoParamsEditor = nil);
    procedure bnBackupClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure CurrentDBProgress(Sender: TComponent; Progress: Double;
      Operation: TACRDatabaseOperation; var Abort: Boolean);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fmMain: TfmMain;
  IsChange : Boolean;
  
implementation

uses ACRDecUtil, WorkGrids, ProgressCancel;

{$R *.dfm}

procedure TfmMain.FormShow(Sender: TObject);
begin
 IsChange := false;
 Encrypted.Checked := false;
 EncryptedClick(fmMain);
 EncryptPageControl.TabIndex := 0;
 OpenDialog1.InitialDir := ExtractFilePath(edDBFileName.Text);
 SaveDialog1.InitialDir := ExtractFilePath(edDBFileName.Text);
 SaveDialog2.InitialDir := ExtractFilePath(edDBFileName.Text);
 SaveDialog2.Options := [ofOverwritePrompt,ofPathMustExist,ofNoReadOnlyReturn];
end;

procedure TfmMain.Button1Click(Sender: TObject);
var s: string;
    i: Integer;
begin
 if (OpenDialog1.Execute) then
  begin
   edDBFileName.Text := OpenDialog1.FileName;
   edBackupFileName.Text := ChangeFileExt(edDBFileName.Text,ACRBackupFileExtension);
   i := 0;
   if (FileExists(edBackupFileName.Text)) then
    repeat
     Inc(i);
     s := StringReplace(ExtractFileName(edBackupFileName.Text),ExtractFileExt(edBackupFileName.Text),'',[]) +
      '_'+Format('%.6d',[i]);
     edBackupFileName.Text := ExtractFilePath(edBackupFileName.Text)+s+ ACRBackupFileExtension;
    until not FileExists(edBackupFileName.Text);
  end;
end;

procedure TfmMain.bnOkClick(Sender: TObject);
begin
 if (Encrypted.Checked) and (tPassword.Text = '')
      and (EncryptPageControl.TabIndex = 0) then
 begin
  MessageDlg('You should enter password for encrypted database!',mtError,[mbOk],0);
 end;
 if (Encrypted.Checked) and (tPassword.Text <> tRPassword.Text)
      and (EncryptPageControl.TabIndex = 0) then
 begin
  MessageDlg('Please reenter password correctly',mtError,[mbOk],0);
 end;
end;

procedure TfmMain.EncryptedClick(Sender: TObject);
var i,j:integer;
begin
 IsChange := True;
 if Encrypted.Checked then
 begin
  for i := 0 to Panel1.ControlCount-1 do
    Panel1.Controls[i].Enabled := true;
  for i := 0 to EncryptPageControl.PageCount - 1 do
   begin
    EncryptPageControl.Pages[i].Enabled := true;
    for j := 0 to EncryptPageControl.Pages[i].ControlCount - 1 do
     EncryptPageControl.Pages[i].Controls[j].Enabled := true;
   end;
 end
 else
 begin
  for i := 0 to Panel1.ControlCount-1 do
    Panel1.Controls[i].Enabled := false;
  for i := 0 to EncryptPageControl.PageCount - 1 do
   begin
    EncryptPageControl.Pages[i].Enabled := false;
    for j := 0 to EncryptPageControl.Pages[i].ControlCount - 1 do
     EncryptPageControl.Pages[i].Controls[j].Enabled := false;
   end;
 end;
end;

procedure TfmMain.Button2Click(Sender: TObject);
begin
  SaveDialog1.FileName := ExtractFileName(edKeyFileName.Text);
  if (SaveDialog1.Execute) then
   edKeyFileName.Text := SaveDialog1.FileName;
end;

procedure TfmMain.Button3Click(Sender: TObject);
begin
  SaveDialog1.FileName := ExtractFileName(edInvFileName.Text);
  if (SaveDialog1.Execute) then
   edInvFileName.Text := SaveDialog1.FileName;
end;

procedure TfmMain.InitVectorGridGetEditMask(Sender: TObject; ACol,
  ARow: Integer; var Value: String);
begin
 Value := 'AA';
end;

procedure TfmMain.KeyGridGetEditMask(Sender: TObject; ACol,
  ARow: Integer; var Value: String);
begin
 Value := 'AA';
end;

procedure TfmMain.EncryptPageControlChange(Sender: TObject);
var i:integer;
begin
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
end;

procedure TfmMain.IsInitVectorClick(Sender: TObject);
var i:integer;
begin
IsChange := True;
if IsInitVector.Checked then
  for i := 0 to Panel2.ControlCount-1 do
    Panel2.Controls[i].Enabled := true
 else
  for i := 0 to Panel2.ControlCount-1 do
    Panel2.Controls[i].Enabled := false;
end;

procedure TfmMain.Button4Click(Sender: TObject);
var
 inv : PAnsiChar;
 invHEX :String;
 fm: TFormat_HEX;
begin
   IsChange := True;
   EmptyGrid(InitVectorGrid);
   CurrentDB.BackupParams.CryptoParams.MakeRandomInitVector;
   inv := CurrentDB.BackupParams.CryptoParams.GetInitVector;
   fm := TFormat_HEX.Create;
   try
     invHEX := fm.Encode(inv,CurrentDB.BackupParams.CryptoParams.MaxInitVectorSize);
   finally
    fm.Free;
   end;
   FillGrid(InitVectorGrid,invHEX);
end;

procedure TfmMain.Button5Click(Sender: TObject);
var
 key : PAnsiChar;
 keyHEX : String;
 fm: TFormat_HEX;
begin
   IsChange := True;
   EmptyGrid(KeyGrid);
   CurrentDB.BackupParams.CryptoParams.MakeRandomKey(seKeySize.Value);
   key := CurrentDB.BackupParams.CryptoParams.GetKey;
   fm := TFormat_HEX.Create;
   try
     keyHEX := fm.Encode(key,CurrentDB.BackupParams.CryptoParams.KeySize);
   finally
    fm.Free;
   end;
   FillGrid(KeyGrid,keyHEX);
end;

procedure TfmMain.VectorSaveClick(Sender: TObject);
begin
 if VectorSave.Checked then
  begin
   Label12.Enabled := true;
   Button3.Enabled := true;
   edInvFileName.Enabled := true
  end
 else
  begin
   Label12.Enabled := false;
   Button3.Enabled := false;
   edInvFileName.Enabled := false
  end;
end;

procedure TfmMain.KeySaveClick(Sender: TObject);
begin
 if KeySave.Checked then
  begin
   Label11.Enabled := true;
   Button2.Enabled := true;
   edKeyFileName.Enabled := true
  end
 else
  begin
   Label11.Enabled := false;
   Button2.Enabled := false;
   edKeyFileName.Enabled := false
  end;
end;

procedure TfmMain.cbAlgorithmSelect(Sender: TObject);
begin
 IsChange := True;
end;
 
procedure TfmMain.cbModeSelect(Sender: TObject);
begin
 IsChange := True;
end;

procedure TfmMain.tPasswordChange(Sender: TObject);
begin
 if tPassword.Modified then IsChange := True;
end;

procedure TfmMain.seKeySizeChange(Sender: TObject);
begin
 if seKeySize.Modified then IsChange := True;
end;

procedure TfmMain.Button6Click(Sender: TObject);
begin
 if (SaveDialog2.Execute) then
  edBackupFileName.Text := SaveDialog2.FileName;
end;

procedure TfmMain.bnExitClick(Sender: TObject);
begin
 Close;
 Application.Terminate;
end;

procedure TfmMain.rgCompressionAlgorithmClick(Sender: TObject);
begin
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


//------------------------------------------------------------------------------
// convert components values to database settings
//------------------------------------------------------------------------------
procedure TfmMain.ConvertDataParamsToDataSettings(CryptoParams: TACRCryptoParamsEditor = nil);
var
    keyfile,invfile: TFileStream;
    key, inv : PChar;
    keyHEX, invHEX :string;
begin
 with fmMain do
  begin
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
       case cbMode.ItemIndex of
        0:CryptoParams.CryptoMode := acmCTS;
        1:CryptoParams.CryptoMode := acmCBC;
        2:CryptoParams.CryptoMode := acmCFB;
        3:CryptoParams.CryptoMode := acmOFB;
       end;
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
       case cbMode.ItemIndex of
        0:CurrentDB.CryptoParams.CryptoMode := acmCTS;
        1:CurrentDB.CryptoParams.CryptoMode := acmCBC;
        2:CurrentDB.CryptoParams.CryptoMode := acmCFB;
        3:CurrentDB.CryptoParams.CryptoMode := acmOFB;
       end;
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

procedure TfmMain.bnBackupClick(Sender: TObject);
begin
 if (Encrypted.Checked) and (tPassword.Text = '')
      and (EncryptPageControl.TabIndex = 0) then
 begin
  MessageDlg('You should enter password for encrypted database!',mtError,[mbOk],0);
  Exit;
 end;
 if (Encrypted.Checked) and (tPassword.Text <> tRPassword.Text)
      and (EncryptPageControl.TabIndex = 0) then
 begin
  MessageDlg('Please reenter password correctly',mtError,[mbOk],0);
  Exit;
 end;
 CurrentDB.DatabaseFileName := edDBFileName.Text;
 if (not CurrentDB.IsAccuracerDatabaseFile) then
  begin
   MessageDlg('Please enter the correct database file name',mtError,[mbOk],0);
   Exit;
  end;
 ConvertDataParamsToDataSettings(CurrentDB.BackupParams.CryptoParams);
 CurrentDB.BackupParams.BlockSize := seBlockSize.Value;
 if (cbCompressionMode.ItemIndex >= 0) then
  CurrentDB.BackupParams.CompressionMode := cbCompressionMode.ItemIndex+1
 else
  CurrentDB.BackupParams.CompressionMode := 0;
 CurrentDB.BackupParams.Description := reDesc.Text;
 CurrentDB.BackupParams.CompressionAlgorithm := TCompressionAlgorithm(rgCompressionAlgorithm.ItemIndex);
 FormProgressCancel.Show;
 FormProgressCancel.Caption := 'Back up database file "'+
 		ExtractFileName(CurrentDB.DatabaseFileName)+'"';
 FormProgressCancel.lbCaption.Caption := 'Processing backup ...';
 FormProgressCancel.bCancel := False;
 try
   CurrentDB.Backup(edBackupFileName.Text);
   MessageDlg('File '''+edDBFileName.Text+''' was successfully backed up',mtInformation,[mbOK],0);
   FormProgressCancel.Indicator.Progress := 100;
   Application.ProcessMessages;
   FormProgressCancel.Hide;
 except
  on e: Exception do
   begin
    FormProgressCancel.Hide;
    MessageDlg('Error during back up processing the file '''+edDBFileName.Text+''': '+e.Message,mtError,[mbOK],0);
    Exit;
   end;
 end;
end;

procedure TfmMain.FormCreate(Sender: TObject);
begin
 seBlockSize.Value := CurrentDB.BackupParams.BlockSize;
end;

procedure TfmMain.CurrentDBProgress(Sender: TComponent; Progress: Double;
  Operation: TACRDatabaseOperation; var Abort: Boolean);
begin
 FormProgressCancel.Indicator.Progress := round(Progress);
 Application.ProcessMessages;
 Abort := FormProgressCancel.bCancel;
end;

end.
