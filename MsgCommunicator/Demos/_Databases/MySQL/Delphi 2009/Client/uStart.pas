unit uStart;

interface

{$IFDEF VER200}
{$WARN IMPLICIT_STRING_CAST OFF}
{$WARN IMPLICIT_STRING_CAST_LOSS OFF}
{$ENDIF}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TfmStart = class(TForm)
    Panel1: TPanel;
    bnOK: TButton;
    bnCancel: TButton;
    rgAction: TRadioGroup;
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fmStart: TfmStart;

implementation


{$R *.dfm}


procedure TfmStart.FormShow(Sender: TObject);
begin
 ModalResult := mrOK;
 bnOK.SetFocus;
end;

end.
