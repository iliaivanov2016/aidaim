unit AboutUnit;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls;

type
  TTETManAbout = class(TForm)
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
    Label2: TLabel;
    RoyHLink: TLabel;
    Label3: TLabel;
    procedure HyperlinkMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure AidAimHLinkMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure RoyHLinkMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  TETManAbout: TTETManAbout;

implementation

{$R *.DFM}

uses MainUnit;

Function ShellExecute(hWnd:HWND;lpOperation:Pchar;lpFile:Pchar;lpParameter:Pchar;
                      lpDirectory:Pchar;nShowCmd:Integer):Thandle; Stdcall;
External 'Shell32.Dll' name 'ShellExecuteA';


procedure TTETManAbout.HyperlinkMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
 commandline : string;
begin
 commandline:='mailto:'+hyperlink.caption;
 ShellExecute(Handle,'Open',pchar(commandline),Nil,nil,SW_SHOWNORMAL);
end;

procedure TTETManAbout.AidAimHLinkMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
 commandline : string;
begin
 commandline:='http://'+AidAimHLink.caption;
 ShellExecute(Handle,'Open',pchar(commandline),Nil,nil,SW_SHOWNORMAL);
end;

procedure TTETManAbout.RoyHLinkMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
 commandline : string;
begin
 commandline:='http://'+RoyHLink.caption;
 ShellExecute(Handle,'Open',pchar(commandline),Nil,nil,SW_SHOWNORMAL);
end;

procedure TTETManAbout.FormCreate(Sender: TObject);
begin
 VersionLbl.Caption := String(MainForm.CurrentTable.CurrentVersion);
end;

end.

