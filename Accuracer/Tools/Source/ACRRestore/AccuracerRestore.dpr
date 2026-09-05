program AccuracerRestore;

uses
  Forms,
  uMain in 'uMain.pas' {fmMain},
  WorkGrids in 'WorkGrids.pas',
  ProgressCancel in 'ProgressCancel.pas' {FormProgressCancel};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfmMain, fmMain);
  Application.CreateForm(TFormProgressCancel, FormProgressCancel);
  Application.Run;
end.
