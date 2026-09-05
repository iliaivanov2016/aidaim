unit ProgressIndicator;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Gauges;

type
  TFormProgress = class(TForm)
    Indicator: TGauge;
    lbCaption: TLabel;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
    mResult : integer;
    EWindowList:pointer;
    EActiveWindow:HWND;
    function MessageHook(var Msg: TMessage): Boolean;
    procedure SetIndicator(v:integer);
  end;

var
  FormProgress: TFormProgress;

implementation

uses MainUnit;

{$R *.DFM}

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
function TFormProgress.MessageHook(var Msg: TMessage): Boolean;
begin
  Result := False;
end;


//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
procedure TFormProgress.SetIndicator(v:integer);
begin
 Indicator.Progress := v;
end;


//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
procedure TFormProgress.FormClose(Sender: TObject;var Action: TCloseAction);
begin
 if (mResult = mrCancel) then
  begin
   action := caNone;
   mResult := mrOk;
  end
 else
  begin
   Application.UnhookMainWindow(MessageHook);
   EnableTaskWindows(EWindowList);
   SetActiveWindow(EActiveWindow);
  end;
end;

end.
