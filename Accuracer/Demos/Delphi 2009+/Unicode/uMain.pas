unit uMain;

interface

{$I ..\..\Ver.Inc}

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Db, ACRMain, ACRTypes, StdCtrls, DBCtrls, Grids, DBGrids, ExtCtrls;

type
  TForm1 = class(TForm)
    ACRTable1: TACRTable;
    DataSource1: TDataSource;
    DBNavigator1: TDBNavigator;
    DBGrid1: TDBGrid;
    DBMemo1: TDBMemo;
    Button1: TButton;
    ACRQuery1: TACRQuery;
    Button2: TButton;
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
 Close();
 Application.Terminate();
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
 ACRQuery1.SQL.Text := 'SELECT * FROM '+ACRTable1.TableName+
 ' WHERE (Text_char = :p0) and (Text_varchar = :p0) and (Text_memo = :p0)';
 ACRQuery1.ParamByName('p0').AsWideString := 'čćžš';
 ACRQuery1.ParamByName('p0').DataType := ftWideString;
 ACRQuery1.Open;
 DataSource1.DataSet := ACRQuery1;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
 ACRTable1.FieldDefs.Clear;
 ACRTable1.AdvFieldDefs.Clear;
 ACRTable1.IndexDefs.Clear;
 ACRTable1.AdvIndexDefs.Clear;
 ACRTable1.ForeignKeyDefs.Clear;
 ACRTable1.AdvFieldDefs.Add('Text_char',aftWideChar,300,False);
 ACRTable1.AdvFieldDefs.Add('Text_varchar',aftWideString,300,False);
 ACRTable1.AdvFieldDefs.Add('Text_memo',aftWideMemo,300,False);
 ACRTable1.CreateTable;
 ACRTable1.Open;
 // Unicode specific characters
 ACRTable1.AppendRecord(['čćžš','čćžš','čćžš']);
 ACRTable1.AppendRecord(['čćžša','čćžš','čćžš']);
 ACRTable1.AppendRecord(['čćžš','čćžša','čćžš']);
 ACRTable1.AppendRecord(['čćžš','čćžš','čćžša']);
 ACRTable1.First;
 ShowMessage(
 'WideChar: '+#9+ACRTable1.Fields[0].AsWideString+#13#10+
 'WideVarChar: '+#9+ACRTable1.Fields[1].AsWideString+#13#10+
 'WideMemo: '+#9+ACRTable1.Fields[2].AsWideString
 );
end;


end.
