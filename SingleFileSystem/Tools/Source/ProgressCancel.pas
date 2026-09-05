unit ProgressCancel;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Gauges;

type
  TFormProgressCancel = class(TForm)
    Indicator: TGauge;
    Label1: TLabel;
    btCancel: TButton;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btCancelClick(Sender: TObject);
  private
    { Private declarations }
    bCancel: Boolean;
  public
    { Public declarations }
		procedure InitProgressForm(fc,lc: string);
    procedure SetIndicator(
                              Sender      : TObject;
                              PercentDone : Real;
                              var Cancel:				Boolean
                           );
  end;

var
  FormProgressCancel: TFormProgressCancel;

implementation

uses MainUnit;

{$R *.DFM}


procedure TFormProgressCancel.InitProgressForm(fc,lc: string);
begin
 Caption := fc;
 Label1.Caption := lc;
 Indicator.Progress := 0;
 Application.ProcessMessages;
 bCancel := false;
end;

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
procedure TFormProgressCancel.SetIndicator(
                              Sender      : TObject;
                              PercentDone : Real;
                              var Cancel:				Boolean
													);
begin
 Indicator.Progress := Round(PercentDone);
 Application.ProcessMessages;
 Cancel := bCancel;
end;



procedure TFormProgressCancel.FormClose(Sender: TObject;
  var Action: TCloseAction);
var time: Cardinal;
begin
 Indicator.Progress := 100;
 time := GetTickCount;
 while GetTickCount - time < 500 do
  Application.ProcessMessages;

 Action := caHide;
end;

procedure TFormProgressCancel.btCancelClick(Sender: TObject);
begin
 bCancel := true;
end;

end.
