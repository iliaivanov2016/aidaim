unit Unit1;

interface

{$I ..\..\Ver.Inc}

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls,
  ACRMain, ACRComMain, ACRTypes,
  ComCtrls, DB, DBCtrls, Grids, DBGrids;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Splitter1: TSplitter;
    Panel4: TPanel;
    Button1: TButton;
    Panel5: TPanel;
    Label1: TLabel;
    Panel6: TPanel;
    reLog: TRichEdit;
    Timer1: TTimer;
    db1: TACRDatabase;
    db2: TACRDatabase;
    t1: TACRTable;
    t2: TACRTable;
    ds1: TDataSource;
    ds2: TDataSource;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    DBGrid2: TDBGrid;
    DBNavigator2: TDBNavigator;
    procedure Button1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    FState:  TACRTableState;
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

procedure TForm1.Timer1Timer(Sender: TObject);
var tempState: TACRTableState;
    s: String;
begin
  tempState := t1.GetTableState;
  if (tempState.TableState <> FState.TableState) then
   begin
    Fstate := tempState;
    t1.Refresh;
    t2.Refresh;
    s := ACRGetLastTableOpertaion(FState.LastTableOperation)+#9+DateTimeToStr(FState.LastModificationDate);
    reLog.Lines.Add(s);
   end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
 db1.DatabaseFileName := IncludeTrailingBackslash(ExtractFilePath(ParamStr(0)))+'test.adb';
 if (not db1.Exists) then
  begin
    db1.CreateDatabase;
    db1.Open;
    t1.AdvFieldDefs.Add('ID',aftAutoInc);
    t1.AdvFieldDefs.Add('Name',aftWideChar,20);
    t1.AdvFieldDefs.Add('RegDate',aftDateTime);
    t1.IndexDefs.Add('PK','ID',[ixPrimary]);
    t1.IndexDefs.Add('idxName','Name',[ixUnique]);
    t1.CreateTable;
    t1.Open;
    t1.InsertRecord([NULL,'User #1',Now]);
    Sleep(100);
    t1.InsertRecord([NULL,'User #2',Now]);
    Sleep(100);
    t1.InsertRecord([NULL,'User #3',Now]);
   end
 else
  begin
   db1.Open;
   t1.Open;
  end;
 db2.DatabaseFileName := db1.DatabaseFileName;
 db2.Open;
 t2.Open;
 FState := t1.GetTableState;
 Timer1.Enabled := True;
end;

end.
