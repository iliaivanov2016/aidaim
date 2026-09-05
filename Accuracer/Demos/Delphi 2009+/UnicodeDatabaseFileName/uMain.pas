unit uMain;

interface

{$I ..\..\Ver.Inc}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, DBCtrls, Grids, DBGrids, DB,
  ACRMain, ACRTypes, ACRConst;

type
  TForm1 = class(TForm)
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    Button1: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
    Fdb: TACRDatabase;
    Ft:  TACRTable;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
var ws,dbFile: WideString;
begin
 SetLength(ws,4);
 ws[1] := #$8DC4;
 ws[2] := #$87C4;
 ws[3] := #$BEC5;
 ws[4] := #$A1C5;
 dbFile := IncludeTrailingBackslash(ExtractFilePath(ParamStr(0)))+ws+'.adb';
 Fdb := TACRDatabase.Create(nil);
 Ft := TACRTable.Create(nil);
 Fdb.DatabaseFileNameUnicode := dbFile;
 Fdb.CreateDatabase;
 Fdb.Open;
 Ft.DatabaseName := Fdb.DatabaseName;
 Ft.FieldDefs.Clear;
 Ft.AdvFieldDefs.Clear;
 Ft.IndexDefs.Clear;
 Ft.ForeignKeyDefs.Clear;
 Ft.TableName := 'Test';
 Ft.AdvFieldDefs.Add('id',aftAutoInc);
 Ft.AdvFieldDefs.Add('name',aftChar,20); // CHAR - ftFixedChar; VARCHAR - ftString
 Ft.IndexDefs.Add('PK','id',[ixPrimary]);
 Ft.CreateTable;
 Ft.Open;
 Ft.Insert;
 Ft.Fields[1].AsString := 'Leo Martin';
 Ft.Post;
 Ft.Insert;
 Ft.Fields[1].AsString := 'Ray Lahoy';
 Ft.Post;
 Ft.Insert;
 Ft.Fields[1].AsString := 'Ella Perelman';
 Ft.Post;
 DataSource1.DataSet := Ft;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 DataSource1.DataSet := nil;
 if (Fdb <> nil) then
  begin
   Ft.Free;
   Fdb.Close;
   Fdb.DeleteDatabase;
   Fdb.Free;
   Fdb := nil;
   Ft := nil;
  end;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
 Close();
end;

end.
