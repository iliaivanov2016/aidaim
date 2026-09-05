unit EditMemo;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, DBCtrls;

type
  TMemoForm = class(TForm)
    Panel2: TPanel;
    btOk: TButton;
    Panel1: TPanel;
    GroupBox1: TGroupBox;
    Panel4: TPanel;
    Panel3: TPanel;
    ImportBtn: TButton;
    ExportBtn: TButton;
    GroupBox2: TGroupBox;
    SizeLbl: TLabel;
    Memo: TDBMemo;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    btCancel: TButton;
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
  MemoForm: TMemoForm;

implementation

uses MainUnit,db;

{$R *.DFM}

procedure TMemoForm.FormShow(Sender: TObject);
begin
 Memo.Datafield := MainForm.OpenGrid.SelectedField.FieldName;
 SizeLbl.Caption := IntToStr(Length(Memo.Text));
 MainForm.CurrentTable.Edit;
end;

procedure TMemoForm.ImportBtnClick(Sender: TObject);
var FS:TFileStream;
    BS:TStream;
begin
 if (OpenDialog1.Execute) then
  begin
   Memo.DataField := '';
   FS := TFileStream.Create(OpenDialog1.FileName,fmOpenRead);
   BS := MainForm.CurrentTable.CreateBlobStream(MainForm.OpenGrid.SelectedField,bmWrite);
   BS.CopyFrom(FS,FS.Size);
   SizeLbl.Caption := IntToStr(FS.Size);
   BS.Free;
   FS.Free;
   Memo.Datafield := MainForm.OpenGrid.SelectedField.FieldName;
  end;
end;

procedure TMemoForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
   Memo.DataField := '';
   if (MainForm.CurrentTable.State = dsEdit) then
    MainForm.CurrentTable.Cancel;
end;

procedure TMemoForm.ExportBtnClick(Sender: TObject);
var FS:TFileStream;
    BS:TStream;
begin
 try
  if (SaveDialog1.Execute) then
   begin
    Memo.DataField := '';
    Memo.Datafield := MainForm.OpenGrid.SelectedField.FieldName;
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

procedure TMemoForm.btOkClick(Sender: TObject);
begin
 MainForm.CurrentTable.Post;
end;

procedure TMemoForm.btCancelClick(Sender: TObject);
begin
 MainForm.CurrentTable.Cancel;
end;

end.

