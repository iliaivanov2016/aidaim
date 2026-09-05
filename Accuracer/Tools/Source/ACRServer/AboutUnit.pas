unit AboutUnit;

interface

{$I ver.inc}

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls, ACRConst;

type
  TACRManAbout = class(TForm)
    Panel1: TPanel;
    ProgramIcon: TImage;
    ProductName: TLabel;
    Version: TLabel;
    OKButton: TButton;
    Hyperlink: TLabel;
    Label6: TLabel;
    Label1: TLabel;
    AidAimHLink: TLabel;
    Label10: TLabel;
    VersionLbl: TLabel;
    procedure HyperlinkMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure AidAimHLinkMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ACRManAbout: TACRManAbout;

implementation

{$R *.DFM}

uses MainUnit;

Function ShellExecute(hWnd:HWND;lpOperation:Pchar;lpFile:Pchar;lpParameter:Pchar;
                      lpDirectory:Pchar;nShowCmd:Integer):Thandle; Stdcall;
External 'Shell32.Dll' name 'ShellExecuteA';


procedure TACRManAbout.HyperlinkMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
 commandline : string;
begin
 commandline:=hyperlink.caption;
 ShellExecute(Handle,'Open',pchar(commandline),Nil,nil,SW_SHOWNORMAL);
end;

procedure TACRManAbout.AidAimHLinkMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
 commandline : string;
begin
 commandline:='http://'+AidAimHLink.caption;
 ShellExecute(Handle,'Open',pchar(commandline),Nil,nil,SW_SHOWNORMAL);
end;

procedure TACRManAbout.FormCreate(Sender: TObject);
begin
 VersionLbl.Caption := MainForm.Server.CurrentVersion+' '+ACRBuildInfo;
{$IFDEF DEBUG_SERVER}
 ProductName.Caption := ProductName.Caption + ' - DEBUG';
{$ENDIF}
end;

end.

