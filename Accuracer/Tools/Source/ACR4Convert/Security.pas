unit Security;

interface

{$I ACR4Convert.Inc}
{$HINTS OFF}

uses
  ACRMain,AC4Main, ACRTypes, ACRConst,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Grids, StdCtrls, ExtCtrls, Buttons;

type
  TFormSecurity = class(TForm)
    bnOk: TBitBtn;
    bnCancel: TBitBtn;
    tPassword: TEdit;
    edKeyfile: TEdit;
    edInitVectorfile: TEdit;
    bnKeyFile: TButton;
    Button3: TButton;
    Label6: TLabel;
    lbKeyFile: TLabel;
    lbPassword: TLabel;
    OpenDialog1: TOpenDialog;
    InitVectorGrid: TStringGrid;
    Label14: TLabel;
    KeyGrid: TStringGrid;
    lbKey: TLabel;
    IsInitVector: TCheckBox;
    procedure bnCancelClick(Sender: TObject);
    procedure bnOkClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure bnKeyFileClick(Sender: TObject);
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
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    bClose: Boolean;
  public
    { Public declarations }

  end;

var
  FormSecurity: TFormSecurity;
  adbFileName : string;
//  FormsVisible : boolean;
  place : byte;
  Data5 : TACRDatabase;
  Data4 : TAC4Database;
  IsACR5: Boolean;


implementation

uses WorkGrids, uMain;

{$R *.dfm}

procedure TFormSecurity.bnCancelClick(Sender: TObject);
begin
 bClose := True;
 ModalResult := mrCancel;
end;

procedure TFormSecurity.bnOkClick(Sender: TObject);
var
  keyfile,invfile:TFileStream;
  key,inv: PChar;
  invS,keyS: string;
  bEncryptedByPassword: Boolean;
begin
 keyfile := nil;
 invfile := nil;
 bClose := true;
 if IsInitVector.Checked then
  begin
   if (IsACR5) then
    Data5.CryptoParams.UseInitVector := True
   else
    Data4.CryptoParams.UseInitVector := True;
   if edInitVectorfile.Text <> '' then
    begin
     try
      invfile := TFileStream.Create(edInitVectorfile.Text,fmOpenRead);
     except
      MessageDlg('InitVector file not found or corrupted',mtError,[mbOK],0);
      edInitVectorfile.Text := '';
     end;
     if invfile <> nil then
      begin
       inv := AllocMem(invfile.Size);
       try
         invfile.ReadBuffer(inv^,invfile.Size);
         if (IsACR5) then
          Data5.CryptoParams.SetInitVector(inv,invfile.Size)
         else
          Data4.CryptoParams.SetInitVector(inv);
       finally
         invfile.Free;
         FreeMem(inv);
         edInitVectorfile.Text := '';
       end;
      end;
    end;
   if (InitVectorGrid.Cells[0,0] <> '') and (invfile = nil) then
    begin
     invS := GetString(InitVectorGrid);
     inv := AllocMem(length(InvS) div 2);
     HexToBin(PChar(LowerCase(invS)),inv,length(InvS) div 2);
     if (IsACR5) then
      begin
       Data5.CryptoParams.UseInitVector := True;
       Data5.CryptoParams.SetInitVector(inv,length(InvS) div 2);
      end
     else
      begin
       Data4.CryptoParams.UseInitVector := True;
       Data4.CryptoParams.SetInitVector(inv);
      end;
     FreeMem(inv);
     EmptyGrid(InitVectorGrid);
    end;
  end;
 if (IsACR5) then
  bEncryptedByPassword := Data5.IsDatabaseEncryptedByPassword
 else
  bEncryptedByPassword := Data4.IsDatabaseEncryptedByPassword;
 if bEncryptedByPassword then
  begin
   if (IsACR5) then
    begin
     Data5.CryptoParams.Password := tPassword.Text;
     if not (Data5.IsCryptoParamsValid) then
      begin
       MessageDlg('Incorrect password or initial vector !',mtError,[mbOk],0);
       bClose := false;
      end;
    end
   else
    begin
     Data4.CryptoParams.Password := tPassword.Text;
     if not (Data4.IsCryptoParamsValid) then
      begin
       MessageDlg('Incorrect password or initial vector !',mtError,[mbOk],0);
       bClose := false;
      end;
    end;
   tPassword.Text := '';
  end // encrypted by password
 else
  begin
   if edKeyfile.Text <> '' then
    begin
     try
      keyfile := TFileStream.Create(edKeyfile.Text,fmOpenRead);
     except
      MessageDlg('Key file not found or corrupted',mtError,[mbOK],0);
      edKeyfile.Text := '';
     end;
     if keyfile <> nil then
      begin
       key := AllocMem(keyfile.Size);
       try
        keyfile.ReadBuffer(key^,keyfile.Size);
        if (IsACR5) then
         Data5.CryptoParams.SetKey(key,keyfile.Size)
        else
         Data4.CryptoParams.SetKey(key,keyfile.Size);
       finally
        keyfile.Free;
        FreeMem(key);
        edKeyfile.Text := '';
       end;
      end;
    end;
   if (KeyGrid.Cells[0,0] <> '') and (keyfile = nil) then
    begin
     keyS := GetString(KeyGrid);
     key := AllocMem(length(KeyS) div 2);
     try
       HexToBin(PChar(LowerCase(keyS)),key,length(keyS) div 2);
       if (IsACR5) then
        Data5.CryptoParams.SetKey(key,length(keyS) div 2)
       else
        Data4.CryptoParams.SetKey(key,length(keyS) div 2);
       EmptyGrid(KeyGrid);
     finally
       FreeMem(key);
     end;
    end;
   if (IsACR5) then
    begin
     if not (Data5.IsCryptoParamsValid) then
      begin
       MessageDlg('Incorrect encrypt key or initial vector !',mtError,[mbOk],0);
       bClose := false;
      end
    end
   else
    begin
     if not (Data4.IsCryptoParamsValid) then
      begin
       MessageDlg('Incorrect encrypt key or initial vector !',mtError,[mbOk],0);
       bClose := false;
      end
    end;
  end
