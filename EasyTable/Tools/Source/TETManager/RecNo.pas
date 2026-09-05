unit RecNo;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Spin, Buttons;

type
  TFormRecNo = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Label1: TLabel;
    seRecNo: TSpinEdit;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormRecNo: TFormRecNo;

implementation

{$R *.DFM}

procedure TFormRecNo.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 Action := caHide;
end;

end.
