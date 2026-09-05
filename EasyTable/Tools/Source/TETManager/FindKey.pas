unit FindKey;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Db, EasyTable, StdCtrls, Buttons, Grids, DBGrids;

type
  TFormFindKey = class(TForm)
    bnOk: TBitBtn;
    bnCancel: TBitBtn;
    cbNearest: TCheckBox;
    sgKeys: TStringGrid;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormFindKey: TFormFindKey;

implementation

{$R *.DFM}

procedure TFormFindKey.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
 Action := caHide;
end;

end.
