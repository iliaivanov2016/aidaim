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
  ExtCtrls, ACRMain;

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
    ACRDatabase1: TACRDatabase;
    ACRTable1: TACRTable;
    Label3: TLabel;
    lbThreadCount: TLabel;
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

 if (not ACRDatabase1.Exists) then
  ACRDatabase1.CreateDatabase;

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
 i,max: integer;
 QueryThread: TQueryThread;
begin
  max := 20;
  // MaxSessionCount - 2 for last thread number is due to table component that
  // uses different from threads session
  if (max > ACRDatabase1.Options.MaxSessionCount-2) then
   max := ACRDatabase1.Options.MaxSessionCount-2;
  lbThreadCount.Caption := IntToStr(max+1); 
  for i := 0 to max do
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
