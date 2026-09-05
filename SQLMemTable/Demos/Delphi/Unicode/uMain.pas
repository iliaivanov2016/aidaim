unit uMain;

interface

uses
  Windows, Messages, SysUtils,
{$IFDEF VER140}
  Variants,
{$ENDIF}
  Classes, Graphics, Controls, Forms,
  Dialogs,
  SQLMemMain, SQLMemTypes, SQLMemConst,
  DB, StdCtrls, DBCtrls, Grids, DBGrids, ExtCtrls;

type
  TForm1 = class(TForm)
    DBNavigator1: TDBNavigator;
    DBGrid1: TDBGrid;
    DBMemo1: TDBMemo;
    Button1: TButton;
    Button2: TButton;
    DataSource1: TDataSource;
    SQLMemQuery1: TSQLMemQuery;
    SQLMemTable1: TSQLMemTable;
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
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
var ws,ws1: WideString;
begin
 SetLength(ws,4);
 SetLength(ws1,5);
 ws[1] := #$8DC4;
 ws[2] := #$87C4;
 ws[3] := #$BEC5;
 ws[4] := #$A1C5;

 ws1[1] := #$8DC4;
 ws1[2] := #$87C4;
 ws1[3] := #$BEC5;
 ws1[4] := #$A1C5;
 ws1[5] := #$61;
 SQLMemTable1.FieldDefs.Clear;
 SQLMemTable1.AdvFieldDefs.Clear;
 SQLMemTable1.IndexDefs.Clear;
 SQLMemTable1.AdvIndexDefs.Clear;
 SQLMemTable1.ForeignKeyDefs.Clear;
 SQLMemTable1.AdvFieldDefs.Add('Text_char',aftWideChar,300,False);
 SQLMemTable1.AdvFieldDefs.Add('Text_varchar',aftWideString,300,False);
 SQLMemTable1.AdvFieldDefs.Add('Text_memo',aftWideMemo,300,False);
 SQLMemTable1.CreateTable;
 SQLMemTable1.Open;
 // Unicode specific characters
 // use SetWideMemoField for all versions of Delphi and C++ Builder
 // lower then 2009
 // as it has no Unicode support
 SQLMemTable1.Insert;
 SQLMemTable1.Fields[0].Value := ws;
 SQLMemTable1.Fields[1].Value := ws;
 SQLMemTable1.SetWideMemoField(SQLMemTable1.Fields[2],ws);
 SQLMemTable1.Post;
 SQLMemTable1.Insert;
 SQLMemTable1.Fields[0].Value := ws1;
 SQLMemTable1.Fields[1].Value := ws;
 SQLMemTable1.SetWideMemoField(SQLMemTable1.Fields[2],ws);
 SQLMemTable1.Post;
 SQLMemTable1.Insert;
 SQLMemTable1.Fields[0].Value := ws;
 SQLMemTable1.Fields[1].Value := ws1;
 SQLMemTable1.SetWideMemoField(SQLMemTable1.Fields[2],ws);
 SQLMemTable1.Post;
 SQLMemTable1.Insert;
 SQLMemTable1.Fields[0].Value := ws;
 SQLMemTable1.Fields[1].Value := ws;
 SQLMemTable1.SetWideMemoField(SQLMemTable1.Fields[2],ws1);
 SQLMemTable1.Post;
 // Unicode specific characters
 // this works only in Delphi 2009 and higher
{
 SQLMemTable1.AppendRecord([ws,ws,ws]);
 SQLMemTable1.AppendRecord([ws1,ws,ws]);
 SQLMemTable1.AppendRecord([ws,ws1,ws]);
 SQLMemTable1.AppendRecord([ws,ws,ws1]);
}
 SQLMemTable1.First;
end;

procedure TForm1.Button2Click(Sender: TObject);
var ws: WideString;
begin
 SetLength(ws,4);
 ws[1] := #$8DC4;
 ws[2] := #$87C4;
 ws[3] := #$BEC5;
 ws[4] := #$A1C5;
 SQLMemQuery1.SQL.Text := 'SELECT * FROM '+SQLMemTable1.TableName+
 ' WHERE (Text_char = :p0) and (Text_varchar = :p0) and (Text_memo = :p0)';
 SQLMemQuery1.ParamByName('p0').DataType := ftWideString;
 SQLMemQuery1.ParamByName('p0').Value := ws;
 SQLMemQuery1.Open;
 DataSource1.DataSet := SQLMemQuery1;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
 Close();
 Application.Terminate();
end;

end.
