unit SetRange;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Db, ACRMain, StdCtrls, Buttons, Grids, DBGrids;

type
  TFormRange = class(TForm)
    bnOk: TBitBtn;
    bnCancel: TBitBtn;
    cbStart: TCheckBox;
    sgStart: TStringGrid;
    cbEnd: TCheckBox;
    sgEnd: TStringGrid;
    Label1: TLabel;
    Label2: TLabel;
    BitBtn1: TBitBtn;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormRange: TFormRange;

implementation

{$R *.DFM}

procedure TFormRange.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
 Action := caHide;
end;

end.
