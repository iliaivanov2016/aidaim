unit Unit1;

interface

{$I ..\..\ver.inc}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, ACRMain;

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
var ExeFile,DBFile: String;
    Database:       TACRDatabase;
begin
  ExeFile := ParamStr(1);
  DBFile := ParamStr(2);
  Database := TACRDatabase.Create(nil);
  try
    Database.Exclusive := True;
    Database.DatabaseFileName := DBFile;
    Database.MakeExeDatabase(ExeFile,ExeFile+'1');
    DeleteFile(ExeFile);
    RenameFile(ExeFile+'1',ExeFile);
  finally
    Database.Free;
    Close;
    Application.Terminate;
  end;
end;

end.
