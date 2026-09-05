unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, SingleFileSystem;

type
  TForm1 = class(TForm)
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

procedure TForm1.FormCreate(Sender: TObject);
var sfs: TSingleFileSystem;
begin
 sfs := TSingleFileSystem.Create('test.sfs',fmCreate);
 sfs.ImportFiles('test.exe');
 sfs.ImportFiles('test.dll');

 if (sfs.LoadLibrary('test.dll') = 0) then
  ShowMessage('dll not loaded');
 if (not sfs.RunApplication('test.exe')) then
  ShowMessage('exe not started');
 sfs.Free;
end;

end.
