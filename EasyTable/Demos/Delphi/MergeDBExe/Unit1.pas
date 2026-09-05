unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, EasyTable;

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
    Database:       TEasyDatabase;
begin
  ExeFile := ParamStr(1);
  DBFile := ParamStr(2);
  Database := TEasyDatabase.Create(nil);
  try
    Database.DatabaseName := 'edb';
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
