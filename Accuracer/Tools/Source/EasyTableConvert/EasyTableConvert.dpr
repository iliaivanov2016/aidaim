program EasyTableConvert;

uses
  Forms,
  MainUnit in 'MainUnit.pas' {MainForm},
  ProgressIndicator in 'ProgressIndicator.pas' {FormProgress};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TFormProgress, FormProgress);
  Application.Run;
end.
