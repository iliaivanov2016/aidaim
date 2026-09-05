unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
 Db, ExtCtrls, DBCtrls, Grids, DBGrids, StdCtrls, ACRMain;

type
  TMainForm = class(TForm)
    DataSource1: TDataSource;
    DataSource2: TDataSource;
    DBGrid1: TDBGrid;
    DBGrid2: TDBGrid;
    DBNavigator1: TDBNavigator;
    DBNavigator2: TDBNavigator;
    Label1: TLabel;
    ACRDatabase1: TACRDatabase;
    ACRTable1: TACRTable;
    ACRTable2: TACRTable;
    procedure FormCreate(Sender: TObject);
    procedure ACRTable1AfterPost(DataSet: TDataSet);
    procedure ACRTable2AfterPost(DataSet: TDataSet);
    procedure ACRTable1AfterDelete(DataSet: TDataSet);
    procedure ACRTable2AfterDelete(DataSet: TDataSet);
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
 ACRTable1.Active := true;
 ACRTable2.Active := true;
end;

procedure TMainForm.ACRTable1AfterPost(DataSet: TDataSet);
begin
 ACRTable2.Refresh;
end;

procedure TMainForm.ACRTable2AfterPost(DataSet: TDataSet);
begin
 ACRTable1.Refresh;
end;

procedure TMainForm.ACRTable1AfterDelete(DataSet: TDataSet);
begin
 ACRTable2.Refresh;
end;

procedure TMainForm.ACRTable2AfterDelete(DataSet: TDataSet);
begin
 ACRTable1.Refresh;
end;

end.
