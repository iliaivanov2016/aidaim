unit ProgInd;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Gauges, EasyTable;

type
  TFormProg = class(TForm)
    Indicator: TGauge;
    Label1: TLabel;
    Label2: TLabel;
    Indicator2: TGauge;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  procedure SetIndicator(
                              Sender      : TEasyDataset;
                              PercentDone : Real;
                              ProgressProcess : TaaProgressProcess
													);
  end;

var
  FormProg: TFormProg;

implementation

uses MainUnit;

{$R *.DFM}

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
procedure TFormProg.SetIndicator(
                              Sender      : TEasyDataset;
                              PercentDone : Real;
                              ProgressProcess : TaaProgressProcess
													);
begin
 Indicator.Progress := Round(PercentDone);
 Application.ProcessMessages;
end;


procedure TFormProg.FormClose(Sender: TObject;
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

end.
