unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, StdCtrls, ComCtrls, DBCtrls, Grids, DBGrids, Menus,
  ExtCtrls, SQLMemMain;

{$IFDEF VER200}
{$WARN IMPLICIT_STRING_CAST OFF}
{$WARN IMPLICIT_STRING_CAST_LOSS OFF}
{$ENDIF}

type
  TForm1 = class(TForm)
    reSQL: TRichEdit;
    Panel1: TPanel;
    bnOpen: TButton;
    bnExecSQL: TButton;
    bnClose: TButton;
    lbRecCount: TLabel;
    lbTime: TLabel;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    SQLMemQuery1: TSQLMemQuery;
    procedure bnCloseClick(Sender: TObject);
    procedure bnExecSQLClick(Sender: TObject);
    procedure bnOpenClick(Sender: TObject);
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

procedure TForm1.bnCloseClick(Sender: TObject);
begin
 Close;
 Application.Terminate;
end;

procedure TForm1.bnExecSQLClick(Sender: TObject);
var t:    Cardinal;
    d,d1: Double;

begin
 try
  t := Windows.GetTickCount;
  SQLMemQuery1.SQL.Text := reSQL.Text;
  SQLMemQuery1.ExecSQL;
  t := Windows.GetTickCount - t;
  d := t / 1000.0;
  d1 := SQLMemQuery1.RowsAffected;
  bnExecSQL.Hint := 'Query execution time, seconds: '+
       FormatFloat('#,##0.000',d)+'. Rows affected: '+FormatFloat('#,##0',d1);
  lbRecCount.Caption := 'RecordCount: '+ FormatFloat('#,##0',d1);
  lbTime.Caption := 'Time, sceonds: '+ FormatFloat('#,##0.000',d);
 except on E: Exception do
  MessageDlg('Error executing SQL script: '+#13#10+e.Message,mtError,[mbOK],0);
 end;
end;

procedure TForm1.bnOpenClick(Sender: TObject);
var t:    Cardinal;
    d,d1: Double;

begin
 try
  t := Windows.GetTickCount;
  SQLMemQuery1.SQL.Text := reSQL.Text;
  SQLMemQuery1.Open;
  t := Windows.GetTickCount - t;
  d := t / 1000.0;
  d1 := SQLMemQuery1.RecordCount;
  bnExecSQL.Hint := 'Query execution time, seconds: '+
       FormatFloat('#,##0.000',d)+'. Rows affected: '+FormatFloat('#,##0',d1);
  lbRecCount.Caption := 'RecordCount: '+ FormatFloat('#,##0',d1);
  lbTime.Caption := 'Time, sceonds: '+ FormatFloat('#,##0.000',d);
 except on E: Exception do
  MessageDlg('Error executing SQL script: '+#13#10+e.Message,mtError,[mbOK],0);
 end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
 reSQL.Text := SQLMemQuery1.SQL.Text;
end;

end.
