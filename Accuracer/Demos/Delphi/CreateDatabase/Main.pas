unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Db, StdCtrls, Buttons, DBCtrls, Grids, DBGrids, ExtCtrls,
  ACRMain;

type
  TForm1 = class(TForm)
    Label1: TLabel;
    DataSource1: TDataSource;
    GroupBox1: TGroupBox;
    Panel1: TPanel;
    DBGrid1: TDBGrid;
    DBMemo1: TDBMemo;
    DBNavigator1: TDBNavigator;
    btnCreate: TButton;
    btnOpen: TButton;
    btnClose: TButton;
    ACRDatabase1: TACRDatabase;
    ACRTable1: TACRTable;
    procedure bnCreateClick(Sender: TObject);
    procedure bnOpenClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

procedure TForm1.bnCreateClick(Sender: TObject);
var pass: string;
begin
 ACRDatabase1.Connected := false;
 ACRDatabase1.CreateDatabase;

 ACRTable1.FieldDefs.Clear;
 ACRTable1.FieldDefs.Add('ID',ftAutoInc);
 ACRTable1.FieldDefs.Add('Name',ftString,100);
 ACRTable1.FieldDefs.Add('Surname',ftString,100);
 ACRTable1.FieldDefs.Add('Comments',ftMemo);
 ACRTable1.IndexDefs.Clear;
 ACRTable1.CreateTable;

 ACRTable1.Active := true;
end;

procedure TForm1.bnOpenClick(Sender: TObject);
var pass: string;
    f:		Boolean;
begin
 ACRDatabase1.Connected := true;
 ACRTable1.Active := true;
end;

procedure TForm1.btnCloseClick(Sender: TObject);
begin
 ACRDatabase1.Connected := False;
end;

end.
