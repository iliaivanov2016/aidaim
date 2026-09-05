unit Unitdbp;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Db, exgrid, RapTree, FlytreePro, dbftreepro, StdCtrls,
  ExtCtrls, ComCtrls, DBCtrls, isplugedit, ispinedit, ISCalendar, EasyTable;

type
  TForm1 = class(TForm)
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    Panel1: TPanel;
    Label1: TLabel;
    DBFP1: TDBFlyTreeviewPro;
    DataSource1: TDataSource;
    DBNavigator1: TDBNavigator;
    DropdownFP: TDBFlyTreeviewPro;
    DetailsDS: TDataSource;
    TabSheet2: TTabSheet;
    Panel2: TPanel;
    Label2: TLabel;
    DBFP2: TDBFlyTreeviewPro;
    MasterSource: TDataSource;
    DemoDB: TEasyDatabase;
    MainTable: TEasyTable;
    Customers: TEasyTable;
    Details: TEasyTable;
    Master: TEasyTable;
    procedure FormCreate(Sender: TObject);
    procedure DBFP1GetNodeData(Node: TFlyNode; Column: Integer;
      var aData: String);
    procedure DBFP1PrepareDropDown(Sender: TISPlugInplaceEdit;
      Section: TISPlugSection; Dropdown: TISDropDown);
    procedure DBFP1ValidateNodeData(Node: TFlyNode; Column: Integer;
      var aData: String; var Cancel: Boolean);
    procedure DBFP1GetDropdownControl(Sender: TISPlugInplaceEdit;
      Section: TISPlugSection; DropDown: TISDropDown;
      var DropDownCtl: TWinControl);
    procedure ISCalendarKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure DBFP1CloseUp(Sender: TISPlugInplaceEdit;
      Section: TISPlugSection; DropDown: TISDropDown; var Accept: Boolean);
    procedure DBFP1ButtonPress(Sender: TISPlugInplaceEdit;
      Button: TPressedButtons);
    procedure DropdownFPKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure DBFP2ButtonPress(Sender: TISPlugInplaceEdit;
      Button: TPressedButtons);
    procedure DBFP2GetDropdownControl(Sender: TISPlugInplaceEdit;
      Section: TISPlugSection; DropDown: TISDropDown;
      var DropDownCtl: TWinControl);
    procedure DBFP2CloseUp(Sender: TISPlugInplaceEdit;
      Section: TISPlugSection; DropDown: TISDropDown; var Accept: Boolean);
    procedure DBFP2PrepareDropDown(Sender: TISPlugInplaceEdit;
      Section: TISPlugSection; Dropdown: TISDropDown);
    procedure DBFP2ValidateNodeData(Node: TFlyNode; Column: Integer;
      var aData: String; var Cancel: Boolean);
  private
    { Private declarations }
    //service functions
    procedure ActivateTable(aTable : TEasyTable);
    function GetCustomerID(aData : string) : string;
    function GetCustomerCompany(aData : string) : string;
    procedure FillCustomers(aSection : TISPlugSection);
  public
    { Public declarations }
  end;

  const
     DetailsCol = 'Details...';
     CustomerIDFld = 'CUSTOMERID';
     CompNameFld = 'COMPANYNAM';
     OrderDateFld = 'ORDERDATE';
     EmployeeFld = 'EMPLOYEEID';
var
  Form1: TForm1;

implementation

{$R *.DFM}

function TForm1.GetCustomerID(aData : string) : string;
begin
 if Customers.Active then
 begin
   if Customers.Locate(CompNameFld, aData, []) then
      Result := Customers.FieldValues[CustomerIDFld]
   else Result := '';//not found
 end;
end;

function TForm1.GetCustomerCompany(aData : string) : string;
begin
 if Customers.Active then
 begin
   if Customers.Locate(CustomerIDFld, aData, []) then
      Result := Customers.FieldValues[CompNameFld]
   else Result := aData;//not found
 end;
end;

procedure TForm1.FillCustomers(aSection : TISPlugSection);
var aNode : TFlyNode;
begin
 if Customers.Active then
 begin
  Customers.First;
  while not Customers.eof do
  begin
    // add items to section for dropdown
    aNode := aSection.Items.Add(nil, Customers.FieldValues[CompNameFld]);
    aNode.Cells[1] := Customers.FieldValues[CustomerIDFld];
    Customers.Next;
  end;
 end;
