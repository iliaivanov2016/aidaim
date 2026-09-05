unit Main;

interface

{$I ..\..\Ver.Inc}

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, DBCtrls, Grids, DBGrids, StdCtrls, DB,
  ADODB, ACRMain;

type
  TForm1 = class(TForm)
    dsADO: TDataSource;
    ADODataSet1: TADODataSet;
    GroupBox1: TGroupBox;
    DBGrid2: TDBGrid;
    DBNavigator2: TDBNavigator;
    dsEasyTable: TDataSource;
    GroupBox2: TGroupBox;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    Label1: TLabel;
    ACRTable1: TACRTable;
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
 var Log: AnsiString;
begin
 ACRTable1.Close;
 ADODataSet1.Open;
 // Import all data from CSV file to Accuracer Table
 if not ACRTable1.ImportTable(ADODataSet1, Log)
  then
   MessageDlg('Error importing table. Error Log: '+log, mtError, [mbOK], 0);
 ACRTable1.Open; // Open the Accuracer Table table
end;

end.
