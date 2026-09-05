unit ProgressIndicator;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Gauges;

type
  TFormProgress = class(TForm)
    Indicator: TGauge;
    Label1: TLabel;
    Label2: TLabel;
    Indicator2: TGauge;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
		procedure InitProgressForm(fc,lc: string);
    procedure SetIndicator(
                              Sender      : TObject;
                              PercentDone : Real;
                              var Cancel:				Boolean
                           );
    procedure SetIndicator2(
                              Sender      : TObject;
                              PercentDone : Real
                           );
  end;

var
  FormProgress: TFormProgress;

implementation

uses MainUnit;

{$R *.DFM}


procedure TFormProgress.InitProgressForm(fc,lc: string);
begin
 Indicator2.MaxValue := 100;
 Caption := fc;
 Label1.Caption := lc;
 Indicator.Progress := 0;
 Indicator2.Progress := 0;
 Application.ProcessMessages;
end;

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
procedure TFormProgress.SetIndicator(
                              Sender      : TObject;
                              PercentDone : Real;
                              var Cancel:				Boolean
													);
begin
 Indicator.Progress := Round(PercentDone);
 Application.ProcessMessages;
end;


procedure TFormProgress.SetIndicator2(
                              Sender      : TObject;
                              PercentDone : Real
													);
begin
 Indicator.Progress := Round(PercentDone);
 Application.ProcessMessages;
end;


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

end.
