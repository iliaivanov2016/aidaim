unit uMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, DBCtrls, StdCtrls, Grids, DBGrids, DB,
{$IFDEF VER140}
Variants,
{$ENDIF}
{$IFDEF VER145}
Variants,
{$ENDIF}
{$IFDEF VER150}
Variants,
{$ENDIF}
  EasyTable, ExtCtrls, ETblCommon;

type
  TfMain = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    Splitter1: TSplitter;
    DataSource1: TDataSource;
    EasyDatabase1: TEasyDatabase;
    EasyTable1: TEasyTable;
    DBGrid1: TDBGrid;
    Label1: TLabel;
    Label2: TLabel;
    DBNavigator1: TDBNavigator;
    lbRecCount: TLabel;
    lbRecNo: TLabel;
    btStart: TButton;
    Panel3: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure btStartClick(Sender: TObject);
    procedure EasyTable1AfterScroll(DataSet: TDataSet);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fMain: TfMain;

implementation

uses BkThread;

{$R *.dfm}

procedure TfMain.FormCreate(Sender: TObject);
begin
 if (not EasyDatabase1.Exists) then
  EasyDatabase1.CreateDatabase;

 if (not EasyTable1.Exists) then
  begin
   EasyTable1.FieldDefs.Clear;
   EasyTable1.FieldDefs.Add('id',ftAutoInc, 0, False);
   EasyTable1.FieldDefs.Add('time',ftTime, 0, False);
   EasyTable1.FieldDefs.Add('name',ftString, 300, False);
   EasyTable1.FieldDefs.Add('integer',ftInteger, 0, False);
   EasyTable1.FieldDefs.Add('money',ftCurrency, 0, False);
   EasyTable1.IndexDefs.Clear;
   EasyTable1.CreateTable;
  end;
 EasyTable1.Open;
 fMain.lbRecCount.Caption := IntToStr(fMain.EasyTable1.RecordCount);
end;


procedure TfMain.btStartClick(Sender: TObject);
var
 i: integer;
 QueryThread: TQueryThread;
begin
  for i:=0 to 19 do
   begin
    QueryThread := TQueryThread.Create(True);
    QueryThread.Priority := tpLower; { set the priority to lower than normal }
    QueryThread.Resume; { now run the thread }
   end;
end;

procedure TfMain.EasyTable1AfterScroll(DataSet: TDataSet);
begin
 lbRecNo.Caption := IntToStr(EasyTable1.RecNo);
end;

end.
