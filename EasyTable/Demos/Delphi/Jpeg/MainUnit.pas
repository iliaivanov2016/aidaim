unit MainUnit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, jpeg,
  Db, EasyTable, ExtCtrls, DBCtrls, Grids, DBGrids, StdCtrls;

type
  TMainForm = class(TForm)
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    EasyTable1: TEasyTable;
    EasyDatabase1: TEasyDatabase;
    DataSource1: TDataSource;
    DBMemo1: TDBMemo;
    Panel1: TPanel;
    Image1: TImage;
    bnLoad: TButton;
    Button1: TButton;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    procedure FormCreate(Sender: TObject);
    procedure bnLoadClick(Sender: TObject);
    procedure EasyTable1AfterScroll(DataSet: TDataSet);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.DFM}

procedure TMainForm.FormCreate(Sender: TObject);
begin
 EasyTable1.Open;
end;

procedure TMainForm.bnLoadClick(Sender: TObject);
var jpg: 	TJpegImage;
    bs:   TStream;
begin
 if (OpenDialog1.Execute) then
  begin
	 jpg := TJpegImage.Create;
   try
		 jpg.LoadFromFile(OpenDialog1.FileName);
   except
     MessageDlg('Invalid JPEG file.',mtError,[mbOk],0);
		 jpg.Free;
     Exit;
   end;
   EasyTable1.Edit;
   bs := EasyTable1.CreateBlobStream(EasyTable1.FieldByName('Image'),bmWrite);
   jpg.SaveToStream(bs);
   EasyTable1.Post;
   bs.Free;
   jpg.Free;
  end;
end;

procedure TMainForm.EasyTable1AfterScroll(DataSet: TDataSet);
var jpg: 	TJpegImage;
    bs:   TStream;
begin
 jpg := TJpegImage.Create;
 try
  bs := EasyTable1.CreateBlobStream(EasyTable1.FieldByName('Image'),bmRead);
  Image1.Picture.Assign(nil);
  if (bs.Size > 0) then
   begin
	  jpg.LoadFromStream(bs);
    Image1.Picture.Assign(jpg);
   end;
  bs.Free;
 except
  MessageDlg('Invalid BLOB field value. This is not an jpeg file!',mtError,[mbOk],0);
  jpg.Free;
  Exit;
 end;
 jpg.Free;
end;

procedure TMainForm.Button1Click(Sender: TObject);
var jpg: 	TJpegImage;
    bs:   TStream;
begin
 if (SaveDialog1.Execute) then
  begin
	 jpg := TJpegImage.Create;
   try
    bs := EasyTable1.CreateBlobStream(EasyTable1.FieldByName('Image'),bmRead);
    if (bs.Size > 0) then
     begin
      jpg.LoadFromStream(bs);
   	  jpg.SaveToFile(SaveDialog1.FileName);
     end;
    bs.Free;
   except
    MessageDlg('Error saving JPEG file.',mtError,[mbOk],0);
		jpg.Free;
    Exit;
   end;
   jpg.Free;
  end;
end;

end.
