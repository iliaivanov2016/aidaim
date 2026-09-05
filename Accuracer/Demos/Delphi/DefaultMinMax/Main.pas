unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  {$IFDEF VER140}
  Variants,
  {$ENDIF}
  Dialogs, Grids, DBGrids, StdCtrls, ExtCtrls, Buttons, DB, ACRMain,
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
 // Create advanced field definition
 AdvFieldDef := ACRTable1.AdvFieldDefs.AddFieldDef;
 AdvFieldDef.Name := Form2.Edit1.Text;
 case Form2.ComboBox2.ItemIndex of
  0: AdvFieldDef.DataType := aftString;
  1: AdvFieldDef.DataType := aftInteger;
 end;
 if AdvFieldDef.DataType = aftString then
  begin
   AdvFieldDef.Size := 30;
   if Form2.Edit2.Text <> '' then
    AdvFieldDef.DefaultValue.AsString := Form2.Edit2.Text;
   if Form2.Edit3.Text <> '' then
    AdvFieldDef.MinValue.AsString := Form2.Edit3.Text;
   if Form2.Edit4.Text <> '' then
    AdvFieldDef.MaxValue.AsString := Form2.Edit4.Text;
  end
 else
  begin
   AdvFieldDef.Size := 0;
   if Form2.Edit2.Text <> '' then
    AdvFieldDef.DefaultValue.AsInteger := StrToInt(Form2.Edit2.Text);
   if Form2.Edit3.Text <> '' then
    AdvFieldDef.MinValue.AsInteger := StrToInt(Form2.Edit3.Text);
   if Form2.Edit4.Text <> '' then
    AdvFieldDef.MaxValue.AsInteger := StrToInt(Form2.Edit4.Text);
  end;
  
 AdvFieldDef := ACRTable1.AdvFieldDefs.AddFieldDef;
 AdvFieldDef.Name := 'Company';
 AdvFieldDef.DataType := aftChar;
 AdvFieldDef.Size := 25;
 ACRTable1.CreateTable;
 ACRTable1.Active := true;

end;

end.
