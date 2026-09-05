unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, ExtCtrls, Grids, DBGrids, Db, DBCtrls,
  ACRMain;

type
  TMainForm = class(TForm)
    DataSource1: TDataSource;
    Panel2: TPanel;
    Label1: TLabel;
    GroupBox1: TGroupBox;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    GroupBox2: TGroupBox;
    DBGrid2: TDBGrid;
    DBNavigator2: TDBNavigator;
    DataSource2: TDataSource;
    ACRDatabase1: TACRDatabase;
    ACRTable1: TACRTable;
    ACRTable2: TACRTable;
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
 ACRTable1.Active := true;
 ACRTable2.Active := true;
end;

end.
