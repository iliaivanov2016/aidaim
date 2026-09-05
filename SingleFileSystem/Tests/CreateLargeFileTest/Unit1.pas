unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, SingleFileSystem,
  StdCtrls, Gauges;

type
  TForm1 = class(TForm)
    Indicator: TGauge;
    Button1: TButton;
    Label1: TLabel;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
   procedure SetIndicator(
                              Sender      : TObject;
                              PercentDone : Real
													);
  end;

var
  Form1: TForm1;

const SFSFileName = 'e:\test.sfs';
const FileName = 'test.bin';
const OutFileName = 'f:\test.bin';
var SFSSize: Int64 = Int64 (Int64(7*1024*1024) * Int64(1024));
//var SFSSize: Int64 = Int64 (Int64(600*1024) * Int64(1024));

implementation

{$R *.DFM}

procedure TForm1.SetIndicator(
                              Sender      : TObject;
                              PercentDone : Real
													);
begin
 Indicator.Progress := Round(PercentDone);
 Application.ProcessMessages;
end;


procedure TForm1.Button1Click(Sender: TObject);
var fs: TFileStream;
    sfs: TSFSFileStream;
    bf: TSingleFileSystem;
begin
 if (IsSFSFile(SFSFileName)) then
  DeleteSFS(SFSFileName);
 bf := TSingleFileSystem.Create(SFSFileName,fmCreate);
 sfs := TSFSFileStream.Create(bf,FileName,fmCreate);
 fs := TFileStream.Create(OutFileName,fmCreate);

 sfs.OnProgress := SetIndicator;

 Label1.Caption := 'creating file';
 Application.ProcessMessages;

 sfs.Size := SFSSize;

ShowMessage('ok');
 Label1.Caption := 'loading file';
 sfs.LoadFromFile('e:\test.bin');

 Label1.Caption := 'saving file';
 Application.ProcessMessages;

 sfs.SaveToStream(fs);

 fs.Free;
 bf.Free;

 ShowMessage('all ok');
end;

end.
