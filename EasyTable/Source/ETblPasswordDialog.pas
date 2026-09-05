{$I ETblVer.inc}

unit EtblPasswordDialog;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls;

type
  TPassDialog = class(TForm)
    Label1: TLabel;
    Pass: TEdit;
    cbOk: TButton;
    cbCancel: TButton;
    lbName: TLabel;
    procedure cbOkClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    FDataManager: TObject;
  end;

var
  PassDialog: TPassDialog;

function PasswordDialog(DataManager: TObject; TableName: AnsiString = ''): Boolean;

implementation

uses EasyTable;
{$R *.DFM}

function PasswordDialog(DataManager: TObject; TableName: AnsiString = ''): Boolean;
begin
 with TPassDialog.Create(Application) do
  begin
   try
    Pass.Text := '';
    FDataManager := DataManager;
    lbName.Caption := TableName;
    Result := (ShowModal = mrOk);
   finally
    Free;
   end;
  end;
end;


procedure TPassDialog.cbOkClick(Sender: TObject);
begin
 (FDataManager as TEasyDataManager).FPassword := Pass.Text;
end;

end.