end;

procedure TForm1.ActivateTable(aTable : TEasyTable);
begin
 if not aTable.Active then
 begin
//  aTable.DatabaseName := ExtractFileDir(paramstr(0));
  aTable.Active := true;
 end;
end;


procedure TForm1.FormCreate(Sender: TObject);
begin
 ActivateTable(MainTable);
 ActivateTable(Customers);
 ActivateTable(Details);
 ActivateTable(Master);
end;


procedure TForm1.DBFP1GetNodeData(Node: TFlyNode; Column: Integer;
  var aData: String);
var aColumn : TDBTreeColumn;
begin
  aColumn := TDBTreeColumn(DBFP1.Columns.VisibleColumn[Column]);
  if aColumn.ColumnField = CustomerIDFld then
     aData := GetCustomerCompany(aData);//translate value
end;

procedure TForm1.DBFP1PrepareDropDown(Sender: TISPlugInplaceEdit;
  Section: TISPlugSection; Dropdown: TISDropDown);
var aColumn : TDBTreeColumn;
    aNode : TFlyNode;
begin
  aColumn := TDBTreeColumn(DBFP1.Columns.VisibleColumn[DBFP1.Col]);
  if aColumn.ColumnField = CustomerIDFld then
  begin
    Section.DropDownColcount := 2;
    Section.DropDownColWidth[1] := aColumn.Width;
    FillCustomers(Section);//fill data from another table

    with TPopupTree(Dropdown.ContainedControl) do
    begin
      FittoHeight := true;
      Colcount := 2; //create multicolumnar tree
      Width := aColumn.Width * 2;
      Height := 120;
      Options := Options + [goVertLine, goColSizing];//you can size columns in dropdown!
    end;
    DropDown.Styles := DropDown.Styles + [ddsSizeToControlSize];
  end
  else if aColumn.ColumnField = OrderDateFld then
  begin
     aNode :=  DBFP1.Selected;
     TISCalendar(Dropdown.ContainedControl).Date := StrToDate(aNode.Cells[dbFP1.Col]);
  end
  else if aColumn.ColumnField = EmployeeFld then
  begin
    DropDown.Styles := DropDown.Styles + [ddsok, ddsSizeToControlSize];//adjust dropdown size to control size
    DropdownFP.Datasource := DetailsDS; //connect
  end;
end;

procedure TForm1.DBFP1ValidateNodeData(Node: TFlyNode; Column: Integer;
  var aData: String; var Cancel: Boolean);
var aColumn : TDBTreeColumn;
begin
 try
  aColumn := TDBTreeColumn(DBFP1.Columns.VisibleColumn[Column]);
  if aColumn.ColumnField = CustomerIDFld then
  begin
    aData := GetCustomerID(aData);//translate value
    Cancel := aData = '';//if value not found
  end
  else if aColumn.ColumnField = EmployeeFld then
  begin
    Cancel :=true ;//prevent from input
  end;
 except
    Cancel := true; //cancel changes
 end;
end;

procedure TForm1.DBFP1GetDropdownControl(Sender: TISPlugInplaceEdit;
  Section: TISPlugSection; DropDown: TISDropDown;
  var DropDownCtl: TWinControl);
var aColumn : TDBTreeColumn;
begin
 aColumn := TDBTreeColumn(DBFP1.Columns.VisibleColumn[DBFP1.Col]);
 if aColumn.ColumnField = OrderDateFld then
 begin
   DropDownCtl := TISCalendar.Create(DropDown);
   with TISCalendar(DropDownCtl) do
   begin
     Colors.Backcolor := clBtnFace;
     Colors.TitleBackColor := clgray;
     Date := StrToDate(TISPlugEdit(Sender).Text);
     Width := TISPlugEdit(Sender).Width;
     Height := TISPlugEdit(Sender).Width;
     OnKeyDown := ISCalendarKeyDown;
     FixedStyle := dsRaised;
     TodayStyle := dsSunken;
     CalendarStyle := dsRaised;
     SelectedStyle := dsSunken;;
   end;
   DropDown.Styles := DropDown.Styles + [ddsSizeToControlSize];
 end
 else if aColumn.ColumnField = EmployeeFld then
 begin
   DropDownCtl := DropdownFP;
   DropDownCtl.Width := DBFP1.Width - Sender.Left;
   DropDownCtl.Height := DBFP1.Height - Sender.Top;
   DropdownFP.Parent := nil;
   DropdownFP.Parentwindow := DropDown.Handle;
   DropDownCtl.visible := true;
 end;
