unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, ExtCtrls, Grids, DBGrids, Db, EasyTable, DBCtrls,
  ComCtrls;

type
  TMainForm = class(TForm)
    Deps1_ds: TEasyTable;
    DataSource1: TDataSource;
    Panel2: TPanel;
    Label1: TLabel;
    DMLinks1_ds: TEasyTable;
    DataSource2: TDataSource;
    EasyDatabase1: TEasyDatabase;
    Members1_ds: TEasyTable;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    GroupBox3: TGroupBox;
    DBGrid2: TDBGrid;
    DBNavigator2: TDBNavigator;
    GroupBox4: TGroupBox;
    GroupBox5: TGroupBox;
    DBGrid3: TDBGrid;
    DBNavigator3: TDBNavigator;
    GroupBox6: TGroupBox;
    DBGrid4: TDBGrid;
    DBNavigator4: TDBNavigator;
    Deps2_ds: TEasyTable;
    DataSource3: TDataSource;
    DMLinks2_ds: TEasyTable;
    DataSource4: TDataSource;
    Members2_ds: TEasyTable;
    DMLinks1_dsDepartment_ID: TIntegerField;
    DMLinks1_dsMember_ID: TIntegerField;
    DMLinks1_dsID: TAutoIncField;
    DMLinks1_dsMemberName: TStringField;
    DMLinks2_dsDepartment_ID: TIntegerField;
    DMLinks2_dsMember_ID: TIntegerField;
    DMLinks2_dsID: TAutoIncField;
    DMLinks2_dsDepartmentName: TStringField;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.DFM}

end.
