unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DBClient, ExtCtrls, DBCtrls, Grids, DBGrids, DB,
  Provider, StdCtrls, EasyTable;

type
  TForm1 = class(TForm)
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    cdsQuery: TClientDataSet;
    cdsTable: TClientDataSet;
    DBGrid2: TDBGrid;
    DBNavigator2: TDBNavigator;
    dsTable: TDataSource;
    dsTableProvider: TDataSetProvider;
    dspQueryProvider: TDataSetProvider;
    Button1: TButton;
    DataSource1: TDataSource;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Button2: TButton;
    Label1: TLabel;
    mQuery: TMemo;
    Button3: TButton;
    EasyDatabase1: TEasyDatabase;
    EasyQuery1: TEasyQuery;
    EasyTable1: TEasyTable;
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure cdsTableAfterDelete(DataSet: TDataSet);
    procedure cdsTableAfterPost(DataSet: TDataSet);
    procedure Button3Click(Sender: TObject);
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
begin
 EasyDatabase1.Close;
 EasyDatabase1.Open;
 cdsTable.Open;

 EasyQuery1.SQL.Text := 'create table Table1 (id autoInc, name VarChar(100))';
 EasyQuery1.ExecSQL;

 EasyQuery1.SQL.Text := 'Insert into Table1 (name) values("Leo")';
 EasyQuery1.ExecSQL;

 EasyQuery1.SQL.Text := 'Insert into Table1 (name) values("Ella")';
 EasyQuery1.ExecSQL;

 EasyQuery1.SQL.Text := 'Insert into Table1 (name) values("Gordon")';
 EasyQuery1.ExecSQL;

 EasyQuery1.SQL.Text := 'Insert into Table1 (name) values("John")';
 EasyQuery1.ExecSQL;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
 Close;
 Application.Terminate;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
 cdsQuery.Close;
 cdsQuery.CommandText := mQuery.Text;
 cdsQuery.Open;
end;

procedure TForm1.cdsTableAfterDelete(DataSet: TDataSet);
begin
 cdsTable.ApplyUpdates(0);
end;

procedure TForm1.cdsTableAfterPost(DataSet: TDataSet);
begin
 cdsTable.ApplyUpdates(0);
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
 cdsQuery.Close;
 cdsQuery.CommandText := mQuery.Text;
 cdsQuery.Execute;
 ShowMessage('Query have been executed successfully.');
end;

end.
