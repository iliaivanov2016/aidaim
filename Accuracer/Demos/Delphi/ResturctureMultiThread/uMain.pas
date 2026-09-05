unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, ACRMain, ACRTypes, DBCtrls, ExtCtrls, Grids, DBGrids,
  StdCtrls, uBkThread;

type
  TForm1 = class(TForm)
    ACRDatabase1: TACRDatabase;
    ACRTable1: TACRTable;
    DBGrid1: TDBGrid;
    Panel1: TPanel;
    DataSource1: TDataSource;
    DBNavigator1: TDBNavigator;
    Button1: TButton;
    Button2: TButton;
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
    FFinished: Boolean;
  public
    { Public declarations }
    procedure Finish;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
 ACRDatabase1.CreateDatabase;
 ACRDatabase1.Open;
 ACRTable1.AdvFieldDefs.Add('id',aftAutoInc);
 ACRTable1.AdvFieldDefs.Add('str',aftChar,20);
 ACRTable1.CreateTable;
 ACRTable1.Open;
 ACRTable1.Insert;
 ACRTable1.Fields[1].AsString := 'test 1';
 ACRTable1.Post;
 ACRTable1.Insert;
 ACRTable1.Fields[1].AsString := 'test 2';
 ACRTable1.Post;
 ACRTable1.Insert;
 ACRTable1.Fields[1].AsString := 'test 3';
 ACRTable1.Post;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  FFinished := True;
  Application.Terminate;
  Close;
end;

procedure TForm1.Button1Click(Sender: TObject);
var th: TRestructureThread;
begin
 FFinished := False;
 ACRTable1.Close;
 Button1.Enabled := False;
 try
  th := TRestructureThread.Create(ACRDatabase1.DatabaseFileName,ACRTable1.TableName);
  th.Resume;
  while (not FFinished) and (not Application.Terminated) do
   begin
    Sleep(16);
    Application.ProcessMessages;
   end;
 finally
   ACRTable1.Open;
   Button1.Enabled := True;
 end;
end;

procedure TForm1.Finish;
begin
  FFinished := True;
end;

end.
