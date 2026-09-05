unit CompLevel;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons;

type
  TFormCompLevel = class(TForm)
    Label6: TLabel;
    CompLevel: TComboBox;
    Label7: TLabel;
    Info: TMemo;
    bnOk: TBitBtn;
    bnCancel: TBitBtn;
    procedure CompLevelChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormCompLevel: TFormCompLevel;

implementation

{$R *.DFM}

uses MainUnit;

procedure TFormCompLevel.CompLevelChange(Sender: TObject);
begin
 Info.Text := levelDesc[CompLevel.ItemIndex];
end;

procedure TFormCompLevel.FormCreate(Sender: TObject);
var i: integer;
begin
 CompLevel.Items.Clear;
 for i := 0 to 9 do
   CompLevel.Items.Add(levelText[i]);
end;

procedure TFormCompLevel.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
 action := caHide;
end;

end.
