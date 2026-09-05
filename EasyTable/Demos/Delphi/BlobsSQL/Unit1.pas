unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, EasyTable, StdCtrls, DBCtrls, ExtCtrls, Grids, DBGrids;

type
  TForm1 = class(TForm)
    EasyQuery1: TEasyQuery;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    DataSource1: TDataSource;
    bnInsert: TButton;
    Button2: TButton;
    DBMemo1: TDBMemo;
    bnClose: TButton;
    procedure bnCloseClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure bnInsertClick(Sender: TObject);
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

procedure TForm1.bnCloseClick(Sender: TObject);
begin
 Close;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
 EasyQuery1.SQL.Text := 'CREATE TABLE Test (ID AutoInc, Text Memo)';
 EasyQuery1.ExecSQL;
 bnInsertClick(Self);
end;

procedure TForm1.bnInsertClick(Sender: TObject);
begin
 EasyQuery1.Params.Clear;
 EasyQuery1.Params.CreateParam(ftMemo,'Param1',ptInput);
 EasyQuery1.Params.Items[0].LoadFromFile('Unit1.pas',ftMemo);

 EasyQuery1.SQL.Text := 'INSERT INTO Test (Text) Values (:Param1)';
 EasyQuery1.ExecSQL;

 EasyQuery1.SQL.Text := 'SELECT * FROM Test';
 EasyQuery1.Open;
end;

procedure TForm1.Button2Click(Sender: TObject);
var s: String;
begin
 s := 'Updated Memo.';
 EasyQuery1.Params.Clear;
 EasyQuery1.Params.CreateParam(ftMemo,'Param1',ptInput);
 EasyQuery1.Params.Items[0].SetBlobData(PChar(@s[1]),Length(s));

 EasyQuery1.SQL.Text := 'UPDATE Test SET Text = :Param1 Where ID = '+EasyQuery1.FieldByName('ID').AsString;
 EasyQuery1.ExecSQL;

 EasyQuery1.SQL.Text := 'SELECT * FROM Test';
 EasyQuery1.Open;
end;

end.
