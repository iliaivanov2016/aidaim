unit UseIndex;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, Db;

type
  TFormIndex = class(TForm)
    lbIndexes: TListBox;
    Label1: TLabel;
    Label2: TLabel;
    bnOk: TBitBtn;
    bnCancel: TBitBtn;
    IndexFields: TEdit;
    cbDesc: TCheckBox;
    cbIns: TCheckBox;
    cbUnique: TCheckBox;
    cbPrimary: TCheckBox;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure lbIndexesDblClick(Sender: TObject);
    procedure lbIndexesClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormIndex: TFormIndex;

implementation

uses MainUnit;

{$R *.DFM}

procedure TFormIndex.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
 Action := caHide;
end;

procedure TFormIndex.lbIndexesDblClick(Sender: TObject);
begin
 bnOk.Click;
end;

procedure TFormIndex.lbIndexesClick(Sender: TObject);
begin
 // descending
 if (ixDescending	in MainForm.CurrentTable.IndexDefs.Find(
 			lbIndexes.Items[lbIndexes.ItemIndex]).Options) then
  cbDesc.Checked := true
 else
  cbDesc.Checked := false;
 // primary
 if (ixPrimary	in MainForm.CurrentTable.IndexDefs.Find(
 			lbIndexes.Items[lbIndexes.ItemIndex]).Options) then
  cbPrimary.Checked := true
 else
  cbPrimary.Checked := false;
 // unique
 if (ixUnique	in MainForm.CurrentTable.IndexDefs.Find(
 			lbIndexes.Items[lbIndexes.ItemIndex]).Options) then
  cbUnique.Checked := true
 else
  cbUnique.Checked := false;
 // case insensitive
 if (ixCaseInsensitive	in MainForm.CurrentTable.IndexDefs.Find(
 			lbIndexes.Items[lbIndexes.ItemIndex]).Options) then
  cbIns.Checked := true
 else
  cbIns.Checked := false;
 // index fields
 IndexFields.Text := MainForm.CurrentTable.IndexDefs.Find(
 			lbIndexes.Items[lbIndexes.ItemIndex]).Fields;
end;

end.
