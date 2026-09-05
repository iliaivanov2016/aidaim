unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  {$IFDEF VER140}
  Variants,
  {$ENDIF}
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
    SearchCondition: TComboBox;
    Label2: TLabel;
    btFindKey: TButton;
    btFindNearest: TButton;
    btGotoKey: TButton;
    btGotoNearest: TButton;
    EasyDatabase1: TEasyDatabase;
    procedure FormCreate(Sender: TObject);
    procedure NewCustBtnClick(Sender: TObject);
    procedure EditCustBtnClick(Sender: TObject);
    procedure DeleteCustBtnClick(Sender: TObject);
    procedure btFindKeyClick(Sender: TObject);
    procedure btFindNearestClick(Sender: TObject);
    procedure btGotoKeyClick(Sender: TObject);
    procedure btGotoNearestClick(Sender: TObject);
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

procedure TMainForm.btFindKeyClick(Sender: TObject);
begin
 EasyTable1.IndexName := 'ByCompany';
 if (not EasyTable1.FindKey([SearchCondition.Text])) then
    MessageDlg('Record not found.',mtInformation,[mbOk],0);
end;

procedure TMainForm.btFindNearestClick(Sender: TObject);
begin
  EasyTable1.IndexName := 'ByCompany';
  EasyTable1.FindNearest([SearchCondition.Text]);
end;

procedure TMainForm.btGotoKeyClick(Sender: TObject);
begin
  EasyTable1.IndexName := 'ByCompany';
  EasyTable1.SetKey;
  EasyTable1.FieldByName('Company').AsString := SearchCondition.Text;
  if (not EasyTable1.GotoKey()) then
    MessageDlg('Record not found.',mtInformation,[mbOk],0);
end;

procedure TMainForm.btGotoNearestClick(Sender: TObject);
begin
  EasyTable1.IndexName := 'ByCompany';
  EasyTable1.SetKey;
  EasyTable1.FieldByName('Company').AsString := SearchCondition.Text;
  EasyTable1.GotoNearest;
end;

end.
