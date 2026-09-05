unit ProgressIndicator;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Gauges;

type
  TFormProgress = class(TForm)
    Indicator: TGauge;
    CancelBtn: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Indicator2: TGauge;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure CancelBtnClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
  private
    { Private declarations }
  public
    FCancel: Boolean;
    { Public declarations }
  end;

var
  FormProgress: TFormProgress;

implementation

uses MainUnit;

{$R *.DFM}


procedure TFormProgress.FormClose(Sender: TObject;
  var Action: TCloseAction);
var time: Cardinal;
begin
 Indicator2.MaxValue := 100;
 Indicator2.Progress := 100;
 Indicator.Progress := 100;
 time := GetTickCount;
 while GetTickCount - time < 500 do
  Application.ProcessMessages;

 Action := caHide;
end;

procedure TFormProgress.CancelBtnClick(Sender: TObject);
begin
 FCancel := True;
 Application.ProcessMessages;
end;

procedure TFormProgress.FormActivate(Sender: TObject);
begin
 FCancel := False;
end;

end.
