unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
 Db, ExtCtrls, DBCtrls, Grids, DBGrids, StdCtrls, ACRMain;

type
  TMainForm = class(TForm)
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    Label1: TLabel;
    Label2: TLabel;
    btSaveTable: TButton;
    ACRTable1: TACRTable;
    Button1: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btSaveTableClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.DFM}

procedure TMainForm.FormCreate(Sender: TObject);
begin
 ACRTable1.InMemory := true;
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
 ACRTable1.Active := true;

end;

procedure TMainForm.btSaveTableClick(Sender: TObject);
begin
 ACRTable1.Close;
 ACRTable1.SaveTableToFile('customers.tbl');
 ACRTable1.Open;
end;

procedure TMainForm.Button1Click(Sender: TObject);
begin
 ACRTable1.Close;
 ACRTable1.LoadTableFromFile('customers.tbl');
 ACRTable1.Open;
end;

end.
