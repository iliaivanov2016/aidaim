unit Ffactwin;

{ This application shows how to display Paradox style memo and graphic
 fields in a form. Table1's DatabaseName property should point to the
 Delphi sample database. Table1's TableName property should be set to 
 the BIOLIFE table. }

interface

uses
  SysUtils, Windows, Messages, Classes, Graphics, Controls,
  Forms, StdCtrls, DBCtrls, DBGrids, DB, DBTables, Buttons, Grids, ExtCtrls,
  EasyTable, Dialogs;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    DBImage1: TDBImage;
    DBLabel1: TDBText;
    DBMemo1: TDBMemo;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    EasyTable1: TEasyTable;
    Label2: TLabel;
    EasyDatabase1: TEasyDatabase;
    EasyTable1Category: TStringField;
    EasyTable1Common_Name: TStringField;
    EasyTable1SpeciesName: TStringField;
    EasyTable1Lengthcm: TFloatField;
    EasyTable1Length_In: TFloatField;
    EasyTable1Notes: TMemoField;
    EasyTable1Graphic: TGraphicField;
    procedure FormCreate(Sender: TObject);
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
 with EasyTable1 do
  begin
      Active := true;
  end;
end;

end.
