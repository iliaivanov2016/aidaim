unit ProgressCancel;

interface

{$I ACRManager.Inc}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Gauges, Buttons;

type
  TFormProgressCancel = class(TForm)
    Indicator: TGauge;
    lbCaption: TLabel;
    bnCancel: TBitBtn;
    lbTableName: TLabel;
    TableIndicator: TGauge;
//    procedure FormShow(Sender: TObject; formCapt, capt : string);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure bnCancelClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    bCancel : Boolean;
    mResult : integer;
    EWindowList:pointer;
    EActiveWindow:HWND;
    function MessageHook(var Msg: TMessage): Boolean;
    procedure SetIndicator(v:integer);
  end;

var
  FormProgressCancel: TFormProgressCancel;

implementation

uses MainUnit;

{$R *.DFM}

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
function TFormProgressCancel.MessageHook(var Msg: TMessage): Boolean;
begin
  Result := False;
end;


//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
procedure TFormProgressCancel.SetIndicator(v:integer);
begin
 Indicator.Progress := v;
end;
{

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
procedure TFormProgress.FormShow(Sender: TObject; formCapt, capt : string);
begin
 lbCaption.Visible := true;
 lbCaption.Caption := capt;
 FormProgress.lbCaption.Caption := formCapt;
 Indicator.Progress := 0;
 mResult := mrOk;
 Show;

end;

 }
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
procedure TFormProgressCancel.FormClose(Sender: TObject;var Action: TCloseAction);
var time: Cardinal;
begin
 if (mResult = mrCancel) then
  begin
   action := caNone;
   mResult := mrOk;
  end
 else
  begin
   Indicator.Progress := 100;
   time := GetTickCount;
   while GetTickCount - time < 500 do
    Application.ProcessMessages;
   Application.UnhookMainWindow(MessageHook);
   EnableTaskWindows(EWindowList);
   SetActiveWindow(EActiveWindow);
  end;
end;

procedure TFormProgressCancel.FormShow(Sender: TObject);
begin
 bCancel := false;
end;

procedure TFormProgressCancel.bnCancelClick(Sender: TObject);
begin
 bCancel := true;
end;

end.
