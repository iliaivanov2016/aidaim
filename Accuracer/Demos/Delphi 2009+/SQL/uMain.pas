unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ACRMain, DB, StdCtrls, ComCtrls, DBCtrls, Grids, DBGrids, Menus,
  ExtCtrls;

{$I ..\..\Ver.Inc}

type
  TForm1 = class(TForm)
    ACRQuery1: TACRQuery;
    ACRDatabase1: TACRDatabase;
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
  ACRQuery1.SQL.Text := reSQL.Text;
  ACRQuery1.ExecSQL;
  t := Windows.GetTickCount - t;
  d := t / 1000.0;
  d1 := ACRQuery1.RowsAffected;
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
  ACRQuery1.SQL.Text := reSQL.Text;
  ACRQuery1.Open;
  t := Windows.GetTickCount - t;
  d := t / 1000.0;
  d1 := ACRQuery1.RecordCount;
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
 reSQL.Text := ACRQuery1.SQL.Text;
 ACRDatabase1.DatabaseFileName :=
  IncludeTrailingBackslash(ExtractFilePath(ParamStr(0)))
  +'..\..\Data\DBDemos.adb';
end;

end.
