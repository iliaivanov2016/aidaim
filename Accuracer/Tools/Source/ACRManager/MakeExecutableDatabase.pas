unit MakeExecutableDatabase;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Buttons, StdCtrls;

type
  TfmMakeExeDatabase = class(TForm)
    Button1: TButton;
    edDBfile: TEdit;
    Label5: TLabel;
    Label1: TLabel;
    edExeDBFile: TEdit;
    Button2: TButton;
    BitBtn1: TBitBtn;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    bnOK: TBitBtn;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure bnOKClick(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    bClose:  Boolean;
    { Private declarations }
  public
    bCancel: Boolean;
    { Public declarations }
  end;

var
  fmMakeExeDatabase: TfmMakeExeDatabase;

implementation

{$R *.dfm}

procedure TfmMakeExeDatabase.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 if (bClose) then
  Action := caHide
 else
  Action := caNone;
end;


procedure TfmMakeExeDatabase.FormShow(Sender: TObject);
begin
 bClose := False;
 bCancel := False;
end;

procedure TfmMakeExeDatabase.BitBtn1Click(Sender: TObject);
begin
 bClose := True;
 ModalResult := mrCancel;
 bCancel := True;
 Close;
end;

procedure TfmMakeExeDatabase.Button1Click(Sender: TObject);
begin
 if (OpenDialog.Execute) then
  edDBfile.Text := OpenDialog.FileName;
end;

procedure TfmMakeExeDatabase.bnOKClick(Sender: TObject);
begin
 if (not FileExists(edDBfile.Text)) then
  begin
   MessageDlg('Executable file does not exists',mtError,[mbOK],0);
   Exit;
  end;
 if (edExeDBFile.Text = '') then
  begin
   MessageDlg('Destination executable database file name is empty',mtError,[mbOK],0);
   Exit;
  end;
 bClose := True;
 ModalResult := mrOK;
 bCancel := False;
 Close;
end;

procedure TfmMakeExeDatabase.Button2Click(Sender: TObject);
begin
 if (SaveDialog.Execute) then
  edExeDBFile.Text := SaveDialog.FileName;
end;

end.
