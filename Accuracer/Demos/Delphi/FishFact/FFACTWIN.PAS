unit Ffactwin;

{ This application shows how to display Paradox style memo and graphic
 fields in a form. Table1's DatabaseName property should point to the
 Delphi sample database. Table1's TableName property should be set to 
 the BIOLIFE table. }

interface

uses
  SysUtils, Windows, Messages, Classes, Graphics, Controls,
  Forms, StdCtrls, DBCtrls, DBGrids, DB, DBTables, Buttons, Grids, ExtCtrls,
 Dialogs, ACRMain;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    DBImage1: TDBImage;
    DBLabel1: TDBText;
    DBMemo1: TDBMemo;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    Label2: TLabel;
    ACRTable1: TACRTable;
    ACRDatabase1: TACRDatabase;
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
begin
 with ACRTable1 do
  begin
      Active := true;
  end;
end;

end.
