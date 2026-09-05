unit QuestUnit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons;

type
  TFormQuest = class(TForm)
    Label1: TLabel;
    Answer: TEdit;
    btnOk: TBitBtn;
    btnCancel: TBitBtn;
    Label2: TLabel;
    Quest: TMemo;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormQuest: TFormQuest;

implementation

{$R *.DFM}

procedure TFormQuest.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 Action := caHide;
end;

procedure TFormQuest.FormShow(Sender: TObject);
begin
 Answer.Text := '';
end;

end.
