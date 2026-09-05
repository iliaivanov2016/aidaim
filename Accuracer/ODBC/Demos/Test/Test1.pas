unit Test1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Db, DBTables, StdCtrls, ACRMain, ExtCtrls, DBCtrls, Grids, DBGrids,
  EasyTable;

type
  TForm1 = class(TForm)
    Table1: TTable;
    Database1: TDatabase;
    ACRTable1: TACRTable;
    ACRDatabase1: TACRDatabase;
    Label1: TLabel;
    Label2: TLabel;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    ODBCTable1: TDataSource;
    OpenTable: TButton;
    CloseTable: TButton;
    DBGrid2: TDBGrid;
    ODBCOpenTable: TButton;
    Button2: TButton;
    DBMemo1: TDBMemo;
    DBNavigator2: TDBNavigator;
    DBMemo2: TDBMemo;
    AccuracerTable1: TDataSource;
    procedure ODBCOpenTableClick(Sender: TObject);
    procedure ODBCCloseTableClick(Sender: TObject);
    procedure ACRTableOpenTableClick(Sender: TObject);
    procedure ACRTableCloseTableClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

//Accuracer

procedure TForm1.ACRTableOpenTableClick(Sender: TObject);
begin
  ACRDatabase1.Open;
  ACRTable1.Open;
  DBMemo2.DataField:='MemoField'
end;

procedure TForm1.ACRTableCloseTableClick(Sender: TObject);
begin
  ACRTable1.Close;
  ACRDatabase1.Close;
end;

//ODBC Driver

procedure TForm1.ODBCOpenTableClick(Sender: TObject);
begin
  Database1.Open;
  Table1.Open;
  DBMemo1.DataField:='MemoField'
end;

procedure TForm1.ODBCCloseTableClick(Sender: TObject);
begin
  Table1.Close;
  Database1.Close;
end;

end.
