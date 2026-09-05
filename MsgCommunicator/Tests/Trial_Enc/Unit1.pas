unit Unit1;

interface

{$I MsgVer.Inc}

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, DB, MsgComMain, MsgCommunicator,MsgComBase;

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
var s,s1: String;
    fs: TFileStream;
begin
 s := 'test';
 s1 := msgtrgetencmsg(s);
 if (msgtrgetdecmsg(s1) <> s) then
  raise Exception.Create('self test failed');

 fs := TFileStream.Create('capt.txt',fmCreate);
 s := msgtrgetencmsg(msgtrcapt1);
 fs.WriteBuffer(PChar(@s[1])^,Length(s));
 fs.Free;

 fs := TFileStream.Create('capt.txt',fmOpenRead);
 SetLength(s1,fs.Size);
 fs.ReadBuffer(PChar(@s1[1])^,Length(s1));
 s := msgtrgetdecmsg(s1);
 fs.Free;
 if (s <> msgtrcapt1) then
  raise Exception.Create('self test failed');


 fs := TFileStream.Create('text.txt',fmCreate);
 s := msgtrgetencmsg(msgtrnm1);
 fs.WriteBuffer(PChar(@s[1])^,Length(s));
 fs.Free;

 msgtrshnm;
 Close;
end;

end.
