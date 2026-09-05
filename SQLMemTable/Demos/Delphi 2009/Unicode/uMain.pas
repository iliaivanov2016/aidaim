unit uMain;

interface

{$IFDEF VER200}
{$WARN IMPLICIT_STRING_CAST OFF}
{$WARN IMPLICIT_STRING_CAST_LOSS OFF}
{$ENDIF}

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Db, SQLMemMain, SQLMemTypes, StdCtrls, DBCtrls, Grids, DBGrids, ExtCtrls;

type
  TForm1 = class(TForm)
    DataSource1: TDataSource;
    DBNavigator1: TDBNavigator;
    DBGrid1: TDBGrid;
    DBMemo1: TDBMemo;
    Button1: TButton;
    Button2: TButton;
    SQLMemQuery1: TSQLMemQuery;
    SQLMemTable1: TSQLMemTable;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
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
 Close;
 Application.Terminate;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
 SQLMemQuery1.SQL.Text := 'SELECT * FROM '+SQLMemTable1.TableName+
 ' WHERE (Text_char = :p0) and (Text_varchar = :p0) and (Text_memo = :p0)';
 SQLMemQuery1.ParamByName('p0').AsWideString := 'čćžš';
 SQLMemQuery1.ParamByName('p0').DataType := ftWideString;
 SQLMemQuery1.Open;
 DataSource1.DataSet := SQLMemQuery1;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
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
 SQLMemTable1.AppendRecord(['čćžš','čćžš','čćžš']);
 SQLMemTable1.AppendRecord(['čćžša','čćžš','čćžš']);
 SQLMemTable1.AppendRecord(['čćžš','čćžša','čćžš']);
 SQLMemTable1.AppendRecord(['čćžš','čćžš','čćžša']);
 SQLMemTable1.First;
 ShowMessage(
 'WideChar: '+#9+SQLMemTable1.Fields[0].AsWideString+#13#10+
 'WideVarChar: '+#9+SQLMemTable1.Fields[1].AsWideString+#13#10+
 'WideMemo: '+#9+SQLMemTable1.Fields[2].AsWideString
 );
end;


end.
