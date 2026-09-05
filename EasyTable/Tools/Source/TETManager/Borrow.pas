unit Borrow;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons;

type
  TFormBorrow = class(TForm)
    lbBorrow: TListBox;
    Label1: TLabel;
    bnOk: TBitBtn;
    bnCancel: TBitBtn;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure lbBorrowDblClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormBorrow: TFormBorrow;

implementation

{$R *.DFM}

procedure TFormBorrow.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 Action := caHide;
end;

procedure TFormBorrow.lbBorrowDblClick(Sender: TObject);
begin
 bnOk.Click;
end;

end.
