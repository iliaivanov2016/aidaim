unit NewDatabase;

interface

uses
  Windows, Messages, SysUtils, {Variants,} Classes, Graphics, Controls, Forms,
  Dialogs, Buttons, StdCtrls;

const DBModes: array[0..2] of String  =
('Minimum database file size is 6 Kb. Use this mode for small tables.',
 'Minimum database file size is 36 Kb. This is a default mode.',
 'Minimum database file size is 136 Kb. This mode is optimized for large tables.');

type
  TFormNewDatabase = class(TForm)
    Label1: TLabel;
    edDBFileName: TEdit;
    Button1: TButton;
    SaveDialog: TSaveDialog;
    Encrypted: TCheckBox;
    Label2: TLabel;
    cmbDBMode: TComboBox;
    lbDBMode: TLabel;
    bnOk: TBitBtn;
    bnCancel: TBitBtn;
    Label3: TLabel;
    tPassword: TEdit;
    procedure cmbDBModeChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure EncryptedClick(Sender: TObject);
    procedure bnOkClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure bnCancelClick(Sender: TObject);
  private
    { Private declarations }
    bClose: Boolean;
  public
    { Public declarations }
  end;

var
  FormNewDatabase: TFormNewDatabase;

implementation

{$R *.dfm}

procedure TFormNewDatabase.cmbDBModeChange(Sender: TObject);
begin
 lbDBMode.Caption := DBModes[cmbDBMode.ItemIndex];
end;

procedure TFormNewDatabase.FormShow(Sender: TObject);
begin
 bClose := false;
 SaveDialog.InitialDir := ExtractFilePath(edDBFileName.Text);
 SaveDialog.FileName := ExtractFileName(edDBFileName.Text);
 SaveDialog.Options := [ofOverwritePrompt,ofPathMustExist,ofNoReadOnlyReturn];
end;

procedure TFormNewDatabase.Button1Click(Sender: TObject);
begin
 if (SaveDialog.Execute) then
  edDBFileName.Text := SaveDialog.FileName;
end;

procedure TFormNewDatabase.FormCreate(Sender: TObject);
begin
 cmbDBMode.ItemIndex := 0;
 lbDBMode.Caption := DBModes[cmbDBMode.ItemIndex];
end;

procedure TFormNewDatabase.EncryptedClick(Sender: TObject);
begin
if Encrypted.checked then
  begin
   tPassword.Enabled := true;
   tPassword.Color := clWindow;
  end
 else
  begin
   tPassword.Color := clSilver;
   tPassword.Enabled := false;
   tPassword.Text := '';
  end;
end;

procedure TFormNewDatabase.bnOkClick(Sender: TObject);
begin
 bClose := true;
 if (Encrypted.Checked) and (tPassword.Text = '') then
  begin
   MessageDlg('You should enter password for encrypted database!',mtError,[mbOk],0);
   bClose := false;
  end;
end;

procedure TFormNewDatabase.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
 if (bClose) then
  Action := caHide
 else
  Action := caNone;
end;

procedure TFormNewDatabase.bnCancelClick(Sender: TObject);
begin
 bClose := True;
end;

end.
