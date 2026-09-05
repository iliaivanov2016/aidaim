unit Test1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Db, DBTables, StdCtrls, EasyTable, ExtCtrls, DBCtrls, Grids, DBGrids;

type
  TForm1 = class(TForm)
    Table1: TTable;
    Test: TDatabase;
    EasyTable1: TEasyTable;
    EasyDatabase1: TEasyDatabase;
    Label1: TLabel;
    Label2: TLabel;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    ODBCTable1: TDataSource;
    OpenTable: TButton;
    CloseTable: TButton;
    DBGrid2: TDBGrid;
    EasyTableTable1: TDataSource;
    ODBCOpenTable: TButton;
    Button2: TButton;
    DBMemo1: TDBMemo;
    DBNavigator2: TDBNavigator;
    DBMemo2: TDBMemo;
    procedure ODBCOpenTableClick(Sender: TObject);
    procedure ODBCCloseTableClick(Sender: TObject);
    procedure EasyTableOpenTableClick(Sender: TObject);
    procedure EasyTableCloseTableClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

Function SQLConnect  (
           ConnectionHandle:Integer;
      		 ServerName:pCHAR;
      		 ServerNameLength:smallInt;
      		 UserName:pCHAR;
      		 UserNameLength:smallInt;
		       Authentication:pCHAR;
      		 AuthLength:smallInt
                      ): SmallInt;stdcall;far;external 'odbc32.dll'

implementation

{$R *.DFM}

//EsyTable

procedure TForm1.EasyTableOpenTableClick(Sender: TObject);
begin
  EasyTable1.Active:=true;
  DBMemo2.DataField:='MemoField'
end;

procedure TForm1.EasyTableCloseTableClick(Sender: TObject);
begin
  EasyTable1.Active:=False;
end;

//ODBC Driver

procedure TForm1.ODBCOpenTableClick(Sender: TObject);
begin
  Table1.Active:=true;
  DBMemo1.DataField:='MemoField'
end;

procedure TForm1.ODBCCloseTableClick(Sender: TObject);
begin
  Table1.Active:=false;
end;

end.
