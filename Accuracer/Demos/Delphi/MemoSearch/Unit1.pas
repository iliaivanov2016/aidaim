unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ACRMain, DB, StdCtrls, ExtCtrls, DBCtrls, Grids, DBGrids,
  ComCtrls;

type
  TForm1 = class(TForm)
    ACRQuery1: TACRQuery;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    Button1: TButton;
    DBMemo1: TDBMemo;
    DBMemo2: TDBMemo;
    DBRichEdit1: TDBRichEdit;
    Button2: TButton;
    Label1: TLabel;
    Memo1: TMemo;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Button3: TButton;
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
 ACRQuery1.Open;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
 ACRQuery1.SQL.Text := Memo1.Lines.Text;
 ACRQuery1.Open;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
 Close;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
 if (not ACRQuery1.Locate('text','AA',[loCaseInsensitive,loPartialKey])) then
  ShowMessage('not found');
end;

end.
