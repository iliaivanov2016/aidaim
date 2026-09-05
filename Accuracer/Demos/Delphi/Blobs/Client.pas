unit Client;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Mask, DBCtrls, Db, ExtDlgs, Buttons, ComCtrls, ExtCtrls;

type
  TClientForm = class(TForm)
    Label1: TLabel;
    CompanyDBEd: TDBEdit;
    Button1: TButton;
    Button2: TButton;
    Image: TDBImage;
    DBMemo1: TDBMemo;
    DBRichEdit1: TDBRichEdit;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    btLoadPic: TBitBtn;
    OpenPictureDialog1: TOpenPictureDialog;
    Label5: TLabel;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    btLoadFile: TButton;
    btSaveFile: TButton;
    Bevel1: TBevel;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure btLoadPicClick(Sender: TObject);
    procedure btLoadFileClick(Sender: TObject);
    procedure btSaveFileClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ClientForm: TClientForm;

implementation

uses Main;

{$R *.DFM}

procedure TClientForm.Button1Click(Sender: TObject);
begin
 MainForm.ACRTable1.Post;
end;

procedure TClientForm.Button2Click(Sender: TObject);
begin
 MainForm.ACRTable1.Cancel;
end;

procedure TClientForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 if (MainForm.ACRTable1.State = dsInsert) or
    (MainForm.ACRTable1.State = dsEdit) then
  MainForm.ACRTable1.Cancel;
end;

procedure TClientForm.FormShow(Sender: TObject);
begin
 ActiveControl := CompanyDBEd;
end;

procedure TClientForm.btLoadPicClick(Sender: TObject);
var FS:TFileStream;
    BS:TStream;
begin
 if (OpenPictureDialog1.Execute) then
  try
   Image.DataField := '';
   FS := TFileStream.Create(OpenPictureDialog1.FileName,fmOpenRead);
   BS := MainForm.ACRTable1.CreateBlobStream(MainForm.ACRTable1.FieldByName('Photo'),bmReadWrite);
   BS.CopyFrom(FS,FS.Size);
   BS.Free;
   FS.Free;
   Image.Datafield := 'Photo';
  except
   MessageDlg('Cannot open file '''+OpenDialog1.FileName+'''',mtError,[mbOK],0);
  end;
end;

procedure TClientForm.btLoadFileClick(Sender: TObject);
var FS:TFileStream;
    BS:TStream;
begin
 if (OpenDialog1.Execute) then
  try
   FS := TFileStream.Create(OpenDialog1.FileName,fmOpenRead);
   BS := MainForm.ACRTable1.CreateBlobStream(MainForm.ACRTable1.FieldByName('File'),bmWrite);
   BS.CopyFrom(FS,FS.Size);
   BS.Free;
   FS.Free;
  except
   MessageDlg('Cannot open file '''+OpenDialog1.FileName+'''',mtError,[mbOK],0);
  end;
end;

procedure TClientForm.btSaveFileClick(Sender: TObject);
var FS:TFileStream;
    BS:TStream;
begin
 try
  if (SaveDialog1.Execute) then
   begin
    FS := TFileStream.Create(SaveDialog1.FileName,fmCreate);
    BS := MainForm.ACRTable1.CreateBlobStream(MainForm.ACRTable1.FieldByName('File'),bmRead);
    FS.CopyFrom(BS,BS.Size);
    BS.Free;
    FS.Free;
   end;
 except
   MessageDlg('Cannot save to file '''+SaveDialog1.FileName+'''',mtError,[mbOK],0);
 end;
end;

end.
