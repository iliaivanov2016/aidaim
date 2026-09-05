unit Security;

interface

{$I ver.inc}

uses
  ACRMain,Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Grids, StdCtrls, ExtCtrls, Buttons;

type
  TFormSecurity = class(TForm)
    bnOk: TBitBtn;
    bnCancel: TBitBtn;
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
    procedure bnCancelClick(Sender: TObject);
    procedure bnOkClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
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
  private
    { Private declarations }
    bClose: Boolean;
  public
    { Public declarations }

  end;

var
  FormSecurity: TFormSecurity;
  adbFileName : string;
  FormsVisible : boolean;
  place : byte;
  Data : TACRDatabase;

implementation

uses NewDatabase, WorkGrids, uMain;

{$R *.dfm}

procedure TFormSecurity.bnCancelClick(Sender: TObject);
begin
 bClose := True;
end;

procedure TFormSecurity.bnOkClick(Sender: TObject);
var
  keyfile,invfile:TFileStream;
  key,inv: PChar;
  invS,keyS: string;
begin
 bClose := true;
 keyfile := nil;
 invfile := nil;
 if IsInitVector.Checked then
  begin
   Data.CryptoParams.UseInitVector := True;
   if edInitVectorfile.Text <> '' then
    begin
     try
      invfile := TFileStream.Create(edInitVectorfile.Text,fmOpenRead);
     except
      MessageDlg('InitVector file not found or corrupted',mtError,[mbOK],0);
      edInitVectorfile.Text := '';
      Exit;
     end;
     if invfile <> nil then
      begin
       inv := AllocMem(invfile.Size);
       invfile.ReadBuffer(inv^,invfile.Size);
       Data.CryptoParams.SetInitVector(inv,invFile.Size);
       invfile.Free;
       FreeMem(inv);
       edInitVectorfile.Text := '';
      end;
    end;
   if (InitVectorGrid.Cells[0,0] <> '') and (invfile = nil) then
    begin
     invS := GetString(InitVectorGrid);
     inv := AllocMem(length(InvS) div 2);
     HexToBin(PChar(LowerCase(invS)),inv,length(InvS) div 2);
     Data.CryptoParams.UseInitVector := True;
     Data.CryptoParams.SetInitVector(inv,length(InvS) div 2);
     FreeMem(inv);
     EmptyGrid(InitVectorGrid);
    end;
  end;
 if Data.IsDatabaseEncryptedByPassword then
  begin
   Data.CryptoParams.Password := tPassword.Text;
   tPassword.Text := '';
  if not (Data.IsCryptoParamsValid) then
    begin
     MessageDlg('Incorrect password or initial vector !',mtError,[mbOk],0);
     bClose := false;
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
       Data.CryptoParams.SetKey(key,keyfile.Size);
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
     Data.CryptoParams.SetKey(key,length(keyS) div 2);
     FreeMem(key);
     EmptyGrid(KeyGrid);
    end;
   if not (Data.IsCryptoParamsValid) then
    begin
     MessageDlg('Incorrect encrypt key or initial vector !',mtError,[mbOk],0);
     bClose := false;
    end
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

procedure TFormSecurity.Button2Click(Sender: TObject);
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