end;

procedure TForm1.ISCalendarKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
   VK_ESCAPE, VK_RETURN:
   begin
     DBFP1.CloseUp(Key = VK_RETURN);
     Key :=0;
   end;
  end;
end;

procedure TForm1.DBFP1CloseUp(Sender: TISPlugInplaceEdit;
  Section: TISPlugSection; DropDown: TISDropDown; var Accept: Boolean);
var aColumn : TDBTreeColumn;
begin
 aColumn := TDBTreeColumn(DBFP1.Columns.VisibleColumn[DBFP1.Col]);
 if (aColumn.ColumnField = OrderDateFld) and Accept then
 begin
    Sender.Text := DateToStr(TISCalendar(Dropdown.ContainedControl).Date);
 end
 else if aColumn.ColumnField = EmployeeFld then
 begin
   DropdownFP.Visible := false;
   DropdownFP.Parent :=Self;
   DropdownFP.Datasource := nil; //disconnect
 end;

end;

procedure TForm1.DBFP1ButtonPress(Sender: TISPlugInplaceEdit;
  Button: TPressedButtons);
var aColumn : TDBTreeColumn;
    aEmpID : string;
begin
 aColumn := TDBTreeColumn(DBFP1.Columns.VisibleColumn[DBFP1.Col]);
 if aColumn.ColumnField = EmployeeFld then
 begin
    aEmpID := DBFP1.Selected.Cells[DBFP1.Col];
    Details.Filtered :=false;
    Details.Filter := '['+EmployeeFld + ']='+ aEmpID;
    Details.Filtered :=true;
    Sender.Dropdown;
 end;

end;

procedure TForm1.DropdownFPKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key in [VK_RETURN, VK_ESCAPE]) then
  begin
   if Pagecontrol1.ActivePage = TabSheet1 then
     DBFP1.CloseUp(false)
   else
     DBFP2.CloseUp(false)
  end;
end;

procedure TForm1.DBFP2ButtonPress(Sender: TISPlugInplaceEdit;
  Button: TPressedButtons);
var aEmpID : string;
begin
   aEmpID := DBFP2.Selected.Cells[DBFP2.Col];
   Details.Filtered :=false;
   Details.Filter := '['+EmployeeFld + ']='+ aEmpID;
   Details.Filtered :=True;
   Sender.Dropdown;
end;

procedure TForm1.DBFP2GetDropdownControl(Sender: TISPlugInplaceEdit;
  Section: TISPlugSection; DropDown: TISDropDown;
  var DropDownCtl: TWinControl);
begin
   DropDownCtl := DropdownFP;
   DropDownCtl.Width := DBFP2.Width - Sender.Left;
   DropDownCtl.Height := DBFP2.Height - Sender.Top;
   DropdownFP.Parent := nil;
   DropdownFP.Parentwindow := DropDown.Handle;
   DropDownCtl.visible := true;
end;

procedure TForm1.DBFP2CloseUp(Sender: TISPlugInplaceEdit;
  Section: TISPlugSection; DropDown: TISDropDown; var Accept: Boolean);
begin
   DropdownFP.Visible := false;
   DropdownFP.Parent :=Self;
   DropdownFP.Datasource := nil; //disconnect
end;

procedure TForm1.DBFP2PrepareDropDown(Sender: TISPlugInplaceEdit;
  Section: TISPlugSection; Dropdown: TISDropDown);
begin
  DropDown.Styles := DropDown.Styles + [ddsok, ddsSizeToControlSize];//adjust dropdown size to control size
  DropdownFP.Datasource := DetailsDS; //connect
end;

procedure TForm1.DBFP2ValidateNodeData(Node: TFlyNode; Column: Integer;
  var aData: String; var Cancel: Boolean);
begin
  Cancel:=true //
end;

end.
