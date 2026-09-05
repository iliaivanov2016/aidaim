unit OpenDatabase;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons, ACRConst;

type
  TfmOpenDatabase = class(TForm)
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    edDBName: TEdit;
    edRemoteHost: TEdit;
    edRemotePort: TEdit;
    edLocalPort: TEdit;
    BitBtn1: TBitBtn;
    bnCancel: TBitBtn;
    rgLocalDatabase: TRadioGroup;
    GroupBox2: TGroupBox;
    Label5: TLabel;
    edDatabaseFile: TEdit;
    Button1: TButton;
    OpenDialog: TOpenDialog;
    lProtocol: TLabel;
    cbProtocol: TComboBox;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    FCloseEnabled: Boolean;
  end;

var
  fmOpenDatabase: TfmOpenDatabase;

implementation

{$R *.dfm}

procedure TfmOpenDatabase.FormCreate(Sender: TObject);
begin
 FCloseEnabled := True;
 edDBName.Text := ACRDefaultDBName;
 edRemoteHost.Text := ACRDefaultHost;
 edRemotePort.Text := IntToStr(ACRDefaultServerPort);
 edLocalPort.Text := IntToStr(ACRDefaultClientPort);
end;

procedure TfmOpenDatabase.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
 if (FCloseEnabled) then
  Action := caHide
 else
  Action := caNone;
end;

procedure TfmOpenDatabase.Button1Click(Sender: TObject);
begin
 FCloseEnabled := False;
 try
   if (FileExists(edDatabaseFile.Text)) then
    OpenDialog.FileName := edDatabaseFile.Text
   else 
    OpenDialog.InitialDir := ExtractFilePath(edDatabaseFile.Text);
   if (OpenDialog.Execute) then
    edDatabaseFile.Text := OpenDialog.FileName;
 finally
   FCloseEnabled := True;
 end;
end;

end.