end;

procedure TFormSecurity.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
 if (bClose) then
  Action := caHide
 else
  Action := caNone;
 bClose := false;
end;

procedure TFormSecurity.FormShow(Sender: TObject);
var byPassword: Boolean;
begin
  if (IsACR5) then
    byPassword :=  Data5.IsDatabaseEncryptedByPassword
  else
    byPassword :=  Data4.IsDatabaseEncryptedByPassword;
  if (byPassword) then
    begin
     tPassword.Visible := True;
     lbPassword.Visible := True;
     lbKeyFile.Visible := False;
     lbKey.Visible := False;
     KeyGrid.Visible := False;
     bnKeyFile.Visible := False;
     edKeyfile.Visible := False;
    end
   else
    begin
     tPassword.Visible := False;
     lbPassword.Visible := False;
     lbKeyFile.Visible := True;
     lbKey.Visible := True;
     KeyGrid.Visible := True;
     bnKeyFile.Visible := True;
     edKeyfile.Visible := True;
    end;
end;

procedure TFormSecurity.bnKeyFileClick(Sender: TObject);
begin
 OpenDialog1.InitialDir := ExtractFilePath(adbFileName);
 OpenDialog1.DefaultExt := '.key';
 OpenDialog1.Filter := 'Key file(*.key)|*.key|Any file(*.*)|*.*';
 if (OpenDialog1.Execute) then
  edKeyfile.Text := OpenDialog1.FileName;
end;

procedure TFormSecurity.Button3Click(Sender: TObject);
begin
 OpenDialog1.InitialDir := ExtractFilePath(adbFileName);
 OpenDialog1.DefaultExt := '.iv';
 OpenDialog1.Filter := 'InitVector file(*.iv)|*.iv|Any file(*.*)|*.*';
 if (OpenDialog1.Execute) then
  edInitVectorfile.Text := OpenDialog1.FileName;
end;

procedure TFormSecurity.KeyGridGetEditMask(Sender: TObject; ACol,
  ARow: Integer; var Value: String);
begin
 Value := 'AA';
end;

procedure TFormSecurity.InitVectorGridGetEditMask(Sender: TObject; ACol,
  ARow: Integer; var Value: String);
begin
 Value := 'AA';
end;

procedure TFormSecurity.IsInitVectorClick(Sender: TObject);
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

procedure TFormSecurity.InitVectorGridEnter(Sender: TObject);
begin
 edInitVectorfile.Text := '';
end;

procedure TFormSecurity.edInitVectorfileEnter(Sender: TObject);
begin
 EmptyGrid(InitVectorGrid);
end;

procedure TFormSecurity.KeyGridEnter(Sender: TObject);
begin
 edKeyfile.Text := '';
end;

procedure TFormSecurity.edKeyfileEnter(Sender: TObject);
begin
 EmptyGrid(KeyGrid);
end;

end.
