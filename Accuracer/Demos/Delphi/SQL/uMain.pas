unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ACRMain, DB, DBCtrls, Grids, DBGrids, StdCtrls, ExtCtrls;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    Splitter1: TSplitter;
    GroupBox1: TGroupBox;
    Memo1: TMemo;
    Splitter2: TSplitter;
    gbResult: TGroupBox;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    DataSource1: TDataSource;
    ACRQuery1: TACRQuery;
    ACRDatabase1: TACRDatabase;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
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
 ACRQuery1.Close;
 ACRQuery1.SQL.Text := Memo1.Text;
 try
  ACRQuery1.Open;
  gbResult.Caption := ' Query Result: '+IntToStr(ACRQuery1.RecordCount)+' records'; 
 except
  on e: Exception do
   begin
    ShowMessage('Errors occurs while opening query: '+e.Message);
    ACRQuery1.Close;
    gbResult.Caption := ' Query Result: ';
   end;
 end;
end;


procedure TForm1.Button2Click(Sender: TObject);
begin
 ACRQuery1.Close;
 ACRQuery1.SQL.Text := Memo1.Text;
 try
  ACRQuery1.ExecSQL;
  ShowMessage('Script was successfully executed. Rows affected = '+IntToStr(ACRQuery1.RowsAffected));
 except
  on e: Exception do
   ShowMessage('Errors occurs while executing script: '+e.Message);
 end;
end;


procedure TForm1.Button3Click(Sender: TObject);
begin
 Close;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
 ACRDatabase1.Open;
end;

end.
