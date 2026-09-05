unit MainUnit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, jpeg,
  Db, ExtCtrls, DBCtrls, Grids, DBGrids, StdCtrls, ACRMain;

type
  TMainForm = class(TForm)
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    DataSource1: TDataSource;
    DBMemo1: TDBMemo;
    Panel1: TPanel;
    Image1: TImage;
    bnLoad: TButton;
    Button1: TButton;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    ACRTable1: TACRTable;
    ACRDatabase1: TACRDatabase;
    procedure FormCreate(Sender: TObject);
    procedure bnLoadClick(Sender: TObject);
    procedure ACRTable1AfterScroll(DataSet: TDataSet);
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
 ACRTable1.Open;
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
   ACRTable1.Edit;
   bs := ACRTable1.CreateBlobStream(ACRTable1.FieldByName('Image'),bmWrite);
   jpg.SaveToStream(bs);
   ACRTable1.Post;
   jpg.Free;
  end;
end;

procedure TMainForm.ACRTable1AfterScroll(DataSet: TDataSet);
var jpg: 	TJpegImage;
    bs:   TStream;
begin
 jpg := TJpegImage.Create;
 try
  bs := ACRTable1.CreateBlobStream(ACRTable1.FieldByName('Image'),bmRead);
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
    bs := ACRTable1.CreateBlobStream(ACRTable1.FieldByName('Image'),bmRead);
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
