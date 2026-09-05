unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  EasyTable, Db, ExtCtrls, DBCtrls, Grids, DBGrids, StdCtrls;

type
  TMainForm = class(TForm)
    EasyTable1: TEasyTable;
    EasyDatabase1: TEasyDatabase;
    DataSource1: TDataSource;
    EasyTable2: TEasyTable;
    DataSource2: TDataSource;
    DBGrid1: TDBGrid;
    DBGrid2: TDBGrid;
    DBNavigator1: TDBNavigator;
    DBNavigator2: TDBNavigator;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    btSaveTable: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btSaveTableClick(Sender: TObject);
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
 EasyTable1.InMemory := true;
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
 EasyTable1.Active := true;

 EasyTable2.InMemory := true;
 EasyTable2.Active := true;
end;

procedure TMainForm.btSaveTableClick(Sender: TObject);
begin
 EasyTable2.SaveTable;
end;

end.
