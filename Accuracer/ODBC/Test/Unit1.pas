unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, DB, DBTables, ExtCtrls, DBCtrls, Grids, DBGrids;

type
  TForm1 = class(TForm)
    Query1: TQuery;
    Button1: TButton;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    DataSource1: TDataSource;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
 Query1.SQL.Text := 'delete from DATALOG WHERE TransportType=1';
 Query1.ExecSQL;
 Query1.SQL.Text := 'select * from DATALOG';
 Query1.Open;
end;

end.
