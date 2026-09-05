unit Filter;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Buttons, StdCtrls, ComCtrls, Db;

type
  TFormFilter = class(TForm)
    bnClear: TButton;
    bnSet: TButton;
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
    procedure bnSetClick(Sender: TObject);
    procedure bnClearClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormFilter: TFormFilter;

implementation

uses MainUnit;
{$R *.DFM}

procedure TFormFilter.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 Action := caHide;
end;

procedure TFormFilter.lbRelDblClick(Sender: TObject);
begin
 reFilter.Text := reFilter.Text + ' '+
  lbRel.Items[lbRel.ItemIndex] + ' ';
end;

procedure TFormFilter.lbLogicDblClick(Sender: TObject);
begin
 reFilter.Text := reFilter.Text + ' '+
  lbLogic.Items[lbLogic.ItemIndex] + ' ';
end;

procedure TFormFilter.lbFieldsDblClick(Sender: TObject);
begin
 reFilter.Text := reFilter.Text + ' '+
  lbFields.Items[lbFields.ItemIndex] + ' ';
end;

procedure TFormFilter.bnSetClick(Sender: TObject);
begin
 MainForm.CurrentTable.Filtered := false;
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
 MainForm.CurrentTable.Filtered := true;
 Close;
end;

procedure TFormFilter.bnClearClick(Sender: TObject);
begin
 MainForm.CurrentTable.Filtered := false;
 Close;
end;

end.
