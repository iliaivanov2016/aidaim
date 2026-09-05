unit NewDatabase;

interface

{$I ver.inc}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, Buttons, StdCtrls, ExtCtrls, Grids, Spin, ComCtrls, ACRConst;

type
  TFormNewDatabase = class(TForm)
    Label1: TLabel;
    edDBFileName: TEdit;
    Button1: TButton;
    SaveDialog: TSaveDialog;
    bnOk: TBitBtn;
    bnCancel: TBitBtn;
    Encrypted: TCheckBox;
    GroupBox1: TGroupBox;
    sePageSize: TSpinEdit;
    seMaxConnections: TSpinEdit;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    SaveDialog1: TSaveDialog;
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
    procedure FormShow(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure bnOkClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure bnCancelClick(Sender: TObject);
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
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    bClose: Boolean;
  public
    { Public declarations }
  end;

var
  FormNewDatabase: TFormNewDatabase;

implementation

uses uMain, ACRDecUtil, WorkGrids;

{$R *.dfm}

procedure TFormNewDatabase.FormShow(Sender: TObject);
begin
 bClose := false;
 EncryptPageControl.TabIndex := 0;
 SaveDialog.InitialDir := ExtractFilePath(edDBFileName.Text);
 SaveDialog.FileName := ExtractFileName(edDBFileName.Text);
 SaveDialog.Options := [ofOverwritePrompt,ofPathMustExist,ofNoReadOnlyReturn];
 SaveDialog1.InitialDir := ExtractFilePath(edDBFileName.Text);
end;

procedure TFormNewDatabase.Button1Click(Sender: TObject);
begin
 if (SaveDialog.Execute) then
  edDBFileName.Text := SaveDialog.FileName;
end;

procedure TFormNewDatabase.bnOkClick(Sender: TObject);
begin
 bClose := true;
 if (Encrypted.Checked) and (tPassword.Text = '')
      and (EncryptPageControl.TabIndex = 0) then
 begin
  MessageDlg('You should enter password for encrypted database!',mtError,[mbOk],0);
  bClose := false;
 end;
 if (Encrypted.Checked) and (tPassword.Text <> tRPassword.Text)
      and (EncryptPageControl.TabIndex = 0) then
 begin
  MessageDlg('Please reenter password correctly',mtError,[mbOk],0);
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

procedure TFormNewDatabase.EncryptedClick(Sender: TObject);
var i,j:integer;
begin
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

procedure TFormNewDatabase.Button2Click(Sender: TObject);
begin
  SaveDialog1.FileName := ExtractFileName(edKeyFileName.Text);
  if (SaveDialog1.Execute) then
   edKeyFileName.Text := SaveDialog1.FileName;
end;

procedure TFormNewDatabase.Button3Click(Sender: TObject);
begin
  SaveDialog1.FileName := ExtractFileName(edInvFileName.Text);
  if (SaveDialog1.Execute) then
   edInvFileName.Text := SaveDialog1.FileName;
end;

procedure TFormNewDatabase.InitVectorGridGetEditMask(Sender: TObject; ACol,
  ARow: Integer; var Value: String);
begin
 Value := 'AA';
end;

procedure TFormNewDatabase.KeyGridGetEditMask(Sender: TObject; ACol,
  ARow: Integer; var Value: String);
begin
 Value := 'AA';
end;

procedure TFormNewDatabase.EncryptPageControlChange(Sender: TObject);
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

procedure TFormNewDatabase.IsInitVectorClick(Sender: TObject);
var i:integer;
begin
if IsInitVector.Checked then
  for i := 0 to Panel2.ControlCount-1 do
    Panel2.Controls[i].Enabled := true
 else
  for i := 0 to Panel2.ControlCount-1 do
    Panel2.Controls[i].Enabled := false;
end;

procedure TFormNewDatabase.Button4Click(Sender: TObject);
var
 inv :    PAnsiChar;
 invHEX : AnsiString;
begin
   EmptyGrid(InitVectorGrid);
   fmMain.CurrentDB.CryptoParams.MakeRandomInitVector;
   inv := fmMain.CurrentDB.CryptoParams.GetInitVector;
   invHEX := StrToFormat(inv,fmMain.CurrentDB.CryptoParams.MaxInitVectorSize,fmtHex);
   FillGrid(InitVectorGrid,invHEX);
end;

procedure TFormNewDatabase.Button5Click(Sender: TObject);
var
 key :    PAnsiChar;
 keyHEX : AnsiString;
begin
   EmptyGrid(KeyGrid);
   fmMain.CurrentDB.CryptoParams.MakeRandomKey(seKeySize.Value);
   key := fmMain.CurrentDB.CryptoParams.GetKey;
   keyHEX := StrToFormat(key,fmMain.CurrentDB.CryptoParams.KeySize,fmtHEX);
   FillGrid(KeyGrid,keyHEX);
end;

procedure TFormNewDatabase.VectorSaveClick(Sender: TObject);
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

procedure TFormNewDatabase.KeySaveClick(Sender: TObject);
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

procedure TFormNewDatabase.FormCreate(Sender: TObject);
begin
 sePageSize.MinValue := ACRMinPageSize;
 sePageSize.MaxValue := ACRMaxPageSize;
 sePageSize.Value := ACRDefaultPageSize;
 sePageSize.Increment := 1024;
 seMaxConnections.MinValue := 1;
 seMaxConnections.MaxValue := ACRMaxSessionCount;
 seMaxConnections.Value := ACRDefaultSessionCount;
 seMaxConnections.Increment := 1;
end;

end.
