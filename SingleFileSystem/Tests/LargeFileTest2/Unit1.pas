unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, SingleFileSystem,
  StdCtrls, Gauges;

type
  TForm1 = class(TForm)
    Indicator: TGauge;
    Button1: TButton;
    Label2: TLabel;
    edTestFileName: TEdit;
    Button2: TButton;
    OpenDialog1: TOpenDialog;
    Log: TMemo;
    Button3: TButton;
    edSFSFileName: TEdit;
    Label1: TLabel;
    Button4: TButton;
    edDestFileName: TEdit;
    Label3: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
   procedure SetIndicator1(
                              Sender:       TObject;
                              PercentDone:  Real;
                              // including relative path
                              FileName:   string
                             		);
   procedure SetIndicator(
                              Sender      : TObject;
                              PercentDone : Real
													);
  end;

var
  Form1: TForm1;

var SFSFileName: string;
var FileName: string;
var OutFileName: string;
var SFSSize: Int64 = Int64 (Int64(200 * 1024) * Int64(1024));

implementation

{$R *.DFM}

procedure TForm1.SetIndicator1(
                              Sender:       TObject;
                              PercentDone:  Real;
                              // including relative path
                              FileName:   string
                             		);
begin
 Indicator.Progress := Round(PercentDone);
 Application.ProcessMessages;
end;

procedure TForm1.SetIndicator(
                              Sender      : TObject;
                              PercentDone : Real
													);
begin
 Indicator.Progress := Round(PercentDone);
 Application.ProcessMessages;
end;


procedure TForm1.Button1Click(Sender: TObject);
var
    fs: TFileStream;
    sfs: TSFSFileStream;
    bf: TSingleFileSystem;

    Handle: Integer;
    buf: pChar;
    size, buf_size,sz: Integer;
begin
// SFSFileName := 'e:\test.sfs';
// OutFileName := 'f:\test.bin';
// SFSFileName := 'e:\test.sfs';

 SFSFileName := edSFSFileName.Text;
 OutFileName := edDestFileName.Text;
 FileName := edTestFileName.Text;

 if (not FileExists(FileName)) then
  begin
   MessageDlg('File '+FileName+' does not exists!',mtError,[mbOk],0);
   Exit;
  end;

 Log.Lines.Add('creating file '+SFSFileName+' ...'+#13#10);

 if (IsSFSFile(SFSFileName)) then
  DeleteSFS(SFSFileName);
 bf := TSingleFileSystem.Create(SFSFileName,fmCreate);
// sfs := TSFSFileStream.Create(bf,ExtractFileName(FileName),fmCreate);

 Handle := bf.FileOpen(ExtractFileName(FileName),fmCreate);
 if (Handle < 0) then
  raise Exception.Create('Error creating file '+ExtractFileName(FileName));
 fs := TFileStream.Create(FileName,fmopenRead or fmShareDenyWrite);


// bf.OnFileProgress := SetIndicator1;
// sfs.OnProgress := SetIndicator;

 Log.Lines.Add('loading file by FileRead '+FileName+' ...'+#13#10);
 Application.ProcessMessages;

// sfs.LoadFromFile(FileName);
 // loading file ....
 buf_size := 1024*1024;
 buf := AllocMem(buf_size);
 try
  while fs.Position < fs.Size do
   begin
    if (fs.Size - fs.Position > buf_size) then
     size := buf_size
    else
     size := fs.Size - fs.Position;
    fs.ReadBuffer(buf^,size);
    sz := bf.FileWrite(Handle,buf^,size);
    if (sz <> size) then
     begin
      showMessage('error, sz = '+IntToStr(sz)+', size = '+IntToStr(size));
      Close;
      Application.Terminate;
     end;
   end;
 finally
  bf.FileClose(Handle);
  fs.Free;
  FreeMem(buf);
 end;


// sfs.Size := SFSSize;

 Log.Lines.Add('file '+FileName+' loaded successfully. Size = '+
   IntToStr(bf.FileSeek(Handle,0,soFromEnd))+#13#10);
   //IntToStr(sfs.Size)+#13#10);
 Application.ProcessMessages;

 sfs := TSFSFileStream.Create(bf,ExtractFileName(FileName),fmOpenRead);

 Log.Lines.Add('saving file '+sfs.FileName+' to file '+OutFileName+' ...'+#13#10);
 Indicator.Progress := 0;
 Application.ProcessMessages;

 sfs.SaveToFile(OutFileName);

 Log.Lines.Add('file '+sfs.FileName+' saved successfully. Size = '+IntToStr(sfs.Size)+#13#10);
 Application.ProcessMessages;

 sfs.Free;
 bf.Free;

 Log.Lines.Add('all ok');
 ShowMessage('All OK');
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
 if (OpenDialog1.Execute) then
  edTestFileName.Text := OpenDialog1.FileName;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
 if (OpenDialog1.Execute) then
  edSFSFileName.Text := OpenDialog1.FileName;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
 if (OpenDialog1.Execute) then
  edDestFileName.Text := OpenDialog1.FileName;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
 OpenDialog1.InitialDir := ExtractFilePath(Application.ExeName);
end;

end.
