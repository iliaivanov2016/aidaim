unit ProgressCancel2;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Gauges, Buttons;

type
  TFormProgressCancel2 = class(TForm)
    Indicator: TGauge;
    Label1: TLabel;
    Label2: TLabel;
    Indicator2: TGauge;
    btnCancel: TBitBtn;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnCancelClick(Sender: TObject);
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
    procedure SetIndicator22(
                              Sender:       TObject;
                              PercentDone:  Real;
                              FileName:     AnsiString
													);
  end;

var
  FormProgressCancel2: TFormProgressCancel2;
  bCancel:      Boolean;

implementation

uses MainUnit;

{$R *.DFM}


procedure TFormProgressCancel2.InitProgressForm(fc,lc: string);
begin
 Indicator.MaxValue := 100;
 Indicator2.MaxValue := 100;
 Caption := fc;
 Label1.Caption := lc;
 Indicator.Progress := 0;
 Indicator2.Progress := 0;
 bCancel := false;
 Application.ProcessMessages;
end;

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
procedure TFormProgressCancel2.SetIndicator(
                              Sender      : TObject;
                              PercentDone : Real;
                              var Cancel:				Boolean
													);
begin
 Indicator2.Progress := Round(PercentDone);
 Application.ProcessMessages;
 Cancel := bCancel;
end;


procedure TFormProgressCancel2.SetIndicator2(
                              Sender      : TObject;
                              PercentDone : Real
													);
begin
 Indicator.Progress := Round(PercentDone);
 Application.ProcessMessages;
end;


procedure TFormProgressCancel2.SetIndicator22(
                              Sender:       TObject;
                              PercentDone:  Real;
                              FileName:     AnsiString
													);
begin
 Label1.Caption := FileName;
 Indicator.Progress := Round(PercentDone);
 Application.ProcessMessages;
end;


procedure TFormProgressCancel2.FormClose(Sender: TObject;
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

procedure TFormProgressCancel2.btnCancelClick(Sender: TObject);
begin
 bCancel := true;
end;

end.
