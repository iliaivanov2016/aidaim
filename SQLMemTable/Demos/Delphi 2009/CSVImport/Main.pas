unit Main;

interface

{$IFDEF VER200}
{$WARN IMPLICIT_STRING_CAST OFF}
{$WARN IMPLICIT_STRING_CAST_LOSS OFF}
{$ENDIF}

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, DBCtrls, Grids, DBGrids, StdCtrls, DB,
  ADODB, SQLMemMain, SQLMemTypes;

type
  TForm1 = class(TForm)
    dsADO: TDataSource;
    ADODataSet1: TADODataSet;
    GroupBox1: TGroupBox;
    DBGrid2: TDBGrid;
    DBNavigator2: TDBNavigator;
    dsSQLMemTable: TDataSource;
    GroupBox2: TGroupBox;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    Label1: TLabel;
    SQLMemTable1: TSQLMemTable;
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
 SQLMemTable1.Close;
 ADODataSet1.Open;
 // Import all data from CSV file to SQLMemTable Table
 if not SQLMemTable1.ImportTable(ADODataSet1, Log)
  then
   MessageDlg('Error importing table. Error Log: '+log, mtError, [mbOK], 0);
 SQLMemTable1.Open; // Open the SQLMemTable table
end;

end.
