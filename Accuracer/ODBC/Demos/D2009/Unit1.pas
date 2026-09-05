unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, DBTables, StdCtrls, ExtCtrls, DBCtrls, Grids, DBGrids;

type
  TForm1 = class(TForm)
    btnOpen: TButton;
    btnClose: TButton;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    Table1: TTable;
    procedure btnOpenClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.btnOpenClick(Sender: TObject);
begin
  Table1.Open;
end;

procedure TForm1.btnCloseClick(Sender: TObject);
begin
  Table1.Close;
end;

end.
