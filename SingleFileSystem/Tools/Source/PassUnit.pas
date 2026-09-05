unit PassUnit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons;

type
  TFormPass = class(TForm)
    Label1: TLabel;
    Password: TEdit;
    btnOk: TBitBtn;
    btnCancel: TBitBtn;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormPass: TFormPass;

implementation

{$R *.DFM}

procedure TFormPass.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 Action := caHide;
end;

procedure TFormPass.FormShow(Sender: TObject);
begin
 Password.Text := '';
end;

end.
