unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, SingleFileSystem;

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

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
const name = 'test.sfs';
var sfs: TSingleFileSystem;
    sr: TSearchRec;
    res: Integer;
begin
  if SysUtils.FileExists(name) then
   SysUtils.DeleteFile(name);
  sfs := TSingleFileSystem.Create(name,fmCreate);
  try
   sfs.ImportFiles('*.pas');
  finally
   sfs.Free;
  end;
  res := FindFirst(name,faAnyFile,sr);
  if res  <> 0 then
   ShowMessage('File does not exists: '+name)
  else
   begin
    ShowMessage('Size: '+IntToStr(sr.Size));
    FindClose(sr);
   end;

end;


end.
