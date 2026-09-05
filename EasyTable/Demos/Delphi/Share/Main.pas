unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  EasyTable, Db, ExtCtrls, DBCtrls, Grids, DBGrids, StdCtrls;

type
  TMainForm = class(TForm)
    EasyTable1: TEasyTable;
    DataSource1: TDataSource;
    EasyTable2: TEasyTable;
    DataSource2: TDataSource;
    DBGrid1: TDBGrid;
    DBGrid2: TDBGrid;
    DBNavigator1: TDBNavigator;
    DBNavigator2: TDBNavigator;
    Label1: TLabel;
    EasyDatabase1: TEasyDatabase;
    procedure FormCreate(Sender: TObject);
    procedure EasyTable1AfterPost(DataSet: TDataSet);
    procedure EasyTable2AfterPost(DataSet: TDataSet);
    procedure EasyTable1AfterDelete(DataSet: TDataSet);
    procedure EasyTable2AfterDelete(DataSet: TDataSet);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.DFM}

procedure TMainForm.FormCreate(Sender: TObject);
begin
 EasyTable1.Active := true;
 EasyTable2.Active := true;
end;

procedure TMainForm.EasyTable1AfterPost(DataSet: TDataSet);
begin
 EasyTable2.Refresh;
end;

procedure TMainForm.EasyTable2AfterPost(DataSet: TDataSet);
begin
 EasyTable1.Refresh;
end;

procedure TMainForm.EasyTable1AfterDelete(DataSet: TDataSet);
begin
 EasyTable2.Refresh;
end;

procedure TMainForm.EasyTable2AfterDelete(DataSet: TDataSet);
begin
 EasyTable1.Refresh;
end;

end.
