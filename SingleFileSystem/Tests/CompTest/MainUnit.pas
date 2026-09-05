unit MainUnit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  FFSFileManage;

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
var fs,fs1: TFileStream;
    time:   Cardinal;
    size:   Cardinal;
    buf:    pChar;
    cs:     TCompressedStream;
begin
 fs := TFileStream.Create('d:\temp\test.txt',fmOpenRead);
 fs1 := TFileStream.Create('d:\temp\test.aa',fmCreate);
 cs := TCompressedStream.Create(fs1,clNone);
 buf:= AllocMem(fs.Size);
 fs.ReadBuffer(buf^,fs.Size);
 time := GetTickCount;
 cs.WriteBuffer(buf^,fs.Size);
 ShowMessage(inttostr(GetTickCount - time));
 FreeMem(buf);
 fs.Free;
 cs.Free;
 fs1.Free;
 Form1.Close;
 Application.Terminate;
end;

end.
