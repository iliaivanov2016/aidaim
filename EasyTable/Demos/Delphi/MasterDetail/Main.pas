unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, ExtCtrls, Grids, DBGrids, Db, EasyTable, DBCtrls;

type
  TMainForm = class(TForm)
    EasyTable1: TEasyTable;
    DataSource1: TDataSource;
    Panel2: TPanel;
    Label1: TLabel;
    GroupBox1: TGroupBox;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    GroupBox2: TGroupBox;
    DBGrid2: TDBGrid;
    DBNavigator2: TDBNavigator;
    EasyTable2: TEasyTable;
    DataSource2: TDataSource;
    EasyDatabase1: TEasyDatabase;
    procedure FormCreate(Sender: TObject);
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
 // open table
 EasyTable1.Active := true;
 EasyTable2.Active := true;
end;

end.
