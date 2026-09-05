unit Main;

interface

{$I ..\..\Ver.Inc}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, ExtCtrls, Grids, DBGrids, Db,ACRMain;

type
  TMainForm = class(TForm)
    DataSource1: TDataSource;
    Panel1: TPanel;
    NewCustBtn: TBitBtn;
    EditCustBtn: TBitBtn;
    DeleteCustBtn: TBitBtn;
    Panel2: TPanel;
    Label1: TLabel;
    GroupBox1: TGroupBox;
    DBGrid1: TDBGrid;
    ACRTable1: TACRTable;
    ACRDatabase1: TACRDatabase;
    procedure FormCreate(Sender: TObject);
    procedure NewCustBtnClick(Sender: TObject);
    procedure EditCustBtnClick(Sender: TObject);
    procedure DeleteCustBtnClick(Sender: TObject);
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
  with ACRTable1 do
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
 ACRTable1.Active := true;
 // update buttons
 UpdateButtons;
end;

procedure TMainForm.NewCustBtnClick(Sender: TObject);
begin
 ACRTable1.Insert;
 CustForm.ShowModal;
 // update buttons
 UpdateButtons;
end;

procedure TMainForm.EditCustBtnClick(Sender: TObject);
begin
 if (EditCustBtn.Enabled) then
  begin
   ACRTable1.Edit;
   CustForm.ShowModal;
   // update buttons
   UpdateButtons;
  end;
end;

procedure TMainForm.DeleteCustBtnClick(Sender: TObject);
begin
 if MessageDlg('Do you really want to delete '+
               QuotedStr(ACRTable1.FieldByName('Company').AsString)+
               ' company?',mtConfirmation,[mbYes,mbNo],0) = mrYes then
  ACRTable1.Delete;
 // update buttons
 UpdateButtons;
end;

procedure TMainForm.UpdateButtons;
begin
 if (ACRTable1.RecordCount > 0) then
  begin
   EditCustBtn.Enabled := true;
   DeleteCustBtn.Enabled := true;
  end
 else
  begin
   EditCustBtn.Enabled := false;
   DeleteCustBtn.Enabled := false;
  end
end;

end.
