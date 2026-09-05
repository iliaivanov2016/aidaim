unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, ExtCtrls, DBCtrls, Grids, DBGrids, ADODB, StdCtrls, ComCtrls;

type
  TForm1 = class(TForm)
    ADOQuery1: TADOQuery;
    ADOConnection1: TADOConnection;
    DBGrid1: TDBGrid;
    DataSource1: TDataSource;
    Panel1: TPanel;
    DBNavigator1: TDBNavigator;
    reSQL: TRichEdit;
    lbProg: TLabel;
    bnOpen: TButton;
    bnExec: TButton;
    Button1: TButton;
    procedure Button1Click(Sender: TObject);
    procedure bnOpenClick(Sender: TObject);
    procedure bnExecClick(Sender: TObject);
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

procedure TForm1.Button1Click(Sender: TObject);
begin
 Close;
end;

procedure TForm1.bnOpenClick(Sender: TObject);
var t: Cardinal;
begin
  bnOpen.Enabled := False;
  bnExec.Enabled := False;
  if (ADOQuery1.Active) then ADOQuery1.Close;
  ADOQuery1.SQL.Text := reSQL.Text;
  t := GetTickCount;
  try
    ADOQuery1.Open;
    t := GetTickCount-t;
    lbProg.Caption := IntToStr(ADOQuery1.RecordCount)+' rows, time = '+IntToStr(t)+ ' ms';
  finally
     bnOpen.Enabled := True;
     bnExec.Enabled := True;
  end;
end;

procedure TForm1.bnExecClick(Sender: TObject);
var t: Cardinal;
begin
  bnOpen.Enabled := False;
  bnExec.Enabled := False;
  if (ADOQuery1.Active) then  ADOQuery1.Close;
  ADOQuery1.SQL.Text := reSQL.Text;
  t := GetTickCount;
  try
    ADOQuery1.ExecSQL;
    t := GetTickCount-t;
    lbProg.Caption := IntToStr(ADOQuery1.RowsAffected)+' rows, time = '+IntToStr(t)+ ' ms';
  finally
    bnOpen.Enabled := True;
    bnExec.Enabled := True;
  end;

end;

procedure TForm1.FormCreate(Sender: TObject);
begin
 ADOConnection1.Open;
end;

end.
