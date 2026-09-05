unit EditGraphic;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, DBCtrls, ComCtrls, ExtDlgs;

type
  TGraphicForm = class(TForm)
    Panel2: TPanel;
    Panel1: TPanel;
    GroupBox1: TGroupBox;
    Panel4: TPanel;
    Panel3: TPanel;
    ImportBtn: TButton;
    ExportBtn: TButton;
    GroupBox2: TGroupBox;
    SizeLbl: TLabel;
    Image: TDBImage;
    OpenDialog1: TOpenPictureDialog;
    SaveDialog1: TSavePictureDialog;
    btCancel: TButton;
    btOk: TButton;
    procedure FormShow(Sender: TObject);
    procedure ImportBtnClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ExportBtnClick(Sender: TObject);
    procedure btOkClick(Sender: TObject);
    procedure btCancelClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  GraphicForm: TGraphicForm;

implementation

uses MainUnit,db;

{$R *.DFM}

procedure TGraphicForm.FormShow(Sender: TObject);
var BS:TStream;
begin
 Image.Datafield := MainForm.OpenGrid.SelectedField.FieldName;
 BS := MainForm.CurrentTable.CreateBlobStream(MainForm.OpenGrid.SelectedField,bmRead);
 SizeLbl.Caption := IntToStr(BS.Size)+' bytes';
 BS.Free;
 Caption := 'GraphicField - '+MainForm.OpenGrid.SelectedField.FieldName;
 MainForm.CurrentTable.Edit;
end;

procedure TGraphicForm.ImportBtnClick(Sender: TObject);
var FS:TFileStream;
    BS:TStream;
begin
 if (OpenDialog1.Execute) then
  try
   Image.DataField := '';
   FS := TFileStream.Create(OpenDialog1.FileName,fmOpenRead);
   BS := MainForm.CurrentTable.CreateBlobStream(MainForm.OpenGrid.SelectedField,bmWrite);
   BS.CopyFrom(FS,FS.Size);
   SizeLbl.Caption := IntToStr(FS.Size);
   BS.Free;
   FS.Free;
   Image.Datafield := MainForm.OpenGrid.SelectedField.FieldName;
  except
   MessageDlg('Cannot open file '''+OpenDialog1.FileName+'''',mtError,[mbOK],0);
  end;
end;

procedure TGraphicForm.ExportBtnClick(Sender: TObject);
var FS:TFileStream;
    BS:TStream;
begin
 try
  if (SaveDialog1.Execute) then
   begin
    Image.DataField := '';
    Image.Datafield := MainForm.OpenGrid.SelectedField.FieldName;
    FS := TFileStream.Create(SaveDialog1.FileName,fmCreate);
    BS := MainForm.CurrentTable.CreateBlobStream(MainForm.OpenGrid.SelectedField,bmRead);
    FS.CopyFrom(BS,BS.Size);
    BS.Free;
    FS.Free;
   end;
 except
   MessageDlg('Cannot save to file '''+SaveDialog1.FileName+'''',mtError,[mbOK],0);
 end;
end;

procedure TGraphicForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
   Image.DataField := '';
   if (MainForm.CurrentTable.State = dsEdit) then
    MainForm.CurrentTable.Cancel;
end;

procedure TGraphicForm.btOkClick(Sender: TObject);
begin
 MainForm.CurrentTable.Post;
end;

procedure TGraphicForm.btCancelClick(Sender: TObject);
begin
 MainForm.CurrentTable.Cancel;
end;

end.

