unit AboutUnit;

interface

{$I ACRManager.Inc}

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls;
           
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
    Label2: TLabel;
    RoyHLink: TLabel;
    Label3: TLabel;
    Label4: TLabel;
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
 commandline:='http://' + AidAimHLink.caption;
 ShellExecute(Handle,'Open',pchar(commandline),Nil,nil,SW_SHOWNORMAL);
end;

procedure TACRManAbout.RoyHLinkMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
 commandline : string;
begin
 commandline:='http://' + RoyHLink.caption;
 ShellExecute(Handle,'Open ',pchar(commandline),Nil,nil,SW_SHOWNORMAL);
end;

procedure TACRManAbout.FormCreate(Sender: TObject);
begin
 VersionLbl.Caption := MainForm.CurrentTable.CurrentVersion;
end;

end.

