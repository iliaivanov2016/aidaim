unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, DB, StdCtrls, ExtCtrls, DBCtrls, Grids, DBGrids,
  ComCtrls, EasyTable;

type
  TForm1 = class(TForm)
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    Button1: TButton;
    DBMemo1: TDBMemo;
    Button2: TButton;
    Label1: TLabel;
    Memo1: TMemo;
    Label2: TLabel;
    Button3: TButton;
    EasyQuery1: TEasyQuery;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
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
 EasyQuery1.Open;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
 EasyQuery1.SQL.Text := Memo1.Lines.Text;
 EasyQuery1.Open;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
 Close;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
 if (not EasyQuery1.Locate('text','AA',[loCaseInsensitive,loPartialKey])) then
  ShowMessage('not found');
end;

end.
