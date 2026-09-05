program TETManager;

uses
  Forms,
  AboutUnit in 'AboutUnit.pas' {TETManAbout},
  AddIndex in 'AddIndex.pas' {FormAddIndex},
  MainUnit in 'MainUnit.pas' {MainForm},
  EditBlob in 'EditBlob.pas' {BlobForm},
  EditMemo in 'EditMemo.pas' {MemoForm},
  EditFmtMemo in 'EditFmtMemo.pas' {FmtMemoForm},
  EditGraphic in 'EditGraphic.pas' {GraphicForm},
  ProgressCancel in 'ProgressCancel.pas' {FormProgressCancel},
  ProgInd in 'ProgInd.pas' {FormProg},
  Borrow in 'Borrow.pas' {FormBorrow},
  UseIndex in 'UseIndex.pas' {FormIndex},
  Filter in 'Filter.pas' {FormFilter},
  Find in 'Find.pas' {FormFind},
  RecNo in 'RecNo.pas' {FormRecNo},
  SetRange in 'SetRange.pas' {FormRange},
  Locate in 'Locate.pas' {FormLocate},
  ProgressIndicator in 'ProgressIndicator.pas' {FormProgress},
  FindKey in 'FindKey.pas' {FormFindKey},
  AddRecords in 'AddRecords.pas' {AddRecordsForm},
  NewDatabase in 'NewDatabase.pas' {FormNewDatabase};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TTETManAbout, TETManAbout);
  Application.CreateForm(TFormAddIndex, FormAddIndex);
  Application.CreateForm(TBlobForm, BlobForm);
  Application.CreateForm(TMemoForm, MemoForm);
  Application.CreateForm(TFmtMemoForm, FmtMemoForm);
  Application.CreateForm(TGraphicForm, GraphicForm);
  Application.CreateForm(TFormProgressCancel, FormProgressCancel);
  Application.CreateForm(TFormProg, FormProg);
  Application.CreateForm(TFormBorrow, FormBorrow);
  Application.CreateForm(TFormIndex, FormIndex);
  Application.CreateForm(TFormFilter, FormFilter);
  Application.CreateForm(TFormFind, FormFind);
  Application.CreateForm(TFormRecNo, FormRecNo);
  Application.CreateForm(TFormRange, FormRange);
  Application.CreateForm(TFormLocate, FormLocate);
  Application.CreateForm(TFormProgress, FormProgress);
  Application.CreateForm(TFormFindKey, FormFindKey);
  Application.CreateForm(TAddRecordsForm, AddRecordsForm);
  Application.CreateForm(TFormNewDatabase, FormNewDatabase);
  Application.Run;
end.
