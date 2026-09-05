unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, DBCtrls, Grids, DBGrids, DB, 
  ACRMain;

type
  TForm1 = class(TForm)
    dsMaster: TDataSource;
    dsDetail: TDataSource;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    DBGrid2: TDBGrid;
    DBNavigator2: TDBNavigator;
    Button1: TButton;
    tMaster: TACRTable;
    tDetail: TACRTable;
    procedure Button1Click(Sender: TObject);
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

procedure TForm1.Button1Click(Sender: TObject);
begin
 Close();
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
 tMaster.TableName := 'master';
 tMaster.ClearDefinitions;
 tMaster.FieldDefs.Add('id',ftAutoInc);
 tMaster.FieldDefs.Add('name',ftFixedChar,25);
 tMaster.IndexDefs.Add('pk','id',[ixPrimary]);
 tMaster.CreateTable;
 tMaster.Open();
 tMaster.Insert;
 tMaster.Fields[1].AsString := 'Master #1';
 tMaster.Post;
 tMaster.Insert;
 tMaster.Fields[1].AsString := 'Master #2';
 tMaster.Post;
 tMaster.Insert;
 tMaster.Fields[1].AsString := 'Master #3';
 tMaster.Post;
 tDetail.TableName := 'detail';
 tDetail.ClearDefinitions;
 tDetail.FieldDefs.Add('id',ftAutoInc);
 tDetail.FieldDefs.Add('masterID',ftInteger);
 tDetail.FieldDefs.Add('name',ftFixedChar,25);
 tDetail.IndexDefs.Add('pk','id',[ixPrimary]);
 tDetail.IndexDefs.Add('fk','masterID',[]);
 tDetail.ForeignKeyDefs.Add('fk','masterID','master');
 tDetail.CreateTable;
 tDetail.IndexName := 'fk';
 tDetail.Open();
 tDetail.Insert;
 tDetail.Fields[1].AsInteger := 1;
 tDetail.Fields[2].AsString := 'Detail #1 from Master #1';
 tDetail.Post;
 tDetail.Insert;
 tDetail.Fields[1].AsInteger := 1;
 tDetail.Fields[2].AsString := 'Detail #2 from Master #1';
 tDetail.Post;
 tDetail.Insert;
 tDetail.Fields[1].AsInteger := 1;
 tDetail.Fields[2].AsString := 'Detail #3 from Master #1';
 tDetail.Post;
 tDetail.Insert;
 tDetail.Fields[1].AsInteger := 2;
 tDetail.Fields[2].AsString := 'Detail #1 from Master #2';
 tDetail.Post;
 tDetail.Insert;
 tDetail.Fields[1].AsInteger := 2;
 tDetail.Fields[2].AsString := 'Detail #2 from Master #2';
 tDetail.Post;
 tDetail.MasterSource := dsMaster;
 tDetail.MasterFields := 'ID';
 tMaster.First;
end;


end.
