unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, DB, StdCtrls, DBCtrls, ExtCtrls, Grids, DBGrids,
  {$IFDEF VER140}
  Variants,
  {$ENDIF}
  ACRMain;

type
  TForm1 = class(TForm)
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    DataSource1: TDataSource;
    bnInsert: TButton;
    Button2: TButton;
    DBMemo1: TDBMemo;
    bnClose: TButton;
    ACRQuery1: TACRQuery;
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
 ACRQuery1.SQL.Text := 'CREATE TABLE Test (ID AutoInc, Text Memo)';
 ACRQuery1.ExecSQL;
 bnInsertClick(Self);
end;

procedure TForm1.bnInsertClick(Sender: TObject);
begin
 ACRQuery1.Params.Clear;
 ACRQuery1.Params.CreateParam(ftMemo,'Param1',ptInput);
 ACRQuery1.Params.Items[0].LoadFromFile('Unit1.pas',ftMemo);

 ACRQuery1.SQL.Text := 'INSERT INTO Test (Text) Values (:Param1)';
 ACRQuery1.ExecSQL;

 ACRQuery1.SQL.Text := 'SELECT * FROM Test';
 ACRQuery1.Open;
end;

procedure TForm1.Button2Click(Sender: TObject);
var s: String;
begin
 s := 'Updated Memo.';
 ACRQuery1.Params.Clear;
 ACRQuery1.Params.CreateParam(ftMemo,'Param1',ptInput);
 ACRQuery1.Params.Items[0].SetBlobData(PChar(@s[1]),Length(s));

 ACRQuery1.SQL.Text := 'UPDATE Test SET Text = :Param1 Where ID = '+ACRQuery1.FieldByName('ID').AsString;
 ACRQuery1.ExecSQL;

 ACRQuery1.SQL.Text := 'SELECT * FROM Test';
 ACRQuery1.Open;
end;

end.
