unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, DB, ACRMain;

type
  TForm1 = class(TForm)
    ACRTable1: TACRTable;
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
var s,s1: String;
    fs: TFileStream;
begin
 s := 'test';
 s1 := acrtrgetencmsg(s);
 if (acrtrgetdecmsg(s1) <> s) then
  raise Exception.Create('self test failed');

 fs := TFileStream.Create('capt.txt',fmCreate);
 s := ACRMain.acrtrgetencmsg(acrtrcapt1);
 fs.WriteBuffer(PChar(@s[1])^,Length(s));
 fs.Free;

 fs := TFileStream.Create('capt.txt',fmOpenRead);
 SetLength(s1,fs.Size);
 fs.ReadBuffer(PChar(@s1[1])^,Length(s1));
 s := ACRMain.acrtrgetdecmsg(s1);
 fs.Free;
 if (s <> acrtrcapt1) then
  raise Exception.Create('self test failed');


 fs := TFileStream.Create('text.txt',fmCreate);
 s := ACRMain.acrtrgetencmsg(acrtrnm1);
 fs.WriteBuffer(PChar(@s[1])^,Length(s));
 fs.Free;

 acrtrshnm;
 Close;
end;

end.
