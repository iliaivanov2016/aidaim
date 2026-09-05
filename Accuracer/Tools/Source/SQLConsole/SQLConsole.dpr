program SQLConsole;

uses
  Forms,
  uMain in 'uMain.pas' {fmMain},
  AboutUnit in 'AboutUnit.pas' {SQLConsoleAbout},
  NewDatabase in 'NewDatabase.pas' {FormNewDatabase},
  Security in 'Security.pas' {FormSecurity},
  WorkGrids in 'WorkGrids.pas',
  OpenDatabase in 'OpenDatabase.pas' {fmOpenDatabase},
  ExportToSQL in 'ExportToSQL.pas' {fmExportToSQL};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TfmMain, fmMain);
  Application.CreateForm(TSQLConsoleAbout, SQLConsoleAbout);
  Application.CreateForm(TFormNewDatabase, FormNewDatabase);
  Application.CreateForm(TfmOpenDatabase, fmOpenDatabase);
  Application.CreateForm(TfmExportToSQL, fmExportToSQL);
  if FormSecurity = nil then
    FormSecurity := TFormSecurity.Create(Application);
  Application.Run;
end.
