unit EditFmtMemo;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, DBCtrls, ComCtrls;

type
  TFmtMemoForm = class(TForm)
    Panel2: TPanel;
    Panel1: TPanel;
    GroupBox1: TGroupBox;
    Panel4: TPanel;
    Panel3: TPanel;
    ImportBtn: TButton;
    ExportBtn: TButton;
    GroupBox2: TGroupBox;
    SizeLbl: TLabel;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    RichEdit: TDBRichEdit;
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
  FmtMemoForm: TFmtMemoForm;

implementation

uses MainUnit,db;

{$R *.DFM}

procedure TFmtMemoForm.FormShow(Sender: TObject);
var BS:TStream;
begin
 RichEdit.Datafield := MainForm.OpenGrid.SelectedField.FieldName;
 BS := MainForm.CurrentTable.CreateBlobStream(MainForm.OpenGrid.SelectedField,bmRead);
 SizeLbl.Caption := IntToStr(BS.Size)+' bytes';
 BS.Free;
 Caption := 'FmtMemoField - '+MainForm.OpenGrid.SelectedField.FieldName;
 MainForm.CurrentTable.Edit;
end;

procedure TFmtMemoForm.ImportBtnClick(Sender: TObject);
var FS:TFileStream;
    BS:TStream;
begin
 if (OpenDialog1.Execute) then
  try
   RichEdit.DataField := '';
   FS := TFileStream.Create(OpenDialog1.FileName,fmOpenRead);
   BS := MainForm.CurrentTable.CreateBlobStream(MainForm.OpenGrid.SelectedField,bmWrite);
   BS.CopyFrom(FS,FS.Size);
   SizeLbl.Caption := IntToStr(FS.Size);
   BS.Free;
   FS.Free;
   RichEdit.Datafield := MainForm.OpenGrid.SelectedField.FieldName;
  except
   MessageDlg('Cannot open file '''+OpenDialog1.FileName+'''',mtError,[mbOK],0);
  end;
end;

procedure TFmtMemoForm.ExportBtnClick(Sender: TObject);
var FS:TFileStream;
    BS:TStream;
begin
 try
  if (SaveDialog1.Execute) then
   begin
    RichEdit.DataField := '';
    RichEdit.Datafield := MainForm.OpenGrid.SelectedField.FieldName;
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

procedure TFmtMemoForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
   RichEdit.DataField := '';
   if (MainForm.CurrentTable.State = dsEdit) then
    MainForm.CurrentTable.Cancel;
end;

procedure TFmtMemoForm.btOkClick(Sender: TObject);
begin
 MainForm.CurrentTable.Post;
end;

procedure TFmtMemoForm.btCancelClick(Sender: TObject);
begin
 MainForm.CurrentTable.Cancel;
end;

end.

