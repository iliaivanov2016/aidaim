unit AboutUnit;

interface 

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls, SFSEngine;

type
  TSFSManagerAbout = class(TForm)
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
  SFSManagerAbout: TSFSManagerAbout;

implementation

{$R *.DFM}

Function ShellExecute(hWnd:HWND;lpOperation:Pchar;lpFile:Pchar;lpParameter:Pchar;
                      lpDirectory:Pchar;nShowCmd:Integer):Thandle; Stdcall;
External 'Shell32.Dll' name 'ShellExecuteA';


procedure TSFSManagerAbout.HyperlinkMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
 commandline : string;
begin
 commandline:='mailto:'+hyperlink.caption;
 ShellExecute(Handle,'Open',pchar(commandline),Nil,nil,SW_SHOWNORMAL);
end;

procedure TSFSManagerAbout.AidAimHLinkMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
 commandline : string;
begin
 commandline:='http://'+AidAimHLink.caption;
 ShellExecute(Handle,'Open',pchar(commandline),Nil,nil,SW_SHOWNORMAL);
end;

procedure TSFSManagerAbout.FormCreate(Sender: TObject);
begin
 VersionLbl.Caption := FloatToStrF(SFSCurrentVersion,ffFixed,3,2);
end;

end.

