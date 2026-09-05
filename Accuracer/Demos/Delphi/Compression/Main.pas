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
    DBMemo1: TDBMemo;
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
 // Create advanced field definition for VarChar field
 AdvFieldDef := ACRTable1.AdvFieldDefs.AddFieldDef;
 AdvFieldDef.Name := Form2.Edit1.Text;
 AdvFieldDef.DataType := aftMemo;
 AdvFieldDef.Size := 1000;
 if Form2.ComboBox2.ItemIndex > 0 then
  begin
   // Compression Algorithm (ZLIB, PPM, BZIP)
   case Form2.ComboBox2.ItemIndex of
    1:AdvFieldDef.BLOBCompressionAlgorithm := caZLIB;
    2:AdvFieldDef.BLOBCompressionAlgorithm := caBZIP;
    3:AdvFieldDef.BLOBCompressionAlgorithm := caPPM;
   end;
   // Compression Mode (from 1 to 9)
   AdvFieldDef.BLOBCompressionMode := Form2.SpinEdit3.Value;
  end;
 // Block Size in Bytes 
 if Form2.SpinEdit1.Value <> 102400 then
  AdvFieldDef.BLOBBlockSize := Form2.SpinEdit1.Value;
  
 AdvFieldDef := ACRTable1.AdvFieldDefs.AddFieldDef;
 AdvFieldDef.Name := 'Company';
 AdvFieldDef.DataType := aftChar;
 AdvFieldDef.Size := 25;
 ACRTable1.CreateTable;
 DBMemo1.DataField := Form2.Edit1.Text;
 ACRTable1.Active := true;

end;

end.
