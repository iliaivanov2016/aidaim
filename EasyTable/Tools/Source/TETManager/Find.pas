unit Find;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Buttons, StdCtrls, ComCtrls, Db;

type
  TFormFind = class(TForm)
    bnFirst: TButton;
    bnNext: TButton;
    bnPrior: TButton;
    bnLast: TButton;
    BitBtn1: TBitBtn;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    reFilter: TRichEdit;
    lbFields: TListBox;
    lbRel: TListBox;
    lbLogic: TListBox;
    cbNoComp: TCheckBox;
    cbCaseIns: TCheckBox;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure lbRelDblClick(Sender: TObject);
    procedure lbLogicDblClick(Sender: TObject);
    procedure lbFieldsDblClick(Sender: TObject);
    procedure bnFirstClick(Sender: TObject);
    procedure bnPriorClick(Sender: TObject);
    procedure bnLastClick(Sender: TObject);
    procedure bnNextClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormFind: TFormFind;

implementation

uses MainUnit;
{$R *.DFM}

procedure TFormFind.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 Action := caHide;
end;

procedure TFormFind.lbRelDblClick(Sender: TObject);
begin
 reFilter.Text := reFilter.Text + ' '+
  lbRel.Items[lbRel.ItemIndex] + ' ';
end;

procedure TFormFind.lbLogicDblClick(Sender: TObject);
begin
 reFilter.Text := reFilter.Text + ' '+
  lbLogic.Items[lbLogic.ItemIndex] + ' ';
end;

procedure TFormFind.lbFieldsDblClick(Sender: TObject);
begin
 reFilter.Text := reFilter.Text + ' '+
  lbFields.Items[lbFields.ItemIndex] + ' ';
end;

procedure TFormFind.bnFirstClick(Sender: TObject);
begin
 MainForm.CurrentTable.Filter := reFilter.text;
 MainForm.CurrentTable.FilterOptions := [];
 // no partial comparison
 if (cbNoComp.Checked) then
  MainForm.CurrentTable.FilterOptions :=
  	MainForm.CurrentTable.FilterOptions + [foNoPartialCompare];
 // case insensitive
 if (cbCaseIns.Checked) then
  MainForm.CurrentTable.FilterOptions :=
  	MainForm.CurrentTable.FilterOptions + [foCaseInsensitive];
 MainForm.CurrentTable.FindFirst;
 Close;
end;

procedure TFormFind.bnPriorClick(Sender: TObject);
begin
 MainForm.CurrentTable.FindPrior;
 Close;
end;

procedure TFormFind.bnLastClick(Sender: TObject);
begin
 MainForm.CurrentTable.Filter := reFilter.text;
 MainForm.CurrentTable.FilterOptions := [];
 // no partial comparison
 if (cbNoComp.Checked) then
  MainForm.CurrentTable.FilterOptions :=
  	MainForm.CurrentTable.FilterOptions + [foNoPartialCompare];
 // case insensitive
 if (cbCaseIns.Checked) then
  MainForm.CurrentTable.FilterOptions :=
  	MainForm.CurrentTable.FilterOptions + [foCaseInsensitive];
 MainForm.CurrentTable.FindLast;
 Close;
end;

procedure TFormFind.bnNextClick(Sender: TObject);
begin
 MainForm.CurrentTable.FindNext;
 Close;
end;

end.
