unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, EasyTable, ExtCtrls, DBCtrls, Grids, DBGrids, StdCtrls, DB,
  ADODB;

type
  TForm1 = class(TForm)
    dsADO: TDataSource;
    ADODataSet1: TADODataSet;
    GroupBox1: TGroupBox;
    DBGrid2: TDBGrid;
    DBNavigator2: TDBNavigator;
    dsEasyTable: TDataSource;
    EasyTable1: TEasyTable;
    GroupBox2: TGroupBox;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    Label1: TLabel;
    procedure FormCreate(Sender: TObject);
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
 var Log: String;
begin
 EasyTable1.Close;
 ADODataSet1.Open;
 // Import all data from CSV file to EasyTable
 if not EasyTable1.ImportTable(dsADO,ADODataSet1.IndexDefs, Log)
  then
   MessageDlg('Error importing table. Error Log: '+log, mtError, [mbOK], 0);
 EasyTable1.Open; // Open the EasyTable table
end;

end.
