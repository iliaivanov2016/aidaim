unit Unit1;

interface

uses
  Windows, Messages, SysUtils, 
  {$IFDEF VER140}
  Variants,
  {$ENDIF}
  Classes, Graphics, Controls, Forms,
  Dialogs, DBClient, ExtCtrls, DBCtrls, Grids, DBGrids, ACRMain, DB,
  Provider, StdCtrls;

type
  TForm1 = class(TForm)
    ACRTable1: TACRTable;
    ACRDatabase1: TACRDatabase;
    ACRQuery1: TACRQuery;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    cdsQuery: TClientDataSet;
    cdsTable: TClientDataSet;
    DBGrid2: TDBGrid;
    DBNavigator2: TDBNavigator;
    dsTable: TDataSource;
    dsTableProvider: TDataSetProvider;
    dspQueryProvider: TDataSetProvider;
    Button1: TButton;
    DataSource1: TDataSource;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Button2: TButton;
    Label1: TLabel;
    mQuery: TMemo;
    Button3: TButton;
    ACRTable2: TACRTable;
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure cdsTableAfterDelete(DataSet: TDataSet);
    procedure cdsTableAfterPost(DataSet: TDataSet);
    procedure Button3Click(Sender: TObject);
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
begin
 ACRDatabase1.Close;
 ACRDatabase1.Open;
 cdsTable.Open;

 ACRTable2.FieldDefs.Clear;
 ACRTable2.AdvFieldDefs.Clear;
 ACRTable2.IndexDefs.Clear;
 ACRTable2.AdvIndexDefs.Clear;
 ACRTable2.FieldDefs.Add('id',ftAutoInc);
 ACRTable2.FieldDefs.Add('name',ftString,100);
 ACRTable2.CreateTable;
 ACRTable2.Open;
 ACRTable2.Insert;
 ACRTable2.FieldByName('name').AsString := 'Leo';
 ACRTable2.Post;
 ACRTable2.Insert;
 ACRTable2.FieldByName('name').AsString := 'Ella';
 ACRTable2.Post;
 ACRTable2.Insert;
 ACRTable2.FieldByName('name').AsString := 'Ray';
 ACRTable2.Post;
 ACRTable2.Insert;
 ACRTable2.FieldByName('name').AsString := 'John';
 ACRTable2.Post;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
 Close;
 Application.Terminate;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
 cdsQuery.Close;
 cdsQuery.CommandText := mQuery.Text;
 cdsQuery.Open;
end;

procedure TForm1.cdsTableAfterDelete(DataSet: TDataSet);
begin
 cdsTable.ApplyUpdates(0);
end;

procedure TForm1.cdsTableAfterPost(DataSet: TDataSet);
begin
 cdsTable.ApplyUpdates(0);
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
 cdsQuery.Close;
 cdsQuery.CommandText := mQuery.Text;
 cdsQuery.Execute;
 ShowMessage('Query have been executed successfully.');
end;

end.
