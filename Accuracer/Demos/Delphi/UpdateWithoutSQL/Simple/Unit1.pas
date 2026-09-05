unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, ACRMain, StdCtrls, ExtCtrls, DBCtrls, Grids, DBGrids;

type
  TForm1 = class(TForm)
    ACRDatabase1: TACRDatabase;
    tMain: TACRTable;
    tInout: TACRTable;
    dsMain: TDataSource;
    dsInout: TDataSource;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    DBNavigator2: TDBNavigator;
    DBGrid2: TDBGrid;
    Label1: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure tMainAfterPost(DataSet: TDataSet);
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
 ACRDatabase1.DatabaseFileName := IncludeTrailingBackslash(ExtractFilePath(ParamStr(0)))+
  ACRDatabase1.DatabaseFileName;
 if (not ACRDatabase1.Exists) then
  ACRDatabase1.CreateDatabase;
 ACRDatabase1.Open;
 if (not tMain.Exists) then
  begin
   tMain.FieldDefs.Clear;
   tMain.FieldDefs.Add('id',ftAutoInc);
   tMain.FieldDefs.Add('name',ftString,20);
   tMain.IndexDefs.Add('pk','id',[ixPrimary]);
   tMain.CreateTable;

   tInout.FieldDefs.Clear;
   tInout.FieldDefs.Add('id',ftAutoInc);
   tInout.FieldDefs.Add('vessel_id',ftInteger);
   tInout.FieldDefs.Add('vessel_details',ftString,20);
   tInout.IndexDefs.Add('pk','id',[ixPrimary]);
   tInout.IndexDefs.Add('vessel_id_index','vessel_id',[]);
   tInout.CreateTable;

   tMain.Open;
   tInout.Open;

   // for better performance on filtering
   tInout.IndexName := 'vessel_id_index';
   tInout.Insert;
   tInout.FieldByName('vessel_id').AsInteger := 1;
   tInout.Post;

   tInout.Insert;
   tInout.FieldByName('vessel_id').AsInteger := 2;
   tInout.Post;

   tInout.Insert;
   tInout.FieldByName('vessel_id').AsInteger := 1;
   tInout.Post;

   tInout.Insert;
   tInout.FieldByName('vessel_id').AsInteger := 1;
   tInout.Post;

   tMain.Insert;
   tMain.FieldByName('name').AsString := 'test1';
   tMain.Post;

   tMain.Insert;
   tMain.FieldByName('name').AsString := 'test2';
   tMain.Post;

  end
 else
  begin
   tMain.Open;
   tInout.Open;
  end;
end;

procedure TForm1.tMainAfterPost(DataSet: TDataSet);
var s: string;
    bm: Pointer;
begin
 if (Dataset <> tMain)  then
  exit;
 bm := tInout.GetBookmark;
 tInout.DisableControls;
 try
   tInout.Filtered := false;
   tInout.Filter := 'vessel_id = '+tMain.FieldByName('id').AsString;
   tInout.Filtered := true;
   tInout.First;
   s := tMain.FieldByName('name').AsString;
   while (not tInout.Eof) do
    begin
     tInout.Edit;
     tInout.FieldByName('vessel_details').AsString := s;
     tInout.Post;
     tInout.Next;
    end;
 finally
  try
   tInout.Filtered := false;
   tInout.Refresh;
   tInout.GotoBookmark(bm);
  finally
   tInout.FreeBookmark(bm);
   tInout.EnableControls;
  end;
 end;
end;

end.
