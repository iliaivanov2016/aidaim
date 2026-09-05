program ACRManager;

uses
  Forms,
  AboutUnit in 'AboutUnit.pas' {ACRManAbout},
  AddIndex in 'AddIndex.pas' {FormAddIndex},
  MainUnit in 'MainUnit.pas' {MainForm},
  EditBlob in 'EditBlob.pas' {BlobForm},
  EditMemo in 'EditMemo.pas' {MemoForm},
  EditFmtMemo in 'EditFmtMemo.pas' {FmtMemoForm},
  EditGraphic in 'EditGraphic.pas' {GraphicForm},
  Borrow in 'Borrow.pas' {FormBorrow},
  UseIndex in 'UseIndex.pas' {FormIndex},
  Filter in 'Filter.pas' {FormFilter},
  Find in 'Find.pas' {FormFind},
  RecNo in 'RecNo.pas' {FormRecNo},
  SetRange in 'SetRange.pas' {FormRange},
  Locate in 'Locate.pas' {FormLocate},
  FindKey in 'FindKey.pas' {FormFindKey},
  NewDatabase in 'NewDatabase.pas' {FormNewDatabase},
  Security in 'Security.pas' {FormSecurity},
  TableProgressCancel in 'TableProgressCancel.pas' {FormTableProgressCancel},
  WorkGrids in 'WorkGrids.pas',
  ProgressCancel in 'ProgressCancel.pas' {FormProgressCancel},
  uDatabaseInfo in 'uDatabaseInfo.pas' {DatabaseInfo},
  OpenDatabase in 'OpenDatabase.pas' {fmOpenDatabase},
  MakeExecutableDatabase in 'MakeExecutableDatabase.pas' {fmMakeExeDatabase},
  ExportToSQL in 'ExportToSQL.pas' {fmExportToSQL};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'Accuracer Manager';
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TACRManAbout, ACRManAbout);
  Application.CreateForm(TFormAddIndex, FormAddIndex);
  Application.CreateForm(TBlobForm, BlobForm);
  Application.CreateForm(TMemoForm, MemoForm);
  Application.CreateForm(TFmtMemoForm, FmtMemoForm);
  Application.CreateForm(TGraphicForm, GraphicForm);
  Application.CreateForm(TFormBorrow, FormBorrow);
  Application.CreateForm(TFormIndex, FormIndex);
  Application.CreateForm(TFormFilter, FormFilter);
  Application.CreateForm(TFormFind, FormFind);
  Application.CreateForm(TFormRecNo, FormRecNo);
  Application.CreateForm(TFormRange, FormRange);
  Application.CreateForm(TFormLocate, FormLocate);
  Application.CreateForm(TFormFindKey, FormFindKey);
  Application.CreateForm(TFormNewDatabase, FormNewDatabase);
  Application.CreateForm(TFormTableProgressCancel, FormTableProgressCancel);
  Application.CreateForm(TFormProgressCancel, FormProgressCancel);
  Application.CreateForm(TDatabaseInfo, DatabaseInfo);
  Application.CreateForm(TfmOpenDatabase, fmOpenDatabase);
  Application.CreateForm(TfmMakeExeDatabase, fmMakeExeDatabase);
  Application.CreateForm(TfmExportToSQL, fmExportToSQL);
  if FormSecurity = nil then
    FormSecurity := TFormSecurity.Create(Application);
  Application.Run;
end.
