unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, ExtCtrls, Grids, DBGrids, Db, DBCtrls,
  ComCtrls, ACRMain;

type
  TMainForm = class(TForm)
    DataSource1: TDataSource;
    Panel2: TPanel;
    Label1: TLabel;
    DataSource2: TDataSource;
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
    DataSource3: TDataSource;
    DataSource4: TDataSource;
    ACRDatabase1: TACRDatabase;
    Deps1_ds: TACRTable;
    Members2_ds: TACRTable;
    DMLinks1_ds: TACRTable;
    DMLinks2_ds: TACRTable;
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
 ACRDatabase1.Open;
 Deps1_ds.Open;
 Members2_ds.Open;
 DMLinks1_ds.Open;
 DMLinks2_ds.Open;
end;

end.
