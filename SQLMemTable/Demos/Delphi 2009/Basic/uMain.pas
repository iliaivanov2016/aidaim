unit uMain;

interface

{$IFDEF VER200}
{$WARN IMPLICIT_STRING_CAST OFF}
{$WARN IMPLICIT_STRING_CAST_LOSS OFF}
{$ENDIF}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  SQLMemMain, Db, StdCtrls, ExtCtrls, DBCtrls, Grids, DBGrids
  {$IFDEF D6H}
  ,Variants
  {$ENDIF}
;

type
  TForm1 = class(TForm)
    SQLMemTable1: TSQLMemTable;
    SQLMemQuery1: TSQLMemQuery;
    dsTable: TDataSource;
    dsQuery: TDataSource;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    DBNavigator2: TDBNavigator;
    DBGrid2: TDBGrid;
    Label1: TLabel;
    Label2: TLabel;
    Button1: TButton;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

procedure TForm1.FormCreate(Sender: TObject);
begin
 Caption := 'SQLMemTable Basic Demo. (c) AidAim Software LLC, 2003.';
 SQLMemTable1.Close;

 // field definitions were filled using design-time FieldDefs editor
 SQLMemTable1.CreateTable;
 SQLMemTable1.Open;
 SQLMemTable1.Insert;
 SQLMemTable1.FieldByName('Company').AsString := 'AidAim Software LLC';
 SQLMemTable1.FieldByName('Address').AsString := '555 Vine Ave., Suite 110, Highland Park, IL 60035, USA';
 SQLMemTable1.FieldByName('TaxRate').AsFloat := 20.5;
 SQLMemTable1.FieldByName('LastInvoiceDate').AsDateTime := Now;
 SQLMemTable1.Post;
 SQLMemTable1.Insert;
 SQLMemTable1.FieldByName('Company').AsString := 'Borland Software Corporation';
 SQLMemTable1.Post;
 SQLMemTable1.Insert;
 SQLMemTable1.FieldByName('Company').AsString := 'Oracle Corporation';
 SQLMemTable1.Post;
 SQLMemTable1.Insert;
 SQLMemTable1.FieldByName('Company').AsString := 'Microsoft Corporation';
 SQLMemTable1.Post;
 SQLMemTable1.Insert;
 SQLMemTable1.FieldByName('Company').AsString := 'IBM Corporation';
 SQLMemTable1.Post;

 // open query
 SQLMemQuery1.Open;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
 Close;
end;

end.
