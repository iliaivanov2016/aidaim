unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,singlefilesystem;

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
var
   sfs :  TSingleFileSystem;
   fs  :  TSFSFileStream;
   buffer : array [0..20000] of char;
   bytesread : integer;
begin

   sfs := TSingleFileSystem.Create ( 'test.sfs', fmCreate );
   fs := TSFSFileStream.Create( sfs, 'test.dat', fmCreate );
   fs.Write( buffer, 3000 ); // I'm writing 3000 bytes
   fs.free;

   fs := TSFSFileStream.Create( sfs, 'test.dat', fmOpenRead );
   bytesread:=fs.Read( buffer, 20000 ); // It returns 4064 bytes????
  // writeln ('Bytes Read : ',bytesread );
   bytesread:=fs.Read( buffer, 2000 ); // Now it returns 0
//   writeln ('Bytes Read : ',bytesread );

   fs.free;
   sfs.free;
end;

end.
