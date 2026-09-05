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
  ExtCtrls, SQLMemMain;

type
  TfMain = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    Splitter1: TSplitter;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    Label1: TLabel;
    Label2: TLabel;
    DBNavigator1: TDBNavigator;
    lbRecCount: TLabel;
    lbRecNo: TLabel;
    btStart: TButton;
    Panel3: TPanel;
    ACRTable1: TSQLMemTable;
    procedure FormCreate(Sender: TObject);
    procedure btStartClick(Sender: TObject);
    procedure ACRTable1AfterScroll(DataSet: TDataSet);
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

// if (not ACRDatabase1.Exists) then
//  ACRDatabase1.CreateDatabase;

 if (not ACRTable1.Exists) then
  begin
   ACRTable1.FieldDefs.Clear;
   ACRTable1.FieldDefs.Add('id',ftAutoInc, 0, False);
   ACRTable1.FieldDefs.Add('time',ftTime, 0, False);
   ACRTable1.FieldDefs.Add('name',ftString, 300, False);
   ACRTable1.FieldDefs.Add('integer',ftInteger, 0, False);
   ACRTable1.FieldDefs.Add('money',ftCurrency, 0, False);
   ACRTable1.IndexDefs.Clear;
   ACRTable1.CreateTable;
  end;
 ACRTable1.Open;
 fMain.lbRecCount.Caption := IntToStr(fMain.ACRTable1.RecordCount);
end;


procedure TfMain.btStartClick(Sender: TObject);
var
 i: integer;
 QueryThread: TQueryThread;
begin
  for i := 0 to 9 do
   begin
    QueryThread := TQueryThread.Create(True);
    QueryThread.Priority := tpNormal; { set the priority to lower than normal }
    QueryThread.Resume; { now run the thread }
   end;
end;

procedure TfMain.ACRTable1AfterScroll(DataSet: TDataSet);
begin
 lbRecNo.Caption := IntToStr(ACRTable1.RecNo);
end;

end.
