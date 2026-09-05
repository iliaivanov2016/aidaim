unit MainForm;

interface

{$I ACRVer.inc}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
{$IFDEF D6H}
  Variants,
{$ENDIF}
  Dialogs, StdCtrls, ExtCtrls;

type
  TForm1 = class(TForm)
    ProcessLog: TMemo;
    Panel1: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Splitter1: TSplitter;
    ErrorLog: TMemo;
    MainLog: TMemo;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 Application.Terminate;
 Application.ProcessMessages;
end;

end.

