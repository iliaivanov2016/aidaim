unit ExportToSQL;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons;

type
  TfmExportToSQL = class(TForm)
    BitBtn3: TBitBtn;
    BitBtn4: TBitBtn;
    cbUseBrackets: TCheckBox;
    GroupBox1: TGroupBox;
    cbExportStructure: TCheckBox;
    cbAddDROPTable: TCheckBox;
    GroupBox2: TGroupBox;
    cbExportIndexes: TCheckBox;
    cbAddDROPIndex: TCheckBox;
    GroupBox3: TGroupBox;
    cbExportData: TCheckBox;
    cbExportBLOBFields: TCheckBox;
    procedure cbExportStructureClick(Sender: TObject);
    procedure cbExportDataClick(Sender: TObject);
    procedure cbExportIndexesClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fmExportToSQL: TfmExportToSQL;

implementation

{$R *.dfm}

procedure TfmExportToSQL.cbExportStructureClick(Sender: TObject);
begin
 if (cbExportStructure.Checked) then
  begin
   cbAddDROPTable.Enabled := True;
  end
 else
  begin
   cbAddDROPTable.Enabled := False;
   cbAddDROPTable.Checked := False;
  end;
end;

procedure TfmExportToSQL.cbExportDataClick(Sender: TObject);
begin
 if (cbExportData.Checked) then
  begin
   cbExportBLOBFields.Enabled := True;
  end
 else
  begin
   cbExportBLOBFields.Enabled := False;
   cbExportBLOBFields.Checked := False;
  end;
end;

procedure TfmExportToSQL.cbExportIndexesClick(Sender: TObject);
begin
 if (cbExportIndexes.Checked) then
  begin
   cbAddDROPIndex.Enabled := True;
  end
 else
  begin
   cbAddDROPIndex.Enabled := False;
   cbAddDROPIndex.Checked := False;
  end;
end;

end.
