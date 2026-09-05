unit TableProgressCancel;

interface

{$I ACRManager.inc}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Gauges, Buttons;

type
  TFormTableProgressCancel = class(TForm)
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
  end;

var
  FormTableProgressCancel: TFormTableProgressCancel;

implementation

uses MainUnit;

{$R *.DFM}

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
function TFormTableProgressCancel.MessageHook(var Msg: TMessage): Boolean;
begin
  Result := False;
end;


//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
procedure TFormTableProgressCancel.FormClose(Sender: TObject;var Action: TCloseAction);
var time: Cardinal;
begin
 if (mResult = mrCancel) then
  begin
   action := caNone;
   mResult := mrOk;
  end
 else
  begin
   TableIndicator.Progress := 100;
   time := GetTickCount;
   while GetTickCount - time < 500 do
    Application.ProcessMessages;
   Application.UnhookMainWindow(MessageHook);
   EnableTaskWindows(EWindowList);
   SetActiveWindow(EActiveWindow);
  end;
end;

procedure TFormTableProgressCancel.FormShow(Sender: TObject);
begin
 bCancel := false;
end;

procedure TFormTableProgressCancel.bnCancelClick(Sender: TObject);
begin
 bCancel := true;
end;

end.
