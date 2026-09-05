unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, Grids, DBGrids, StdCtrls, ExtCtrls, Buttons, DB, ACRMain,
  {$IFDEF VER140}
  Variants,
  {$ENDIF}
  DBCtrls, ACRTypes;

type
  TMainForm = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    GroupBox1: TGroupBox;
    DBGrid1: TDBGrid;
    Label1: TLabel;
    ACRTable1: TACRTable;
    ACRDatabase1: TACRDatabase;
    DataSource1: TDataSource;
    NewCustBtn: TBitBtn;
    DBNavigator1: TDBNavigator;
    procedure FormCreate(Sender: TObject);
    procedure NewCustBtnClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses Cust;

procedure TMainForm.FormCreate(Sender: TObject);
begin
 ACRDatabase1.Connected := True;
 if ACRTable1.Exists then
  ACRTable1.Active := True;
end;

procedure TMainForm.NewCustBtnClick(Sender: TObject);
var
 AdvFieldDef: TACRAdvFieldDef;
begin

 if (Form2.ShowModal=mrCancel) then
  Exit;

 ACRTable1.Active := false;

 if ACRTable1.Exists then ACRTable1.DeleteTable;

 ACRTable1.AdvFieldDefs.Clear;
 // Create advanced field definition for AutoInc field
 AdvFieldDef := ACRTable1.AdvFieldDefs.AddFieldDef;
 AdvFieldDef.Name := Form2.Edit1.Text;
 case Form2.ComboBox1.ItemIndex of
  0:AdvFieldDef.DataType := aftAutoInc;
  1:AdvFieldDef.DataType := aftAutoIncShortint;
  2:AdvFieldDef.DataType := aftAutoIncSmallint;
  3:AdvFieldDef.DataType := aftAutoIncInteger;
  4:AdvFieldDef.DataType := aftAutoIncLargeint;
  5:AdvFieldDef.DataType := aftAutoIncByte;
  6:AdvFieldDef.DataType := aftAutoIncWord;
  7:AdvFieldDef.DataType := aftAutoIncCardinal;
 end;
 AdvFieldDef.Size := 0;
 // AutoincMinValue
 if (Form2.SpinEdit4.Value > -1) then
  AdvFieldDef.AutoincMinValue := Form2.SpinEdit4.Value;
 // AutoincMaxValue
 if (Form2.SpinEdit1.Value > 0) then
  AdvFieldDef.AutoincMaxValue := Form2.SpinEdit1.Value;
 // AutoincInitialValue
 if (Form2.SpinEdit2.Value > -1) then
  AdvFieldDef.AutoincInitialValue := Form2.SpinEdit2.Value;
 // AutoincIncrement
 if (Form2.SpinEdit3.Value > 1) then
  AdvFieldDef.AutoincIncrement := Form2.SpinEdit3.Value;
 // AutoincCycled
 AdvFieldDef.AutoincCycled := Form2.CheckBox1.Checked;

 AdvFieldDef := ACRTable1.AdvFieldDefs.AddFieldDef;
 AdvFieldDef.Name := 'Company';
 AdvFieldDef.DataType := aftChar;
 AdvFieldDef.Size := 25;
 ACRTable1.CreateTable;
 ACRTable1.Active := true;

end;

end.
