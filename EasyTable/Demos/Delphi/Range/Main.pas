unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, ExtCtrls, Grids, DBGrids, Db, EasyTable;

type
  TMainForm = class(TForm)
    EasyTable1: TEasyTable;
    DataSource1: TDataSource;
    Panel1: TPanel;
    Panel2: TPanel;
    Label1: TLabel;
    GroupBox1: TGroupBox;
    DBGrid1: TDBGrid;
    Panel3: TPanel;
    NewCustBtn: TBitBtn;
    EditCustBtn: TBitBtn;
    DeleteCustBtn: TBitBtn;
    GroupBox2: TGroupBox;
    cmbStartRange: TComboBox;
    Label2: TLabel;
    btApply: TButton;
    btCancel: TButton;
    Label3: TLabel;
    cmbEndRange: TComboBox;
    cbStartKeyExclusive: TCheckBox;
    cbEndKeyExclusive: TCheckBox;
    EasyDatabase1: TEasyDatabase;
    procedure FormCreate(Sender: TObject);
    procedure NewCustBtnClick(Sender: TObject);
    procedure EditCustBtnClick(Sender: TObject);
    procedure DeleteCustBtnClick(Sender: TObject);
    procedure btApplyClick(Sender: TObject);
    procedure btCancelClick(Sender: TObject);
  private
    { Private declarations }
    procedure UpdateButtons;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

uses Cust;

{$R *.DFM}

procedure TMainForm.FormCreate(Sender: TObject);
begin

  with EasyTable1 do
  {if table doesn't exist}
  if not Exists then
   begin
      {set table structure}
			with FieldDefs do
				begin
 			   Clear;
         Add('CustNo',ftAutoInc,0,False);
         Add('Company',ftString,30,False);
         Add('Address',ftString,30,False);
         Add('Phone',ftString,15,False);
         Add('FAX',ftString,15,False);
         Add('TaxRate',ftFloat,0,False);
         Add('LastInvoiceDate',ftDateTime,0,False);
 				end;
			with IndexDefs do
				begin
				 Clear;
         Add('PrimaryKey','CustNo',[ixPrimary]);
         Add('ByCompany','Company',[ixCaseInsensitive]);
				end;
      {and create the table}
	 	  CreateTable;
   end;
 // open table
 EasyTable1.Active := true;
 EasyTable1.IndexName := 'ByCompany';
 // update buttons
 UpdateButtons;
end;

procedure TMainForm.NewCustBtnClick(Sender: TObject);
begin
 EasyTable1.Insert;
 CustForm.ShowModal;
 // update buttons
 UpdateButtons;
end;

procedure TMainForm.EditCustBtnClick(Sender: TObject);
begin
 if (EditCustBtn.Enabled) then
  begin
   EasyTable1.Edit;
   CustForm.ShowModal;
   // update buttons
   UpdateButtons;
  end;
end;

procedure TMainForm.DeleteCustBtnClick(Sender: TObject);
begin
 if MessageDlg('Do you really want to delete '+
               QuotedStr(EasyTable1.FieldByName('Company').AsString)+
               ' company?',mtConfirmation,[mbYes,mbNo],0) = mrYes then
  EasyTable1.Delete;
 // update buttons
 UpdateButtons;
end;

procedure TMainForm.UpdateButtons;
begin
 // New / Edit / Delete buttons
 if (EasyTable1.RecordCount > 0) then
  begin
   EditCustBtn.Enabled := true;
   DeleteCustBtn.Enabled := true;
  end
 else
  begin
   EditCustBtn.Enabled := false;
   DeleteCustBtn.Enabled := false;
  end;
end;

procedure TMainForm.btApplyClick(Sender: TObject);
begin
 EasyTable1.IndexName := 'ByCompany';
 EasyTable1.SetRangeStart;
 EasyTable1.FieldByName('Company').AsString := cmbStartRange.Text;
 EasyTable1.KeyExclusive := cbStartKeyExclusive.Checked;
 EasyTable1.SetRangeEnd;
 EasyTable1.FieldByName('Company').AsString := cmbEndRange.Text;
 EasyTable1.KeyExclusive := cbEndKeyExclusive.Checked;
 EasyTable1.ApplyRange;
 btApply.Enabled := false;
 btCancel.Enabled := true;
 UpdateButtons;
end;

procedure TMainForm.btCancelClick(Sender: TObject);
begin
 EasyTable1.CancelRange;
 btApply.Enabled := true;
 btCancel.Enabled := false;
 UpdateButtons;
end;

end.
