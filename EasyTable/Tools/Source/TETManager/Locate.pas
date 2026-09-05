unit Locate;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Db, EasyTable, StdCtrls, Buttons, Grids, DBGrids;

type
  TFormLocate = class(TForm)
    bnOk: TBitBtn;
    bnCancel: TBitBtn;
    cbIns: TCheckBox;
    sgKeys: TStringGrid;
    cbPart: TCheckBox;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormLocate: TFormLocate;

implementation

{$R *.DFM}

procedure TFormLocate.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
 Action := caHide;
end;

end.
